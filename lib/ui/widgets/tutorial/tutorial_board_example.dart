import 'package:flutter/material.dart';

class TutorialBoardExample extends StatefulWidget {
  final String exampleType;

  const TutorialBoardExample({
    Key? key,
    required this.exampleType,
  }) : super(key: key);

  @override
  State<TutorialBoardExample> createState() => _TutorialBoardExampleState();
}

class _TutorialBoardExampleState extends State<TutorialBoardExample>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _blockController;
  late AnimationController _movesController;
  late AnimationController _teleportController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _blockController = AnimationController(
      duration: const Duration(milliseconds: 7000), // Más tiempo para pausa al final
      vsync: this,
    );
    
    _movesController = AnimationController(
      duration: const Duration(milliseconds: 10000), // Más tiempo para pasos intermedios y pausa
      vsync: this,
    );
    
    _teleportController = AnimationController(
      duration: const Duration(milliseconds: 6000), // Más tiempo para pausa al final
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animaciones según el tipo de ejemplo
    if (widget.exampleType == 'blocked_tiles') {
      _blockController.repeat();
    } else if (widget.exampleType == 'moves_limit') {
      _movesController.repeat();
    } else if (widget.exampleType == 'corner_teleport') {
      _teleportController.repeat();
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _blockController.dispose();
    _movesController.dispose();
    _teleportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: _buildExample(),
    );
  }

  Widget _buildExample() {
    switch (widget.exampleType) {
      case 'movement':
        return _buildMovementExample();
      case 'moves_limit':
        return _buildMovesLimitExample();
      case 'corner_teleport':
        return _buildCornerTeleportExample();
      case 'blocked_tiles':
        return _buildBlockedTilesExample();
      case 'win_condition':
        return _buildWinConditionExample();
      default:
        return Container();
    }
  }

  Widget _buildMovementExample() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: 16,
      itemBuilder: (context, index) {
        int row = index ~/ 4;
        int col = index % 4;
        bool isPlayer = row == 1 && col == 1;
        bool isValidMove = (row == 0 && col == 1) ||
                          (row == 2 && col == 1) ||
                          (row == 1 && col == 0) ||
                          (row == 1 && col == 2);
        
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isValidMove ? _pulseAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isPlayer 
                      ? const Color(0xFF007AFF)
                      : isValidMove 
                          ? const Color(0xFF34C759)
                          : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isPlayer || isValidMove ? [
                    BoxShadow(
                      color: (isPlayer 
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF34C759)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: isPlayer 
                      ? const Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMovesLimitExample() {
    return AnimatedBuilder(
      animation: _movesController,
      builder: (context, child) {
        double progress = _movesController.value;
        
        // Secuencia de animación con retorno a inicio:
        // 0.0-0.08: En posición inicial (1,1) con "2"
        // 0.08-0.12: Se mueve 1 casilla a la derecha (1,2) - paso intermedio
        // 0.12-0.16: Se mueve 2 casillas a la derecha (1,3) - destino final
        // 0.16-0.24: Pausa en (1,3)
        // 0.24-0.28: Vuelve a posición inicial (1,1)
        // 0.28-0.36: Pausa en inicio
        // 0.36-0.40: Se mueve 1 casilla abajo (2,1) - paso intermedio
        // 0.40-0.44: Se mueve 2 casillas abajo (3,1) - destino final
        // 0.44-0.52: Pausa en (3,1)
        // 0.52-0.56: Vuelve a posición inicial (1,1)
        // 0.56-0.64: Pausa en inicio
        // 0.64-0.68: Se mueve 1 derecha (1,2) - paso intermedio
        // 0.68-0.72: Se mueve 1 arriba desde (1,2) para llegar a (0,2) - destino final
        // 0.72-0.80: Pausa en (0,2)
        // 0.80-0.84: Vuelve a posición inicial (1,1)
        // 0.84-1.0: Pausa larga antes de reiniciar
        
        int playerRow = 1;
        int playerCol = 1;
        bool isInStartPosition = true;
        
        if (progress >= 0.08 && progress < 0.12) {
          // Paso intermedio: 1 casilla a la derecha
          playerRow = 1;
          playerCol = 2;
          isInStartPosition = false;
        } else if (progress >= 0.12 && progress < 0.28) {
          // Destino: 2 casillas a la derecha
          playerRow = 1;
          playerCol = 3;
          isInStartPosition = false;
        } else if (progress >= 0.36 && progress < 0.40) {
          // Paso intermedio: 1 casilla abajo
          playerRow = 2;
          playerCol = 1;
          isInStartPosition = false;
        } else if (progress >= 0.40 && progress < 0.56) {
          // Destino: 2 casillas abajo
          playerRow = 3;
          playerCol = 1;
          isInStartPosition = false;
        } else if (progress >= 0.64 && progress < 0.68) {
          // Paso intermedio: 1 derecha
          playerRow = 1;
          playerCol = 2;
          isInStartPosition = false;
        } else if (progress >= 0.68 && progress < 0.84) {
          // Destino: 1 derecha y 1 arriba
          playerRow = 0;
          playerCol = 2;
          isInStartPosition = false;
        }
        
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            int row = index ~/ 4;
            int col = index % 4;
            bool isPlayer = row == playerRow && col == playerCol;
            bool isStartPosition = row == 1 && col == 1;
            
            Color cellColor;
            Widget? cellChild;
            
            if (isPlayer && isInStartPosition) {
              // En posición inicial con número "2"
              cellColor = const Color(0xFF007AFF);
              cellChild = const Text(
                '2',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              );
            } else if (isPlayer && !isInStartPosition) {
              // Jugador moviéndose (icono de persona)
              cellColor = const Color(0xFF007AFF);
              cellChild = const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              );
            } else if (isStartPosition && !isInStartPosition) {
              // Casilla inicial con número "2" gastado
              cellColor = const Color(0xFF007AFF).withOpacity(0.3);
              cellChild = const Text(
                '2',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              );
            } else {
              cellColor = const Color(0xFFE5E5EA);
            }
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: (isPlayer || (isStartPosition && isInStartPosition)) ? [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(child: cellChild),
            );
          },
        );
      },
    );
  }

  Widget _buildCornerTeleportExample() {
    return AnimatedBuilder(
      animation: _teleportController,
      builder: (context, child) {
        double progress = _teleportController.value;
        
        // Animación de teletransporte simplificada:
        // 0.0-0.2: En posición inicial (2,0) con "1"
        // 0.2-0.4: Se mueve hacia la izquierda (sale del tablero) - MOSTRAR FLECHAS
        // 0.4-0.6: Aparece en el lado derecho (2,3)
        // 0.6-0.85: Pausa en (2,3)
        // 0.85-1.0: Pausa larga antes de reiniciar
        
        int playerRow = 2;
        int playerCol = 0;
        bool isVisible = true;
        bool isInStartPosition = true;
        bool showTunnelArrows = false;
        
        if (progress >= 0.2 && progress < 0.4) {
          // Desaparece temporalmente - MOSTRAR FLECHAS
          isVisible = false;
          isInStartPosition = false;
          showTunnelArrows = true;
        } else if (progress >= 0.4) {
          // Aparece en el otro lado
          playerRow = 2;
          playerCol = 3;
          isInStartPosition = false;
        }
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;
            
            // Calcular el tamaño de cada celda (considerando spacing)
            final cellSize = (availableWidth - (3 * 6)) / 4; // 6px de spacing entre 4 columnas
            final totalGridHeight = (availableHeight - (3 * 6)) / 4; // 6px de spacing entre 4 filas
            
            // Calcular la posición Y de la fila 2 (donde ocurre el túnel)
            final row2Y = (totalGridHeight + 6) * 2; // Fila 2 * (tamaño + spacing)
            
            return Stack(
              clipBehavior: Clip.none, // Permitir que las flechas se salgan del contenedor
              children: [
                // GridView principal
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    int row = index ~/ 4;
                    int col = index % 4;
                    
                    bool isPlayer = row == playerRow && col == playerCol && isVisible;
                    bool isStartPosition = row == 2 && col == 0;
                    //bool isEndPosition = row == 2 && col == 3;
                    bool isBlockedMiddle = row == 2 && (col == 1 || col == 2); // Bloqueo en el medio
                    
                    Color cellColor;
                    Widget? cellChild;
                    
                    if (isPlayer && isInStartPosition) {
                      // Posición inicial con número "1"
                      cellColor = const Color(0xFF007AFF);
                      cellChild = const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    } else if (isPlayer && !isInStartPosition) {
                      // Jugador en destino (icono de persona)
                      cellColor = const Color(0xFF007AFF);
                      cellChild = const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      );
                    } else if (isStartPosition && !isInStartPosition) {
                      // Casilla inicial con número "1" gastado
                      cellColor = const Color(0xFF007AFF).withOpacity(0.3);
                      cellChild = const Text(
                        '1',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    } else if (isBlockedMiddle) {
                      cellColor = const Color(0xFF8E8E93); // Color gris para bloqueos
                      cellChild = const Icon(Icons.block_rounded, color: Colors.white, size: 16);
                    } else {
                      cellColor = const Color(0xFFE5E5EA);
                    }
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: (isPlayer || (isStartPosition && isInStartPosition)) ? [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : isBlockedMiddle ? [
                          BoxShadow(
                            color: const Color(0xFF8E8E93).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Center(child: cellChild),
                    );
                  },
                ),
                
                // Flechas del túnel (solo visibles durante el teletransporte)
                if (showTunnelArrows) ...[
                  // Flecha izquierda (salida) - posicionada dinámicamente
                  Positioned(
                    left: -cellSize * 0.4, // Un poco fuera del borde izquierdo
                    top: row2Y,
                    width: cellSize * 0.8,
                    height: totalGridHeight,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: showTunnelArrows ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: const Color(0xFFAF52DE),
                            size: cellSize * 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Flecha derecha (entrada) - posicionada dinámicamente
                  Positioned(
                    right: -cellSize * 0.4, // Un poco fuera del borde derecho
                    top: row2Y,
                    width: cellSize * 0.8,
                    height: totalGridHeight,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: showTunnelArrows ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: const Color(0xFFAF52DE),
                            size: cellSize * 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBlockedTilesExample() {
    return AnimatedBuilder(
      animation: _blockController,
      builder: (context, child) {
        double progress = _blockController.value;
        
        // Fases de la animación con más tiempo de pausa:
        // 0.0-0.15: Usuario en (1,1) con "2"
        // 0.15-0.25: Usuario en (2,1), "2" permanece en (1,1) pero gastado
        // 0.25-0.35: Usuario en (2,2), "2" permanece en (1,1) pero gastado
        // 0.35-0.45: Usuario en (2,2), casilla (1,1) se bloquea (reemplaza al "2")
        // 0.45-0.85: Pausa larga en estado final
        // 0.85-1.0: Pausa extra antes de reiniciar
        
        bool isPhase1 = progress < 0.15;  // Usuario en (1,1) con "2"
        bool isPhase2 = progress >= 0.15 && progress < 0.25;  // Usuario en (2,1), "2" gastado en (1,1)
        bool isPhase3 = progress >= 0.25 && progress < 0.35;  // Usuario en (2,2), "2" gastado en (1,1)
        bool isPhase4 = progress >= 0.35;  // Usuario en (2,2), (1,1) bloqueada
        
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            int row = index ~/ 4;
            int col = index % 4;
            
            bool isStartPosition = row == 1 && col == 1;
            bool isMiddlePosition = row == 2 && col == 1;
            bool isEndPosition = row == 2 && col == 2;
            
            Color cellColor = const Color(0xFFE5E5EA);
            Widget? cellIcon;
            
            if (isPhase1) {
              // Fase 1: Usuario en (1,1) con "2"
              if (isStartPosition) {
                cellColor = const Color(0xFF007AFF);
                cellIcon = const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                );
              }
            } else if (isPhase2) {
              // Fase 2: Usuario en (2,1), "2" gastado en (1,1)
              if (isMiddlePosition) {
                cellColor = const Color(0xFF007AFF);
                cellIcon = const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                );
              }
              if (isStartPosition) {
                cellColor = const Color(0xFF007AFF).withOpacity(0.3);
                cellIcon = const Text(
                  '2',
                  style: TextStyle(
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                );
              }
            } else if (isPhase3) {
              // Fase 3: Usuario en (2,2), "2" gastado en (1,1)
              if (isEndPosition) {
                cellColor = const Color(0xFF007AFF);
                cellIcon = const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                );
              }
              if (isStartPosition) {
                cellColor = const Color(0xFF007AFF).withOpacity(0.3);
                cellIcon = const Text(
                  '2',
                  style: TextStyle(
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                );
              }
            } else if (isPhase4) {
              // Fase 4: Usuario en (2,2), casilla (1,1) bloqueada
              if (isEndPosition) {
                cellColor = const Color(0xFF007AFF);
                cellIcon = const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                );
              }
              if (isStartPosition) {
                cellColor = const Color(0xFF8E8E93); // Color gris para bloqueos
                cellIcon = const Icon(Icons.block_rounded, color: Colors.white, size: 20);
              }
            }
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: cellIcon != null ? [
                  BoxShadow(
                    color: cellColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(child: cellIcon),
            );
          },
        );
      },
    );
  }

  Widget _buildWinConditionExample() {
    // Dejamos esta función igual como solicitaste
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: 16,
      itemBuilder: (context, index) {
        int row = index ~/ 4;
        int col = index % 4;
        bool isPlayer1 = row == 1 && col == 1;
        bool isPlayer2 = row == 2 && col == 2;
        bool isBlocked = (row == 1 && col == 2) ||
                        (row == 2 && col == 1) ||
                        (row == 3 && col == 2) ||
                        (row == 2 && col == 3);
        
        return Container(
          decoration: BoxDecoration(
            color: isPlayer1 
                ? const Color(0xFF007AFF)
                : isPlayer2
                    ? const Color(0xFFFF3B30)
                    : isBlocked 
                        ? const Color(0xFF8E8E93) // Mismo color gris para consistencia
                        : const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isPlayer1 || isPlayer2 || isBlocked ? [
              BoxShadow(
                color: (isPlayer1 
                    ? const Color(0xFF007AFF)
                    : isPlayer2
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF8E8E93)).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: isPlayer1 
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  )
                : isPlayer2
                    ? const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      )
                    : isBlocked
                        ? const Icon(
                            Icons.block_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
          ),
        );
      },
    );
  }
}