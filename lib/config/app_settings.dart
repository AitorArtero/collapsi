import 'package:shared_preferences/shared_preferences.dart';

/// Gestión de configuración de la aplicación
class AppSettings {
  static const String difficultyKey = 'difficulty';
  static const String soundEnabledKey = 'sound_enabled';
  static const String gridSizeKey = 'grid_size';
  static const String aiModeKey = 'ai_mode';
  
  // CONFIGURACIONES POR DEFECTO
  static const String defaultDifficultyKey = 'default_difficulty';
  static const String defaultGridSizeKey = 'default_grid_size';
  
  // CONFIGURACIONES DE EXPERIENCIA DE USUARIO
  static const String gameHapticsKey = 'game_haptics_enabled';
  static const String appHapticsKey = 'app_haptics_enabled';
  static const String animationsEnabledKey = 'animations_enabled';
  static const String gameSoundEnabledKey = 'game_sound_enabled';
  static const String movementHelpEnabledKey = 'movement_help_enabled';
  static const String movementHelpDelayKey = 'movement_help_delay';
  
  // CONFIGURACIONES DE MÚSICA DE FONDO
  static const String backgroundMusicEnabledKey = 'background_music_enabled';
  static const String backgroundMusicTrackKey = 'background_music_track';
  static const String backgroundMusicVolumeKey = 'background_music_volume';

