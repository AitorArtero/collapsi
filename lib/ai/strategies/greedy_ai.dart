import 'dart:math' as math;
import '../../../config/game_constants.dart';
import '../../../core/collapsi_engine.dart';
import '../ai_manager.dart';

/// Clase para almacenar movimientos con puntuación
class MoveScore {
  final ({int x, int y}) move;
  double score;
  
  MoveScore(this.move, this.score);
}

/// IA FÁCIL - "El Novato"
/// Añade sistema de errores humanos típicos para ser más realista
/// y menos frustrante para principiantes reales.
class GreedyAI implements AIStrategy {
  @override
  final CollapsiEngine game;
  final String name = "Greedy AI";
  
  // Configuración de personalidad
  final double errorRate = 0.25;        // 25% probabilidad de error
  final double randomnessBonus = 0.15;  // 15% de aleatoriedad en evaluación
  final math.Random _random = math.Random();

  GreedyAI(this.game) {
    print("🤖 $name inicializada - Personalidad: Novato con errores humanos (${(errorRate*100).toInt()}%)");
  }

  /// Sistema de decisión con errores "humanos"
  @override
  ({int x, int y})? chooseBestMove(Set<String> validMoves) {
    if (validMoves.isEmpty || game.gameOver) {
      return null;
    }

    print("\n🤖 IA Novato evaluando ${validMoves.length} movimientos...");

    // 1. Evaluar todos los movimientos
    List<MoveScore> moveScores = [];
    
    for (String moveKey in validMoves) {
      List<String> coords = moveKey.split(',');
      int x = int.parse(coords[0]);
      int y = int.parse(coords[1]);
      
      // Evaluar usando algoritmo greedy básico
      double baseScore = _evaluateGreedyMove(x, y).toDouble();
      
      // Añadir ruido aleatorio para simular incertidumbre humana
      double randomNoise = (_random.nextDouble() - 0.5) * randomnessBonus * baseScore;
      double finalScore = baseScore + randomNoise;
      
      moveScores.add(MoveScore((x: x, y: y), finalScore));
      print("   📍 ($x,$y): Score base=$baseScore, final=${finalScore.toStringAsFixed(1)}");
    }

    // 2. Ordenar movimientos por puntuación (mejor primero)
    moveScores.sort((a, b) => b.score.compareTo(a.score));

    // 3. SISTEMA DE ERRORES HUMANOS
    if (_random.nextDouble() < errorRate) {
      return _makeHumanLikeError(moveScores);
    } else {
      // Jugar óptimo (75% del tiempo)
      var bestMove = moveScores.first.move;
      print("🎯 IA Novato elige ÓPTIMO: $bestMove");
      return bestMove;
    }
  }

  /// Simula errores típicos de jugadores humanos
  ({int x, int y}) _makeHumanLikeError(List<MoveScore> rankedMoves) {
    // Los humanos novatos tienden a:
    // - No siempre elegir el peor movimiento
    // - A veces elegir el 2do o 3er mejor
    // - Raramente el último
    
    int numMoves = rankedMoves.length;
    ({int x, int y}) chosenMove;
    String errorType;

    if (numMoves == 1) {
      // Solo hay un movimiento
      chosenMove = rankedMoves[0].move;
      errorType = "único";
    } else if (numMoves == 2) {
      // 50% probabilidad de elegir el peor entre 2
      int index = _random.nextBool() ? 1 : 0;
      chosenMove = rankedMoves[index].move;
      errorType = index == 1 ? "peor de 2" : "mejor de 2";
    } else {
      // 3+ movimientos: distribución realista de errores humanos
      double roll = _random.nextDouble();
      int index;
      
      if (roll < 0.4) {
        // 40% elegir 2do mejor (error común)
        index = 1;
        errorType = "2do mejor";
      } else if (roll < 0.7) {
        // 30% elegir 3er mejor (error moderado)
        index = math.min(2, numMoves - 1);
        errorType = "3er mejor";
      } else {
        // 30% elegir uno aleatorio del resto (error grave)
        index = _random.nextInt(numMoves);
        errorType = "aleatorio";
      }
      
      chosenMove = rankedMoves[index].move;
    }

    print("🎲 IA Novato comete ERROR ($errorType): $chosenMove");
    return chosenMove;
  }

