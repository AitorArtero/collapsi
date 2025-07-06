import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../core/collapsi_engine.dart';
import '../ai_manager.dart';

/// ALGORITMO MINIMAX CON PODA ALPHA-BETA
/// 
/// Implementación completa que explora 4 turnos hacia adelante.
/// 
/// CARACTERÍSTICAS:
/// - Búsqueda recursiva hasta profundidad 4
/// - Poda Alpha-Beta para optimización
/// - Simulación real del estado del juego
/// - Función de evaluación multi-factor
/// - Asume que ambos jugadores juegan óptimamente
class MinimaxAI implements AIStrategy {
  @override
  final CollapsiEngine game;
  final int maxDepth;
  final int aiPlayer = 1; // IA = jugador rojo
  final int humanPlayer = 0; // Humano = jugador azul

  // Pesos para función de evaluación (basados en la versión Python)
  final double mobilityWeight = 100.0;
  final double opponentBlockWeight = 90.0;
  final double survivalWeight = 80.0;
  final double controlWeight = 20.0;

  // Estadísticas para análisis
  int nodesEvaluated = 0;
  int pruningCount = 0;
  int maxDepthReached = 0;

  // Control de recursión
  bool isThinking = false;

  MinimaxAI(this.game, {this.maxDepth = 4}) {
    print("🧠 VERDADERO MinimaxAI inicializado - Profundidad: $maxDepth");
    print("🎯 Pesos: Movilidad=$mobilityWeight, Bloqueo=$opponentBlockWeight, Supervivencia=$survivalWeight");
  }

  @override
  ({int x, int y})? chooseBestMove(Set<String> validMoves) {
    if (validMoves.isEmpty || game.gameOver) {
      debugPrint("🛑 MinimaxAI: No hay movimientos válidos o juego terminado");
      return null;
    }

    if (game.currentPlayer != aiPlayer) {
      debugPrint("🛑 MinimaxAI: No es mi turno (actual: ${game.currentPlayer})");
      return null;
    }

    if (isThinking) {
      debugPrint("🛑 MinimaxAI: Ya estoy calculando");
      return null;
    }

    isThinking = true;

    try {
      // Reiniciar estadísticas
      nodesEvaluated = 0;
      pruningCount = 0;
      maxDepthReached = 0;

      print("\n🧠 === MINIMAX INICIANDO ===");
      print("🎯 Profundidad máxima: $maxDepth");
      print("🔍 Movimientos a evaluar: ${validMoves.length}");
      print("👤 Jugador actual: $aiPlayer (IA)");

      ({int x, int y})? bestMove;
      double bestScore = double.negativeInfinity;

      // ALGORITMO MINIMAX PRINCIPAL
      // Crear copia para evitar modificación concurrente durante iteración
      List<String> movesList = validMoves.toList();
      for (String moveStr in movesList) {
        List<String> coords = moveStr.split(',');
        int x = int.parse(coords[0]);
        int y = int.parse(coords[1]);

        print("\n🔍 === Evaluando movimiento ($x,$y) ===");

        // Guardar estado actual
        GameStateSnapshot initialState = game.createSnapshot();

        // Simular movimiento
        if (game.simulateMove(x, y)) {
          print("✅ Movimiento simulado exitosamente");
          print("📊 Estado después del movimiento: ${game.getSimulationDebugInfo()}");

          // LLAMADA RECURSIVA MINIMAX
          double score = minimax(
            depth: maxDepth - 1,
            isMaximizing: false, // Siguiente turno es del humano (minimiza)
            alpha: double.negativeInfinity,
            beta: double.infinity,
            currentDepth: 1,
          );

          print("📈 Score obtenido: ${score.toStringAsFixed(2)}");

          // Restaurar estado original
          game.restoreFromSnapshot(initialState);
          print("↩️ Estado restaurado");

          // Actualizar mejor movimiento
          if (score > bestScore) {
            bestScore = score;
            bestMove = (x: x, y: y);
            print("⭐ NUEVO MEJOR MOVIMIENTO: ($x,$y) con score ${score.toStringAsFixed(2)}");
          }
        } else {
          print("❌ Error simulando movimiento ($x,$y)");
          game.restoreFromSnapshot(initialState);
        }
      }

      print("\n🎯 === RESULTADO FINAL ===");
      print("🏆 Mejor movimiento: $bestMove");
      print("📊 Score final: ${bestScore.toStringAsFixed(2)}");
      print("🔍 Nodos evaluados: $nodesEvaluated");
      print("✂️ Podas realizadas: $pruningCount");
      print("📏 Profundidad máxima alcanzada: $maxDepthReached");

      return bestMove;

    } catch (e) {
      debugPrint("❌ Error en MinimaxAI: $e");
      return null;
    } finally {
      isThinking = false;
    }
  }

