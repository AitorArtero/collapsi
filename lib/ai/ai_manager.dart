/// Sistema Gestor Inteligente de IAs para Collapsi MEJORADO
/// Maneja automáticamente la selección y cambio entre diferentes tipos de IA
/// según la dificultad configurada.
///
/// ARQUITECTURA:
/// - AISelector: Factory que crea la IA apropiada según dificultad
/// - SmartAI: Wrapper que gestiona automáticamente el cambio de IAs
/// - Integración transparente con el sistema existente
///
/// TIPOS DE IA DISPONIBLES:
/// FÁCIL   → GreedyAI MEJORADA     (algoritmo goloso + 25% errores humanos)
/// MEDIO   → HeuristicAI MEJORADA  (heurística balanceada + 15% errores)  
/// DIFÍCIL → HeuristicAI AVANZADA  (heurística agresiva + lookahead + predicción)
/// EXPERTO → MinimaxAI             (minimax perfecto con poda Alpha-Beta)

import 'strategies/greedy_ai.dart';
import 'strategies/heuristic_ai.dart';
import 'strategies/minimax_ai.dart';
import '../core/collapsi_engine.dart';

/// Interfaz base para todas las estrategias de IA
abstract class AIStrategy {
  /// El motor de juego asociado a esta IA
  CollapsiEngine get game;
  
  /// Elige el mejor movimiento de los movimientos válidos disponibles
  ({int x, int y})? chooseBestMove(Set<String> validMoves);
}

/// Información detallada sobre cada nivel de dificultad ACTUALIZADA
class DifficultyInfo {
  final String name;
  final String aiType;
  final String description;
  final String strategy;
  final String emoji;

  const DifficultyInfo({
    required this.name,
    required this.aiType,
    required this.description,
    required this.strategy,
    required this.emoji,
  });
}

/// Factory que crea la IA apropiada según la dificultad MEJORADO
class AISelector {
  static const Map<String, DifficultyInfo> _difficultyInfos = {
    'easy': DifficultyInfo(
      name: 'Fácil',
      aiType: 'Novato con Errores',
      description: 'IA que comete errores humanos típicos (25% error)',
      strategy: 'Algoritmo greedy + errores aleatorios realistas',
      emoji: '🤖',
    ),
    'medium': DifficultyInfo(
      name: 'Medio',
      aiType: 'Competidor Equilibrado',
      description: 'IA balanceada con errores ocasionales (15% error)',
      strategy: 'Heurística balanceada + errores menores entre top 3',
      emoji: '🧠',
    ),
    'hard': DifficultyInfo(
      name: 'Difícil',
      aiType: 'Estratega Avanzado',
      description: 'IA con lookahead, predicción y trampas (0% error)',
      strategy: 'Heurística agresiva + lookahead 2 turnos + predicción oponente',
      emoji: '🎯',
    ),
    'expert': DifficultyInfo(
      name: 'Experto',
      aiType: 'Minimax Perfecto',
      description: 'IA perfecta con algoritmo Minimax y poda Alpha-Beta',
      strategy: 'Búsqueda exhaustiva 4 turnos - juego matemáticamente óptimo',
      emoji: '🧠',
    ),
  };

