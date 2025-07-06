import 'dart:math' as math;
import '../../../config/game_constants.dart';
import '../../../core/collapsi_engine.dart';
import '../ai_manager.dart';

/// Clase para movimientos con análisis completo (usada por IA difícil)
class AdvancedMoveScore {
  final ({int x, int y}) move;
  double baseScore;
  double lookAheadBonus;
  double trapBonus;
  double predictionBonus;
  
  AdvancedMoveScore(this.move, this.baseScore) 
      : lookAheadBonus = 0, trapBonus = 0, predictionBonus = 0;
  
  double get totalScore => baseScore + lookAheadBonus + trapBonus + predictionBonus;
}

/// Sistema de Inteligencia Artificial para Collapsi (Versión Mejorada)
/// Implementa tanto el nivel MEDIO como DIFÍCIL con diferencias significativas
class HeuristicAI implements AIStrategy {
  @override
  final CollapsiEngine game;
  late Map<String, double> weights;
  String difficulty = "medium";
  
  // CONFIGURACIÓN PARA MODO DIFÍCIL
  final int lookAheadDepth = 2;          // Solo para modo difícil
  final double aggressionFactor = 1.4;   // Solo para modo difícil
  final math.Random _random = math.Random();

  HeuristicAI(this.game) {
    // Establecer pesos por defecto (medium)
    weights = DifficultyLevels.getAIWeights("medium");
  }

  @override
  ({int x, int y})? chooseBestMove(Set<String> validMoves) {
    if (validMoves.isEmpty) {
      return null;
    }

    // Decidir estrategia según dificultad
    if (difficulty == "hard") {
      return _chooseAdvancedMove(validMoves);
    } else {
      return _chooseMediumMove(validMoves);
    }
  }

  /// ESTRATEGIA PARA MODO MEDIO - Con errores ocasionales
  ({int x, int y})? _chooseMediumMove(Set<String> validMoves) {
    print("\n🧠 IA Competidor evaluando ${validMoves.length} movimientos...");

    List<({({int x, int y}) move, double score})> moveScores = [];
    
    for (String moveKey in validMoves) {
      List<String> coords = moveKey.split(',');
      int x = int.parse(coords[0]);
      int y = int.parse(coords[1]);
      
      double score = evaluateMove(x, y);
      moveScores.add((move: (x: x, y: y), score: score));
      print("   📍 ($x,$y): Score ${score.toStringAsFixed(1)}");
    }

    // Ordenar por puntuación
    moveScores.sort((a, b) => b.score.compareTo(a.score));

    // Sistema de errores ocasionales (15%)
    double errorRate = 0.15;
    if (_random.nextDouble() < errorRate) {
      // 15% del tiempo, elegir entre los top 3 en lugar del mejor
      int maxIndex = math.min(3, moveScores.length) - 1;
      int randomIndex = _random.nextInt(maxIndex + 1);
      var chosenMove = moveScores[randomIndex];
      print("🎲 IA Competidor comete error menor: ${chosenMove.move} (${randomIndex == 0 ? 'óptimo' : '${randomIndex + 1}º mejor'})");
      return chosenMove.move;
    } else {
      // 85% del tiempo, jugar óptimo
      var bestMove = moveScores.first;
      print("🎯 IA Competidor elige ÓPTIMO: ${bestMove.move}");
      return bestMove.move;
    }
  }

