import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../config/game_constants.dart';
import '../ai/ai_manager.dart';

/// Clase principal que maneja la lógica del juego Collapsi
class CollapsiEngine extends ChangeNotifier {
  // Estado del juego
  late List<List<CellState>> _grid;
  late List<int> _values;
  int _currentPlayer = 0; // 0: azul, 1: rojo
  final Set<String> _validMoves = <String>{};
  bool _gameOver = false;
  int? _winner;
  int _moveCount = 0;
  
  // Configuración
  int _gridSize = GameConstants.gridSize;
  bool _aiMode = false;
  String _aiDifficulty = "medium";
  bool _aiThinking = false;
  double _aiThinkTimer = 0;
  
  // Sistema de IA inteligente
  late SmartAI _smartAI;
  
  // Sistema de historial
  List<Map<String, dynamic>> _gameHistory = [];
  
  // Lista de valores iniciales
  late List<int> _initialValues;

  CollapsiEngine() {
    updateGridConfiguration();
    resetGame();
    // Inicializar el sistema de IA inteligente
    _smartAI = SmartAI(this);
  }

  // Getters
  List<List<CellState>> get grid => _grid;
  List<int> get values => _values;
  int get currentPlayer => _currentPlayer;
  Set<String> get validMoves => _validMoves;
  bool get gameOver => _gameOver;
  int? get winner => _winner;
  int get moveCount => _moveCount;
  int get gridSize => _gridSize;
  bool get aiMode => _aiMode;
  String get aiDifficulty => _aiDifficulty;
  bool get aiThinking => _aiThinking;
  int get historySize => _gameHistory.length;
  
  /// Obtiene información detallada sobre la IA actual
  Map<String, dynamic> get aiInfo => _smartAI.getAIInfo();

  /// Actualiza la configuración según el tamaño del grid
  void updateGridConfiguration() {
    // Usar valores especiales para inicio: 99 = azul, 100 = rojo
    
    if (_gridSize == 4) {
      // Grid 4x4 = 16 celdas (configuración original)
      _initialValues = [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 99, 100];
      debugPrint("📐 Configuración 4x4: 4 de cada (1,2,3,4) + 2 inicio (99=azul, 100=rojo)");
    } else if (_gridSize == 5) {
      // Grid 5x5 = 25 celdas
      _initialValues = [
        1, 1, 1, 1, 1,          // 5 huecos de 1
        2, 2, 2, 2, 2,          // 5 huecos de 2  
        3, 3, 3, 3, 3,          // 5 huecos de 3
        4, 4, 4, 4, 4,          // 5 huecos de 4
        5, 5, 5,                // 3 huecos de 5 (NORMALES)
        99, 100                 // 2 casillas de inicio (99=azul, 100=rojo)
      ];
      debugPrint("📐 Configuración 5x5: 5 de cada (1,2,3,4) + 3 de 5 + 2 inicio = 25 celdas");
    } else if (_gridSize == 6) {
      // Grid 6x6 = 36 celdas  
      _initialValues = [
        1, 1, 1, 1, 1, 1,       // 6 huecos de 1
        2, 2, 2, 2, 2, 2,       // 6 huecos de 2
        3, 3, 3, 3, 3, 3,       // 6 huecos de 3  
        4, 4, 4, 4, 4, 4,       // 6 huecos de 4
        5, 5, 5, 5, 5, 5,       // 6 huecos de 5
        6, 6, 6, 6,             // 4 huecos de 6 (NORMALES)
        99, 100                 // 2 casillas de inicio (99=azul, 100=rojo)
      ];
      debugPrint("📐 Configuración 6x6: 6 de cada (1,2,3,4,5) + 4 de 6 + 2 inicio = 36 celdas");
    }
  }

  /// Cambia el tamaño del grid y reinicia el juego
  void setGridSize(int size) {
    debugPrint("🔄 Cambiando grid de ${_gridSize}x$_gridSize a ${size}x$size");
    _gridSize = size;
    updateGridConfiguration();
    resetGame();
    debugPrint("✅ Grid cambiado exitosamente a ${size}x$size");
  }

  /// Establece la dificultad de la IA
  void setAIDifficulty(String difficulty) {
    _aiDifficulty = difficulty;
    notifyListeners();
  }

