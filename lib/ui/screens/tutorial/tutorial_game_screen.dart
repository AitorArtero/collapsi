import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/tutorial_manager.dart';
import '../../../core/collapsi_engine.dart';
import '../../../core/haptic_manager.dart';
import '../../../core/sound_manager.dart';
import '../../../config/app_settings.dart';
import '../../widgets/game_board.dart';
import '../../widgets/movement_help_snackbar.dart';
import '../menu_screen.dart';
import '../game_screen.dart';
import 'dart:async';

class TutorialGameScreen extends StatefulWidget {
  const TutorialGameScreen({Key? key}) : super(key: key);

  @override
  State<TutorialGameScreen> createState() => _TutorialGameScreenState();
}

class _TutorialGameScreenState extends State<TutorialGameScreen>
    with TickerProviderStateMixin {
  late CollapsiEngine _game;
  late Timer _updateTimer;
  bool _gameEndHandled = false;
  bool _isProcessingResult = false;
  bool _waitingForAIAnimation = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _firstMoveAnimationController;
  late Animation<double> _firstMovePulseAnimation;
  late Animation<double> _firstMoveGlowAnimation;

  // Estado para ayuda de movimiento
  bool _movementHelpEnabled = false;
  double _movementHelpDelay = 3.0;
  final GlobalKey<GameBoardState> _gameBoardKey = GlobalKey<GameBoardState>();

  @override
  void initState() {
    super.initState();
    
    // Inicializar el motor de juego real
    _game = CollapsiEngine();
    
    // Configurar para tutorial: 4x4 vs IA fácil
    _game.setGridSize(4);
    _game.setAIDifficulty('easy');
    _game.toggleAIMode(); // Activar modo IA

    _game.setAIMoveCallback(_handleAIMoveDecision);
    debugPrint('🎬 TutorialGameScreen: Callback de IA configurado');
    
    // Configurar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _firstMoveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _firstMovePulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _firstMoveAnimationController,
      curve: Curves.easeInOut,
    ));

    _firstMoveGlowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _firstMoveAnimationController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animación en bucle para primer movimiento
    _firstMoveAnimationController.repeat(reverse: true);
    
    // Timer para actualizaciones de IA
    _updateTimer = Timer.periodic(
      const Duration(milliseconds: 33), // 30 FPS
      (timer) => _updateGame(0.033),
    );
    
    // Cargar configuración de ayuda de movimiento
    _loadMovementHelpSettings();
    
    // Iniciar animación de entrada
    _fadeController.forward();
    
    debugPrint('🎮 Tutorial Game iniciado: 4x4 vs IA Fácil');
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _firstMoveAnimationController.dispose();
    _fadeController.dispose();

    // Limpiar callback de IA
    _game.setAIMoveCallback(null);
    debugPrint('🎬 TutorialGameScreen: Callback de IA limpiado');

    _game.dispose();
    super.dispose();
  }

  // Cargar configuración de ayuda de movimiento
  Future<void> _loadMovementHelpSettings() async {
    try {
      final settings = await AppSettings.getMovementHelpSettings();
      if (mounted) {
        setState(() {
          _movementHelpEnabled = settings['enabled'] as bool;
          _movementHelpDelay = settings['delay'] as double;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando configuración de ayuda: $e');
    }
  }

  /// Maneja cuando la IA decide un movimiento en el tutorial (inicia animación)
  Future<void> _handleAIMoveDecision(int targetX, int targetY) async {
    debugPrint('🎬 TutorialGameScreen: _handleAIMoveDecision llamado para ($targetX,$targetY)');

    if (_waitingForAIAnimation) {
      debugPrint('⚠️ TutorialGameScreen: Ya esperando animación de IA');
      return;
    }

    debugPrint('🤖 TutorialGameScreen: IA decidió moverse a ($targetX,$targetY)');

    _waitingForAIAnimation = true;

    // Verificar que tenemos referencia al GameBoard
    final gameBoard = _gameBoardKey.currentState;
    if (gameBoard == null) {
      debugPrint('❌ TutorialGameScreen: GameBoard no disponible, ejecutando movimiento directo');
      _game.executeAIMove(targetX, targetY);
      _waitingForAIAnimation = false;
      return;
    }

    debugPrint('✅ TutorialGameScreen: GameBoard disponible, delegando animación');

    try {
      // El GameBoard manejará la animación y ejecutará el movimiento real al final
      await gameBoard.executeAIMove(targetX, targetY);
      debugPrint('✅ TutorialGameScreen: Animación de IA completada exitosamente');
    } catch (e) {
      debugPrint('❌ TutorialGameScreen: Error en animación de IA: $e');
      // Fallback: ejecutar directamente
      _game.executeAIMove(targetX, targetY);
    } finally {
      _waitingForAIAnimation = false;
    }
  }


  // Toggle ayuda de movimiento
  Future<void> _toggleMovementHelp() async {
    try {
      await HapticManager.instance.buttonTap();
      await SoundManager.instance.playButtonTap();

      final newState = !_movementHelpEnabled;
      
      // Guardar en configuración
      await AppSettings.setMovementHelpEnabled(newState);
      
      // Actualizar estado local
      setState(() {
        _movementHelpEnabled = newState;
      });

      // Actualizar todas las celdas del tablero
      _gameBoardKey.currentState?.updateMovementHelpInAllCells(
        _movementHelpEnabled, 
        _movementHelpDelay
      );

      // Mostrar mensaje informativo
      if (newState) {
        MovementHelpSnackbar.showActivated(context);
      } else {
        MovementHelpSnackbar.showDeactivated(context);
      }

      debugPrint('🔧 Ayuda de movimiento ${newState ? "activada" : "desactivada"}');
    } catch (e) {
      debugPrint('❌ Error al cambiar ayuda de movimiento: $e');
    }
  }

  void _updateGame(double dt) {
    _game.updateAI(dt);
    
    // Verificar si el juego terminó
    if (_game.gameOver && !_gameEndHandled && !_isProcessingResult) {
      _gameEndHandled = true;
      _handleGameEnd();
    }
  }

  /// Manejar el final del juego
  Future<void> _handleGameEnd() async {
    _isProcessingResult = true;
    
    try {
      // Crear resultado de la partida
      final result = GameResult(
        hasWinner: _game.winner != null,
        winner: _game.winner,
        moveCount: _game.moveCount,
      );

      debugPrint('🏁 Tutorial Game finalizado:');
      debugPrint('   Ganador: ${result.winner == null ? "Empate" : (result.humanWon ? "Humano" : "IA")}');
      debugPrint('   Movimientos: ${result.moveCount}');

      // Feedback de sonido y vibración según el resultado
      await _playEndGameFeedback(result);

      // Pequeña pausa para que se vea el último movimiento
      await Future.delayed(const Duration(milliseconds: 800));

      // Marcar tutorial como completado
      await TutorialManager.markTutorialCompleted();
      
      // Mostrar diálogo de finalización del tutorial
      if (mounted) {
        await _showTutorialCompletionDialog();
      }

    } catch (e) {
      debugPrint('❌ Error procesando final de tutorial: $e');
    } finally {
      _isProcessingResult = false;
    }
  }

  /// Reproducir feedback según el resultado del juego
  Future<void> _playEndGameFeedback(GameResult result) async {
    if (result.humanWon) {
      await HapticManager.instance.gameWin();
      await SoundManager.instance.playGameWin();
    } else if (result.aiWon) {
      await HapticManager.instance.gameLose();
      await SoundManager.instance.playGameLose();
    } else {
      await HapticManager.instance.moveInvalid(); // Vibración neutral para empate
    }
  }

  /// Mostrar diálogo de finalización del tutorial
  Future<void> _showTutorialCompletionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de éxito
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34C759).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF34C759),
                size: 48,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título
            Text(
              '¡Tutorial completado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Descripción
            Text(
              'Ahora estás listo para jugar partidas completas y disfrutar de todos los modos de juego.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3C3C43),
                letterSpacing: -0.2,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Botón
            GestureDetector(
              onTap: () async {
                await HapticManager.instance.buttonTap();
                await SoundManager.instance.playButtonTap();
                Navigator.of(context).pop();
                _returnToMenu();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Ir al menú principal',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _returnToMenu() async {
    try {
      // Marcar tutorial como completado al salir
      await TutorialManager.markTutorialCompleted();
      debugPrint('✅ Tutorial marcado como completado al salir con X');
      
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MenuScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ Error al marcar tutorial completado: $e');
      // Aún así navegar al menú
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MenuScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    }
  }

  void _onCellTap(int x, int y) {
    // En modo IA, solo permitir toques cuando es turno del humano
    if (_game.aiMode && (_game.currentPlayer == 1 || _game.aiThinking)) {
      return;
    }

    // No permitir movimientos si se está procesando el resultado
    if (_isProcessingResult) {
      return;
    }

    // Feedback al hacer movimiento exitoso
    if (_game.isValidMoveCell(x, y)) {
      _playMoveSuccessFeedback();
    }

    _game.makeMove(x, y);
  }

  /// Feedback para movimiento exitoso
  Future<void> _playMoveSuccessFeedback() async {
    await SoundManager.instance.playMoveSuccess();
    await HapticManager.instance.moveSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _game,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer<CollapsiEngine>(
            builder: (context, game, child) {
              return Column(
                children: [
                  // Header del juego
                  _buildGameHeader(game),
                  
                  // Control de ayuda de movimiento
                  _buildMovementHelpControl(),
                  
                  // Tablero de juego
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GameBoard(
                        key: _gameBoardKey,
                        game: game,
                        onCellTap: _onCellTap,
                        enableAnimations: true,
                      ),
                    ),
                  ),
                  
                  // Estado del juego
                  _buildGameInfo(game),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.close_rounded,
          color: Color(0xFF007AFF),
          size: 28,
        ),
        onPressed: _returnToMenu,
      ),
      title: Text(
        'Tutorial - Partida de práctica',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1C1E),
          letterSpacing: -0.2,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildGameHeader(CollapsiEngine game) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Información del modo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF007AFF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school_rounded,
                  color: const Color(0xFF007AFF),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tablero 4×4 vs IA Fácil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Contador de movimientos
          Text(
            'Movimiento #${game.moveCount}',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF8E8E93),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget para control de ayuda de movimiento
  Widget _buildMovementHelpControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _movementHelpEnabled 
              ? const Color(0xFF007AFF).withOpacity(0.3)
              : const Color(0xFF8E8E93).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (_movementHelpEnabled 
                  ? const Color(0xFF007AFF) 
                  : const Color(0xFF8E8E93)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _movementHelpEnabled 
                  ? Icons.lightbulb_rounded 
                  : Icons.lightbulb_outline_rounded,
              color: _movementHelpEnabled 
                  ? const Color(0xFF007AFF) 
                  : const Color(0xFF8E8E93),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ayuda de Movimiento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
                Text(
                  _movementHelpEnabled 
                      ? 'Resalta casillas válidas después de ${_movementHelpDelay.toInt()}s'
                      : 'Toca para activar ayuda visual',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          
          // Switch
          Switch.adaptive(
            value: _movementHelpEnabled,
            onChanged: (value) => _toggleMovementHelp(),
            activeColor: const Color(0xFF007AFF),
          ),
        ],
      ),
    );
  }

Widget _buildGameInfo(CollapsiEngine game) {
  final statusWidget = _buildGameStatus(game);
  final instructionsWidget = _buildInstructions(game);
  
  // Si ambos widgets están vacíos, no mostrar el contenedor
  if (statusWidget is SizedBox && instructionsWidget is SizedBox) {
    return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        // Estado del juego
        _buildGameStatus(game),
        const SizedBox(height: 8),
        // Instrucciones
        _buildInstructions(game),
      ],
    ),
  );
}

Widget _buildGameStatus(CollapsiEngine game) {
  String statusText;
  Color statusColor;
  bool isFirstMoveMessage = false;

  if (game.gameOver) {
    if (game.winner != null) {
      statusText = game.winner == 0 ? "¡Has ganado!" : "La IA ha ganado";
      statusColor = game.winner == 0 ? const Color(0xFF007AFF) : const Color(0xFFFF3B30);
    } else {
      statusText = "¡Empate!";
      statusColor = const Color(0xFF8E8E93);
    }
  } else {
    // Mensaje especial para el primer movimiento
    if (game.moveCount == 0 && game.currentPlayer == 0) {
      statusText = "¡Puedes moverte a cualquier casilla del tablero!";
      statusColor = Color(0xFF34C759); // Verde más llamativo
      isFirstMoveMessage = true;
    } else if (game.currentPlayer == 0) {
      statusText = "Tu turno";
      statusColor = const Color(0xFF007AFF);
    } else {
      statusText = "IA pensando...";
      statusColor = const Color(0xFFFF3B30);
    }
  }

  // Contenedor especial con animación para primer movimiento
  if (isFirstMoveMessage) {
    return AnimatedBuilder(
      animation: _firstMoveAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _firstMovePulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withOpacity(_firstMoveGlowAnimation.value), 
                width: 2
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(_firstMoveGlowAnimation.value * 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Contenedor normal para otros estados
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: statusColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
    ),
    child: Text(
      statusText,
      style: TextStyle(
        fontSize: 16,
        color: statusColor,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

Widget _buildInstructions(CollapsiEngine game) {
  String instructionText;

  if (game.gameOver) {
    instructionText = "¡Partida de tutorial terminada!";
  } else if (game.currentPlayer == 0) {
    instructionText = (_movementHelpEnabled 
        ? "Las casillas válidas se resaltarán en ${_movementHelpDelay.toInt()}s"
        : "Toca las casillas donde puedes moverte");
  } else {
    instructionText = "La IA está evaluando sus opciones";
  }

  return Text(
    instructionText,
    style: TextStyle(
      fontSize: 14,
      color: const Color(0xFF8E8E93),
      letterSpacing: -0.2,
    ),
    textAlign: TextAlign.center,
  );
}

  /// Activar ayuda de movimiento DESDE TUTORIAL (con mensaje)
  Future<void> enableMovementHelpFromTutorial(BuildContext context) async {
    await AppSettings.setMovementHelpEnabled(true);
    MovementHelpSnackbar.showActivated(context);
  }

  /// Cambiar delay de ayuda DESDE TUTORIAL (con mensaje)  
  Future<void> updateMovementHelpDelayFromTutorial(BuildContext context, double delay) async {
    await AppSettings.setMovementHelpDelay(delay);
    MovementHelpSnackbar.showDelayUpdated(context, delay);
  }
}