  /// ALGORITMO MINIMAX RECURSIVO CON PODA ALPHA-BETA
  double minimax({
    required int depth,
    required bool isMaximizing,
    required double alpha,
    required double beta,
    required int currentDepth,
  }) {
    nodesEvaluated++;
    maxDepthReached = math.max(maxDepthReached, currentDepth);

    // CASO BASE 1: Profundidad máxima alcanzada
    if (depth == 0) {
      double score = evaluatePosition();
      print("${'  ' * currentDepth}🎯 Evaluación hoja (profundidad $currentDepth): ${score.toStringAsFixed(2)}");
      return score;
    }

    // CASO BASE 2: Juego terminado
    if (game.isGameTerminated()) {
      double terminalScore = evaluateTerminalState();
      print("${'  ' * currentDepth}🏁 Estado terminal: ${terminalScore.toStringAsFixed(2)}");
      return terminalScore;
    }

    // Obtener movimientos válidos y crear copia para evitar modificación concurrente
    List<String> movesList = game.validMoves.toList();

    // CASO BASE 3: Sin movimientos válidos
    if (movesList.isEmpty) {
      // El jugador actual pierde
      double lossScore = isMaximizing ? -10000.0 - depth : 10000.0 + depth;
      print("${'  ' * currentDepth}💀 Sin movimientos (${isMaximizing ? 'IA' : 'Humano'} pierde): ${lossScore.toStringAsFixed(2)}");
      return lossScore;
    }

    print("${'  ' * currentDepth}${isMaximizing ? '🤖' : '👤'} Nivel $currentDepth (${isMaximizing ? 'MAX' : 'MIN'}): ${movesList.length} movimientos");

    if (isMaximizing) {
      // MAXIMIZAR (Turno de la IA)
      double maxEval = double.negativeInfinity;

      for (String moveStr in movesList) {
        List<String> coords = moveStr.split(',');
        int x = int.parse(coords[0]);
        int y = int.parse(coords[1]);

        // Guardar estado antes de simular
        GameStateSnapshot stateBeforeMove = game.createSnapshot();

        if (game.simulateMove(x, y)) {
          print("${'  ' * currentDepth}📍 IA simula ($x,$y)");

          // Llamada recursiva
          double eval = minimax(
            depth: depth - 1,
            isMaximizing: false,
            alpha: alpha,
            beta: beta,
            currentDepth: currentDepth + 1,
          );

          // Restaurar estado
          game.restoreFromSnapshot(stateBeforeMove);

          maxEval = math.max(maxEval, eval);
          alpha = math.max(alpha, eval);

          print("${'  ' * currentDepth}📈 IA eval: ${eval.toStringAsFixed(2)}, max: ${maxEval.toStringAsFixed(2)}, α: ${alpha.toStringAsFixed(2)}");

          // PODA BETA
          if (beta <= alpha) {
            pruningCount++;
            print("${'  ' * currentDepth}✂️ PODA BETA (β=${beta.toStringAsFixed(2)} ≤ α=${alpha.toStringAsFixed(2)})");
            break;
          }
        } else {
          // Restaurar estado si la simulación falló
          game.restoreFromSnapshot(stateBeforeMove);
        }
      }

      print("${'  ' * currentDepth}🤖 MAX retorna: ${maxEval.toStringAsFixed(2)}");
      return maxEval;

    } else {
      // MINIMIZAR (Turno del humano)
      double minEval = double.infinity;

      for (String moveStr in movesList) {
        List<String> coords = moveStr.split(',');
        int x = int.parse(coords[0]);
        int y = int.parse(coords[1]);

        // Guardar estado antes de simular
        GameStateSnapshot stateBeforeMove = game.createSnapshot();

        if (game.simulateMove(x, y)) {
          print("${'  ' * currentDepth}📍 Humano simula ($x,$y)");

          // Llamada recursiva
          double eval = minimax(
            depth: depth - 1,
            isMaximizing: true,
            alpha: alpha,
            beta: beta,
            currentDepth: currentDepth + 1,
          );

          // Restaurar estado
          game.restoreFromSnapshot(stateBeforeMove);

          minEval = math.min(minEval, eval);
          beta = math.min(beta, eval);

          print("${'  ' * currentDepth}📉 Humano eval: ${eval.toStringAsFixed(2)}, min: ${minEval.toStringAsFixed(2)}, β: ${beta.toStringAsFixed(2)}");

          // PODA ALPHA
          if (beta <= alpha) {
            pruningCount++;
            print("${'  ' * currentDepth}✂️ PODA ALPHA (β=${beta.toStringAsFixed(2)} ≤ α=${alpha.toStringAsFixed(2)})");
            break;
          }
        } else {
          // Restaurar estado si la simulación falló
          game.restoreFromSnapshot(stateBeforeMove);
        }
      }

      print("${'  ' * currentDepth}👤 MIN retorna: ${minEval.toStringAsFixed(2)}");
      return minEval;
    }
  }