  /// Reinicia el juego a su estado inicial
  void resetGame() {
    // Verificar que la configuración sea correcta
    int expectedCells = _gridSize * _gridSize;
    int actualCells = _initialValues.length;
    if (actualCells != expectedCells) {
      debugPrint("❌ ERROR: Grid ${_gridSize}x$_gridSize necesita $expectedCells celdas, pero initial_values tiene $actualCells");
    }

    // Inicializar valores del tablero con shuffle aleatorio
    _values = _shuffle(_initialValues.toList());

    // Inicializar estado de las celdas
    _grid = [];
    for (int y = 0; y < _gridSize; y++) {
      List<CellState> row = [];
      for (int x = 0; x < _gridSize; x++) {
        int val = _values[y * _gridSize + x];
        CellState state;
        if (val == 99) {  // Valor especial para inicio azul
          state = CellState.blue;  // Azul siempre empieza
        } else if (val == 100) {  // Valor especial para inicio rojo
          state = CellState.red;   // Rojo es segundo
        } else {
          state = CellState.empty;
        }
        row.add(state);
      }
      _grid.add(row);
    }

    // El jugador azul (0) siempre empieza
    _currentPlayer = 0;
    _validMoves.clear();
    _gameOver = false;
    _winner = null;
    _moveCount = 0;
    _gameHistory.clear(); // Reiniciar historial
    _aiThinking = false;
    _aiThinkTimer = 0;

    // Guardar estado inicial en el historial
    _saveGameState();
    
    _updateValidMoves();
    debugPrint("🎮 Juego reiniciado - Grid ${_gridSize}x$_gridSize");
    notifyListeners();
  }

  /// Baraja un array usando el algoritmo Fisher-Yates
  List<int> _shuffle(List<int> array) {
    final random = math.Random();
    for (int i = array.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      int temp = array[i];
      array[i] = array[j];
      array[j] = temp;
    }
    return array;
  }

