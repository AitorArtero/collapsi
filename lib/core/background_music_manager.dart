import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/app_settings.dart';

/// Opciones de música de fondo disponibles
enum BackgroundMusicTrack {
  none('Silencio', '🔇', 'Sin música de fondo'),
  zen('Zen Garden', '🧘', 'Música zen relajante y meditativa'),
  lofi_piano('Lo-Fi Piano', '🎹', 'Piano lo-fi suave y concentrativo'),
  relaxing_guitar('Guitarra Relajante', '🎸', 'Guitarra acústica chill y tranquila'),
  rhythm_zen('Zen Rítmico', '🎵', 'Ritmos zen con toques ambientales');

  const BackgroundMusicTrack(this.displayName, this.emoji, this.description);
  
  final String displayName;
  final String emoji;
  final String description;
}

/// Gestor de música de fondo para Collapsi
class BackgroundMusicManager with WidgetsBindingObserver {
  static BackgroundMusicManager? _instance;
  static BackgroundMusicManager get instance => _instance ??= BackgroundMusicManager._internal();
  
  BackgroundMusicManager._internal();

  // Reproductor de audio para música de fondo
  late AudioPlayer _musicPlayer;
  
  // Estado actual
  BackgroundMusicTrack _currentTrack = BackgroundMusicTrack.rhythm_zen;
  bool _musicEnabled = true;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _wasPlayingBeforePause = false; // Para recordar si estaba sonando antes de pausar
  double _volume = 0.3; // Volumen más bajo para música de fondo

  // Mapa de archivos de música
  static const Map<BackgroundMusicTrack, String> _musicFiles = {
    BackgroundMusicTrack.zen: 'music/zen.mp3',
    BackgroundMusicTrack.lofi_piano: 'music/piano_ritmo.mp3',
    BackgroundMusicTrack.relaxing_guitar: 'music/guitarra_chill.mp3',
    BackgroundMusicTrack.rhythm_zen: 'music/zen_ritmo.mp3',
  };

  /// Inicializar el gestor de música de fondo
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _musicPlayer = AudioPlayer();
      
