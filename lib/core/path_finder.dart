import '../config/game_constants.dart';
import 'collapsi_engine.dart';

/// Representa un punto en el tablero
class GridPoint {
  final int x;
  final int y;
  
  const GridPoint(this.x, this.y);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPoint && runtimeType == other.runtimeType &&
      x == other.x && y == other.y;
  
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
  
  @override
  String toString() => '($x,$y)';
}

/// PathFinder que usa el mismo algoritmo que CollapsiEngine para evitar desincronización
class GamePathFinder {
  final CollapsiEngine game;
  
  GamePathFinder(this.game);
  
  /// Encuentra el path real usando el mismo algoritmo que CollapsiEngine
  List<GridPoint>? findMovementPath(int targetX, int targetY, {int? forPlayer}) {
    final player = forPlayer ?? game.currentPlayer;
    final playerPos = game.getPlayerPosition(player);
    
    if (playerPos == null) {
      print('❌ PathFinder: No se encontró posición del jugador $player');
      return null;
    }
    
    final startX = playerPos.x;
    final startY = playerPos.y;
    
    print('🔍 PathFinder: Buscando path de ($startX,$startY) → ($targetX,$targetY)');
    
    // Verificar que Engine confirma la validez del destino antes de buscar path
    if (!game.validMoves.contains('$targetX,$targetY')) {
      print('❌ PathFinder: Engine no dice que ($targetX,$targetY) sea válido');
      print('   Movimientos válidos: ${game.validMoves.toList()}');
      return null;
    }
    
    // Obtener movimientos permitidos desde la posición actual
    final allowedMoves = game.getAllowedMovesPublic(startX, startY);
    print('📝 Movimientos permitidos: $allowedMoves');
    
    // Intentar encontrar path usando exactamente el mismo algoritmo que Engine
    for (final moveCount in allowedMoves) {
      final path = _findPathUsingEngineAlgorithm(startX, startY, targetX, targetY, moveCount);
      if (path != null && path.isNotEmpty) {
        print('✅ Path encontrado con $moveCount movimientos: ${path.map((p) => p.toString()).join(' → ')}');
        
        // Verificar que el path es realmente válido antes de retornarlo
        if (_validatePathStrict(path, targetX, targetY)) {
          return path;
        } else {
          print('⚠️ Path encontrado pero falló validación estricta');
        }
      }
    }
    
    // Si el algoritmo sincronizado falla, usar método directo como fallback
    print('⚠️ PathFinder: Algoritmo sincronizado falló, usando fallback directo');
    return _createFallbackPath(startX, startY, targetX, targetY);
  }
  
