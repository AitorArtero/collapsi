import 'package:flutter/material.dart';
import '../../config/ui_constants.dart';
import '../../core/collapsi_engine.dart';
import '../../core/haptic_manager.dart';
import '../../core/sound_manager.dart';
import '../../core/path_finder.dart';
import 'game_cell.dart';
import 'animated_piece.dart'; //

/// Widget del tablero de juego - Con sistema completo de animaciones
class GameBoard extends StatefulWidget {
  final CollapsiEngine game;
  final Function(int x, int y)? onCellTap;
  final bool enableAnimations;

  const GameBoard({
    super.key,
    required this.game,
    this.onCellTap,
    this.enableAnimations = true, // Por defecto habilitadas
  });

  @override
  State<GameBoard> createState() => GameBoardState();
}

class GameBoardState extends State<GameBoard> {
  // Referencias a las celdas para poder actualizar su ayuda de movimiento
  final List<List<GlobalKey>> _cellKeys = [];
  int _lastPlayerTurn = -1;
  
  // Sistema de animaciones
  bool _isAnimating = false;
  List<GridPoint>? _currentAnimationPath;
  int? _animatingPlayer;
  late GamePathFinder _pathFinder;
  double _boardSize = 0;
  
  // Callback para ejecutar movimiento después de animación
  Function()? _pendingMoveExecution;

  @override
  void initState() {
    super.initState();
    _initializeCellKeys();
    _lastPlayerTurn = widget.game.currentPlayer;
    _pathFinder = GamePathFinder(widget.game);
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Detectar cambio de turno y notificar a las celdas
    if (widget.game.currentPlayer != _lastPlayerTurn) {
      _lastPlayerTurn = widget.game.currentPlayer;
      _notifyTurnChangeToAllCells();
    }
    
    // Recrear PathFinder si cambió el game instance
    if (widget.game != oldWidget.game) {
      _pathFinder = GamePathFinder(widget.game);
    }
  }

  // Inicializar keys para las celdas
  void _initializeCellKeys() {
    _cellKeys.clear();
    for (int y = 0; y < widget.game.gridSize; y++) {
      List<GlobalKey> row = [];
      for (int x = 0; x < widget.game.gridSize; x++) {
        row.add(GlobalKey());
      }
      _cellKeys.add(row);
    }
  }