      // Configurar el reproductor para loop continuo
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_volume);
      
      // Cargar configuración guardada
      _musicEnabled = await AppSettings.getBackgroundMusicEnabled();
      final savedTrack = await AppSettings.getBackgroundMusicTrack();
      _currentTrack = _parseTrackFromString(savedTrack);
      
      // Configurar listeners
      _setupPlayerListeners();
      
      // Registrar observer del ciclo de vida
      WidgetsBinding.instance.addObserver(this);
      
      _isInitialized = true;
      debugPrint('🎵 BackgroundMusicManager inicializado - Música: ${_musicEnabled ? "ON" : "OFF"}, Pista: ${_currentTrack.displayName}');
      
      // Iniciar reproducción si está habilitada
      if (_musicEnabled && _currentTrack != BackgroundMusicTrack.none) {
        await _playCurrentTrack();
      }
      
    } catch (e) {
      debugPrint('❌ Error inicializando BackgroundMusicManager: $e');
      _isInitialized = false;
    }
  }

  /// Manejar cambios en el ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🎵 🔴 CICLO DE VIDA: $state');
    debugPrint('🎵 🔴 Estado antes del cambio: _isPlaying=$_isPlaying, _musicEnabled=$_musicEnabled, _currentTrack=${_currentTrack.name}');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App va a segundo plano o se minimiza
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App vuelve a primer plano
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        // App se está cerrando
        _handleAppDetached();
        break;
    }
  }

  /// Manejar cuando la app se pausa/minimiza
  void _handleAppPaused() {
    debugPrint('🎵 📱 PAUSANDO APP...');
    debugPrint('🎵 📱 _isPlaying actual: $_isPlaying');
    debugPrint('🎵 📱 _musicEnabled: $_musicEnabled');
    debugPrint('🎵 📱 _currentTrack: ${_currentTrack.name}');
    
    // Guardar si DEBERÍA estar sonando (no solo si está sonando ahora)
    _wasPlayingBeforePause = _musicEnabled && _currentTrack != BackgroundMusicTrack.none;
    
    if (_isPlaying) {
      _stopMusicSync();
    }
    
    debugPrint('🎵 📱 App pausada. wasPlayingBeforePause=$_wasPlayingBeforePause');
  }

  /// Manejar cuando la app se reanuda
  void _handleAppResumed() {
    debugPrint('🎵 📱 REANUDANDO APP...');
    debugPrint('🎵 📱 _wasPlayingBeforePause: $_wasPlayingBeforePause');
    debugPrint('🎵 📱 _musicEnabled: $_musicEnabled');
    debugPrint('🎵 📱 _currentTrack: ${_currentTrack.name}');
    
    if (_wasPlayingBeforePause && _musicEnabled && _currentTrack != BackgroundMusicTrack.none) {
      // Delay más largo para asegurar que la app esté completamente activa
      Future.delayed(const Duration(milliseconds: 300), () async {
        debugPrint('🎵 📱 ⏰ Ejecutando reanudación después del delay...');
        await _playCurrentTrack();
        _wasPlayingBeforePause = false; // Reset del estado
        debugPrint('🎵 📱 ✅ App reanudada - Música reanudada');
      });
    } else {
      debugPrint('🎵 📱 ❌ No se reanuda música: wasPlaying=$_wasPlayingBeforePause, enabled=$_musicEnabled, track=${_currentTrack.name}');
      _wasPlayingBeforePause = false;
    }
  }

  /// Manejar cuando la app se cierra
  void _handleAppDetached() {
    _stopMusicSync();
    _wasPlayingBeforePause = false;
    debugPrint('🎵 App cerrada - Música detenida');
  }

  /// Configurar listeners del reproductor
  void _setupPlayerListeners() {
    _musicPlayer.onPlayerStateChanged.listen((PlayerState state) {
      final oldPlaying = _isPlaying;
      _isPlaying = state == PlayerState.playing;
      
      if (oldPlaying != _isPlaying) {
        debugPrint('🎵 Estado del reproductor cambió: $state (isPlaying: $_isPlaying)');
      }
    });

    _musicPlayer.onPlayerComplete.listen((event) {
      debugPrint('🎵 Pista completada, el loop debería reiniciar automáticamente');
    });
  }

  /// Reproducir la pista actual
  Future<void> _playCurrentTrack() async {
    if (!_isInitialized || !_musicEnabled || _currentTrack == BackgroundMusicTrack.none) {
      debugPrint('🎵 ❌ No se puede reproducir - Init: $_isInitialized, Enabled: $_musicEnabled, Track: $_currentTrack');
      return;
    }

    try {
      final musicFile = _musicFiles[_currentTrack];
      if (musicFile == null) {
        debugPrint('⚠️ Archivo de música no encontrado para: ${_currentTrack.displayName}');
        return;
      }

      // Detener la música actual si está reproduciéndose
      if (_isPlaying) {
        await _musicPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Reproducir la nueva pista
      await _musicPlayer.play(AssetSource(musicFile));
      debugPrint('🎵 ✅ Reproduciendo música de fondo: ${_currentTrack.displayName}');
      
    } catch (e) {
      debugPrint('❌ Error reproduciendo música ${_currentTrack.displayName}: $e');
    }
  }

  /// Detener música de forma síncrona para evitar problemas
  void _stopMusicSync() {
    try {
      _musicPlayer.stop();
      _isPlaying = false; // Forzar el estado para evitar inconsistencias
      debugPrint('🎵 🔴 Música detenida síncronamente');
    } catch (e) {
      debugPrint('❌ Error deteniendo música: $e');
      _isPlaying = false;
    }
  }

  /// Cambiar la pista de música de fondo
  Future<void> setMusicTrack(BackgroundMusicTrack track) async {
    if (_currentTrack == track) return;

    _currentTrack = track;
    await AppSettings.setBackgroundMusicTrack(track.name);
    
    if (_musicEnabled) {
      if (track == BackgroundMusicTrack.none) {
        await stopMusic();
      } else {
        await _playCurrentTrack();
      }
    }
    
    debugPrint('🎵 Pista de música cambiada a: ${track.displayName}');
  }

  /// Habilitar/deshabilitar música de fondo
  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabled == enabled) return;

    _musicEnabled = enabled;
    await AppSettings.setBackgroundMusicEnabled(enabled);
    
    if (enabled && _currentTrack != BackgroundMusicTrack.none) {
      await _playCurrentTrack();
    } else {
      await stopMusic();
    }
    
    debugPrint('🎵 Música de fondo ${enabled ? "habilitada" : "deshabilitada"}');
  }

  /// Detener la música
  Future<void> stopMusic() async {
    if (_isPlaying) {
      await _musicPlayer.stop();
      debugPrint('🎵 Música de fondo detenida');
    }
    _wasPlayingBeforePause = false; // También resetear cuando el usuario para manualmente
  }

  /// Reanudar la música
  Future<void> resumeMusic() async {
    if (_musicEnabled && _currentTrack != BackgroundMusicTrack.none && !_isPlaying) {
      await _playCurrentTrack();
      debugPrint('🎵 Música de fondo reanudada');
    }
  }

  /// Establecer volumen de la música
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_volume);
    await AppSettings.setBackgroundMusicVolume(_volume);
    debugPrint('🎵 Volumen de música establecido a: ${(_volume * 100).round()}%');
  }

  /// Convertir string a BackgroundMusicTrack
  BackgroundMusicTrack _parseTrackFromString(String trackName) {
    try {
      return BackgroundMusicTrack.values.firstWhere(
        (track) => track.name == trackName,
        orElse: () => BackgroundMusicTrack.lofi_piano,
      );
    } catch (e) {
      return BackgroundMusicTrack.lofi_piano;
    }
  }

  /// Recargar configuración desde AppSettings
  Future<void> reloadSettings() async {
    if (!_isInitialized) return;

    _musicEnabled = await AppSettings.getBackgroundMusicEnabled();
    final savedTrack = await AppSettings.getBackgroundMusicTrack();
    final newTrack = _parseTrackFromString(savedTrack);
    final savedVolume = await AppSettings.getBackgroundMusicVolume();
    
    if (savedVolume != _volume) {
      _volume = savedVolume;
      await _musicPlayer.setVolume(_volume);
    }
    
    if (newTrack != _currentTrack) {
      _currentTrack = newTrack;
      if (_musicEnabled) {
        await _playCurrentTrack();
      }
    }
    
    debugPrint('🔄 Configuración de música recargada: ${_musicEnabled ? "ON" : "OFF"}, Pista: ${_currentTrack.displayName}');
  }

  /// Método para debugging - obtener estado completo
  Map<String, dynamic> getDebugState() {
    return {
      'isInitialized': _isInitialized,
      'musicEnabled': _musicEnabled,
      'isPlaying': _isPlaying,
      'shouldBePlayingWhenResumed': _wasPlayingBeforePause,
      'currentTrack': _currentTrack.name,
      'volume': _volume,
    };
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    if (_isInitialized) {
      // Desregistrar observer del ciclo de vida
      WidgetsBinding.instance.removeObserver(this);
      
      await _musicPlayer.stop();
      await _musicPlayer.dispose();
      _isInitialized = false;
      _wasPlayingBeforePause = false;
      debugPrint('🎵 BackgroundMusicManager liberado');
    }
  }

  // Getters públicos
  BackgroundMusicTrack get currentTrack => _currentTrack;
  bool get isMusicEnabled => _musicEnabled;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  /// Obtener información de la pista actual
  Map<String, dynamic> get currentTrackInfo => {
    'track': _currentTrack.name,
    'displayName': _currentTrack.displayName,
    'emoji': _currentTrack.emoji,
    'description': _currentTrack.description,
    'enabled': _musicEnabled,
    'playing': _isPlaying,
  };
}

/// Extension para fácil acceso desde cualquier parte de la app
extension BackgroundMusicExtension on Object {
  BackgroundMusicManager get backgroundMusic => BackgroundMusicManager.instance;
}