  /// Usa exactamente el mismo algoritmo DFS que CollapsiEngine._findValidMoves
  List<GridPoint>? _findPathUsingEngineAlgorithm(int startX, int startY, int targetX, int targetY, int maxMoves) {
    List<GridPoint>? foundPath;
    
    // Wrapper para el DFS que también construye el path
    void dfs(int x, int y, int movesLeft, Set<String> visitedPath, List<GridPoint> currentPath) {
      if (foundPath != null) return; // Ya encontramos un path
      
      if (game.grid[y][x] == CellState.blocked) {
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
      
      // Direcciones: arriba, derecha, abajo, izquierda - mismas que Engine
      List<({int dx, int dy})> directions = [
        (dx: 0, dy: -1), (dx: 1, dy: 0), (dx: 0, dy: 1), (dx: -1, dy: 0)
      ];
      
      for (var dir in directions) {
        if (foundPath != null) return; // Early exit
        
        int nextX = x + dir.dx;
        int nextY = y + dir.dy;
        bool wrapped = false;
        int edgeX = x, edgeY = y;
        
        // Manejo de wrap-around exactamente igual que Engine
        if (nextX < 0) {
          wrapped = true;
          edgeX = 0;
          nextX = game.gridSize - 1;
        } else if (nextX >= game.gridSize) {
          wrapped = true;
          edgeX = game.gridSize - 1;
          nextX = 0;
        }
        
        if (nextY < 0) {
          wrapped = true;
          edgeY = 0;
          nextY = game.gridSize - 1;
        } else if (nextY >= game.gridSize) {
          wrapped = true;
          edgeY = game.gridSize - 1;
          nextY = 0;
        }
        
        // No se puede envolver a través de celdas bloqueadas
        if (wrapped && game.grid[edgeY][edgeX] == CellState.blocked) {
          continue;
        }
        
        // No se puede mover a celdas bloqueadas
        if (game.grid[nextY][nextX] == CellState.blocked) {
          continue;
        }
        
        String nextKey = "$nextX,$nextY";
        if (visitedPath.contains(nextKey)) {
          continue;
        }
        
        // Construir path con puntos de túnel para wrap-around
        List<GridPoint> newPath = List.from(currentPath);
        
        if (wrapped) {
          // Agregar puntos del túnel para animación de wrap-around
          int exitX = x, exitY = y;
          int entryX = nextX, entryY = nextY;
          
          if (x + dir.dx < 0) exitX = -1;
          else if (x + dir.dx >= game.gridSize) exitX = game.gridSize;
          
          if (y + dir.dy < 0) exitY = -1;
          else if (y + dir.dy >= game.gridSize) exitY = game.gridSize;
          
          int entryExitX = entryX, entryExitY = entryY;
          if (exitX == -1) entryExitX = game.gridSize;
          else if (exitX == game.gridSize) entryExitX = -1;
          if (exitY == -1) entryExitY = game.gridSize;
          else if (exitY == game.gridSize) entryExitY = -1;
          
          newPath.add(GridPoint(exitX, exitY));
          newPath.add(GridPoint(entryExitX, entryExitY));
        }
        
        newPath.add(GridPoint(nextX, nextY));
        
        // Si es el último movimiento y la celda está vacía, verificar si es nuestro target
        if (movesLeft == 1 && game.grid[nextY][nextX] == CellState.empty) {
          if (nextX == targetX && nextY == targetY) {
            foundPath = newPath;
            return;
          }
        } else {
          // Continuar DFS con nueva copia del visitedPath, igual que Engine
          Set<String> newVisitedPath = Set.from(visitedPath);
          dfs(nextX, nextY, movesLeft - 1, newVisitedPath, newPath);
        }
      }
    }
    
    // Iniciar DFS
    dfs(startX, startY, maxMoves, <String>{}, [GridPoint(startX, startY)]);
    return foundPath;
  }
  
  /// Validación estricta del path
  bool _validatePathStrict(List<GridPoint> path, int targetX, int targetY) {
    if (path.isEmpty) return false;
    
    // El último punto debe ser el destino
    final lastPoint = path.last;
    if (lastPoint.x != targetX || lastPoint.y != targetY) {
      print('❌ Validación: Último punto ${lastPoint} no es destino ($targetX,$targetY)');
      return false;
    }
    
    // Validar cada paso del path
    for (int i = 1; i < path.length; i++) {
      final prev = path[i - 1];
      final curr = path[i];
      
      // Saltar validación de puntos fuera del tablero para túneles
      bool prevOutside = prev.x < 0 || prev.x >= game.gridSize || prev.y < 0 || prev.y >= game.gridSize;
      bool currOutside = curr.x < 0 || curr.x >= game.gridSize || curr.y < 0 || curr.y >= game.gridSize;
      
      if (prevOutside || currOutside) {
        continue; // Permitir transiciones de túnel
      }
      
      if (!_isValidSingleMove(prev.x, prev.y, curr.x, curr.y)) {
        print('❌ Validación: Movimiento inválido ${prev} → ${curr}');
        return false;
      }
    }
    
    return true;
  }
  
  /// Verifica si un solo movimiento es válido
  bool _isValidSingleMove(int fromX, int fromY, int toX, int toY) {
    int dx = toX - fromX;
    int dy = toY - fromY;
    
    // Movimiento directo ortogonal
    bool isDirect = (dx == 0 && dy.abs() == 1) || (dy == 0 && dx.abs() == 1);
    
    // Wrap-around horizontal o vertical
    bool isWrapX = dy == 0 && dx.abs() == game.gridSize - 1;
    bool isWrapY = dx == 0 && dy.abs() == game.gridSize - 1;
    
    return isDirect || isWrapX || isWrapY;
  }
  
  /// Path directo como fallback cuando todo falla
  List<GridPoint> _createFallbackPath(int startX, int startY, int targetX, int targetY) {
    print('🚨 Usando fallback directo para ($startX,$startY) → ($targetX,$targetY)');
    
    final path = <GridPoint>[GridPoint(startX, startY)];
    int currentX = startX;
    int currentY = startY;
    
    // Movimiento horizontal primero
    while (currentX != targetX) {
      int nextX;
      if (targetX > currentX) {
        nextX = (currentX + 1) % game.gridSize;
        // Si hay wrap-around, agregar puntos de túnel
        if (nextX == 0 && currentX == game.gridSize - 1) {
          path.add(GridPoint(game.gridSize, currentY)); // Salida derecha
          path.add(GridPoint(-1, currentY)); // Entrada izquierda
        }
      } else {
        nextX = (currentX - 1 + game.gridSize) % game.gridSize;
        // Si hay wrap-around, agregar puntos de túnel
        if (nextX == game.gridSize - 1 && currentX == 0) {
          path.add(GridPoint(-1, currentY)); // Salida izquierda
          path.add(GridPoint(game.gridSize, currentY)); // Entrada derecha
        }
      }
      currentX = nextX;
      path.add(GridPoint(currentX, currentY));
    }
    
    // Movimiento vertical después
    while (currentY != targetY) {
      int nextY;
      if (targetY > currentY) {
        nextY = (currentY + 1) % game.gridSize;
        // Si hay wrap-around, agregar puntos de túnel
        if (nextY == 0 && currentY == game.gridSize - 1) {
          path.add(GridPoint(currentX, game.gridSize)); // Salida abajo
          path.add(GridPoint(currentX, -1)); // Entrada arriba
        }
      } else {
        nextY = (currentY - 1 + game.gridSize) % game.gridSize;
        // Si hay wrap-around, agregar puntos de túnel
        if (nextY == game.gridSize - 1 && currentY == 0) {
          path.add(GridPoint(currentX, -1)); // Salida arriba
          path.add(GridPoint(currentX, game.gridSize)); // Entrada abajo
        }
      }
      currentY = nextY;
      path.add(GridPoint(currentX, currentY));
    }
    
    return path;
  }
  
  /// Método de debug para comparar Engine vs PathFinder
  static void debugCompareAlgorithms(CollapsiEngine game, int targetX, int targetY) {
    final player = game.currentPlayer;
    final playerPos = game.getPlayerPosition(player);
    if (playerPos == null) return;
    
    final startX = playerPos.x;
    final startY = playerPos.y;
    
    print('🔍 COMPARACIÓN ENGINE vs PATHFINDER:');
    print('   Origen: ($startX,$startY) → Destino: ($targetX,$targetY)');
    
    // Verificar si Engine dice que es válido
    final isValidInEngine = game.validMoves.contains('$targetX,$targetY');
    print('   ✓ Engine dice válido: $isValidInEngine');
    
    if (!isValidInEngine) {
      print('   ℹ️ Engine no dice que sea válido, no hay problema de sincronización');
      return;
    }
    
    // Verificar si PathFinder puede encontrar path
    final pathFinder = GamePathFinder(game);
    final path = pathFinder.findMovementPath(targetX, targetY);
    final pathFinderFound = path != null && path.isNotEmpty;
    print('   ✓ PathFinder encuentra: $pathFinderFound');
    
    if (isValidInEngine && !pathFinderFound) {
      print('   🚨 DESINCRONIZACIÓN DETECTADA!');
      print('   Engine dice SÍ, PathFinder dice NO');
      
      // Debug detallado
      final allowedMoves = game.getAllowedMovesPublic(startX, startY);
      print('   Movimientos permitidos: $allowedMoves');
      
      for (final moveCount in allowedMoves) {
        final validMovesForCount = game.findValidMovesPublic(startX, startY, moveCount);
        final foundWithCount = validMovesForCount.contains('$targetX,$targetY');
        print('   Con $moveCount movimientos - Engine encuentra: $foundWithCount');
      }
    } else if (!isValidInEngine && pathFinderFound) {
      print('   🚨 DESINCRONIZACIÓN INVERSA!');
      print('   Engine dice NO, PathFinder dice SÍ');
    } else {
      print('   ✅ Ambos algoritmos coinciden');
      if (path != null) {
        print('   Path: ${path.map((p) => p.toString()).join(' → ')}');
      }
    }
  }
  
  // Métodos heredados adaptados
  bool validatePath(List<GridPoint> path, int targetX, int targetY) {
    return _validatePathStrict(path, targetX, targetY);
  }
  
  List<GridPoint> optimizePath(List<GridPoint> path) {
    return path; // Sin optimización por ahora
  }
  
  Duration calculateAnimationDuration(List<GridPoint> path) {
    const baseDurationPerMove = Duration(milliseconds: 300);
    final actualMoves = path.length - 1;
    return baseDurationPerMove * actualMoves;
  }
}