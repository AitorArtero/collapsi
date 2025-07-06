import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../config/ui_constants.dart';
import '../../core/collapsi_engine.dart';
import '../../core/haptic_manager.dart';
import '../../core/sound_manager.dart';
import '../../core/tournament_manager.dart';
import '../../core/path_finder.dart';
import '../widgets/game_board.dart';
import '../widgets/zen_page_scaffold.dart';

/// Información del resultado de una partida
class GameResult {
  final bool hasWinner;
  final int? winner; // 0 = jugador humano/azul, 1 = IA/rojo
  final int moveCount;
  final bool humanWon;
  final bool aiWon;
  final bool isDraw;
  final DateTime completedAt;

  GameResult({
    required this.hasWinner,
    required this.winner,
    required this.moveCount,
  }) : humanWon = winner == 0,
       aiWon = winner == 1,
       isDraw = !hasWinner,
       completedAt = DateTime.now();

  /// Convertir a Map para logging/debugging
  Map<String, dynamic> toJson() {
    return {
      'hasWinner': hasWinner,
      'winner': winner,
      'moveCount': moveCount,
      'humanWon': humanWon,
      'aiWon': aiWon,
      'isDraw': isDraw,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

/// Pantalla del juego con diseño zen minimalista e integración completa + feedback
class GameScreen extends StatefulWidget {
  final CollapsiEngine game;
  final bool allowUndo;
  final bool allowRestart;
  final VoidCallback? onGameEnd;
  final Function(GameResult)? onGameEndWithResult;
  final bool isReplay;
  final int? tournamentLevelId;
  final bool isStreakMode;
  final BlockStreakState? streakState;
  final Function(int levelId, GameResult)? onStreakLevelComplete;
  
  // Parámetros para análisis y retry
  final bool isAnalysisMode;
  final VoidCallback? onAnalysisComplete;
  final VoidCallback? onRetryLevel;
  final bool showPostGameControls;
  final CollapsiEngine? gameToAnalyze;

  const GameScreen({
    super.key,
    required this.game,
    this.allowUndo = true,
    this.allowRestart = true,
    this.onGameEnd,
    this.onGameEndWithResult,
    this.isReplay = false,
    this.tournamentLevelId,
    this.isStreakMode = false,
    this.streakState,
    this.onStreakLevelComplete,
    this.isAnalysisMode = false,
    this.onAnalysisComplete,
    this.onRetryLevel,
    this.showPostGameControls = false,
    this.gameToAnalyze,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Timer _updateTimer;
  bool _gameEndHandled = false;
  bool _isProcessingResult = false;
  bool _lastAIThinking = false;
  
  // Controlador de animación para mensaje del primer movimiento
  late AnimationController _firstMoveAnimationController;
  late Animation<double> _firstMovePulseAnimation;
  late Animation<double> _firstMoveGlowAnimation;
  
  // Referencias para animaciones de movimiento
  final GlobalKey<GameBoardState> _gameBoardKey = GlobalKey<GameBoardState>();
  bool _waitingForAIAnimation = false;
  
  // Estado para controles post-juego
  bool _showingPostGameControls = false;
  
  // Referencia al TournamentManager
  TournamentManager? _tournamentManager;
  bool _shouldCancelStreakOnDispose = true;

  @override
  void initState() {
    super.initState();
    
    // Inicializar animación para primer movimiento
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
    
    // Inicializar TournamentManager si es modo streak
    if (widget.isStreakMode) {
      _tournamentManager = TournamentManager();
    }

    // Si viene con showPostGameControls, activarlo
    _showingPostGameControls = widget.showPostGameControls;
    
    // Configurar callback para movimientos de IA
    if (!widget.isAnalysisMode) {
      widget.game.setAIMoveCallback(_handleAIMoveDecision);
      debugPrint('🎬 GameScreen: Callback de IA configurado en initState');
    }
    
    // Timer para actualizaciones de IA (30 FPS para menos parpadeo)
    _updateTimer = Timer.periodic(
      const Duration(milliseconds: 33),
      (timer) => _updateGame(0.033),
    );

    // Log del inicio de partida para debugging
    if (widget.tournamentLevelId != null) {
      debugPrint('🎮 Iniciando nivel de torneo ${widget.tournamentLevelId}');
      debugPrint('🔄 Rejuego: ${widget.isReplay}');
      debugPrint('🔍 Análisis: ${widget.isAnalysisMode}');
    }
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _firstMoveAnimationController.dispose(); // Liberar animación

    // Solo cancelar streak si realmente el usuario salió manualmente
    if (widget.isStreakMode && 
        _tournamentManager != null && 
        !widget.isAnalysisMode && 
        _shouldCancelStreakOnDispose) { // Verificar flag

      // Como no inicializamos el manager, usamos el callback para notificar
      // que el usuario salió del streak
      if (widget.onStreakLevelComplete != null) {
        debugPrint('🚪 Cancelando streak por salida manual del usuario');

        // Crear un resultado de "salida"
        final exitResult = GameResult(
          hasWinner: false,
          winner: null,
          moveCount: widget.game.moveCount,
        );
        // Llamar con un ID especial para indicar salida
        widget.onStreakLevelComplete!(-1, exitResult);
      }
    }

    widget.game.setAIMoveCallback(null);

    widget.game.dispose();
    super.dispose();
  }

/// Maneja cuando la IA decide un movimiento (inicia animación)
Future<void> _handleAIMoveDecision(int targetX, int targetY) async {
  debugPrint('🎬 GameScreen: _handleAIMoveDecision llamado para ($targetX,$targetY)');
  
  if (_waitingForAIAnimation) {
    debugPrint('⚠️ GameScreen: Ya esperando animación de IA');
    return;
  }
  
  debugPrint('🤖 GameScreen: IA decidió moverse a ($targetX,$targetY)');
  
  _waitingForAIAnimation = true;
  
  // Verificar que tenemos referencia al GameBoard
  final gameBoard = _gameBoardKey.currentState;
  if (gameBoard == null) {
    debugPrint('❌ GameScreen: GameBoard no disponible, ejecutando movimiento directo');
    widget.game.executeAIMove(targetX, targetY);
    _waitingForAIAnimation = false;
    return;
  }
  
  debugPrint('✅ GameScreen: GameBoard disponible, delegando animación');
  
  try {
    // El GameBoard manejará la animación y ejecutará el movimiento real al final
    await gameBoard.executeAIMove(targetX, targetY);
    debugPrint('✅ GameScreen: Animación de IA completada exitosamente');
  } catch (e) {
    debugPrint('❌ GameScreen: Error en animación de IA: $e');
    // Fallback: ejecutar directamente
    widget.game.executeAIMove(targetX, targetY);
  } finally {
    _waitingForAIAnimation = false;
  }
}



  void _updateGame(double dt) {
    // Si está en modo análisis, no actualizar IA
    if (widget.isAnalysisMode) return;
    
    widget.game.updateAI(dt);
    
    // Detectar cuando la IA termina de pensar y ejecuta movimiento
    if (_lastAIThinking && !widget.game.aiThinking && widget.game.aiMode) {
      _handleAIMove();
    }
    _lastAIThinking = widget.game.aiThinking;
    
    // Verificar si el juego terminó para manejar el resultado
    if (widget.game.gameOver && !_gameEndHandled && !_isProcessingResult) {
      _gameEndHandled = true;
      _handleGameEnd();
    }
  }

  /// Manejar cuando la IA hace un movimiento
  Future<void> _handleAIMove() async {
    await SoundManager.instance.playAIMove();
    // Vibración más sutil para movimientos de IA
    // (no usamos cellTap ya que es para el humano)
  }


  /// Manejar el final del juego con información detallada, persistencia y feedback
/// Manejar el final del juego con información detallada, persistencia y feedback
Future<void> _handleGameEnd() async {
  _isProcessingResult = true;
  
  try {
    // Crear resultado de la partida
    final result = GameResult(
      hasWinner: widget.game.winner != null,
      winner: widget.game.winner,
      moveCount: widget.game.moveCount,
    );

    debugPrint('🏁 Partida finalizada:');
    debugPrint('   Ganador: ${result.winner == null ? "Empate" : (result.humanWon ? "Humano" : "IA")}');
    debugPrint('   Movimientos: ${result.moveCount}');
    debugPrint('   Torneo ID: ${widget.tournamentLevelId}');

    // Feedback de sonido y vibración según el resultado
    await _playEndGameFeedback(result);

    // Pequeña pausa suave para que se vea el último movimiento
    await Future.delayed(const Duration(milliseconds: 800));

    if (widget.isStreakMode && widget.onStreakLevelComplete != null) {
      // Evitar cancelar streak en dispose ya que vamos a navegar intencionalmente
      _shouldCancelStreakOnDispose = false;
      
      widget.onStreakLevelComplete!(widget.tournamentLevelId!, result);
      return; // El callback maneja la navegación
    }

    // Si es torneo y se pierde, mostrar controles post-juego
    if (widget.tournamentLevelId != null && !result.humanWon && !widget.isAnalysisMode) {
      setState(() {
        _showingPostGameControls = true;
      });
      return; // No ejecutar callbacks normales
    }

    // Restablecer _isProcessingResult antes de callbacks
    // para partidas rápidas normales
    _isProcessingResult = false;
    
    // Notificar a la UI que el estado cambió
    setState(() {
      // Esto fuerza la reconstrucción de la UI para habilitar los botones
    });

    // Llamar callback con resultado si existe
    if (widget.onGameEndWithResult != null) {
      widget.onGameEndWithResult!(result);
      debugPrint('✅ Callback de resultado ejecutado');
    }

    // Llamar callback simple si existe (para compatibilidad)
    if (widget.onGameEnd != null) {
      widget.onGameEnd!();
      debugPrint('✅ Callback simple ejecutado');
    }

  } catch (e) {
    debugPrint('❌ Error procesando final de partida: $e');
  } finally {
    // Asegurar que siempre se restablezca
    _isProcessingResult = false;
    
    // Asegurar que la UI se actualice incluso en caso de error
    if (mounted) {
      setState(() {
        // Esto fuerza la reconstrucción de la UI para habilitar los botones
      });
    }
  }
}

  /// Reproducir feedback según el resultado del juego
  Future<void> _playEndGameFeedback(GameResult result) async {
    if (result.humanWon) {
      // ¡Victoria del humano!
      await HapticManager.instance.gameWin();
      await SoundManager.instance.playGameWin();
    } else if (result.aiWon) {
      // Derrota del humano
      await HapticManager.instance.gameLose();
      await SoundManager.instance.playGameLose();
    } else {
      // Empate (raro pero por gestionar todas las posibilidades, nunca se sabe xdd)
      await HapticManager.instance.moveInvalid(); // Vibración neutral
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.game,
      child: Scaffold(
        backgroundColor: UIColors.background,
        appBar: AppBar(
          title: Text(
            widget.isAnalysisMode ? 'ANÁLISIS' : 'COLLAPSI',
            style: TextStyle(
              fontSize: UIConstants.fontSizeLarge,
              color: widget.isAnalysisMode ? UIColors.warning : UIColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: UIColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => _exitGame(),
          ),
        ),
        body: Consumer<CollapsiEngine>(
          builder: (context, game, child) {
            return Column(
              children: [
                // Información del juego - altura fija
                _buildGameHeader(game),

                // Tablero de juego - se expande para llenar el espacio disponible
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
                    child: GameBoard(
                      key: _gameBoardKey,
                      game: game,
                      onCellTap: widget.isAnalysisMode ? null : _onCellTap, // Deshabilitar en análisis
                    ),
                  ),
                ),

                // Estado del juego - altura fija
                _buildGameInfo(game),

                // Controles - altura fija
                _buildGameControls(game),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameHeader(CollapsiEngine game) {
    final modeText = game.aiMode ? "Tú vs IA" : "Jugador vs Jugador";
    final gridSize = game.gridSize;
    
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$modeText (${gridSize}x$gridSize)',
                style: ZenTextStyles.body,
                textAlign: TextAlign.center,
              ),
              
              // Indicador de modo análisis
              if (widget.isAnalysisMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: UIColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    border: Border.all(color: UIColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded, color: UIColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Análisis',
                        style: ZenTextStyles.caption.copyWith(
                          color: UIColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (widget.isStreakMode && widget.streakState != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    border: Border.all(color: Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Bloque Perfecto ${widget.streakState!.progressText}',
                        style: ZenTextStyles.caption.copyWith(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (widget.isReplay) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: UIColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    border: Border.all(color: UIColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded, color: UIColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Rejuego',
                        style: ZenTextStyles.caption.copyWith(
                          color: UIColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Indicador de nivel de torneo (código existente)
              if (widget.tournamentLevelId != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: UIColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    border: Border.all(color: UIColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded, color: UIColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Nivel ${widget.tournamentLevelId}',
                        style: ZenTextStyles.caption.copyWith(
                          color: UIColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Movimiento #${game.moveCount}',
            style: ZenTextStyles.caption,
            textAlign: TextAlign.center,
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
      padding: const EdgeInsets.all(UIConstants.spacing16),
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

    // Estados especiales para análisis y controles post-juego
    if (widget.isAnalysisMode) {
      statusText = "Análisis de partida";
      statusColor = UIColors.warning;
    } else if (_showingPostGameControls) {
      statusText = "";
      statusColor = UIColors.textSecondary;
    } else if (game.gameOver) {
      if (game.winner != null) {
        if (game.aiMode) {
          statusText = game.winner == 0 ? "¡Has ganado!" : "La IA ha ganado";
        } else {
          final winnerName = game.winner == 0 ? "Azul" : "Rojo";
          statusText = "¡$winnerName gana!";
        }
        statusColor = game.winner == 0 ? UIColors.player1 : UIColors.player2;
      } else {
        statusText = "¡Empate!";
        statusColor = UIColors.textSecondary;
      }
    } else {
      // Mensaje especial para el primer movimiento (igual en ambos modos)
      if (game.moveCount == 0 && game.currentPlayer == 0) {
        statusText = "¡Puedes moverte a cualquier casilla del tablero!";
        statusColor = Color(0xFF34C759); // Verde más llamativo
        isFirstMoveMessage = true;
      } else if (game.aiMode) {
        if (game.currentPlayer == 0) {
          statusText = "Tu turno";
          statusColor = UIColors.player1;
        } else {
          // Texto estático sin animación para evitar parpadeo
          statusText = "IA pensando...";
          statusColor = UIColors.player2;
        }
      } else {
        final playerName = game.currentPlayer == 0 ? "Azul" : "Rojo";
        statusText = "Turno de $playerName";
        statusColor = game.currentPlayer == 0 ? UIColors.player1 : UIColors.player2;
      }
    }

    // No mostrar contenedor cuando no hay texto
    if (statusText.isEmpty) {
      return const SizedBox.shrink();
    }

    // Contenedor especial con animación para primer movimiento
    if (isFirstMoveMessage) {
      return AnimatedBuilder(
        animation: _firstMoveAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _firstMovePulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(UIConstants.spacing16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.15),
                    statusColor.withOpacity(0.25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
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
                        fontSize: UIConstants.fontSizeMedium,
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
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: UIConstants.fontSizeMedium,
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInstructions(CollapsiEngine game) {
    String instructionText;

    // Instrucciones para diferentes modos
    if (widget.isAnalysisMode) {
      instructionText = "";
    } else if (_showingPostGameControls) {
      instructionText = "";
    } else if (game.gameOver) {
      // Mensaje específico para torneos
      if (widget.tournamentLevelId != null) {
        if (game.winner == 0) {
          instructionText = widget.isReplay 
              ? "¡Nivel rejugado exitosamente!"
              : "¡Nivel completado! Progreso guardado automáticamente";
        } else {
          instructionText = "Intenta de nuevo para completar el nivel";
        }
      } else {
        instructionText = "¡Partida terminada!";
      }
    } else if (game.aiMode && game.currentPlayer == 1) {
      instructionText = "La IA está evaluando sus opciones";
    } else {
      instructionText = "Toca en una casilla válida para moverte";
    }

    // No mostrar contenedor cuando no hay texto
    if (instructionText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      instructionText,
      style: ZenTextStyles.caption,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGameControls(CollapsiEngine game) {
    // Controles especiales para análisis
    if (widget.isAnalysisMode) {
      return Container(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onRetryLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: UIColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Repetir Nivel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2, // Más ancho como pidió el usuario
              child: ElevatedButton(
                onPressed: widget.onAnalysisComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: UIColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Continuar'),
              ),
            ),
          ],
        ),
      );
    }

    // Controles especiales cuando pierdes en torneo
    if (_showingPostGameControls) {
      return Container(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Row( // De Column a Row para solo el botón
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onRetryLevel ?? _retryCurrentLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: UIColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Volver a Intentar'),
              ),
            ),
          ],
        ),
      );
    }

    // En modo streak, no mostrar controles de reinicio/undo
    if (widget.isStreakMode) {
      return Container(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing12),
              decoration: BoxDecoration(
                color: Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Modo Bloque Perfecto - Sin reinicio ni deshacer',
                    style: ZenTextStyles.caption.copyWith(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }


    // Controles normales (código existente)
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Row(
        children: [
          if (widget.allowRestart) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessingResult ? null : () => _restartGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UIColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Reiniciar', style: TextStyle(fontSize: 14), maxLines: 1),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          if (widget.allowUndo) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: (game.canUndo() && !_isProcessingResult) ? () => _undoMove() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: UIColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Deshacer', style: TextStyle(fontSize: 14), maxLines: 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onCellTap(int x, int y) {
    // En modo IA, solo permitir toques cuando es turno del humano
    if (widget.game.aiMode && 
        (widget.game.currentPlayer == 1 || widget.game.aiThinking)) {
      return;
    }

    // No permitir movimientos si se está procesando el resultado
    if (_isProcessingResult) {
      return;
    }

    // Feedback al hacer movimiento exitoso
    if (widget.game.isValidMoveCell(x, y)) {
      _playMoveSuccessFeedback();
      
      GamePathFinder.debugCompareAlgorithms(widget.game, x, y);
    }

    widget.game.makeMove(x, y);
  }

  /// Feedback para movimiento exitoso
  Future<void> _playMoveSuccessFeedback() async {
    await SoundManager.instance.playMoveSuccess();
    await HapticManager.instance.moveSuccess();
  }

  void _restartGame() async {
    // Feedback al reiniciar
    await HapticManager.instance.buttonTap();
    await SoundManager.instance.playButtonTap();
    
    _gameEndHandled = false; // Reset flag
    _isProcessingResult = false; // Reset processing flag
    _showingPostGameControls = false; // Reset controles post-juego
    widget.game.resetGame();
    
    // Log del restart para debugging
    if (widget.tournamentLevelId != null) {
      debugPrint('🔄 Reiniciando nivel de torneo ${widget.tournamentLevelId}');
    }
  }

  void _undoMove() async {
    if (widget.game.canUndo() && !_isProcessingResult) {
      // Feedback al deshacer
      await HapticManager.instance.undoMove();
      await SoundManager.instance.playUndoMove();
      
      widget.game.undoLastMove();
    }
  }

  // Método para repetir nivel actual
  void _retryCurrentLevel() async {
    await HapticManager.instance.buttonTap();
    await SoundManager.instance.playButtonTap();
    
    // Reset del juego
    _gameEndHandled = false;
    _isProcessingResult = false;
    _showingPostGameControls = false;
    widget.game.resetGame();
    
    setState(() {
      // Refresh UI
    });
  }

  void _exitGame() async {
    // Feedback al salir
    await HapticManager.instance.navigation();

    _shouldCancelStreakOnDispose = true;

    if (widget.isStreakMode && !widget.isAnalysisMode) {
      final shouldExit = await _showExitStreakConfirmation();
      if (!shouldExit) return;
    }

    if (_isProcessingResult) {
      // Esperar a que termine el procesamiento antes de salir
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showExitStreakConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: TweenAnimationBuilder<double>(
          duration: AnimationConstants.medium,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.7 + (0.3 * value),
              child: Opacity(
                opacity: value,
                child: _buildExitStreakDialogContent(),
              ),
            );
          },
        ),
      ),
    ) ?? false;
  }
  
  Widget _buildExitStreakDialogContent() {
    return Container(
      margin: const EdgeInsets.all(UIConstants.spacing24),
      decoration: BoxDecoration(
        color: UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        border: Border.all(
          color: UIColors.warning.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: UIColors.warning.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing32),
            child: Column(
              children: [
                // Icono de advertencia
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        UIColors.warning.withOpacity(0.2),
                        UIColors.warning.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: UIColors.warning.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: UIColors.warning,
                  ),
                ),
                
                const ZenSpacer.large(),
                
                // Título
                Text(
                  '¿Salir del Streak?',
                  style: ZenTextStyles.title.copyWith(
                    color: UIColors.warning,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const ZenSpacer.medium(),
                
                // Mensaje
                Text(
                  'Si sales ahora, perderás todo el progreso del Modo Bloque Perfecto.',
                  style: ZenTextStyles.body.copyWith(
                    color: UIColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Separador
          Container(
            height: 1,
            color: UIColors.borderLight,
          ),
          
          // Botones del mismo tamaño en horizontal
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: Row(
              children: [
                // Botón Cancelar (mismo tamaño)
                Expanded(
                  child: _buildStreakExitButton(
                    text: 'Continuar Jugando',
                    isPrimary: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Salir (mismo tamaño)
                Expanded(
                  child: _buildStreakExitButton(
                    text: 'Salir y Perder',
                    isPrimary: false,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  
  Widget _buildStreakExitButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: UIConstants.buttonHeight + 8,
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      UIColors.success,
                      UIColors.success.withOpacity(0.8),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      UIColors.error,
                      UIColors.error.withOpacity(0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: (isPrimary ? UIColors.success : UIColors.error).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              splashFactory: NoSplash.splashFactory,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: ZenTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}