  /// Crea la IA apropiada según la dificultad
  /// 
  /// [gameInstance] - Referencia al motor de juego
  /// [difficulty] - "easy", "medium", "hard", "expert"
  /// 
  /// Returns: Instancia de la IA apropiada
  static AIStrategy createAI(CollapsiEngine gameInstance, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        print('🤖 Creando IA GREEDY MEJORADA para modo FÁCIL');
        print('   └── Características: Algoritmo goloso + 25% errores humanos');
        return GreedyAI(gameInstance);
        
      case 'medium':
        print('🧠 Creando IA HEURÍSTICA EQUILIBRADA para modo MEDIO');
        print('   └── Características: Heurística balanceada + 15% errores ocasionales');
        final ai = HeuristicAI(gameInstance);
        DifficultyLevels.applyDifficultyModifier(ai, difficulty);
        return ai;
        
      case 'hard':
        print('🎯 Creando IA HEURÍSTICA AVANZADA para modo DIFÍCIL');
        print('   └── Características: Heurística agresiva + lookahead 2 turnos + predicción');
        final ai = HeuristicAI(gameInstance);
        DifficultyLevels.applyDifficultyModifier(ai, difficulty);
        return ai;
        
      case 'expert':
        print('🧠 Creando IA MINIMAX para modo EXPERTO');
        print('   └── Características: Algoritmo minimax perfecto con poda Alpha-Beta');
        return MinimaxAI(gameInstance, maxDepth: 4);
        
      default:
        print('🧠 Dificultad desconocida "$difficulty", usando MEDIO por defecto');
        final ai = HeuristicAI(gameInstance);
        DifficultyLevels.applyDifficultyModifier(ai, "medium");
        return ai;
    }
  }

  /// Retorna descripción de la IA según dificultad ACTUALIZADA
  static String getAIDescription(String difficulty) {
    final info = _difficultyInfos[difficulty.toLowerCase()];
    if (info == null) return '🤖 IA Desconocida';
    
    return '${info.emoji} IA ${info.aiType} - ${info.description}';
  }

  /// Retorna información completa sobre las dificultades disponibles
  static Map<String, DifficultyInfo> getAvailableDifficulties() {
    return Map.unmodifiable(_difficultyInfos);
  }

  /// Retorna información específica de una dificultad
  static DifficultyInfo? getDifficultyInfo(String difficulty) {
    return _difficultyInfos[difficulty.toLowerCase()];
  }

  /// Retorna lista de todas las dificultades disponibles
  static List<String> getDifficultyKeys() {
    return _difficultyInfos.keys.toList();
  }

  /// Retorna comparación detallada entre dificultades
  static String getDifficultyComparison() {
    return '''
🎮 COMPARACIÓN DE DIFICULTADES:

🤖 FÁCIL (Novato):
   • Errores: 25% (humanos típicos)
   • Lookahead: 1 turno
   • Predicción: No
   • Ideal para: Principiantes

🧠 MEDIO (Competidor):
   • Errores: 15% (ocasionales)
   • Lookahead: 1 turno
   • Predicción: No
   • Ideal para: Jugadores intermedios

🎯 DIFÍCIL (Estratega):
   • Errores: 0% (perfecto en tactics)
   • Lookahead: 2 turnos
   • Predicción: Sí (comportamiento humano)
   • Trampas: Detecta jaque mate
   • Ideal para: Jugadores avanzados

🧠 EXPERTO (Maestro):
   • Errores: 0% (matemáticamente óptimo)
   • Lookahead: 4 turnos (minimax)
   • Predicción: Sí (minimax asume juego perfecto)
   • Ideal para: Máximo desafío
    ''';
  }
}

/// 🧠 IA ADAPTATIVA INTELIGENTE MEJORADA
/// 
/// Esta clase wrapper maneja automáticamente el cambio entre diferentes
/// tipos de IA según la dificultad configurada. Ahora con mejor diferenciación
/// entre niveles y métricas de rendimiento.
class SmartAI {
  final CollapsiEngine game;
  String _currentDifficulty = 'medium';
  AIStrategy? _currentAI;
  int _aiSwitchCount = 0;
  
  // Métricas de rendimiento
  int _totalMoves = 0;
  int _winsAgainstHuman = 0;
  int _lossesAgainstHuman = 0;
  DateTime _lastSwitchTime = DateTime.now();

  SmartAI(this.game) {
    // Inicializar con la IA apropiada
    updateAIType();
    print('🧠 SmartAI MEJORADA inicializada');
    print('📊 ${AISelector.getAIDescription(_currentDifficulty)}');
    print('🎯 Diferenciación significativa entre niveles activada');
  }

  /// Actualiza el tipo de IA según la dificultad actual del juego MEJORADO
  /// 
  /// Returns: true si se cambió la IA, false si no fue necesario
  bool updateAIType() {
    // Obtener dificultad actual del juego
    final newDifficulty = game.aiDifficulty;
    
    // Solo cambiar si es necesario
    if (newDifficulty != _currentDifficulty || _currentAI == null) {
      final oldDifficulty = _currentDifficulty;
      final oldAIType = _currentAI?.runtimeType.toString() ?? 'None';
      
      print('\n🔄 === CAMBIO DE IA ===');
      print('🔄 Anterior: $oldDifficulty ($oldAIType)');
      print('🔄 Nueva: $newDifficulty');
      
      // Actualizar dificultad y crear nueva IA
      _currentDifficulty = newDifficulty;
      _currentAI = AISelector.createAI(game, newDifficulty);
      _aiSwitchCount++;
      _lastSwitchTime = DateTime.now();
      
      // final newAIType = _currentAI?.runtimeType.toString() ?? 'None';
      print('✅ ${AISelector.getAIDescription(newDifficulty)}');
      print('📊 Cambios de IA realizados: $_aiSwitchCount');
      print('🕐 Hora del cambio: ${_lastSwitchTime.toString().substring(11, 19)}');
      
      // Mostrar características específicas del nuevo nivel
      _logDifficultyFeatures(newDifficulty);
      
      return true;
    }
    
    return false;
  }

