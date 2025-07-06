import 'package:flutter/foundation.dart';
import '../config/app_settings.dart';

/// Tipos de sonidos del juego
enum GameSoundType {
  cellTap,        // Tocar una celda
  moveSuccess,    // Movimiento exitoso
  moveInvalid,    // Movimiento inválido
  gameWin,        // Victoria del jugador
  gameLose,       // Derrota del jugador
  aiMove,         // Movimiento de la IA
  undoMove,       // Deshacer movimiento
  buttonTap,      // Tocar botón de UI
  themeChange,    // Cambio de tema
  levelComplete,  // Completar nivel de torneo
}

/// Gestor de sonidos del juego
/// 
/// Esta clase está preparada para integrar archivos de audio fácilmente.
/// Solo necesitas:
/// 1. Añadir dependencia de audio (flutter_sound, audioplayers, etc.)
/// 2. Añadir archivos de audio a assets/sounds/
/// 3. Implementar el reproductor en _playAudioFile()
class SoundManager {
  static SoundManager? _instance;
  static SoundManager get instance => _instance ??= SoundManager._internal();
  
  SoundManager._internal();

  // Estado del sonido
  bool _soundEnabled = true;
  bool _isInitialized = false;

  // Mapa de archivos de sonido (listos para conectar)
  static const Map<GameSoundType, String> _soundFiles = {
    GameSoundType.cellTap: 'sounds/cell_tap.wav',
    GameSoundType.moveSuccess: 'sounds/move_success.wav',
    GameSoundType.moveInvalid: 'sounds/move_invalid.wav',
    GameSoundType.gameWin: 'sounds/game_win.wav',
    GameSoundType.gameLose: 'sounds/game_lose.wav',
    GameSoundType.aiMove: 'sounds/ai_move.wav',
    GameSoundType.undoMove: 'sounds/undo_move.wav',
    GameSoundType.buttonTap: 'sounds/button_tap.wav',
    GameSoundType.themeChange: 'sounds/theme_change.wav',
    GameSoundType.levelComplete: 'sounds/level_complete.wav',
  };

  /// Inicializar el gestor de sonidos
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Cargar configuración de sonido
      _soundEnabled = await AppSettings.getGameSoundEnabled();
      
      // Ejemplo para audioplayers:
      // await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      _isInitialized = true;
      debugPrint('🎵 SoundManager inicializado - Sonido: ${_soundEnabled ? "ON" : "OFF"}');
    } catch (e) {
      debugPrint('❌ Error inicializando SoundManager: $e');
      _isInitialized = false;
    }
  }

  /// Reproducir un sonido específico
  Future<void> playSound(GameSoundType soundType) async {
    if (!_isInitialized || !_soundEnabled) return;

    try {
      final soundFile = _soundFiles[soundType];
      if (soundFile == null) {
        debugPrint('⚠️ Archivo de sonido no encontrado para: $soundType');
        return;
      }

  
      await _playAudioFile(soundFile);
      
      debugPrint('🔊 Reproduciendo: ${soundType.name}');
    } catch (e) {
      debugPrint('❌ Error reproduciendo sonido ${soundType.name}: $e');
    }
  }

  /// MÉTODO PARA IMPLEMENTAR AUDIO
  Future<void> _playAudioFile(String filePath) async {
    // 📁 OPCIÓN 1: Con audioplayers
    // await _audioPlayer.play(AssetSource(filePath));
    
    // 📁 OPCIÓN 2: Con flutter_sound
    // await _flutterSoundPlayer.startPlayer(fromAsset: filePath);
    
    // 📁 OPCIÓN 3: Con just_audio
    // await _audioPlayer.setAsset(filePath);
    // await _audioPlayer.play();
    
    // Por ahora, solo logging para demostrar que funciona
    debugPrint('🎵 [PREPARADO] Reproduciría: $filePath');
  }

  /// Métodos de conveniencia para sonidos comunes

  /// Reproducir sonido de tocar celda
  Future<void> playCellTap() async {
    await playSound(GameSoundType.cellTap);
  }

  /// Reproducir sonido de movimiento exitoso
  Future<void> playMoveSuccess() async {
    await playSound(GameSoundType.moveSuccess);
  }

  /// Reproducir sonido de movimiento inválido
  Future<void> playMoveInvalid() async {
    await playSound(GameSoundType.moveInvalid);
  }

  /// Reproducir sonido de victoria
  Future<void> playGameWin() async {
    await playSound(GameSoundType.gameWin);
  }

  /// Reproducir sonido de derrota
  Future<void> playGameLose() async {
    await playSound(GameSoundType.gameLose);
  }

  /// Reproducir sonido de movimiento de IA
  Future<void> playAIMove() async {
    await playSound(GameSoundType.aiMove);
  }

  /// Reproducir sonido de deshacer
  Future<void> playUndoMove() async {
    await playSound(GameSoundType.undoMove);
  }

  /// Reproducir sonido de botón de UI
  Future<void> playButtonTap() async {
    await playSound(GameSoundType.buttonTap);
  }

  /// Reproducir sonido de cambio de tema
  Future<void> playThemeChange() async {
    await playSound(GameSoundType.themeChange);
  }

  /// Reproducir sonido de nivel completado
  Future<void> playLevelComplete() async {
    await playSound(GameSoundType.levelComplete);
  }

  /// Habilitar/deshabilitar sonidos
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await AppSettings.setGameSoundEnabled(enabled);
    debugPrint('🎵 Sonido ${enabled ? "habilitado" : "deshabilitado"}');
  }

  /// Verificar si los sonidos están habilitados
  bool get isSoundEnabled => _soundEnabled;

  /// Verificar si está inicializado
  bool get isInitialized => _isInitialized;

  /// Recargar configuración desde AppSettings
  Future<void> reloadSettings() async {
    _soundEnabled = await AppSettings.getGameSoundEnabled();
    debugPrint('🔄 Configuración de sonido recargada: ${_soundEnabled ? "ON" : "OFF"}');
  }

  /// Limpiar recursos (llamar en dispose)
  Future<void> dispose() async {
    // AQUÍ LIBERARÍAS LOS RECURSOS DEL REPRODUCTOR
    // await _audioPlayer.dispose();
    
    _isInitialized = false;
    debugPrint('🎵 SoundManager liberado');
  }
}

/// Extension para fácil acceso desde cualquier parte de la app
extension SoundManagerExtension on Object {
  SoundManager get soundManager => SoundManager.instance;
}