  /// Evaluación greedy básica (sin cambios del original)
  int _evaluateGreedyMove(int targetX, int targetY) {
    // Crear copia temporal del grid
    List<List<CellState>> tempGrid = game.grid.map((row) => List<CellState>.from(row)).toList();

    // Simular el movimiento
    List<List<CellState>> futureGrid = _simulateMove(targetX, targetY, tempGrid, game.currentPlayer);

    // Calcular movimientos disponibles desde la nueva posición
    List<int> allowedMoves = _getAllowedMoves(targetX, targetY);
    Set<String> totalFutureMoves = <String>{};

    for (int moveCount in allowedMoves) {
      Set<String> futureMoves = _findValidMovesOnGrid(targetX, targetY, moveCount, futureGrid);
      totalFutureMoves.addAll(futureMoves);
    }

    return totalFutureMoves.length;
  }

  /// Simula un movimiento sin afectar el juego real
  List<List<CellState>> _simulateMove(int targetX, int targetY, List<List<CellState>> tempGrid, int tempPlayer) {
    List<List<CellState>> newGrid = tempGrid.map((row) => List<CellState>.from(row)).toList();
    int gridSize = game.gridSize;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (newGrid[y][x] == (tempPlayer == 0 ? CellState.blue : CellState.red)) {
          newGrid[y][x] = CellState.blocked;
        }
      }
    }

    newGrid[targetY][targetX] = tempPlayer == 0 ? CellState.blue : CellState.red;
    return newGrid;
  }

  /// Encuentra movimientos válidos en un grid temporal
  Set<String> _findValidMovesOnGrid(int startX, int startY, int maxMoves, List<List<CellState>> tempGrid) {
    Set<String> result = <String>{};
    int gridSize = game.gridSize;

    void dfs(int x, int y, int movesLeft, Set<String> visitedPath) {
      if (tempGrid[y][x] == CellState.blocked) return;
      
      String posKey = "$x,$y";
      if (visitedPath.contains(posKey)) return;
      
      visitedPath.add(posKey);
      if (movesLeft == 0) return;

      List<({int dx, int dy})> directions = [
        (dx: 0, dy: -1), (dx: 1, dy: 0), (dx: 0, dy: 1), (dx: -1, dy: 0)
      ];

      for (var dir in directions) {
        int nextX = x + dir.dx;
        int nextY = y + dir.dy;
        bool wrapped = false;
        int edgeX = x, edgeY = y;

        if (nextX < 0) {
          wrapped = true; edgeX = 0; nextX = gridSize - 1;
        } else if (nextX >= gridSize) {
          wrapped = true; edgeX = gridSize - 1; nextX = 0;
        }

        if (nextY < 0) {
          wrapped = true; edgeY = 0; nextY = gridSize - 1;
        } else if (nextY >= gridSize) {
          wrapped = true; edgeY = gridSize - 1; nextY = 0;
        }

        if (wrapped && tempGrid[edgeY][edgeX] == CellState.blocked) continue;
        if (tempGrid[nextY][nextX] == CellState.blocked) continue;

        String nextKey = "$nextX,$nextY";
        if (visitedPath.contains(nextKey)) continue;

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

  /// Obtiene los movimientos permitidos desde una posición
  List<int> _getAllowedMoves(int x, int y) {
    int val = game.values[y * game.gridSize + x];

    if (val == 99 || val == 100) {
      if (game.gridSize == 4) return [1, 2, 3, 4];
      else if (game.gridSize == 5) return [1, 2, 3, 4, 5];
      else if (game.gridSize == 6) return [1, 2, 3, 4, 5, 6];
    } else {
      return [val];
    }
    return [];
  }
}