  // Notificar cambio de turno a todas las celdas
  void _notifyTurnChangeToAllCells() {
    for (int y = 0; y < widget.game.gridSize; y++) {
      for (int x = 0; x < widget.game.gridSize; x++) {
        final cellState = _cellKeys[y][x].currentState as GameCellState?;
        cellState?.forceUpdateMovementHelp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reinicializar keys si el tamaño del grid cambió
    if (_cellKeys.length != widget.game.gridSize) {
      _initializeCellKeys();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular el tamaño máximo disponible considerando padding
        final availableWidth = constraints.maxWidth - (UIConstants.spacing16 * 2);
        final availableHeight = constraints.maxHeight - (UIConstants.spacing16 * 2);
        final maxSize = availableWidth < availableHeight ? availableWidth : availableHeight;
        
        // Guardar el tamaño del tablero para animaciones
        _boardSize = maxSize;
        
        return Center(
          child: Container(
            width: maxSize,
            height: maxSize,
            decoration: BoxDecoration(
              color: UIColors.gridBackground,
              borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
              border: Border.all(
                color: UIColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: UIColors.shadow,
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Tablero base con celdas
                Padding(
                  padding: const EdgeInsets.all(UIConstants.spacing8),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.game.gridSize,
                      crossAxisSpacing: UIConstants.cellPadding,
                      mainAxisSpacing: UIConstants.cellPadding,
                    ),
                    itemCount: widget.game.gridSize * widget.game.gridSize,
                    itemBuilder: (context, index) {
                      final x = index % widget.game.gridSize;
                      final y = index ~/ widget.game.gridSize;
                      
                      return GameCell(
                        key: _cellKeys[y][x],
                        gridX: x,
                        gridY: y,
                        game: widget.game,
                        onTap: widget.onCellTap != null ? () => _handleCellTap(x, y) : null,
                      );
                    },
                  ),
                ),
                
                // Overlay de animación
                if (_isAnimating && _currentAnimationPath != null && _animatingPlayer != null)
                  MovementAnimationOverlay(
                    path: _currentAnimationPath!,
                    player: _animatingPlayer!,
                    boardSize: _boardSize,
                    gridSize: widget.game.gridSize,
                    onComplete: _onAnimationComplete,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Maneja tap en celda con posible animación
  Future<void> _handleCellTap(int x, int y) async {
    // No permitir nuevos taps durante animación
    if (_isAnimating) {
      print('⚠️ GameBoard: Ignorando tap durante animación');
      return;
    }
    
    final isValid = widget.game.isValidMoveCell(x, y);
    
    if (isValid) {
      //  Movimiento válido
      await HapticManager.instance.cellTap();
      await SoundManager.instance.playCellTap();
      
      // Ejecutar con animación si está habilitada
      if (widget.enableAnimations) {
        await _executeAnimatedMove(x, y, widget.game.currentPlayer);
      } else {
        // Ejecución directa sin animación
        widget.onCellTap?.call(x, y);
      }
    } else {
      // Movimiento inválido
      await HapticManager.instance.moveInvalid();
      await SoundManager.instance.playMoveInvalid();
    }
  }

  /// Ejecuta movimiento con animación
  Future<void> _executeAnimatedMove(int targetX, int targetY, int player) async {
    if (_isAnimating) {
      print('⚠️ GameBoard: Ya hay una animación en curso');
      return;
    }
    
    print('🎬 GameBoard: Iniciando movimiento animado a ($targetX,$targetY) para jugador $player');

    // Para comprobar que no hya discrepancias entre el path del engine y el pathFinder
    GamePathFinder.debugCompareAlgorithms(widget.game, targetX, targetY);

    // Desactivar ayuda de movimiento durante animación
    _disableMovementHelpTemporarily();
    
    // Encontrar el path del movimiento
    final path = _pathFinder.findMovementPath(targetX, targetY, forPlayer: player);
    
    if (path == null || path.isEmpty) {
      print('❌ GameBoard: No se pudo encontrar path, ejecutando movimiento directo');
      widget.onCellTap?.call(targetX, targetY);
      return;
    }
    
    // Validar el path
    if (!_pathFinder.validatePath(path, targetX, targetY)) {
      print('❌ GameBoard: Path inválido, ejecutando movimiento directo');
      widget.onCellTap?.call(targetX, targetY);
      return;
    }
    
    // Configurar animación
    setState(() {
      _isAnimating = true;
      _currentAnimationPath = path;
      _animatingPlayer = player;
    });

    
    
    // Guardar callback para ejecutar el movimiento real al finalizar
    _pendingMoveExecution = () {
      widget.onCellTap?.call(targetX, targetY);
    };
    
    print('✅ GameBoard: Animación configurada con path de ${path.length} puntos (300ms por movimiento)');
  }

  /// Callback cuando termina la animación
  void _onAnimationComplete() {
    print('✅ GameBoard: Animación completada, ejecutando movimiento real');
    
    // Ejecutar el movimiento real
    final moveExecution = _pendingMoveExecution;
    
    // Limpiar estado de animación
    setState(() {
      _isAnimating = false;
      _currentAnimationPath = null;
      _animatingPlayer = null;
    });
    _pendingMoveExecution = null;
    
    // Ejecutar movimiento después de limpiar el estado
    moveExecution?.call();

    // NOTA: La ayuda de movimiento se reactivará automáticamente
    // cuando cambie el turno y se llame a _notifyTurnChangeToAllCells()
  }

  /// Ejecuta movimiento de IA con animación
  Future<void> executeAIMove(int targetX, int targetY) async {
    print('🤖 GameBoard: executeAIMove llamado para ($targetX,$targetY)');
    
    if (!widget.enableAnimations) {
      // Sin animación, ejecutar directamente en el engine
      print('🤖 GameBoard: Animaciones deshabilitadas, ejecutando directo');
      widget.game.executeAIMove(targetX, targetY);
      return;
    }
    
    print('🤖 GameBoard: Buscando path para movimiento de IA');

    // Desactivar ayuda de movimiento durante animación de IA
    _disableMovementHelpTemporarily();
    
    // Encontrar el path del movimiento
    final path = _pathFinder.findMovementPath(targetX, targetY, forPlayer: 1);
    
    if (path == null || path.isEmpty) {
      print('❌ GameBoard: No se pudo encontrar path para IA, ejecutando directo');
      widget.game.executeAIMove(targetX, targetY);
      return;
    }
    
    print('🎯 GameBoard: Path encontrado para IA: ${path.map((p) => "(${p.x},${p.y})").join(" → ")}');
    
    // Validar el path
    if (!_pathFinder.validatePath(path, targetX, targetY)) {
      print('❌ GameBoard: Path de IA inválido, ejecutando directo');
      widget.game.executeAIMove(targetX, targetY);
      return;
    }
    
    print('✅ GameBoard: Path de IA validado correctamente');
    
    // Verificar si ya hay una animación en curso
    if (_isAnimating) {
      print('⚠️ GameBoard: Ya hay una animación en curso, cancelando IA');
      widget.game.executeAIMove(targetX, targetY);
      return;
    }
    
    // Configurar animación
    setState(() {
      _isAnimating = true;
      _currentAnimationPath = path;
      _animatingPlayer = 1; // IA siempre es jugador 1
    });
    
    // Guardar callback para ejecutar el movimiento real de IA al finalizar
    _pendingMoveExecution = () {
      print('🎬 GameBoard: Ejecutando movimiento real de IA tras animación');
      widget.game.executeAIMove(targetX, targetY);
    };
    
    print('✅ GameBoard: Animación de IA configurada con path de ${path.length} puntos (300ms por movimiento)');
  }
  
  /// Cancela animación actual si existe
  void cancelCurrentAnimation() {
    if (_isAnimating) {
      print('🚫 GameBoard: Cancelando animación actual');
      setState(() {
        _isAnimating = false;
        _currentAnimationPath = null;
        _animatingPlayer = null;
      });
      _pendingMoveExecution = null;
    }
  }

  /// Desactiva temporalmente la ayuda de movimiento en todas las celdas
  void _disableMovementHelpTemporarily() {
    print('🎬 GameBoard: Desactivando ayuda de movimiento durante animación');

    for (int y = 0; y < widget.game.gridSize; y++) {
      for (int x = 0; x < widget.game.gridSize; x++) {
        final cellState = _cellKeys[y][x].currentState as GameCellState?;
        cellState?.disableMovementHelpTemporarily();
      }
    }
  }


  // Actualizar configuraciones de ayuda en todas las celdas
  void updateMovementHelpInAllCells(bool enabled, double delay) {
    for (int y = 0; y < widget.game.gridSize; y++) {
      for (int x = 0; x < widget.game.gridSize; x++) {
        final cellState = _cellKeys[y][x].currentState as GameCellState?;
        cellState?.updateMovementHelpSettings(enabled, delay);
      }
    }
  }

  // Getters para estado de animación
  bool get isAnimating => _isAnimating;
  int? get animatingPlayer => _animatingPlayer;
  List<GridPoint>? get currentAnimationPath => _currentAnimationPath;
}