  /// FUNCIÓN DE EVALUACIÓN MULTI-FACTOR
  /// (Basada en la versión Python original)
  double evaluatePosition() {
    var aiPos = game.getPlayerPosition(aiPlayer);
    var humanPos = game.getPlayerPosition(humanPlayer);

    if (aiPos == null || humanPos == null) {
      return 0.0;
    }

    double totalScore = 0.0;

    // 1. ANÁLISIS DE MOVILIDAD (40%)
    Set<String> aiMoves = game.getValidMovesForPlayer(aiPlayer);
    Set<String> humanMoves = game.getValidMovesForPlayer(humanPlayer);

    int aiMobility = aiMoves.length;
    int humanMobility = humanMoves.length;

    double mobilityAdvantage = (aiMobility - humanMobility).toDouble();
    double mobilityScore = mobilityAdvantage * mobilityWeight;
    totalScore += mobilityScore;

    // 2. ANÁLISIS DE CAPACIDAD DE BLOQUEO (35%)
    double blockingPotential = calculateBlockingPotential();
    totalScore += blockingPotential * opponentBlockWeight;

    // 3. ANÁLISIS DE SUPERVIVENCIA (20%)
    int aiSurvival = estimateSurvivalTurns(aiPlayer);
    int humanSurvival = estimateSurvivalTurns(humanPlayer);

    double survivalAdvantage = (aiSurvival - humanSurvival).toDouble();
    double survivalScore = survivalAdvantage * survivalWeight;
    totalScore += survivalScore;

    // 4. CONTROL GENERAL DEL JUEGO (5%)
    double controlScore = evaluateGameControl();
    totalScore += controlScore * controlWeight;

    return totalScore;
  }