  /// Encuentra la posición del jugador especificado
  ({int x, int y})? getPlayerPosition([int? player]) {
    player ??= _currentPlayer;
    CellState playerState = player == 0 ? CellState.blue : CellState.red;
    
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (_grid[y][x] == playerState) {
          return (x: x, y: y);
        }
      }
    }
    return null;
  }

  /// Obtiene los movimientos permitidos desde una posición
  List<int> _getAllowedMoves(int x, int y) {
    int val = _values[y * _gridSize + x];
    
    // VALORES ESPECIALES DE INICIO: 99 y 100
    if (val == 99 || val == 100) {  // Valores especiales de inicio
      if (_gridSize == 4) {
        return [1, 2, 3, 4];
      } else if (_gridSize == 5) {
        return [1, 2, 3, 4, 5];
      } else if (_gridSize == 6) {
        return [1, 2, 3, 4, 5, 6];
      }
    } else {
      // Valor normal: solo permite moverse ese número de casillas
      return [val];
    }
    return [];
  }

  /// Encuentra movimientos válidos usando algoritmo DFS
  Set<String> _findValidMoves(int startX, int startY, int maxMoves) {
    Set<String> result = <String>{};
    
    void dfs(int x, int y, int movesLeft, Set<String> visitedPath) {
      if (_grid[y][x] == CellState.blocked) {
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
        
        // Manejo de wrap-around (los bordes se conectan)
        if (nextX < 0) {
          wrapped = true;
          edgeX = 0;
          nextX = _gridSize - 1;
        } else if (nextX >= _gridSize) {
          wrapped = true;
          edgeX = _gridSize - 1;
          nextX = 0;
        }
        
        if (nextY < 0) {
          wrapped = true;
          edgeY = 0;
          nextY = _gridSize - 1;
        } else if (nextY >= _gridSize) {
          wrapped = true;
          edgeY = _gridSize - 1;
          nextY = 0;
        }
        
        // No se puede envolver a través de celdas bloqueadas
        if (wrapped && _grid[edgeY][edgeX] == CellState.blocked) {
          continue;
        }
        
        // No se puede mover a celdas bloqueadas
        if (_grid[nextY][nextX] == CellState.blocked) {
          continue;
        }
        
        String nextKey = "$nextX,$nextY";
        if (visitedPath.contains(nextKey)) {
          continue;
        }
        
        // Si es el último movimiento y la celda está vacía, es válida
        if (movesLeft == 1 && _grid[nextY][nextX] == CellState.empty) {
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

  /// Actualiza los movimientos válidos para el jugador actual
  void _updateValidMoves() {
    _validMoves.clear();
    
    var pos = getPlayerPosition();
    if (pos == null) {
      _gameOver = true;
      notifyListeners();
      return;
    }
    
    List<int> allowedMoves = _getAllowedMoves(pos.x, pos.y);
    
    for (int moveCount in allowedMoves) {
      Set<String> moves = _findValidMoves(pos.x, pos.y, moveCount);
      _validMoves.addAll(moves);
    }
    
    if (_validMoves.isEmpty) {
      _gameOver = true;
      _winner = 1 - _currentPlayer;
      notifyListeners();
      return;
    }
    
    // Si es modo IA y es el turno de la IA (rojo = jugador 1), iniciar proceso de "pensamiento"
    if (_aiMode && _currentPlayer == 1 && !_gameOver && !_aiThinking) {
      _aiThinking = true;
      _aiThinkTimer = GameConstants.aiThinkDuration;
    }
    
    notifyListeners();
  }

  /// Guarda el estado actual del juego para poder hacer undo
  void _saveGameState() {
    Map<String, dynamic> state = {
      'grid': _grid.map((row) => List<CellState>.from(row)).toList(),
      'current_player': _currentPlayer,
      'move_count': _moveCount,
      'game_over': _gameOver,
      'winner': _winner,
    };
    _gameHistory.add(state);
    
    // Limitar historial para eficiencia
    if (_gameHistory.length > GameConstants.maxHistorySize) {
      _gameHistory.removeAt(0);
    }
  }

  /// Deshace el último movimiento
  bool undoLastMove() {
    if (_gameHistory.isEmpty) {
      return false;  // No hay movimientos que deshacer
    }

    // Guardar una copia del historial por si necesitamos restaurarlo
    List<Map<String, dynamic>> originalHistory = List.from(_gameHistory);

    // En modo IA, si es turno del humano (azul) o el juego terminó, 
    // retroceder 2 movimientos (saltando el de la IA)
    int movesToUndo = 1;
    if (_aiMode && (_currentPlayer == 0 || _gameOver) && _gameHistory.length >= 2) {
      movesToUndo = 2;
    }

    // Evitar eliminar más estados de los disponibles
    movesToUndo = math.min(movesToUndo, _gameHistory.length);

    // Obtener el estado al que queremos volver
    Map<String, dynamic>? targetState;

    if (movesToUndo == 1) {
      targetState = _gameHistory.last;
      _gameHistory.removeLast();  // Eliminar el estado actual
    } else if (movesToUndo == 2) {
      _gameHistory.removeLast();  // Eliminar el estado actual
      targetState = _gameHistory.last;
      _gameHistory.removeLast();  // Eliminar el estado al que volveremos
    }

    // Restaurar el estado
    if (targetState != null) {
      _grid = (targetState['grid'] as List).map((row) => 
          List<CellState>.from(row as List)).toList();
      _currentPlayer = targetState['current_player'];
      _moveCount = targetState['move_count'];
      _gameOver = targetState['game_over'];
      _winner = targetState['winner'];

      // Actualizar movimientos válidos
      _aiThinking = false;
      _aiThinkTimer = 0;
      _updateValidMoves();
      return true;
    } else {
      // Si algo salió mal, restaurar el historial original
      _gameHistory = originalHistory;
      return false;
    }
  }

  /// Realiza un movimiento en el tablero
  bool makeMove(int targetX, int targetY) {
    String moveKey = "$targetX,$targetY";
    if (!_validMoves.contains(moveKey)) {
      return false;
    }
    
    // Guardar estado antes del movimiento para poder hacer undo
    _saveGameState();
    
    // Limpiar la posición anterior del jugador (convertirla en bloqueada)
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (_grid[y][x] == (_currentPlayer == 0 ? CellState.blue : CellState.red)) {
          _grid[y][x] = CellState.blocked;
        }
      }
    }
    
    // Colocar jugador en nueva posición
    _grid[targetY][targetX] = _currentPlayer == 0 ? CellState.blue : CellState.red;
    
    // Cambiar turno
    _currentPlayer = 1 - _currentPlayer;
    _moveCount++;
    
    // Resetear el estado de MinimaxAI cuando cambia de turno
    _smartAI.resetAIState();
    
    _updateValidMoves();
    
    return true;
  }


  // Variables para animaciones de IA
  Function(int x, int y)? _onAIMoveDecided;
  bool _aiMoveInProgress = false;
  
  bool get aiMoveInProgress => _aiMoveInProgress;
    
  /// Establece callback para notificar cuando la IA decide un movimiento
  void setAIMoveCallback(Function(int x, int y)? callback) {
    _onAIMoveDecided = callback;
    debugPrint('🎬 CollapsiEngine: Callback de IA ${callback != null ? "configurado" : "removido"}');
  }
  
  /// Ejecuta un movimiento de IA después de que termine la animación
  bool executeAIMove(int targetX, int targetY) {
    if (!_aiMoveInProgress) {
      debugPrint('⚠️ executeAIMove llamado sin movimiento de IA en progreso');
      return false;
    }
    
    debugPrint('🎬 CollapsiEngine: Ejecutando movimiento real de IA en ($targetX,$targetY)');
    
    // Verificar que el movimiento sigue siendo válido
    String moveKey = "$targetX,$targetY";
    if (!_validMoves.contains(moveKey)) {
      debugPrint('❌ Movimiento de IA ya no es válido: ($targetX,$targetY)');
      _aiMoveInProgress = false;
      return false;
    }
    
    // Limpiar estado de animación antes de ejecutar
    _aiMoveInProgress = false;
    
    // Ejecutar el movimiento real
    bool success = makeMove(targetX, targetY);
    debugPrint('🎬 CollapsiEngine: Movimiento de IA ${success ? "exitoso" : "falló"}');
    
    return success;
  }
  
  /// Cancela un movimiento de IA en progreso
  void cancelAIMove() {
    if (_aiMoveInProgress) {
      debugPrint('🚫 CollapsiEngine: Cancelando movimiento de IA en progreso');
      _aiMoveInProgress = false;
    }
  }
    
  /// Actualiza la lógica de la IA (con soporte para animaciones)
  void updateAI(double dt) {
    // Solo procesar IA en modo IA y cuando sea turno de la IA (jugador 1)
    if (!_aiMode || _currentPlayer != 1 || _gameOver) {
      // Si no es turno de IA, asegurarse de que no esté en estado de "pensamiento"
      if (_aiThinking) {
        _aiThinking = false;
        _aiThinkTimer = 0;
        notifyListeners();
      }
      return;
    }
    
    // No procesar IA si hay un movimiento en progreso
    if (_aiMoveInProgress) {
      debugPrint('🎬 CollapsiEngine: Esperando que termine animación de IA...');
      return;
    }
    
    // Si la IA está "pensando", reducir el temporizador
    if (_aiThinking) {
      _aiThinkTimer -= dt;
      
      // Cuando termina de "pensar", decide su movimiento
      if (_aiThinkTimer <= 0) {
        _aiThinking = false;
        
        // Verificar una vez más que es el turno correcto antes de decidir
        if (_currentPlayer == 1 && !_gameOver && _aiMode) {
          // Usar SmartAI para elegir el mejor movimiento
          final aiMove = _smartAI.chooseBestMove(_validMoves);
          if (aiMove != null) {
            debugPrint('🤖 CollapsiEngine: IA eligió movimiento: (${aiMove.x}, ${aiMove.y})');
            
            // Si hay callback de animación, notificar y esperar
            if (_onAIMoveDecided != null) {
              debugPrint('🎬 CollapsiEngine: Iniciando animación de IA...');
              _aiMoveInProgress = true;
              _onAIMoveDecided!(aiMove.x, aiMove.y);
              // El movimiento real se ejecutará cuando termine la animación
              // a través de executeAIMove()
            } else {
              // Sin animación, ejecutar directamente
              debugPrint('🎬 CollapsiEngine: Sin callback, ejecutando movimiento directo');
              makeMove(aiMove.x, aiMove.y);
            }
            return;
          } else {
            debugPrint('⚠️ IA no pudo encontrar movimiento válido');
            // Si no hay movimientos válidos, el juego debería terminar
            if (_validMoves.isEmpty) {
              _gameOver = true;
              _winner = 0; // El jugador humano gana por defecto
            }
          }
        }
        notifyListeners();
      }
      // No notificar durante el pensamiento para evitar parpadeo constante
    } else if (_currentPlayer == 1 && !_gameOver) {
      // Iniciar "pensamiento" de la IA cuando sea su turno
      debugPrint('🤖 CollapsiEngine: IA comenzando a pensar...');
      _aiThinking = true;
      _aiThinkTimer = 1.0; // 1 segundo de pensamiento
      notifyListeners();
    }
  }
  
  //  método de debug opcional:
  void debugAnimationState() {
    debugPrint('🔍 CollapsiEngine Animation State:');
    debugPrint('   aiMoveInProgress: $_aiMoveInProgress');
    debugPrint('   onAIMoveDecided callback: ${_onAIMoveDecided != null}');
    debugPrint('   aiThinking: $_aiThinking');
    debugPrint('   currentPlayer: $_currentPlayer');
    debugPrint('   gameOver: $_gameOver');
    debugPrint('   aiMode: $_aiMode');
  }

  

  /// Cambia entre modo Humano vs Humano y Humano vs IA
  void toggleAIMode() {
    _aiMode = !_aiMode;
    resetGame();  // Reiniciar para aplicar el nuevo modo
  }

  /// Verifica si una celda pertenece al jugador actual
  bool isCurrentPlayerCell(int x, int y) {
    CellState cellState = _grid[y][x];
    return (_currentPlayer == 0 && cellState == CellState.blue) ||
           (_currentPlayer == 1 && cellState == CellState.red);
  }

  /// Verifica si una celda es un movimiento válido
  bool isValidMoveCell(int x, int y) {
    return _validMoves.contains("$x,$y");
  }

  /// Verifica si se puede hacer undo en el estado actual
  bool canUndo() {
    if (_gameHistory.isEmpty) {
      return false;
    }
    
    // En modo IA, permitir undo en turno humano o cuando el juego ha terminado
    if (_aiMode && _currentPlayer != 0 && !_gameOver) {
      return false;
    }
    
    return true;
  }

  /// Obtiene el valor a mostrar en una celda
  String getCellDisplayValue(int x, int y) {
    int value = _values[y * _gridSize + x];
    
    if (_grid[y][x] == CellState.blocked) {
      return "";  // No mostrar valor en celdas bloqueadas
    } else if (value == 99 || value == 100) {  // VALORES ESPECIALES DE INICIO
      // Casillas de inicio - mostrar rango según tamaño del grid
      if (_gridSize == 4) {
        return "1-4";
      } else if (_gridSize == 5) {
        return "1-5";
      } else if (_gridSize == 6) {
        return "1-6";
      }
    } else {
      return value.toString();
    }
    return "";
  }


  

  /// Obtiene el estado actual del juego para la UI
  Map<String, dynamic> getGameState() {
    return {
      'grid': _grid,
      'values': _values,
      'current_player': _currentPlayer,
      'valid_moves': _validMoves,
      'game_over': _gameOver,
      'winner': _winner,
      'move_count': _moveCount,
      'ai_mode': _aiMode,
      'ai_difficulty': _aiDifficulty,
      'ai_thinking': _aiThinking,
      'history_size': _gameHistory.length,
      'grid_size': _gridSize,
    };
  }

  /// MÉTODOS DE SIMULACIÓN PARA MINIMAX ///

  /// Crea una instantánea del estado actual del juego
  GameStateSnapshot createSnapshot() {
    return GameStateSnapshot(
      grid: _grid.map((row) => List<CellState>.from(row)).toList(),
      currentPlayer: _currentPlayer,
      validMoves: Set<String>.from(_validMoves),
      gameOver: _gameOver,
      winner: _winner,
      moveCount: _moveCount,
    );
  }

  /// Restaura el juego a un estado previo desde una instantánea
  void restoreFromSnapshot(GameStateSnapshot snapshot) {
    _grid = snapshot.grid.map((row) => List<CellState>.from(row)).toList();
    _currentPlayer = snapshot.currentPlayer;
    _validMoves.clear();
    _validMoves.addAll(snapshot.validMoves);
    _gameOver = snapshot.gameOver;
    _winner = snapshot.winner;
    _moveCount = snapshot.moveCount;
  }

  /// Simula un movimiento SIN afectar el estado real del juego
  /// Retorna true si el movimiento fue exitoso
  bool simulateMove(int targetX, int targetY) {
    String moveKey = "$targetX,$targetY";
    if (!_validMoves.contains(moveKey)) {
      return false;
    }

    // Limpiar la posición anterior del jugador
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (_grid[y][x] == (_currentPlayer == 0 ? CellState.blue : CellState.red)) {
          _grid[y][x] = CellState.blocked;
        }
      }
    }

    // Colocar jugador en nueva posición
    _grid[targetY][targetX] = _currentPlayer == 0 ? CellState.blue : CellState.red;

    // Cambiar turno
    _currentPlayer = 1 - _currentPlayer;
    _moveCount++;

    // Actualizar movimientos válidos
    _updateValidMoves();

    return true;
  }

  /// Obtiene movimientos válidos para un jugador específico
  /// sin cambiar el estado del juego
  Set<String> getValidMovesForPlayer(int player) {
    var pos = getPlayerPosition(player);
    if (pos == null) {
      return <String>{};
    }

    Set<String> playerMoves = <String>{};
    List<int> allowedMoves = _getAllowedMoves(pos.x, pos.y);

    for (int moveCount in allowedMoves) {
      Set<String> moves = _findValidMoves(pos.x, pos.y, moveCount);
      playerMoves.addAll(moves);
    }

    return playerMoves;
  }

  /// Hace público el método _getAllowedMoves para la IA
  List<int> getAllowedMovesPublic(int x, int y) {
    return _getAllowedMoves(x, y);
  }

  /// Hace público el método _findValidMoves para la IA  
  Set<String> findValidMovesPublic(int startX, int startY, int maxMoves) {
    return _findValidMoves(startX, startY, maxMoves);
  }

  /// Evalúa si el juego ha terminado después de actualizar movimientos válidos
  bool isGameTerminated() {
    return _gameOver || _validMoves.isEmpty;
  }

  /// Hace público el método _updateValidMoves para simulaciones
  void updateValidMovesPublic() {
    _updateValidMoves();
  }

  /// Obtiene información de debug del estado actual
  Map<String, dynamic> getSimulationDebugInfo() {
    return {
      'current_player': _currentPlayer,
      'valid_moves_count': _validMoves.length,
      'game_over': _gameOver,
      'winner': _winner,
      'move_count': _moveCount,
      'ai_position': getPlayerPosition(1),
      'human_position': getPlayerPosition(0),
    };
  }

  /// Crea una copia exacta del estado actual del juego para análisis
  CollapsiEngine createAnalysisCopy() {
    final copy = CollapsiEngine();
    
    // Configurar el juego con los mismos parámetros
    copy._gridSize = this._gridSize;
    copy._aiMode = this._aiMode;
    copy._aiDifficulty = this._aiDifficulty;
    copy._initialValues = List.from(this._initialValues);
    copy.updateGridConfiguration();
    
    // Copiar el estado exacto del grid
    copy._grid = this._grid.map((row) => List<CellState>.from(row)).toList();
    copy._values = List.from(this._values);
    
    // Copiar el estado del juego
    copy._currentPlayer = this._currentPlayer;
    copy._moveCount = this._moveCount;
    copy._gameOver = this._gameOver;
    copy._winner = this._winner;
    
    // Limpiar estado de IA para análisis
    copy._aiThinking = false;
    copy._aiThinkTimer = 0;
    
    // Copiar movimientos válidos
    copy._validMoves.clear();
    copy._validMoves.addAll(this._validMoves);
    
    // Copiar historial para permitir navegación
    copy._gameHistory = this._gameHistory.map((state) => Map<String, dynamic>.from(state)).toList();
    
    debugPrint('🔍 Copia de análisis creada exitosamente');
    debugPrint('   Grid: ${copy._gridSize}x${copy._gridSize}');
    debugPrint('   Movimientos: ${copy._moveCount}');
    debugPrint('   Estado: ${copy._gameOver ? "Terminado" : "En curso"}');
    debugPrint('   Ganador: ${copy._winner}');
    
    return copy;
  }

  
}
/// Clase para guardar una instantánea completa del estado del juego
class GameStateSnapshot {
  final List<List<CellState>> grid;
  final int currentPlayer;
  final Set<String> validMoves;
  final bool gameOver;
  final int? winner;
  final int moveCount;

  GameStateSnapshot({
    required this.grid,
    required this.currentPlayer,
    required this.validMoves,
    required this.gameOver,
    required this.winner,
    required this.moveCount,
  });

  /// Crea una copia profunda del estado
  GameStateSnapshot.deepCopy(GameStateSnapshot other)
      : grid = other.grid.map((row) => List<CellState>.from(row)).toList(),
        currentPlayer = other.currentPlayer,
        validMoves = Set<String>.from(other.validMoves),
        gameOver = other.gameOver,
        winner = other.winner,
        moveCount = other.moveCount;
}