  /// ESTRATEGIA PARA MODO DIFÍCIL - Sin errores, con lookahead
  ({int x, int y})? _chooseAdvancedMove(Set<String> validMoves) {
    print("\n🎯 IA Estratega analizando ${validMoves.length} movimientos...");
    print("🧠 Activando análisis avanzado: Lookahead $lookAheadDepth + Predicción de oponente");

    // 1. Evaluación base de todos los movimientos
    List<AdvancedMoveScore> moveScores = [];
    
    for (String moveKey in validMoves) {
      List<String> coords = moveKey.split(',');
      int x = int.parse(coords[0]);
      int y = int.parse(coords[1]);
      
      double baseScore = evaluateMove(x, y);
      moveScores.add(AdvancedMoveScore((x: x, y: y), baseScore));
    }

    // 2. ANÁLISIS PREDICTIVO DE OPONENTE
    Map<String, double> opponentPredictions = _predictOpponentStrategy();
    
    // 3. ANÁLISIS AVANZADO PARA CADA MOVIMIENTO
    for (var moveScore in moveScores) {
      // Lookahead de 2 turnos
      moveScore.lookAheadBonus = _evaluateLookAhead(moveScore.move, lookAheadDepth);
      
      // Potencial de trampa
      moveScore.trapBonus = _calculateTrapPotential(moveScore.move) * aggressionFactor;
      
      // Bonus por contrarrestar estrategia del oponente
      moveScore.predictionBonus = _evaluateCounterStrategy(moveScore.move, opponentPredictions);
      
      print("   🎯 (${moveScore.move.x},${moveScore.move.y}): "
          "Base=${moveScore.baseScore.toStringAsFixed(1)}, "
          "Lookahead=+${moveScore.lookAheadBonus.toStringAsFixed(1)}, "
          "Trampa=+${moveScore.trapBonus.toStringAsFixed(1)}, "
          "Contra=+${moveScore.predictionBonus.toStringAsFixed(1)} "
          "→ TOTAL=${moveScore.totalScore.toStringAsFixed(1)}");
    }

    // 4. Seleccionar mejor movimiento
    moveScores.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    var bestMove = moveScores.first;
    
    print("🏆 IA Estratega elige: ${bestMove.move} (Score: ${bestMove.totalScore.toStringAsFixed(1)})");
    return bestMove.move;
  }

  /// PREDICE LA ESTRATEGIA DEL OPONENTE (solo modo difícil)
  Map<String, double> _predictOpponentStrategy() {
    print("🔮 Analizando patrones del oponente...");
    
    var humanPos = game.getPlayerPosition(0); // Humano = jugador 0
    if (humanPos == null) return {};
    
    Set<String> humanMoves = game.getValidMovesForPlayer(0);
    Map<String, double> predictions = {};
    
    for (String moveKey in humanMoves) {
      List<String> coords = moveKey.split(',');
      int x = int.parse(coords[0]);
      int y = int.parse(coords[1]);
      
      // Simular qué puntuación le daría una IA media a este movimiento
      double humanLikelihood = _simulateHumanThinking(x, y);
      predictions[moveKey] = humanLikelihood;
    }
    
    // Encontrar movimientos más probables del humano
    var sortedPredictions = predictions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedPredictions.isNotEmpty) {
      print("🎯 Predicción: Humano probablemente jugará ${sortedPredictions.first.key}");
    }
    