  /// Calcula potencial de bloqueo del rival
  double calculateBlockingPotential() {
    Set<String> humanCurrentOptions = game.getValidMovesForPlayer(humanPlayer);

    if (humanCurrentOptions.isEmpty) {
      return 100.0; // Humano ya bloqueado
    }

    double maxBlocking = 0.0;
    Set<String> aiMoves = game.getValidMovesForPlayer(aiPlayer);

    // Evaluar muestra de movimientos de la IA para ver cuánto bloquean al humano
    List<String> sampleMoves = aiMoves.take(5).toList();

    for (String moveStr in sampleMoves) {
      List<String> coords = moveStr.split(',');
      int x = int.parse(coords[0]);
      int y = int.parse(coords[1]);

      GameStateSnapshot stateBeforeMove = game.createSnapshot();

      if (game.simulateMove(x, y)) {
        Set<String> humanOptionsAfter = game.getValidMovesForPlayer(humanPlayer);
        double blocking = (humanCurrentOptions.length - humanOptionsAfter.length).toDouble();
        maxBlocking = math.max(maxBlocking, blocking);

        game.restoreFromSnapshot(stateBeforeMove);
      } else {
        game.restoreFromSnapshot(stateBeforeMove);
      }
    }

    return maxBlocking;
  }

  /// Estima turnos de supervivencia
  int estimateSurvivalTurns(int player) {
    Set<String> moves = game.getValidMovesForPlayer(player);
    if (moves.isEmpty) return 0;

    // Evaluación simplificada pero efectiva
    int baseSurvival = moves.length;

    // Evaluar calidad de movimientos disponibles
    var playerPos = game.getPlayerPosition(player);
    if (playerPos != null) {
      List<int> allowedMoves = game.getAllowedMovesPublic(playerPos.x, playerPos.y);
      int totalMoveTypes = allowedMoves.length;
      int maxMoveDistance = allowedMoves.isEmpty ? 1 : allowedMoves.reduce(math.max);

      // Bonus por diversidad y distancia de movimientos
      baseSurvival += totalMoveTypes * 2;
      baseSurvival += maxMoveDistance;
    }

    return baseSurvival;
  }

  /// Evalúa control general del juego
  double evaluateGameControl() {
    var aiPos = game.getPlayerPosition(aiPlayer);
    var humanPos = game.getPlayerPosition(humanPlayer);

    if (aiPos == null || humanPos == null) {
      return 0.0;
    }

    double controlScore = 0.0;

    // Evaluar valores en posiciones actuales
    int aiCellValue = game.values[aiPos.y * game.gridSize + aiPos.x];
    int humanCellValue = game.values[humanPos.y * game.gridSize + humanPos.x];

    // Valores especiales (99, 100) dan más opciones
    if (aiCellValue == 99 || aiCellValue == 100) {
      controlScore += 15.0;
    } else if (aiCellValue >= 4) {
      controlScore += 5.0;
    }

    if (humanCellValue == 99 || humanCellValue == 100) {
      controlScore -= 15.0;
    } else if (humanCellValue >= 4) {
      controlScore -= 5.0;
    }

    return controlScore;
  }

  /// Evalúa estados terminales
  double evaluateTerminalState() {
    if (game.winner == aiPlayer) {
      return 10000.0; // IA gana
    } else if (game.winner == humanPlayer) {
      return -10000.0; // IA pierde
    } else {
      return 0.0; // Empate
    }
  }

  /// Resetea el estado interno
  void resetState() {
    isThinking = false;
    nodesEvaluated = 0;
    pruningCount = 0;
    maxDepthReached = 0;
  }

  /// Obtiene estadísticas de rendimiento
  Map<String, dynamic> getStats() {
    return {
      'nodes_evaluated': nodesEvaluated,
      'pruning_count': pruningCount,
      'max_depth_reached': maxDepthReached,
      'max_depth': maxDepth,
      'ai_player': aiPlayer,
      'weights': {
        'mobility': mobilityWeight,
        'blocking': opponentBlockWeight,
        'survival': survivalWeight,
        'control': controlWeight,
      }
    };
  }
}