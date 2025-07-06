import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Información de un nivel del torneo con sistema de estrellas
class TournamentLevel {
  final int id;
  final String name;
  final String description;
  final int gridSize;
  final String aiDifficulty;
  final int block; // 1, 2, o 3
  final bool isBlockBoss; // True para niveles 5, 10, 15
  
  // Estado del progreso
  final bool isUnlocked;
  final int starsEarned; // 0-3 estrellas
  final int bestMoves; // Mejor número de movimientos (para criterio de estrellas)
  final bool isCompleted; // True si tiene al menos 1 estrella
  final bool hasStreakStar; // Estrella especial de streak

  const TournamentLevel({
    required this.id,
    required this.name,
    required this.description,
    required this.gridSize,
    required this.aiDifficulty,
    required this.block,
    this.isBlockBoss = false,
    this.isUnlocked = false,
    this.starsEarned = 0,
    this.bestMoves = 0,
    this.hasStreakStar = false,
  }) : isCompleted = starsEarned > 0;

  TournamentLevel copyWith({
    bool? isUnlocked,
    int? starsEarned,
    int? bestMoves,
    bool? hasStreakStar,
  }) {
    return TournamentLevel(
      id: id,
      name: name,
      description: description,
      gridSize: gridSize,
      aiDifficulty: aiDifficulty,
      block: block,
      isBlockBoss: isBlockBoss,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      starsEarned: starsEarned ?? this.starsEarned,
      bestMoves: bestMoves ?? this.bestMoves,
      hasStreakStar: hasStreakStar ?? this.hasStreakStar,
    );
  }

  /// Convierte a Map para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'starsEarned': starsEarned,
      'bestMoves': bestMoves,
      'hasStreakStar': hasStreakStar,
    };
  }

  /// Crea desde Map de SharedPreferences
  static TournamentLevel fromProgressJson(TournamentLevel template, Map<String, dynamic> json) {
    return template.copyWith(
      isUnlocked: json['isUnlocked'] ?? false,
      starsEarned: json['starsEarned'] ?? 0,
      bestMoves: json['bestMoves'] ?? 0,
      hasStreakStar: json['hasStreakStar'] ?? false,
    );
  }
}

/// Información de un bloque del torneo
class TournamentBlock {
  final int blockNumber;
  final String name;
  final String description;
  final List<int> levelIds;

  const TournamentBlock({
    required this.blockNumber,
    required this.name,
    required this.description,
    required this.levelIds,
  });
}

/// Estado de un streak activo por bloque
class BlockStreakState {
  final int blockNumber;
  final List<int> completedLevels; // IDs de niveles completados en este streak
  final int currentLevelIndex; // Índice del nivel actual (0-4)
  final bool isActive;
  final DateTime startedAt;

  const BlockStreakState({
    required this.blockNumber,
    required this.completedLevels,
    required this.currentLevelIndex,
    required this.isActive,
    required this.startedAt,
  });

  BlockStreakState copyWith({
    List<int>? completedLevels,
    int? currentLevelIndex,
    bool? isActive,
  }) {
    return BlockStreakState(
      blockNumber: blockNumber,
      completedLevels: completedLevels ?? this.completedLevels,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      isActive: isActive ?? this.isActive,
      startedAt: startedAt,
    );
  }

