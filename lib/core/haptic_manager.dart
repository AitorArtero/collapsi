import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../config/app_settings.dart';

/// Tipos de feedback háptico
enum HapticType {
  // Para el juego
  cellTap,        // Tocar celda del juego
  moveSuccess,    // Movimiento exitoso
  moveInvalid,    // Movimiento inválido
  gameWin,        // Victoria
  gameLose,       // Derrota
  undoMove,       // Deshacer movimiento
  
  // Para la UI/App
  buttonTap,      // Tocar botón
  switchToggle,   // Cambiar switch/configuración
  themeChange,    // Cambio de tema
  navigation,     // Navegación entre pantallas
  selection,      // Seleccionar opción
  error,          // Error en la UI
}

/// Gestor de feedback háptico (vibración)
class HapticManager {
  static HapticManager? _instance;
  static HapticManager get instance => _instance ??= HapticManager._internal();
  
  HapticManager._internal();

  // Estados de configuración
  bool _gameHapticsEnabled = true;
  bool _appHapticsEnabled = true;
  bool _isInitialized = false;

  /// Inicializar el gestor de vibración
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Cargar configuraciones
      _gameHapticsEnabled = await AppSettings.getGameHapticsEnabled();
      _appHapticsEnabled = await AppSettings.getAppHapticsEnabled();
      
      _isInitialized = true;
      debugPrint('📳 HapticManager inicializado');
      debugPrint('   🎮 Juego: ${_gameHapticsEnabled ? "ON" : "OFF"}');
      debugPrint('   📱 App: ${_appHapticsEnabled ? "ON" : "OFF"}');
    } catch (e) {
      debugPrint('❌ Error inicializando HapticManager: $e');
      _isInitialized = false;
    }
  }

  /// Ejecutar feedback háptico según el tipo
  Future<void> performHaptic(HapticType type) async {
    if (!_isInitialized) return;

    // Verificar si el tipo de háptico está habilitado
    if (!_shouldPerformHaptic(type)) return;

    try {
      switch (type) {
        // HÁPTICOS DEL JUEGO
        case HapticType.cellTap:
        case HapticType.moveSuccess:
          await HapticFeedback.lightImpact();
          break;
          
        case HapticType.moveInvalid:
        case HapticType.undoMove:
          await HapticFeedback.mediumImpact();
          break;
          
        case HapticType.gameWin:
          // Vibración especial para victoria (doble vibración)
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          break;
          
        case HapticType.gameLose:
          await HapticFeedback.heavyImpact();
          break;

        // HÁPTICOS DE LA APP
        case HapticType.buttonTap:
        case HapticType.selection:
        case HapticType.navigation:
          await HapticFeedback.selectionClick();
          break;
          
        case HapticType.switchToggle:
        case HapticType.themeChange:
          await HapticFeedback.lightImpact();
          break;
          
        case HapticType.error:
          await HapticFeedback.mediumImpact();
          break;
      }
      
      debugPrint('📳 Háptico ejecutado: ${type.name}');
    } catch (e) {
      debugPrint('❌ Error ejecutando háptico ${type.name}: $e');
    }
  }

  /// Verificar si debe ejecutar el háptico según configuración
  bool _shouldPerformHaptic(HapticType type) {
    switch (type) {
      case HapticType.cellTap:
      case HapticType.moveSuccess:
      case HapticType.moveInvalid:
      case HapticType.gameWin:
      case HapticType.gameLose:
      case HapticType.undoMove:
        return _gameHapticsEnabled;
        
      case HapticType.buttonTap:
      case HapticType.switchToggle:
      case HapticType.themeChange:
      case HapticType.navigation:
      case HapticType.selection:
      case HapticType.error:
        return _appHapticsEnabled;
    }
  }

  /// Métodos de conveniencia para el JUEGO

  /// Vibración al tocar celda del juego
  Future<void> cellTap() async {
    await performHaptic(HapticType.cellTap);
  }

  /// Vibración al hacer movimiento exitoso
  Future<void> moveSuccess() async {
    await performHaptic(HapticType.moveSuccess);
  }

  /// Vibración al hacer movimiento inválido
  Future<void> moveInvalid() async {
    await performHaptic(HapticType.moveInvalid);
  }

  /// Vibración al ganar el juego
  Future<void> gameWin() async {
    await performHaptic(HapticType.gameWin);
  }

  /// Vibración al perder el juego
  Future<void> gameLose() async {
    await performHaptic(HapticType.gameLose);
  }

  /// Vibración al deshacer movimiento
  Future<void> undoMove() async {
    await performHaptic(HapticType.undoMove);
  }

  /// Métodos de conveniencia para la APP

  /// Vibración al tocar botón de UI
  Future<void> buttonTap() async {
    await performHaptic(HapticType.buttonTap);
  }

  /// Vibración al cambiar switch/configuración
  Future<void> switchToggle() async {
    await performHaptic(HapticType.switchToggle);
  }

  /// Vibración al cambiar tema
  Future<void> themeChange() async {
    await performHaptic(HapticType.themeChange);
  }

  /// Vibración al navegar entre pantallas
  Future<void> navigation() async {
    await performHaptic(HapticType.navigation);
  }

  /// Vibración al seleccionar opción
  Future<void> selection() async {
    await performHaptic(HapticType.selection);
  }

  /// Vibración de error
  Future<void> error() async {
    await performHaptic(HapticType.error);
  }

  /// Configuración para hápticos del juego
  Future<void> setGameHapticsEnabled(bool enabled) async {
    _gameHapticsEnabled = enabled;
    await AppSettings.setGameHapticsEnabled(enabled);
    debugPrint('📳 Hápticos del juego ${enabled ? "habilitados" : "deshabilitados"}');
  }

  /// Configuración para hápticos de la app
  Future<void> setAppHapticsEnabled(bool enabled) async {
    _appHapticsEnabled = enabled;
    await AppSettings.setAppHapticsEnabled(enabled);
    debugPrint('📳 Hápticos de la app ${enabled ? "habilitados" : "deshabilitados"}');
  }

  /// Getters de estado
  bool get isGameHapticsEnabled => _gameHapticsEnabled;
  bool get isAppHapticsEnabled => _appHapticsEnabled;
  bool get isInitialized => _isInitialized;

  /// Recargar configuración desde AppSettings
  Future<void> reloadSettings() async {
    _gameHapticsEnabled = await AppSettings.getGameHapticsEnabled();
    _appHapticsEnabled = await AppSettings.getAppHapticsEnabled();
    debugPrint('🔄 Configuración háptica recargada');
    debugPrint('   🎮 Juego: ${_gameHapticsEnabled ? "ON" : "OFF"}');
    debugPrint('   📱 App: ${_appHapticsEnabled ? "ON" : "OFF"}');
  }
}

/// Extension para fácil acceso desde cualquier parte de la app
extension HapticManagerExtension on Object {
  HapticManager get hapticManager => HapticManager.instance;
}