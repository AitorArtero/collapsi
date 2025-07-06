import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/ui_constants.dart';
import '../../config/game_constants.dart';
import '../../core/collapsi_engine.dart';
import '../../config/app_settings.dart';

/// Widget individual para cada celda del tablero - Con delay y animación gradual
class GameCell extends StatefulWidget {
  final int gridX;
  final int gridY;
  final CollapsiEngine game;
  final VoidCallback? onTap;

  const GameCell({
    super.key,
    required this.gridX,
    required this.gridY,
    required this.game,
    this.onTap,
  });

  @override
  State<GameCell> createState() => GameCellState(); // 🆕 CAMBIO: Hacer público
}

class GameCellState extends State<GameCell> // 🆕 CAMBIO: Clase pública
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isPressed = false;
  bool _movementHelpEnabled = false; // Por defecto false después del tutorial
  double _movementHelpDelay = 3.0; // Por defecto 3 segundos
  bool _showingValidMoves = false; // Controla si se muestran movimientos válidos
  Timer? _delayTimer; // Timer para el delay
  int _lastPlayerTurn = -1; // Para detectar cambios de turno
  bool _helpTemporarilyDisabled = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: AnimationConstants.extremelySlow,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConstants.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConstants.easeInOut,
    ));

    // Animación para fade-in gradual
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Cargar configuraciones iniciales
    _loadMovementHelpSettings();
  }

  @override
  void dispose() {
    _delayTimer?.cancel(); // Cancelar timer
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GameCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Detectar cambio de turno
    if (widget.game.currentPlayer != _lastPlayerTurn) {
      _lastPlayerTurn = widget.game.currentPlayer;
      _onTurnChanged();
    }
  }

  // Cargar configuraciones de ayuda de movimiento
  Future<void> _loadMovementHelpSettings() async {
    try {
      final settings = await AppSettings.getMovementHelpSettings();
      if (mounted) {
        setState(() {
          _movementHelpEnabled = settings['enabled'] as bool;
          _movementHelpDelay = settings['delay'] as double;
        });
        
        // Si está habilitado, inicializar el sistema de ayuda
        if (_movementHelpEnabled) {
          _setupMovementHelp();
        }
      }
    } catch (e) {
      // En caso de error, usar valores por defecto
      if (mounted) {
        setState(() {
          _movementHelpEnabled = false;
          _movementHelpDelay = 3.0;
        });
      }
    }
  }

  // Configurar sistema de ayuda de movimiento
  void _setupMovementHelp() {
    if (!_movementHelpEnabled) return;
    
    _lastPlayerTurn = widget.game.currentPlayer;
    _onTurnChanged();
  }

  // Manejar cambio de turno
  void _onTurnChanged() {
    if (!_movementHelpEnabled) return;

  // Cancelar timer anterior si existe
  _delayTimer?.cancel();
  
  // Ocultar movimientos válidos inmediatamente
  setState(() {
    _showingValidMoves = false;
  });
  _animationController.reset();

  // No mostrar ayuda si está temporalmente desactivada
  if (_helpTemporarilyDisabled) {
    print('🎬 GameCell (${widget.gridX},${widget.gridY}): Ayuda bloqueada - temporalmente desactivada');
    return;
  }

  // Solo mostrar ayuda si es turno del jugador humano (0) y el juego no ha terminado
  if (widget.game.currentPlayer == 0 && !widget.game.gameOver) {
    // Iniciar timer para el delay
    _delayTimer = Timer(Duration(milliseconds: (_movementHelpDelay * 1000).round()), () {
      if (mounted && _movementHelpEnabled && widget.game.currentPlayer == 0 && !_helpTemporarilyDisabled) {
          setState(() {
            _showingValidMoves = true;
          });
          // Iniciar animación de fade-in gradual
          _animationController.forward();
        }
      });
    }
  }


  /// Desactiva temporalmente la ayuda de movimiento (durante animaciones)
  void disableMovementHelpTemporarily() {
    if (_movementHelpEnabled && _showingValidMoves) {
      print('🎬 GameCell (${widget.gridX},${widget.gridY}): Desactivando ayuda temporalmente');
      setState(() {
        _helpTemporarilyDisabled = true;
        _showingValidMoves = false;
      });

      // Cancelar timer si existe
      _delayTimer?.cancel();
      _animationController.reset();
    }
  }





  @override
  Widget build(BuildContext context) {
    final cellState = widget.game.grid[widget.gridY][widget.gridX];
    final isCurrentPlayer = widget.game.isCurrentPlayerCell(widget.gridX, widget.gridY);
    final isValidMove = widget.game.isValidMoveCell(widget.gridX, widget.gridY);
    
    // Solo mostrar ayuda si está habilitada Y se están mostrando movimientos válidos
    final showMovementHelp = _movementHelpEnabled && _showingValidMoves && isValidMove;
    final displayValue = widget.game.getCellDisplayValue(widget.gridX, widget.gridY);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(),
            onTapCancel: () => _handleTapUp(),
            child: Container(
              decoration: _buildCellDecoration(cellState, isCurrentPlayer, showMovementHelp),
              child: Stack(
                children: [
                  // Overlay con fade-in gradual para movimientos válidos
                  if (showMovementHelp)
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: UIColors.validMove,
                          borderRadius: BorderRadius.circular(UIConstants.radiusSmall - 1),
                        ),
                      ),
                    ),
                  
                  // Contenido de la celda
                  _buildCellContent(cellState, displayValue, showMovementHelp),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construir decoración considerando fade-in gradual
  BoxDecoration _buildCellDecoration(CellState cellState, bool isCurrentPlayer, bool showMovementHelp) {
    Color backgroundColor = _getCellColor(cellState);
    Color borderColor = isCurrentPlayer ? UIColors.primary : UIColors.cellBorder;
    double borderWidth = isCurrentPlayer ? 2.0 : 1.0;
    
    List<BoxShadow> shadows = [];
    
    // Efecto especial con fade-in gradual
    if (showMovementHelp) {
      final glowOpacity = 0.3 + 0.2 * _glowAnimation.value;
      final fadeOpacity = _fadeAnimation.value;
      
      shadows.add(
        BoxShadow(
          color: UIColors.primary.withOpacity(glowOpacity * fadeOpacity),
          blurRadius: 4 + 2 * _glowAnimation.value,
          offset: const Offset(0, 2),
        ),
      );
      
      // Animar glow suavemente para movimientos válidos
      if (!_animationController.isAnimating && _showingValidMoves) {
        _animationController.repeat(reverse: true);
      }
    } else {
      // Parar animación si no se debe mostrar ayuda
      if (_animationController.isAnimating) {
        _animationController.stop();
        _animationController.reset();
      }
    }
    
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
      boxShadow: shadows,
    );
  }

  /// Construir contenido con fade-in gradual
  Widget _buildCellContent(CellState cellState, String displayValue, bool showMovementHelp) {
    if (displayValue.isNotEmpty && cellState != CellState.blocked) {
      return Center(
        child: Text(
          displayValue,
          style: TextStyle(
            fontSize: UIConstants.fontSizeMedium,
            fontWeight: FontWeight.w600,
            color: _getTextColor(cellState),
          ),
        ),
      );
    } else if (showMovementHelp) {
      // Indicador con fade-in gradual
      return Center(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: UIColors.primary.withOpacity(
                    (0.6 + 0.4 * _glowAnimation.value) * _fadeAnimation.value
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      );
    } else if (cellState == CellState.blocked) {
      // Indicador para celdas bloqueadas
      return Center(
        child: Icon(
          Icons.block_rounded,
          color: Colors.white,
          size: UIConstants.fontSizeMedium,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  /// Determina el color de fondo de la celda zen
  Color _getCellColor(CellState cellState) {
    switch (cellState) {
      case CellState.empty:
        return UIColors.cellEmpty;
      case CellState.blue:
        return UIColors.player1;
      case CellState.red:
        return UIColors.player2;
      case CellState.blocked:
        return UIColors.textTertiary;
    }
  }

  /// Determina el color del texto de la celda zen
  Color _getTextColor(CellState cellState) {
    switch (cellState) {
      case CellState.empty:
        return UIColors.textPrimary;
      case CellState.blue:
      case CellState.red:
      case CellState.blocked:
        return Colors.white;
    }
  }

  /// Manejar tap down con animación
  void _handleTapDown() {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  /// Manejar tap up con animación
  void _handleTapUp() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  // Actualizar configuración dinámicamente
  void updateMovementHelpSetting() {
    _loadMovementHelpSettings();
  }

  // Actualizar configuraciones específicas
  void updateMovementHelpSettings(bool enabled, double delay) {
    if (mounted) {
      setState(() {
        _movementHelpEnabled = enabled;
        _movementHelpDelay = delay;
      });
      
      if (enabled) {
        _setupMovementHelp();
      } else {
        // Si se desactiva, cancelar timers y ocultar ayuda
        _delayTimer?.cancel();
        setState(() {
          _showingValidMoves = false;
        });
        _animationController.reset();
      }
    }
  }

  /// Fuerza actualización de ayuda de movimiento (llamado cuando cambia el turno)
  void forceUpdateMovementHelp() {
    print('🔄 GameCell (${widget.gridX},${widget.gridY}): forceUpdateMovementHelp llamado');

    // Reactivar ayuda si estaba temporalmente desactivada
    if (_helpTemporarilyDisabled) {
      print('🎬 GameCell (${widget.gridX},${widget.gridY}): Reactivando ayuda tras animación');
      _helpTemporarilyDisabled = false;
    }

    // Usar el sistema existente de cambio de turno
    _onTurnChanged();
  }

}