  /// Convertir a Map para persistencia
  Map<String, dynamic> toJson() {
    return {
      'blockNumber': blockNumber,
      'completedLevels': completedLevels,
      'currentLevelIndex': currentLevelIndex,
      'isActive': isActive,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  /// Crear desde Map de persistencia
  static BlockStreakState fromJson(Map<String, dynamic> json) {
    return BlockStreakState(
      blockNumber: json['blockNumber'],
      completedLevels: List<int>.from(json['completedLevels']),
      currentLevelIndex: json['currentLevelIndex'],
      isActive: json['isActive'],
      startedAt: DateTime.parse(json['startedAt']),
    );
  }

  /// Obtener nivel actual del streak
int get currentLevelId {
  switch (blockNumber) {
    case 1: return currentLevelIndex + 1;     // Índices 0-4 → IDs 1-5
    case 2: return currentLevelIndex + 6;     // Índices 0-4 → IDs 6-10  
    case 3: return currentLevelIndex + 11;    // Índices 0-4 → IDs 11-15
    default: return 1;
  }
}

  /// Verificar si el streak está completado
  bool get isCompleted => completedLevels.length == 5;

  /// Obtener progreso del streak (ej: "2/5")
  String get progressText => "${completedLevels.length}/5";
}

/// Gestor del sistema de torneo con persistencia completa
class TournamentManager extends ChangeNotifier {
  static const String _progressKey = 'tournament_progress_v2'; // Versión 2 para nueva estructura
  static const String _versionKey = 'tournament_version';
  static const int _currentVersion = 2; // Para futuras migraciones
  static const String _streakProgressKey = 'block_streaks_progress_v1';

  Map<int, BlockStreakState> _activeStreaks = {};


  // Definición de los 15 niveles del torneo
  static const List<TournamentLevel> _baseLevels = [
    // BLOQUE 1: FUNDAMENTOS (Niveles 1-5)
    TournamentLevel(
      id: 1, name: 'Primer Paso', description: 'Tu primera partida oficial',
      gridSize: 4, aiDifficulty: 'Fácil', block: 1, isUnlocked: true,
    ),
    TournamentLevel(
      id: 2, name: 'Consolidando', description: 'Consolida lo básico',
      gridSize: 4, aiDifficulty: 'Fácil', block: 1,
    ),
    TournamentLevel(
      id: 3, name: 'Primer Salto', description: 'Primer salto de dificultad',
      gridSize: 4, aiDifficulty: 'Medio', block: 1,
    ),
    TournamentLevel(
      id: 4, name: 'Más Espacio', description: 'Introducción a tableros grandes',
      gridSize: 5, aiDifficulty: 'Fácil', block: 1,
    ),
    TournamentLevel(
      id: 5, name: 'Estratega Junior', description: 'Jefe del Bloque 1',
      gridSize: 5, aiDifficulty: 'Medio', block: 1, isBlockBoss: true,
    ),
    
    // BLOQUE 2: DESARROLLO (Niveles 6-10)
    TournamentLevel(
      id: 6, name: 'Táctica Avanzada', description: 'Táctica avanzada en espacio reducido',
      gridSize: 4, aiDifficulty: 'Difícil', block: 2,
    ),
    TournamentLevel(
      id: 7, name: 'Tamaño Estándar', description: 'Práctica en el tamaño estándar',
      gridSize: 5, aiDifficulty: 'Medio', block: 2,
    ),
    TournamentLevel(
      id: 8, name: 'Gran Tablero', description: 'Primer tablero grande',
      gridSize: 6, aiDifficulty: 'Fácil', block: 2,
    ),
    TournamentLevel(
      id: 9, name: 'Equilibrio', description: 'Equilibrio entre espacio y dificultad',
      gridSize: 5, aiDifficulty: 'Difícil', block: 2,
    ),
    TournamentLevel(
      id: 10, name: 'Estratega Senior', description: 'Jefe del Bloque 2',
      gridSize: 6, aiDifficulty: 'Medio', block: 2, isBlockBoss: true,
    ),
    
    // BLOQUE 3: MAESTRÍA (Niveles 11-15)
    TournamentLevel(
      id: 11, name: 'Perfección Compacta', description: 'Perfección en mínimo espacio',
      gridSize: 4, aiDifficulty: 'Experto', block: 3,
    ),
    TournamentLevel(
      id: 12, name: 'Estrategia Compleja', description: 'Estrategia compleja',
      gridSize: 6, aiDifficulty: 'Difícil', block: 3,
    ),
    TournamentLevel(
      id: 13, name: 'Maestro Clásico', description: 'El tablero clásico al máximo',
      gridSize: 5, aiDifficulty: 'Experto', block: 3,
    ),
    TournamentLevel(
      id: 14, name: 'Penúltimo Desafío', description: 'Solo queda un paso más',
      gridSize: 6, aiDifficulty: 'Difícil', block: 3,
    ),
    TournamentLevel(
      id: 15, name: 'Gran Maestro', description: 'GRAN FINAL ⭐',
      gridSize: 6, aiDifficulty: 'Experto', block: 3, isBlockBoss: true,
    ),
  ];

  // Definición de los 3 bloques
  static const List<TournamentBlock> _blocks = [
    TournamentBlock(
      blockNumber: 1,
      name: 'Fundamentos',
      description: 'Aprendiendo a caminar',
      levelIds: [1, 2, 3, 4, 5],
    ),
    TournamentBlock(
      blockNumber: 2,
      name: 'Desarrollo',
      description: 'Construyendo estrategia',
      levelIds: [6, 7, 8, 9, 10],
    ),
    TournamentBlock(
      blockNumber: 3,
      name: 'Maestría',
      description: 'El camino del maestro',
      levelIds: [11, 12, 13, 14, 15],
    ),
  ];

  // Estado actual
  List<TournamentLevel> _levels = [];
  bool _isLoaded = false;

  // Getters
  List<TournamentLevel> get levels => _levels;
  List<TournamentBlock> get blocks => _blocks;
  bool get isLoaded => _isLoaded;

  Map<int, BlockStreakState> get activeStreaks => _activeStreaks;
  
  bool get hasActiveStreak => _activeStreaks.values.any((s) => s.isActive);
  
  BlockStreakState? get currentActiveStreak {
    try {
      return _activeStreaks.values.firstWhere((s) => s.isActive);
    } catch (e) {
      return null;
    }
  }
  
  /// Inicializar el gestor de torneo
  Future<void> initialize() async {
    await _loadProgress();
  }

  /// Cargar progreso desde SharedPreferences - IMPLEMENTACIÓN COMPLETA
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar versión para futuras migraciones
      final savedVersion = prefs.getInt(_versionKey) ?? 1;
      if (savedVersion < _currentVersion) {
        await _migrateData(prefs, savedVersion);
      }

      final progressJson = prefs.getString(_progressKey);

      if (progressJson != null && progressJson.isNotEmpty) {
        // Cargar progreso existente
        final Map<String, dynamic> progressMap = json.decode(progressJson);

        _levels = _baseLevels.map((baseLevel) {
          final levelProgressKey = baseLevel.id.toString();

          if (progressMap.containsKey(levelProgressKey)) {
            final levelProgress = Map<String, dynamic>.from(progressMap[levelProgressKey]);
            return TournamentLevel.fromProgressJson(baseLevel, levelProgress);
          } else {
            return baseLevel.copyWith(
              isUnlocked: baseLevel.id == 1,
            );
          }
        }).toList();

        debugPrint('✅ Progreso del torneo cargado exitosamente');
      } else {
        _initializeDefaultProgress();
        debugPrint('🆕 Iniciando torneo por primera vez');
      }

      // Cargar progreso de streaks
      await _loadStreakProgress();

    } catch (e) {
      debugPrint('❌ Error cargando progreso del torneo: $e');
      _initializeDefaultProgress();
    }

    _isLoaded = true;
    notifyListeners();
  }