  /// Registra las características específicas de cada dificultad
  void _logDifficultyFeatures(String difficulty) {
    final info = AISelector.getDifficultyInfo(difficulty);
    if (info != null) {
      print('🎯 Estrategia: ${info.strategy}');
      
      switch (difficulty.toLowerCase()) {
        case 'easy':
          print('🎲 Error Rate: 25% - Simula jugador novato');
          break;
        case 'medium':
          print('🎲 Error Rate: 15% - Errores ocasionales entre top 3');
          break;
        case 'hard':
          print('🔮 Predicción de oponente: ACTIVADA');
          print('👁️ Lookahead: 2 turnos');
          print('⚔️ Detección de trampas: ACTIVADA');
          print('🎯 Factor agresividad: 1.4x');
          break;
        case 'expert':
          print('🧠 Algoritmo: Minimax con poda Alpha-Beta');
          print('📏 Profundidad: 4 turnos');
          print('🎯 Juego: Matemáticamente óptimo');
          break;
      }
    }
  }

  /// Delega la elección del mejor movimiento a la IA actual MEJORADO
  ({int x, int y})? chooseBestMove(Set<String> validMoves) {
    // Verificar si necesitamos cambiar de IA
    final aiChanged = updateAIType();
    
    if (aiChanged) {
      print('🔄 IA actualizada para nueva dificultad: $_currentDifficulty');
    }
    
    // Delegar a la IA actual
    if (_currentAI != null) {
      try {
        final startTime = DateTime.now();
        final move = _currentAI!.chooseBestMove(validMoves);
        final endTime = DateTime.now();
        final thinkTime = endTime.difference(startTime).inMilliseconds;
        
        if (move != null) {
          _totalMoves++;
          print('🎯 ${_currentAI.runtimeType} eligió: $move');
          print('⏱️ Tiempo de cálculo: ${thinkTime}ms');
          
          // Log adicional para modo difícil
          if (_currentDifficulty == 'hard') {
            print('🧠 Análisis avanzado completado (lookahead + predicción)');
          }
        } else {
          print('❌ ${_currentAI.runtimeType} no encontró movimientos válidos');
        }
        return move;
      } catch (e) {
        print('❌ Error en IA ${_currentAI.runtimeType}: $e');
        return null;
      }
    } else {
      print('❌ Error: No hay IA disponible');
      return null;
    }
  }

  /// Resetea el estado de la IA actual si es MinimaxAI
  void resetAIState() {
    if (_currentAI is MinimaxAI) {
      (_currentAI as MinimaxAI).resetState();
    }
  }

  /// Registra resultado de partida para métricas
  void recordGameResult(bool aiWon) {
    if (aiWon) {
      _winsAgainstHuman++;
    } else {
      _lossesAgainstHuman++;
    }
    
    print('📊 Resultado registrado: IA ${aiWon ? 'GANÓ' : 'PERDIÓ'}');
    print('🏆 Record actual: ${_winsAgainstHuman}W - ${_lossesAgainstHuman}L');
  }

  /// Retorna información detallada sobre la IA actual MEJORADA
  Map<String, dynamic> getAIInfo() {
    final aiType = _currentAI?.runtimeType.toString() ?? 'None';
    final difficultyInfo = AISelector.getDifficultyInfo(_currentDifficulty);
    
    return {
      'difficulty': _currentDifficulty,
      'difficultyName': difficultyInfo?.name ?? 'Desconocido',
      'aiType': aiType,
      'aiClass': difficultyInfo?.aiType ?? 'Unknown',
      'description': AISelector.getAIDescription(_currentDifficulty),
      'strategy': difficultyInfo?.strategy ?? 'N/A',
      'switchCount': _aiSwitchCount,
      'totalMoves': _totalMoves,
      'wins': _winsAgainstHuman,
      'losses': _lossesAgainstHuman,
      'winRate': _totalMoves > 0 ? (_winsAgainstHuman / (_winsAgainstHuman + _lossesAgainstHuman) * 100).toStringAsFixed(1) + '%' : '0%',
      'lastSwitchTime': _lastSwitchTime.toString(),
      'isGreedy': _currentAI is GreedyAI,
      'isHeuristic': _currentAI is HeuristicAI,
      'isMinimax': _currentAI is MinimaxAI,
      
      'hasErrorSystem': ['easy', 'medium'].contains(_currentDifficulty),
      'hasLookahead': ['hard', 'expert'].contains(_currentDifficulty),
      'hasPrediction': ['hard', 'expert'].contains(_currentDifficulty),
      'hasTrapDetection': _currentDifficulty == 'hard',
      'errorRate': _currentDifficulty == 'easy' ? '25%' : 
                   _currentDifficulty == 'medium' ? '15%' : '0%',
      'lookAheadDepth': _currentDifficulty == 'hard' ? '2 turnos' :
                        _currentDifficulty == 'expert' ? '4 turnos' : '1 turno',
    };
  }