    return predictions;
  }

  /// Simula el pensamiento de un humano promedio
  double _simulateHumanThinking(int x, int y) {
    // Los humanos tienden a priorizar supervivencia y movilidad inmediata
    // Simular evaluación con pesos "humanos típicos"
    const humanWeights = {
      'mobility': 0.45,       // Humanos priorizan supervivencia
      'rival_reduction': 0.20, // Menos agresivos que IA difícil
      'survival': 0.30,       // Importante para humanos
      'freedom': 0.05,
    };
    
    return _evaluateWithCustomWeights(x, y, humanWeights);
  }

  /// ANÁLISIS LOOKAHEAD DE 2 TURNOS (solo modo difícil)
  double _evaluateLookAhead(({int x, int y}) move, int depth) {
    if (depth <= 0) return 0;
    
    GameStateSnapshot initialState = game.createSnapshot();
    
    if (!game.simulateMove(move.x, move.y)) {
      game.restoreFromSnapshot(initialState);
      return -1000; // Movimiento inválido
    }
    
    // Evaluar posición después de nuestro movimiento
    double immediateValue = _evaluateCurrentPosition();
    
    // Si el juego terminó, evaluar resultado
    if (game.isGameTerminated()) {
      game.restoreFromSnapshot(initialState);
      return game.winner == 1 ? 1000 : -1000; // 1 = IA gana, 0 = humano gana
    }
    
    // Simular mejor respuesta del humano
    Set<String> humanResponses = game.getValidMovesForPlayer(0);
    double worstCaseForUs = double.infinity;
    
    for (String responseKey in humanResponses.take(3)) { // Limitar para eficiencia
      List<String> coords = responseKey.split(',');
      int rx = int.parse(coords[0]);
      int ry = int.parse(coords[1]);
      
      GameStateSnapshot beforeHumanMove = game.createSnapshot();
      
      if (game.simulateMove(rx, ry)) {
        double positionAfterHuman = _evaluateCurrentPosition();
        worstCaseForUs = math.min(worstCaseForUs, positionAfterHuman);
        
        game.restoreFromSnapshot(beforeHumanMove);
      } else {
        game.restoreFromSnapshot(beforeHumanMove);
      }
    }
    
    game.restoreFromSnapshot(initialState);
    
    // Retornar evaluación conservadora (asumiendo respuesta óptima del humano)
    double lookAheadValue = immediateValue - (worstCaseForUs == double.infinity ? 0 : worstCaseForUs * 0.5);
    return lookAheadValue * 0.3; // Reducir peso del lookahead para balancear
  }

  /// CALCULA POTENCIAL DE TRAMPA MORTAL (solo modo difícil)
  double _calculateTrapPotential(({int x, int y}) move) {
    GameStateSnapshot initialState = game.createSnapshot();
    
    if (!game.simulateMove(move.x, move.y)) {
      game.restoreFromSnapshot(initialState);
      return 0;
    }
    
    // Analizar opciones restantes del humano
    var humanOptions = game.getValidMovesForPlayer(0);
    int humanMobility = humanOptions.length;
    
    game.restoreFromSnapshot(initialState);
    
    // Calcular nivel de trampa
    double trapScore = 0;
    
    if (humanMobility == 0) {
      trapScore = 200; // ¡JAQUE MATE! 
      print("   💀 TRAMPA MORTAL detectada en (${move.x},${move.y})");
    } else if (humanMobility == 1) {
      trapScore = 100; // Forzar único movimiento
      print("   🎯 Trampa crítica en (${move.x},${move.y}) - humano tendrá 1 opción");
    } else if (humanMobility <= 3) {
      trapScore = 50;  // Presión alta
      print("   ⚠️ Presión alta en (${move.x},${move.y}) - humano tendrá $humanMobility opciones");
    }
    
    return trapScore;
  }

  /// EVALÚA CONTRA-ESTRATEGIA (solo modo difícil)
  double _evaluateCounterStrategy(({int x, int y}) move, Map<String, double> opponentPredictions) {
    if (opponentPredictions.isEmpty) return 0;
    
    // Si sabemos qué va a hacer el humano, ¿este movimiento lo contrarresta?
    var topHumanMove = opponentPredictions.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    // Simular secuencia: nosotros movemos, luego humano juega su movimiento probable
    GameStateSnapshot initialState = game.createSnapshot();
    
    if (game.simulateMove(move.x, move.y)) {
      List<String> coords = topHumanMove.key.split(',');
      int hx = int.parse(coords[0]);
      int hy = int.parse(coords[1]);
      
      if (game.simulateMove(hx, hy)) {
        // Evaluar qué tan buena es la posición resultante para nosotros
        double finalPosition = _evaluateCurrentPosition();
        game.restoreFromSnapshot(initialState);
        return finalPosition * 0.2; // Peso moderado
      }
    }
    
    game.restoreFromSnapshot(initialState);
    return 0;
  }

  /// Evalúa posición actual para lookahead
  double _evaluateCurrentPosition() {
    var aiPos = game.getPlayerPosition(1);
    var humanPos = game.getPlayerPosition(0);
    
    if (aiPos == null || humanPos == null) return 0;
    
    int aiMoves = game.getValidMovesForPlayer(1).length;
    int humanMoves = game.getValidMovesForPlayer(0).length;
    
    return (aiMoves - humanMoves) * 10.0;
  }

  /// HEURÍSTICA HÍBRIDA - Evalúa cuanto de bueno es un movimiento
  double evaluateMove(int targetX, int targetY) {
    return _evaluateWithCustomWeights(targetX, targetY, weights);
  }

  /// Evaluación con pesos personalizados
  double _evaluateWithCustomWeights(int targetX, int targetY, Map<String, double> customWeights) {
    // Simular el movimiento
    List<List<CellState>> futureGrid = simulateMove(
      targetX, targetY, game.grid, game.currentPlayer
    );

    // === FACTOR 1: MOVILIDAD FUTURA ===
    int myFutureMoves = countMovesFromPosition(targetX, targetY, futureGrid, game.currentPlayer);
    double mobilityScore = myFutureMoves * 10.0; // Cada movimiento futuro vale 10 puntos

    // === FACTOR 2: REDUCIR RIVAL ===
    int rivalPlayer = 1 - game.currentPlayer;
    var rivalPos = game.getPlayerPosition(rivalPlayer);
    double rivalReductionScore = 0;

    if (rivalPos != null) {
      // Opciones del rival antes y después de mi movimiento
      int rivalMovesBefore = countMovesFromPosition(rivalPos.x, rivalPos.y, game.grid, rivalPlayer);
      int rivalMovesAfter = countMovesFromPosition(rivalPos.x, rivalPos.y, futureGrid, rivalPlayer);

      // Puntos por reducir opciones del rival
      int movesReduced = rivalMovesBefore - rivalMovesAfter;
      rivalReductionScore = movesReduced * 10.0; // Igual peso que movilidad propia
    }

    // === FACTOR 3: SUPERVIVENCIA LARGO PLAZO ===
    double survivalScore = evaluateLongTermSurvival(
      targetX, targetY, futureGrid, game.currentPlayer, depth: 3
    );

    // === FACTOR 4: LIBERTAD LOCAL ===
    double freedomScore = evaluateLocalFreedom(targetX, targetY, futureGrid);

    // === COMBINACIÓN FINAL CON PESOS CONFIGURABLES ===
    double finalScore = (
      mobilityScore * customWeights['mobility']! +
      rivalReductionScore * customWeights['rival_reduction']! +
      survivalScore * customWeights['survival']! +
      freedomScore * customWeights['freedom']!
    );

    return finalScore;
  }

  /// Simula un movimiento sin afectar el juego real.
  List<List<CellState>> simulateMove(
    int targetX, 
    int targetY, 
    List<List<CellState>> tempGrid, 
    int tempPlayer
  ) {
    // Crear copia del grid para simulación
    List<List<CellState>> newGrid = tempGrid.map((row) => List<CellState>.from(row)).toList();
    int gridSize = game.gridSize;

    // Limpiar posición anterior del jugador
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (newGrid[y][x] == (tempPlayer == 0 ? CellState.blue : CellState.red)) {
          newGrid[y][x] = CellState.blocked;
        }
      }
    }

    // Colocar jugador en nueva posición
    newGrid[targetY][targetX] = tempPlayer == 0 ? CellState.blue : CellState.red;

    return newGrid;
  }

  /// Cuenta cuántos movimientos válidos tendría un jugador desde una posición específica.
  int countMovesFromPosition(
    int x, 
    int y, 
    List<List<CellState>> tempGrid, 
    int player
  ) {
    List<int> allowedMoves = _getAllowedMoves(x, y);
    Set<String> totalMoves = <String>{};

    for (int moveCount in allowedMoves) {
      Set<String> moves = findValidMovesOnGrid(x, y, moveCount, tempGrid);
      totalMoves.addAll(moves);
    }

    return totalMoves.length;
  }

  /// Versión de find_valid_moves que funciona en un grid temporal.
  Set<String> findValidMovesOnGrid(
    int startX, 
    int startY, 
    int maxMoves, 
    List<List<CellState>> tempGrid
  ) {
    Set<String> result = <String>{};
    int gridSize = game.gridSize;

    void dfs(int x, int y, int movesLeft, Set<String> visitedPath) {
      if (tempGrid[y][x] == CellState.blocked) {
        return;
      }

      String posKey = "$x,$y";
      if (visitedPath.contains(posKey)) {
        return;
      }

      visitedPath.add(posKey);

      if (movesLeft == 0) {
        return;
      }

      // Direcciones: arriba, derecha, abajo, izquierda
      List<({int dx, int dy})> directions = [
        (dx: 0, dy: -1), (dx: 1, dy: 0), (dx: 0, dy: 1), (dx: -1, dy: 0)
      ];

      for (var dir in directions) {
        int nextX = x + dir.dx;
        int nextY = y + dir.dy;
        bool wrapped = false;
        int edgeX = x, edgeY = y;

        // Manejo de wrap-around (igual que en el juego original)
        if (nextX < 0) {
          wrapped = true;
          edgeX = 0;
          nextX = gridSize - 1;
        } else if (nextX >= gridSize) {
          wrapped = true;
          edgeX = gridSize - 1;
          nextX = 0;
        }

        if (nextY < 0) {
          wrapped = true;
          edgeY = 0;
          nextY = gridSize - 1;
        } else if (nextY >= gridSize) {
          wrapped = true;
          edgeY = gridSize - 1;
          nextY = 0;
        }

        // No se puede envolver a través de celdas bloqueadas
        if (wrapped && tempGrid[edgeY][edgeX] == CellState.blocked) {
          continue;
        }

        // No se puede mover a celdas bloqueadas
        if (tempGrid[nextY][nextX] == CellState.blocked) {
          continue;
        }

        String nextKey = "$nextX,$nextY";
        if (visitedPath.contains(nextKey)) {
          continue;
        }

        // Si es el último movimiento y la celda está vacía, es válida
        if (movesLeft == 1 && tempGrid[nextY][nextX] == CellState.empty) {
          result.add(nextKey);
        } else {
          Set<String> newPath = Set.from(visitedPath);
          dfs(nextX, nextY, movesLeft - 1, newPath);
        }
      }
    }

    dfs(startX, startY, maxMoves, <String>{});
    return result;
  }

  /// Evalúa la libertad local de una posición.
  double evaluateLocalFreedom(int x, int y, List<List<CellState>> tempGrid) {
    int gridSize = game.gridSize;
    double freedomScore = 0;

    // Evaluar celdas adyacentes (8 direcciones)
    List<({int dx, int dy})> directions = [
      (dx: -1, dy: -1), (dx: -1, dy: 0), (dx: -1, dy: 1), // Fila superior
      (dx: 0, dy: -1), (dx: 0, dy: 1), // Lados
      (dx: 1, dy: -1), (dx: 1, dy: 0), (dx: 1, dy: 1) // Fila inferior
    ];

    int totalNeighbors = 0;
    int freeNeighbors = 0;

    for (var dir in directions) {
      int adjX = x + dir.dx;
      int adjY = y + dir.dy;

      // Manejar wrap-around
      adjX = adjX % gridSize;
      adjY = adjY % gridSize;

      totalNeighbors++;

      // Contar celdas no bloqueadas como "libres"
      if (tempGrid[adjY][adjX] != CellState.blocked) {
        freeNeighbors++;
      }
    }

    // Calcular proporción de libertad
    if (totalNeighbors > 0) {
      double freedomRatio = freeNeighbors / totalNeighbors;
      freedomScore = freedomRatio * 10; // Escalar a 0-10 puntos
    }

    return freedomScore;
  }

  /// Evalúa supervivencia a largo plazo simulando múltiples caminos.
  double evaluateLongTermSurvival(
    int x, 
    int y, 
    List<List<CellState>> tempGrid, 
    int player, 
    {int depth = 3}
  ) {
    if (depth == 0) {
      return 1; // Caso base: si llegamos aquí, hay supervivencia
    }

    // Contar movimientos inmediatos desde esta posición
    int immediateMoves = countMovesFromPosition(x, y, tempGrid, player);

    if (immediateMoves == 0) {
      return 0; // Sin movimientos = muerte inmediata
    }

    // Evaluar múltiples caminos futuros
    double totalSurvivalPaths = 0;
    Set<String> validFutureMoves = findValidMovesOnGrid(x, y, 1, tempGrid);

    if (validFutureMoves.isEmpty) {
      return immediateMoves.toDouble(); // Solo evaluar movimientos inmediatos
    }

    // Limitar evaluaciones para eficiencia (máximo 5 caminos)
    List<String> sampleMoves = validFutureMoves.take(5).toList();

    for (String moveStr in sampleMoves) {
      List<String> coords = moveStr.split(',');
      int futureX = int.parse(coords[0]);
      int futureY = int.parse(coords[1]);

      // Simular este movimiento futuro
      List<List<CellState>> futureGrid = simulateMove(futureX, futureY, tempGrid, player);

      // Evaluar recursivamente desde la nueva posición
      double futureSurvival = evaluateLongTermSurvival(
        futureX, futureY, futureGrid, player, depth: depth - 1
      );

      totalSurvivalPaths += futureSurvival;
    }

    // Promediar los caminos evaluados
    double avgSurvival = 0;
    if (sampleMoves.isNotEmpty) {
      avgSurvival = totalSurvivalPaths / sampleMoves.length;
    }

    // Combinar movimientos inmediatos con supervivencia futura
    double survivalScore = immediateMoves + (avgSurvival * 0.5);

    return survivalScore.clamp(0, 20); // Limitar máximo para evitar valores extremos
  }

  /// Obtiene los movimientos permitidos desde una posición
  List<int> _getAllowedMoves(int x, int y) {
    int val = game.values[y * game.gridSize + x];

    // VALORES ESPECIALES DE INICIO: 99 y 100
    if (val == 99 || val == 100) {
      if (game.gridSize == 4) {
        return [1, 2, 3, 4];
      } else if (game.gridSize == 5) {
        return [1, 2, 3, 4, 5];
      } else if (game.gridSize == 6) {
        return [1, 2, 3, 4, 5, 6];
      }
    } else {
      // Valor normal: solo permite moverse ese número de casillas
      return [val];
    }
    return [];
  }
}