  // Método para cargar streaks
  Future<void> _loadStreakProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakJson = prefs.getString(_streakProgressKey);

      if (streakJson != null && streakJson.isNotEmpty) {
        final Map<String, dynamic> streakMap = json.decode(streakJson);

        _activeStreaks.clear();
        for (var entry in streakMap.entries) {
          final blockNumber = int.parse(entry.key);
          final streakData = Map<String, dynamic>.from(entry.value);
          _activeStreaks[blockNumber] = BlockStreakState.fromJson(streakData);
        }

        debugPrint('✅ Progreso de streaks cargado: ${_activeStreaks.length} streaks');
      }
    } catch (e) {
      debugPrint('❌ Error cargando streaks: $e');
      _activeStreaks.clear();
    }
  }

  /// Inicializar progreso por defecto (primera instalación)
  void _initializeDefaultProgress() {
    _levels = _baseLevels.map((level) {
      return level.copyWith(
        isUnlocked: level.id == 1, // Solo el primer nivel desbloqueado
      );
    }).toList();
  }

  /// Migrar datos de versiones anteriores
  Future<void> _migrateData(SharedPreferences prefs, int fromVersion) async {
    debugPrint('🔄 Migrando datos del torneo desde versión $fromVersion a $_currentVersion');
    
    if (fromVersion == 1) {
      // Migrar desde versión 1 (formato anterior)
      final oldProgressString = prefs.getString('tournament_progress');
      if (oldProgressString != null) {
        // Intentar parsear formato antiguo y convertir
        try {
          // Lógica de migración específica aquí si es necesario
          debugPrint('⚠️ Datos antiguos encontrados, aplicando migración...');
        } catch (e) {
          debugPrint('⚠️ Error en migración, usando estado por defecto: $e');
        }
      }
    }
    
    // Actualizar versión
    await prefs.setInt(_versionKey, _currentVersion);
  }

  /// Guardar progreso en SharedPreferences - IMPLEMENTACIÓN COMPLETA
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Crear mapa de progreso serializable
      Map<String, dynamic> progressMap = {};

      for (var level in _levels) {
        progressMap[level.id.toString()] = level.toJson();
      }

      // Guardar progreso normal
      final progressJson = json.encode(progressMap);
      await prefs.setString(_progressKey, progressJson);

      // Guardar progreso de streaks
      await _saveStreakProgress();

      // Guardar versión actual
      await prefs.setInt(_versionKey, _currentVersion);

      debugPrint('💾 Progreso completo guardado exitosamente');
    } catch (e) {
      debugPrint('❌ Error guardando progreso: $e');
    }
  }

  // Método para guardar streaks
  Future<void> _saveStreakProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      Map<String, dynamic> streakMap = {};
      for (var entry in _activeStreaks.entries) {
        streakMap[entry.key.toString()] = entry.value.toJson();
      }

      final streakJson = json.encode(streakMap);
      await prefs.setString(_streakProgressKey, streakJson);

      debugPrint('💾 Progreso de streaks guardado: ${_activeStreaks.length} streaks');
    } catch (e) {
      debugPrint('❌ Error guardando streaks: $e');
    }
  }

  /// Obtener nivel por ID
  TournamentLevel? getLevelById(int id) {
    try {
      return _levels.firstWhere((level) => level.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener niveles de un bloque específico
  List<TournamentLevel> getLevelsInBlock(int blockNumber) {
    return _levels.where((level) => level.block == blockNumber).toList();
  }

  /// Completar un nivel con cierto número de movimientos
  Future<bool> completeLevel(int levelId, int moves) async {
    final levelIndex = _levels.indexWhere((level) => level.id == levelId);
    if (levelIndex == -1) return false;

    final level = _levels[levelIndex];
    
    // Calcular estrellas basado en movimientos
    int newStars = _calculateStars(level, moves);
    
    // Solo actualizar si es mejor que el resultado anterior
    int finalStars = newStars > level.starsEarned ? newStars : level.starsEarned;
    int bestMoves = level.bestMoves == 0 ? moves : (moves < level.bestMoves ? moves : level.bestMoves);
    
    bool isImprovement = newStars > level.starsEarned || 
                        (level.bestMoves > 0 && moves < level.bestMoves);
    
    // Actualizar nivel
    _levels[levelIndex] = level.copyWith(
      starsEarned: finalStars,
      bestMoves: bestMoves,
    );

    // Desbloquear siguiente nivel si es la primera vez que completa
    if (level.starsEarned == 0 && newStars > 0) {
      _unlockNextLevel(levelId);
      debugPrint('🔓 Nivel ${levelId + 1} desbloqueado');
    }

    // Guardar progreso automáticamente
    await _saveProgress();
    notifyListeners();
    
    debugPrint('⭐ Nivel $levelId completado: $newStars estrellas, $moves movimientos');
    
    return isImprovement;
  }

  /// Calcular estrellas según rendimiento
  int _calculateStars(TournamentLevel level, int moves) {
    // Criterios diferentes según bloque y tamaño
    Map<String, int> thresholds = _getStarThresholds(level);
    
    if (moves <= thresholds['gold']!) {
      return 3; // Oro
    } else if (moves <= thresholds['silver']!) {
      return 2; // Plata  
    } else {
      return 1; // Bronce (por completar)
    }
  }

  /// Obtener umbrales de estrellas por nivel
  Map<String, int> _getStarThresholds(TournamentLevel level) {
    // Basado en tamaño del grid y dificultad
    int base = level.gridSize * 3; // Base: 12 para 4x4, 15 para 5x5, 18 para 6x6
    
    // Ajustar según dificultad
    double multiplier = 1.0;
    switch (level.aiDifficulty) {
      case 'Fácil': multiplier = 0.8; break;
      case 'Medio': multiplier = 1.0; break;
      case 'Difícil': multiplier = 1.2; break;
      case 'Experto': multiplier = 1.5; break;
    }
    
    int adjustedBase = (base * multiplier).round();
    
    return {
      'gold': (adjustedBase * 0.7).round(),    // 70% del base
      'silver': (adjustedBase * 0.9).round(),  // 90% del base
      'bronze': adjustedBase * 2,              // Cualquier completado
    };
  }

  /// Desbloquear siguiente nivel
  void _unlockNextLevel(int currentLevelId) {
    if (currentLevelId < _levels.length) {
      final nextLevelIndex = _levels.indexWhere((level) => level.id == currentLevelId + 1);
      if (nextLevelIndex != -1) {
        _levels[nextLevelIndex] = _levels[nextLevelIndex].copyWith(isUnlocked: true);
      }
    }
  }

  /// Obtener progreso del torneo (0.0 a 1.0)
  double get overallProgress {
    if (_levels.isEmpty) return 0.0;
    
    int completedLevels = _levels.where((level) => level.isCompleted).length;
    return completedLevels / _levels.length;
  }

  /// Obtener progreso de un bloque específico
  double getBlockProgress(int blockNumber) {
    final blockLevels = getLevelsInBlock(blockNumber);
    if (blockLevels.isEmpty) return 0.0;
    
    int completedLevels = blockLevels.where((level) => level.isCompleted).length;
    return completedLevels / blockLevels.length;
  }

  /// Obtener total de estrellas ganadas
  int get totalStars {
    return _levels.fold(0, (sum, level) => sum + level.starsEarned);
  }

  /// Obtener máximo de estrellas posibles
  int get maxStars {
    return _levels.length * 3;
  }

  /// Verificar si es campeón (completó todos los niveles)
  bool get isChampion {
    return _levels.isNotEmpty && _levels.every((level) => level.isCompleted);
  }

  /// Obtener nivel actual (próximo nivel no completado)
  TournamentLevel? get currentLevel {
    try {
      return _levels.firstWhere((level) => level.isUnlocked && !level.isCompleted);
    } catch (e) {
      // Si todos están completados, retornar el último
      return _levels.isNotEmpty ? _levels.last : null;
    }
  }

  /// Resetear todo el progreso del torneo - CON PERSISTENCIA
  Future<void> resetProgress() async {
    debugPrint('🔄 Reseteando progreso del torneo...');
    
    _levels = _baseLevels.map((level) {
      return level.copyWith(
        isUnlocked: level.id == 1, // Solo el primer nivel desbloqueado
        starsEarned: 0,
        bestMoves: 0,
      );
    }).toList();

    // Guardar el reset automáticamente
    await _saveProgress();
    notifyListeners();
    
    debugPrint('✅ Progreso del torneo reseteado completamente');
  }

  /// Obtener información de un bloque
  TournamentBlock? getBlockInfo(int blockNumber) {
    try {
      return _blocks.firstWhere((block) => block.blockNumber == blockNumber);
    } catch (e) {
      return null;
    }
  }

  /// Verificar si un bloque está completado
  bool isBlockCompleted(int blockNumber) {
    final blockLevels = getLevelsInBlock(blockNumber);
    return blockLevels.isNotEmpty && blockLevels.every((level) => level.isCompleted);
  }

  /// Obtener estadísticas detalladas del progreso
  Map<String, dynamic> getProgressStatistics() {
    final completedLevels = _levels.where((l) => l.isCompleted).length;
    final perfectLevels = _levels.where((l) => l.starsEarned == 3).length;
    final block1Progress = getBlockProgress(1);
    final block2Progress = getBlockProgress(2);
    final block3Progress = getBlockProgress(3);
    
    return {
      'totalLevels': _levels.length,
      'completedLevels': completedLevels,
      'perfectLevels': perfectLevels,
      'totalStars': totalStars,
      'maxStars': maxStars,
      'overallProgress': overallProgress,
      'isChampion': isChampion,
      'blockProgress': {
        1: block1Progress,
        2: block2Progress,
        3: block3Progress,
      },
      'completionPercentage': (overallProgress * 100).round(),
      'starPercentage': maxStars > 0 ? ((totalStars / maxStars) * 100).round() : 0,
    };
  }

  /// Forzar guardado manual (para casos específicos)
  Future<void> forceSave() async {
    await _saveProgress();
  }

  /// Verificar integridad de los datos
  bool verifyDataIntegrity() {
    try {
      // Verificar que todos los niveles base existen
      if (_levels.length != _baseLevels.length) {
        debugPrint('⚠️ Cantidad de niveles incorrecta: ${_levels.length} vs ${_baseLevels.length}');
        return false;
      }
      
      // Verificar que el primer nivel esté desbloqueado
      final firstLevel = getLevelById(1);
      if (firstLevel == null || !firstLevel.isUnlocked) {
        debugPrint('⚠️ Primer nivel no desbloqueado');
        return false;
      }
      
      // Verificar lógica de desbloqueo secuencial
      for (int i = 2; i <= _levels.length; i++) {
        final currentLevel = getLevelById(i);
        final previousLevel = getLevelById(i - 1);
        
        if (currentLevel != null && previousLevel != null) {
          if (currentLevel.isUnlocked && !previousLevel.isCompleted) {
            debugPrint('⚠️ Nivel $i desbloqueado sin completar nivel anterior');
            return false;
          }
        }
      }
      
      debugPrint('✅ Integridad de datos del torneo verificada');
      return true;
    } catch (e) {
      debugPrint('❌ Error verificando integridad: $e');
      return false;
    }
  }


  bool canStartBlockStreak(int blockNumber) {
    // 1. El bloque debe estar completado
    if (!isBlockCompleted(blockNumber)) return false;

    // Permitir rejugar incluso si ya tiene la estrella de streak
    // 2. No debe haber un streak activo (removemos la verificación de estrella existente)
    if (hasActiveStreak) return false;

    return true;
  }

  /// Verificar si un bloque ya fue completado en modo perfecto (para mostrar estado visual)
  bool wasBlockStreakCompleted(int blockNumber) {
    return hasBlockStreakStar(blockNumber);
  }



  /// Verificar si un bloque tiene la estrella de streak
  bool hasBlockStreakStar(int blockNumber) {
    final blockLevels = getLevelsInBlock(blockNumber);
    return blockLevels.isNotEmpty && blockLevels.first.hasStreakStar;
  }

  /// Iniciar un nuevo streak para un bloque
  Future<bool> startBlockStreak(int blockNumber) async {
    if (!canStartBlockStreak(blockNumber)) {
      debugPrint('❌ No se puede iniciar streak para bloque $blockNumber');
      return false;
    }

    // Crear nuevo estado de streak
    final newStreak = BlockStreakState(
      blockNumber: blockNumber,
      completedLevels: [],
      currentLevelIndex: 0,
      isActive: true,
      startedAt: DateTime.now(),
    );

    _activeStreaks[blockNumber] = newStreak;
    await _saveStreakProgress();
    notifyListeners();

    debugPrint('🚀 Streak iniciado para bloque $blockNumber');
    return true;
  }

  /// Actualizar progreso del streak cuando se completa un nivel
Future<bool> updateStreakProgress(int levelId, bool levelWon) async {
  final currentStreak = currentActiveStreak;
  if (currentStreak == null) return false;

  final expectedLevelId = currentStreak.currentLevelId;
  if (levelId != expectedLevelId) {
    debugPrint('❌ Nivel incorrecto en streak: esperado $expectedLevelId, recibido $levelId');
    return false;
  }

  if (!levelWon) {
    // STREAK FALLIDO
    debugPrint('💥 Streak fallido en nivel $levelId');
    await _failStreak(currentStreak.blockNumber, 'level_lost');
    return false;
  }

  // Nivel completado exitosamente
  final updatedCompletedLevels = [...currentStreak.completedLevels, levelId];
  
  // currentLevelIndex representa el índice del PRÓXIMO nivel a jugar
  // Después de completar el nivel en índice N, avanzamos al índice N+1
  final updatedStreak = currentStreak.copyWith(
    completedLevels: updatedCompletedLevels,
    currentLevelIndex: currentStreak.currentLevelIndex + 1,
  );

  _activeStreaks[currentStreak.blockNumber] = updatedStreak;

  // Verificar si el streak está completado
  if (updatedStreak.isCompleted) {
    await _completeStreak(currentStreak.blockNumber);
  } else {
    await _saveStreakProgress();
    notifyListeners();
  }

  debugPrint('Streak actualizado: ${updatedStreak.progressText}');
  debugPrint('   Próximo nivel: ${getCurrentStreakLevel()?.name ?? "Streak completado"}');
  return true;
}

  /// Fallar un streak activo
  Future<void> _failStreak(int blockNumber, String reason) async {
    _activeStreaks.remove(blockNumber);
    await _saveStreakProgress();
    notifyListeners();

    debugPrint('💥 Streak fallido para bloque $blockNumber: $reason');
  }

  /// Completar un streak exitosamente
  Future<void> _completeStreak(int blockNumber) async {
    // Marcar todos los niveles del bloque con la estrella de streak
    for (int i = 0; i < _levels.length; i++) {
      if (_levels[i].block == blockNumber) {
        _levels[i] = _levels[i].copyWith(hasStreakStar: true);
      }
    }

    // Remover el streak activo
    _activeStreaks.remove(blockNumber);

    // Guardar progreso
    await _saveProgress(); // Esto guarda tanto niveles como streaks
    notifyListeners();

    debugPrint('🏆 ¡Streak completado para bloque $blockNumber!');
  }

  /// Cancelar streak activo (cuando usuario sale)
  Future<void> cancelActiveStreak(String reason) async {
    final currentStreak = currentActiveStreak;
    if (currentStreak != null) {
      await _failStreak(currentStreak.blockNumber, reason);
    }
  }

  /// Obtener nivel actual del streak activo
  TournamentLevel? getCurrentStreakLevel() {
    final currentStreak = currentActiveStreak;
    if (currentStreak == null) return null;

    return getLevelById(currentStreak.currentLevelId);
  }

  /// Obtener siguiente nivel del streak activo
  TournamentLevel? getNextStreakLevel() {
    final currentStreak = currentActiveStreak;
    if (currentStreak == null) return null;

    // Verificar que hay un siguiente nivel disponible
    if (currentStreak.currentLevelIndex >= 5) {
      return null; // No hay siguiente nivel (ya completó todos)
    }

    // El siguiente nivel es simplemente el nivel actual según currentLevelIndex
    return getLevelById(currentStreak.currentLevelId);
  }


  /// Obtener total de estrellas de streak ganadas
  int get totalStreakStars {
    int count = 0;
    for (int blockNumber = 1; blockNumber <= 3; blockNumber++) {
      if (hasBlockStreakStar(blockNumber)) count++;
    }
    return count;
  }

  /// Obtener máximo de estrellas de streak posibles
  int get maxStreakStars => 3; // Una por bloque

}