  /// Fuerza una actualización de la IA (útil para debugging)
  Map<String, dynamic> forceAIUpdate() {
    final oldInfo = getAIInfo();
    _currentAI = null; // Forzar recreación
    final aiChanged = updateAIType();
    final newInfo = getAIInfo();
    
    return {
      'forcedUpdate': true,
      'aiChanged': aiChanged,
      'oldAI': oldInfo['aiType'],
      'newAI': newInfo['aiType'],
      'difficulty': _currentDifficulty,
      'timestamp': DateTime.now().toString(),
    };
  }

  /// Retorna estadísticas de rendimiento de la IA MEJORADAS
  Map<String, dynamic> getPerformanceStats() {
    final totalGames = _winsAgainstHuman + _lossesAgainstHuman;
    
    return {
      'currentDifficulty': _currentDifficulty,
      'aiSwitches': _aiSwitchCount,
      'currentAIType': _currentAI?.runtimeType.toString() ?? 'None',
      'totalMoves': _totalMoves,
      'totalGames': totalGames,
      'wins': _winsAgainstHuman,
      'losses': _lossesAgainstHuman,
      'winRate': totalGames > 0 ? (_winsAgainstHuman / totalGames) : 0.0,
      'averageMovesPerGame': totalGames > 0 ? (_totalMoves / totalGames) : 0.0,
      'gameGridSize': game.gridSize,
      'gameAIMode': game.aiMode,
      'lastSwitchTime': _lastSwitchTime.toString(),
      'sessionDuration': DateTime.now().difference(_lastSwitchTime).inMinutes,
    };
  }

  /// Retorna análisis de efectividad por dificultad
  Map<String, dynamic> getDifficultyEffectivenessAnalysis() {
    final totalGames = _winsAgainstHuman + _lossesAgainstHuman;
    final winRate = totalGames > 0 ? (_winsAgainstHuman / totalGames) : 0.0;
    
    String effectiveness;
    String recommendation;
    
    if (winRate >= 0.8) {
      effectiveness = "Muy Alta - Dominante";
      recommendation = "Considera aumentar dificultad";
    } else if (winRate >= 0.6) {
      effectiveness = "Alta - Desafiante";
      recommendation = "Dificultad bien balanceada";
    } else if (winRate >= 0.4) {
      effectiveness = "Media - Equilibrada";
      recommendation = "Partidas competitivas";
    } else if (winRate >= 0.2) {
      effectiveness = "Baja - Vulnerable";
      recommendation = "IA lucha contra este jugador";
    } else {
      effectiveness = "Muy Baja - Inefectiva";
      recommendation = "Considera reducir dificultad";
    }
    
    return {
      'difficulty': _currentDifficulty,
      'winRate': winRate,
      'effectiveness': effectiveness,
      'recommendation': recommendation,
      'totalGames': totalGames,
      'confidenceLevel': totalGames >= 5 ? 'Alta' : totalGames >= 3 ? 'Media' : 'Baja',
    };
  }

  /// Retorna información completa para debugging MEJORADA
  Map<String, dynamic> debugInfo() {
    return {
      'aiInfo': getAIInfo(),
      'performanceStats': getPerformanceStats(),
      'effectivenessAnalysis': getDifficultyEffectivenessAnalysis(),
      'availableDifficulties': AISelector.getAvailableDifficulties().map(
        (key, value) => MapEntry(key, {
          'name': value.name,
          'aiType': value.aiType,
          'description': value.description,
          'strategy': value.strategy,
          'emoji': value.emoji,
        }),
      ),
      'gameState': {
        'aiDifficulty': game.aiDifficulty,
        'aiMode': game.aiMode,
        'gridSize': game.gridSize,
        'currentPlayer': game.currentPlayer,
        'gameOver': game.gameOver,
        'moveCount': game.moveCount,
      },
      'systemInfo': {
        'version': '2.0 - Improved Differentiation',
        'features': [
          'Error systems for Easy/Medium',
          'Advanced lookahead for Hard',
          'Opponent prediction for Hard',
          'Trap detection for Hard',
          'Performance tracking',
          'Effectiveness analysis'
        ],
      },
    };
  }

  // Getters de conveniencia ACTUALIZADOS
  String get currentDifficulty => _currentDifficulty;
  AIStrategy? get currentAI => _currentAI;
  int get aiSwitchCount => _aiSwitchCount;
  int get totalMoves => _totalMoves;
  double get winRate {
    final totalGames = _winsAgainstHuman + _lossesAgainstHuman;
    return totalGames > 0 ? (_winsAgainstHuman / totalGames) : 0.0;
  }
}