/// Sistema de niveles de dificultad que modifica la heurística
class DifficultyLevels {
  /// Retorna los pesos de la heurística según dificultad
  static Map<String, double> getAIWeights(String difficulty) {
    switch (difficulty) {
      case "easy":
        // IA principiante: Se enfoca mucho en movilidad propia, ignora estrategia
        return {
          'mobility': 0.50,
          'rival_reduction': 0.15,
          'survival': 0.30,
          'freedom': 0.05
        };
      case "hard":
        // IA experta: MUY AGRESIVA - Mucho más enfoque en bloquear rival
        return {
          'mobility': 0.25,          // Reducido para dar espacio a agresividad
          'rival_reduction': 0.50,   // ¡AUMENTADO SIGNIFICATIVAMENTE!
          'survival': 0.20,          // Reducido ligeramente
          'freedom': 0.05
        };
      default: // Medium
        // IA balanceada: Configuración estándar equilibrada
        return {
          'mobility': 0.35,
          'rival_reduction': 0.35,
          'survival': 0.25,
          'freedom': 0.05
        };
    }
  }

  /// Modifica el comportamiento de la IA según dificultad
  static void applyDifficultyModifier(HeuristicAI aiInstance, String difficulty) {
    aiInstance.difficulty = difficulty;
    aiInstance.weights = getAIWeights(difficulty);
  }
}