  /// Guarda una configuración
  static Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  /// Carga una configuración
  static Future<T?> loadSetting<T>(String key, [T? defaultValue]) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(key);
    return value as T? ?? defaultValue;
  }

  /// Métodos específicos para configuraciones comunes (EXISTENTES)
  static Future<String> getDifficulty() async {
    return await loadSetting<String>(difficultyKey, 'medium') ?? 'medium';
  }

  static Future<void> setDifficulty(String difficulty) async {
    await saveSetting(difficultyKey, difficulty);
  }

  static Future<bool> getSoundEnabled() async {
    return await loadSetting<bool>(soundEnabledKey, true) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    await saveSetting(soundEnabledKey, enabled);
  }

  static Future<int> getGridSize() async {
    return await loadSetting<int>(gridSizeKey, 4) ?? 4;
  }

  static Future<void> setGridSize(int size) async {
    await saveSetting(gridSizeKey, size);
  }

  static Future<bool> getAIMode() async {
    return await loadSetting<bool>(aiModeKey, false) ?? false;
  }

  static Future<void> setAIMode(bool enabled) async {
    await saveSetting(aiModeKey, enabled);
  }

  // CONFIGURACIONES POR DEFECTO (EXISTENTES)
  
  /// Obtiene la dificultad de IA por defecto
  static Future<String> getDefaultDifficulty() async {
    final value = await loadSetting<String>(defaultDifficultyKey, 'Medio');
    // Validar que el valor sea válido
    const validDifficulties = ['Fácil', 'Medio', 'Difícil', 'Experto'];
    if (validDifficulties.contains(value)) {
      return value!;
    }
    return 'Medio'; // Valor por defecto si es inválido
  }

  /// Establece la dificultad de IA por defecto
  static Future<void> setDefaultDifficulty(String difficulty) async {
    // Validar que el valor sea válido antes de guardar
    const validDifficulties = ['Fácil', 'Medio', 'Difícil', 'Experto'];
    if (validDifficulties.contains(difficulty)) {
      await saveSetting(defaultDifficultyKey, difficulty);
    }
  }

  /// Obtiene el tamaño de tablero por defecto
  static Future<int> getDefaultGridSize() async {
    final value = await loadSetting<int>(defaultGridSizeKey, 4);
    // Validar que el valor sea válido (4, 5, o 6)
    if (value != null && [4, 5, 6].contains(value)) {
      return value;
    }
    return 4; // Valor por defecto si es inválido
  }

  /// Establece el tamaño de tablero por defecto
  static Future<void> setDefaultGridSize(int size) async {
    // Validar que el valor sea válido antes de guardar
    if ([4, 5, 6].contains(size)) {
      await saveSetting(defaultGridSizeKey, size);
    }
  }

  // CONFIGURACIONES DE EXPERIENCIA DE USUARIO

  /// Obtiene configuración de vibración en el juego (tocar celdas)
  static Future<bool> getGameHapticsEnabled() async {
    return await loadSetting<bool>(gameHapticsKey, true) ?? true;
  }

  /// Establece configuración de vibración en el juego
  static Future<void> setGameHapticsEnabled(bool enabled) async {
    await saveSetting(gameHapticsKey, enabled);
  }

  /// Obtiene configuración de vibración en la app (botones, navegación)
  static Future<bool> getAppHapticsEnabled() async {
    return await loadSetting<bool>(appHapticsKey, true) ?? true;
  }

  /// Establece configuración de vibración en la app
  static Future<void> setAppHapticsEnabled(bool enabled) async {
    await saveSetting(appHapticsKey, enabled);
  }

  /// Obtiene configuración de animaciones de la app
  static Future<bool> getAnimationsEnabled() async {
    return await loadSetting<bool>(animationsEnabledKey, true) ?? true;
  }

  /// Establece configuración de animaciones de la app
  static Future<void> setAnimationsEnabled(bool enabled) async {
    await saveSetting(animationsEnabledKey, enabled);
  }

  /// Obtiene configuración de sonidos del juego
  static Future<bool> getGameSoundEnabled() async {
    return await loadSetting<bool>(gameSoundEnabledKey, true) ?? true;
  }

  /// Establece configuración de sonidos del juego
  static Future<void> setGameSoundEnabled(bool enabled) async {
    await saveSetting(gameSoundEnabledKey, enabled);
  }

  // CONFIGURACIONES DE AYUDA DE MOVIMIENTO
  
  /// Obtiene configuración de ayuda de movimiento (resaltar casillas válidas)
  /// Por defecto FALSE (deshabilitada)
  static Future<bool> getMovementHelpEnabled() async {
    return await loadSetting<bool>(movementHelpEnabledKey, false) ?? false;
  }

  /// Establece configuración de ayuda de movimiento
  static Future<void> setMovementHelpEnabled(bool enabled) async {
    await saveSetting(movementHelpEnabledKey, enabled);
  }

  /// Obtiene el delay para la ayuda de movimiento (en segundos)
  /// Por defecto 3 segundos, rango 0-20 segundos
  static Future<double> getMovementHelpDelay() async {
    final value = await loadSetting<double>(movementHelpDelayKey, 3.0);
    return (value ?? 3.0).clamp(0.0, 20.0);
  }

  /// Establece el delay para la ayuda de movimiento
  static Future<void> setMovementHelpDelay(double delaySeconds) async {
    await saveSetting(movementHelpDelayKey, delaySeconds.clamp(0.0, 20.0));
  }

  // CONFIGURACIONES DE MÚSICA DE FONDO

  /// Obtiene si la música de fondo está habilitada
  static Future<bool> getBackgroundMusicEnabled() async {
    return await loadSetting<bool>(backgroundMusicEnabledKey, true) ?? true;
  }

  /// Establece si la música de fondo está habilitada
  static Future<void> setBackgroundMusicEnabled(bool enabled) async {
    await saveSetting(backgroundMusicEnabledKey, enabled);
  }

  /// Obtiene la pista de música de fondo seleccionada
  static Future<String> getBackgroundMusicTrack() async {
    return await loadSetting<String>(backgroundMusicTrackKey, 'lofi_piano') ?? 'lofi_piano';
  }

  /// Establece la pista de música de fondo
  static Future<void> setBackgroundMusicTrack(String track) async {
    // Validar que sea una pista válida
    const validTracks = ['none', 'zen', 'lofi_piano', 'relaxing_guitar', 'rhythm_zen'];
    if (validTracks.contains(track)) {
      await saveSetting(backgroundMusicTrackKey, track);
    }
  }

  /// Obtiene el volumen de la música de fondo (0.0 - 1.0)
  static Future<double> getBackgroundMusicVolume() async {
    final value = await loadSetting<double>(backgroundMusicVolumeKey, 0.3);
    return (value ?? 0.3).clamp(0.0, 1.0);
  }

  /// Establece el volumen de la música de fondo
  static Future<void> setBackgroundMusicVolume(double volume) async {
    await saveSetting(backgroundMusicVolumeKey, volume.clamp(0.0, 1.0));
  }

  // MÉTODOS DE UTILIDAD

  /// Restablece todas las configuraciones por defecto
  static Future<void> resetDefaultSettings() async {
    await setDefaultDifficulty('Medio');
    await setDefaultGridSize(4);
  }

  /// Restablece todas las configuraciones de experiencia de usuario
  static Future<void> resetExperienceSettings() async {
    await setGameHapticsEnabled(true);
    await setAppHapticsEnabled(true);
    await setAnimationsEnabled(true);
    await setGameSoundEnabled(true);
    await setMovementHelpEnabled(false); // Por defecto false
    await setMovementHelpDelay(3.0); // Resetear delay a 3 segundos
    // Resetear también configuraciones de música
    await setBackgroundMusicEnabled(true);
    await setBackgroundMusicTrack('lofi_piano');
    await setBackgroundMusicVolume(0.3);
  }

  /// Restablece TODAS las configuraciones
  static Future<void> resetAllSettings() async {
    await resetDefaultSettings();
    await resetExperienceSettings();
  }

  /// Obtiene todas las configuraciones por defecto de una vez
  static Future<Map<String, dynamic>> getDefaultSettings() async {
    return {
      'difficulty': await getDefaultDifficulty(),
      'gridSize': await getDefaultGridSize(),
    };
  }

  /// Obtiene todas las configuraciones de experiencia de usuario
  static Future<Map<String, dynamic>> getExperienceSettings() async {
    return {
      'gameHaptics': await getGameHapticsEnabled(),
      'appHaptics': await getAppHapticsEnabled(),
      'animations': await getAnimationsEnabled(),
      'gameSound': await getGameSoundEnabled(),
      'movementHelp': await getMovementHelpEnabled(),
      'movementHelpDelay': await getMovementHelpDelay(),
      'backgroundMusicEnabled': await getBackgroundMusicEnabled(),
      'backgroundMusicTrack': await getBackgroundMusicTrack(),
      'backgroundMusicVolume': await getBackgroundMusicVolume(),
    };
  }

  /// Obtiene SOLO las configuraciones de música de fondo
  static Future<Map<String, dynamic>> getBackgroundMusicSettings() async {
    return {
      'enabled': await getBackgroundMusicEnabled(),
      'track': await getBackgroundMusicTrack(),
      'volume': await getBackgroundMusicVolume(),
    };
  }

  /// Obtiene configuraciones específicas de ayuda de movimiento
  static Future<Map<String, dynamic>> getMovementHelpSettings() async {
    return {
      'enabled': await getMovementHelpEnabled(),
      'delay': await getMovementHelpDelay(),
    };
  }

  /// Obtiene TODAS las configuraciones de la aplicación
  static Future<Map<String, dynamic>> getAllSettings() async {
    final defaultSettings = await getDefaultSettings();
    final experienceSettings = await getExperienceSettings();
    
    return {
      ...defaultSettings,
      ...experienceSettings,
    };
  }

  /// Aplica configuraciones por defecto en lote
  static Future<void> setDefaultSettings({
    String? difficulty,
    int? gridSize,
  }) async {
    if (difficulty != null) {
      await setDefaultDifficulty(difficulty);
    }
    if (gridSize != null) {
      await setDefaultGridSize(gridSize);
    }
  }

  /// Aplica configuraciones de experiencia en lote
  static Future<void> setExperienceSettings({
    bool? gameHaptics,
    bool? appHaptics,
    bool? animations,
    bool? gameSound,
    bool? movementHelp,
    double? movementHelpDelay,
    bool? backgroundMusicEnabled,
    String? backgroundMusicTrack,
    double? backgroundMusicVolume,
  }) async {
    if (gameHaptics != null) {
      await setGameHapticsEnabled(gameHaptics);
    }
    if (appHaptics != null) {
      await setAppHapticsEnabled(appHaptics);
    }
    if (animations != null) {
      await setAnimationsEnabled(animations);
    }
    if (gameSound != null) {
      await setGameSoundEnabled(gameSound);
    }
    if (movementHelp != null) {
      await setMovementHelpEnabled(movementHelp);
    }
    if (movementHelpDelay != null) {
      await setMovementHelpDelay(movementHelpDelay);
    }
    // Aplicar configuraciones de música
    if (backgroundMusicEnabled != null) {
      await setBackgroundMusicEnabled(backgroundMusicEnabled);
    }
    if (backgroundMusicTrack != null) {
      await setBackgroundMusicTrack(backgroundMusicTrack);
    }
    if (backgroundMusicVolume != null) {
      await setBackgroundMusicVolume(backgroundMusicVolume);
    }
  }

  /// Aplica configuraciones de música de fondo en lote
  static Future<void> setBackgroundMusicSettings({
    bool? enabled,
    String? track,
    double? volume,
  }) async {
    if (enabled != null) {
      await setBackgroundMusicEnabled(enabled);
    }
    if (track != null) {
      await setBackgroundMusicTrack(track);
    }
    if (volume != null) {
      await setBackgroundMusicVolume(volume);
    }
  }

  /// Aplica configuraciones de ayuda de movimiento en lote
  static Future<void> setMovementHelpSettings({
    bool? enabled,
    double? delay,
  }) async {
    if (enabled != null) {
      await setMovementHelpEnabled(enabled);
    }
    if (delay != null) {
      await setMovementHelpDelay(delay);
    }
  }
}