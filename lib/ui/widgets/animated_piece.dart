import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/ui_constants.dart';
import '../../core/path_finder.dart';

/// Widget que anima una ficha moviéndose por el tablero
class AnimatedPiece extends StatefulWidget {
  final List<GridPoint> path;
  final int player; // 0 = azul, 1 = rojo
  final double boardSize;
  final int gridSize;
  final VoidCallback onAnimationComplete;
  final Duration? customDuration;

  const AnimatedPiece({
    super.key,
    required this.path,
    required this.player,
    required this.boardSize,
    required this.gridSize,
    required this.onAnimationComplete,
    this.customDuration,
  });

  @override
  State<AnimatedPiece> createState() => _AnimatedPieceState();
}

class _AnimatedPieceState extends State<AnimatedPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pathAnimation;
  late List<Offset> _screenPositions;

  @override
  void initState() {
    super.initState();
    
    // Calcular posiciones en pantalla para cada punto del path
    _calculateScreenPositions();
    
    // Configurar animación
    final duration = widget.customDuration ?? 
        Duration(milliseconds: (widget.path.length - 1) * 300); // 300ms por movimiento (antes 200ms)
    
    _animationController = AnimationController(
      duration: duration,
      vsync: this,
    );
    
    _pathAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animación
    _animationController.forward().then((_) {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Convierte posiciones del grid a posiciones en pantalla
  void _calculateScreenPositions() {
    _screenPositions = [];
    
    // Calcular tamaño de celda (incluyendo padding)
    final totalPadding = UIConstants.spacing8 * 2; // Padding del container principal
    final availableSize = widget.boardSize - totalPadding;
    final cellSpacing = UIConstants.cellPadding;
    final totalSpacing = cellSpacing * (widget.gridSize - 1);
    final cellSize = (availableSize - totalSpacing) / widget.gridSize;
    
    for (final point in widget.path) {
      // Manejar posiciones fuera del tablero para túneles
      double x, y;
      
      if (point.x >= 0 && point.x < widget.gridSize && point.y >= 0 && point.y < widget.gridSize) {
        // Posición normal dentro del tablero
        x = UIConstants.spacing8 + // Padding inicial
            (point.x * cellSize) + // Posición base
            (point.x * cellSpacing) + // Espaciado acumulado
            (cellSize / 2); // Centro de la celda
            
        y = UIConstants.spacing8 + // Padding inicial
            (point.y * cellSize) + // Posición base
            (point.y * cellSpacing) + // Espaciado acumulado
            (cellSize / 2); // Centro de la celda
      } else {
        // Posición fuera del tablero (para túneles)
        if (point.x == -1) {
          // Fuera por la izquierda
          x = -cellSize / 2;
        } else if (point.x == widget.gridSize) {
          // Fuera por la derecha
          x = widget.boardSize + cellSize / 2;
        } else {
          // Posición X normal
          x = UIConstants.spacing8 + (point.x * cellSize) + (point.x * cellSpacing) + (cellSize / 2);
        }
        
        if (point.y == -1) {
          // Fuera por arriba
          y = -cellSize / 2;
        } else if (point.y == widget.gridSize) {
          // Fuera por abajo
          y = widget.boardSize + cellSize / 2;
        } else {
          // Posición Y normal
          y = UIConstants.spacing8 + (point.y * cellSize) + (point.y * cellSpacing) + (cellSize / 2);
        }
      }
      
      _screenPositions.add(Offset(x, y));
    }
    
    print('🎯 AnimatedPiece: Calculadas ${_screenPositions.length} posiciones (con túneles)');
    print('   Celda size: ${cellSize.toStringAsFixed(1)}px');
    print('   Path: ${widget.path.map((p) => "(${p.x},${p.y})").join(" → ")}');
    print('   Posiciones: ${_screenPositions.map((p) => "(${p.dx.toInt()},${p.dy.toInt()})").join(" → ")}');
  }

  /// Calcula la posición actual basada en el progreso de la animación
  Offset _getCurrentPosition(double progress) {
    if (_screenPositions.isEmpty) return Offset.zero;
    if (_screenPositions.length == 1) return _screenPositions.first;
    
    // Calcular qué segmento del path estamos animando
    final totalSegments = _screenPositions.length - 1;
    final currentSegmentFloat = progress * totalSegments;
    final currentSegment = currentSegmentFloat.floor().clamp(0, totalSegments - 1);
    final segmentProgress = (currentSegmentFloat - currentSegment).clamp(0.0, 1.0);
    
    // Manejo especial para segmentos que van fuera del tablero
    final startPos = _screenPositions[currentSegment];
    final endPos = _screenPositions[currentSegment + 1];
    
    // Verificar si este segmento representa un túnel (salida/entrada del tablero)
    final startPoint = widget.path[currentSegment];
    final endPoint = widget.path[currentSegment + 1];
    
    bool isStartOutside = startPoint.x < 0 || startPoint.x >= widget.gridSize || 
                         startPoint.y < 0 || startPoint.y >= widget.gridSize;
    bool isEndOutside = endPoint.x < 0 || endPoint.x >= widget.gridSize || 
                       endPoint.y < 0 || endPoint.y >= widget.gridSize;
    
    // Si cualquiera de los puntos está fuera, usar interpolación más rápida para el túnel
    if (isStartOutside || isEndOutside) {
      // Interpolar normalmente pero asegurar que se vea el movimiento
      return Offset.lerp(startPos, endPos, segmentProgress) ?? startPos;
    }
    
    // Interpolación normal para movimientos dentro del tablero
    return Offset.lerp(startPos, endPos, segmentProgress) ?? startPos;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pathAnimation,
      builder: (context, child) {
        final currentPos = _getCurrentPosition(_pathAnimation.value);
        
        return Positioned(
          left: currentPos.dx - 20, // Centrar la ficha (asumiendo 40px de ancho)
          top: currentPos.dy - 20,  // Centrar la ficha (asumiendo 40px de alto)
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.player == 0 ? UIColors.player1 : UIColors.player2,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.player == 0 ? UIColors.player1 : UIColors.player2)
                      .withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}

/// Manager que coordina las animaciones de movimiento en el tablero
class MovementAnimationManager {
  static MovementAnimationManager? _instance;
  static MovementAnimationManager get instance => 
      _instance ??= MovementAnimationManager._internal();
  
  MovementAnimationManager._internal();

  bool _isAnimating = false;
  VoidCallback? _onAnimationComplete;
  
  /// Verifica si hay una animación en curso
  bool get isAnimating => _isAnimating;
  
  /// Inicia una animación de movimiento
  Future<void> animateMovement({
    required BuildContext context,
    required List<GridPoint> path,
    required int player,
    required double boardSize,
    required int gridSize,
    Duration? duration,
  }) async {
    if (_isAnimating) {
      print('⚠️ MovementAnimationManager: Animación ya en curso, ignorando nueva solicitud');
      return;
    }
    
    print('🎬 MovementAnimationManager: Iniciando animación para jugador $player');
    print('   Path: ${path.map((p) => p.toString()).join(" → ")}');
    
    _isAnimating = true;
    
    // Crear un Completer para esperar a que termine la animación
    final completer = Completer<void>();
    _onAnimationComplete = () {
      _isAnimating = false;
      _onAnimationComplete = null;
      completer.complete();
    };
    
    // La animación se maneja a través del widget AnimatedPiece
    // que debe ser insertado en el widget tree por el GameBoard
    
    return completer.future;
  }
  
  /// Cancela la animación actual (si existe)
  void cancelAnimation() {
    if (_isAnimating) {
      print('🚫 MovementAnimationManager: Cancelando animación');
      _isAnimating = false;
      _onAnimationComplete?.call();
    }
  }
  
  /// Callback interno para cuando termina la animación
  void _notifyAnimationComplete() {
    if (_onAnimationComplete != null) {
      print('✅ MovementAnimationManager: Animación completada');
      _onAnimationComplete!();
    }
  }
}

/// Widget de conveniencia para mostrar una animación de movimiento
class MovementAnimationOverlay extends StatelessWidget {
  final List<GridPoint> path;
  final int player;
  final double boardSize;
  final int gridSize;
  final VoidCallback onComplete;
  final Duration? duration;

  const MovementAnimationOverlay({
    super.key,
    required this.path,
    required this.player,
    required this.boardSize,
    required this.gridSize,
    required this.onComplete,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPiece(
      path: path,
      player: player,
      boardSize: boardSize,
      gridSize: gridSize,
      onAnimationComplete: () {
        MovementAnimationManager.instance._notifyAnimationComplete();
        onComplete();
      },
      customDuration: duration,
    );
  }
}