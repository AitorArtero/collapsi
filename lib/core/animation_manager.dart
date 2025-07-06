import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/app_settings.dart';
import '../config/ui_constants.dart';

/// Gestor de animaciones de la aplicación
class AnimationManager {
  static AnimationManager? _instance;
  static AnimationManager get instance => _instance ??= AnimationManager._internal();
  
  AnimationManager._internal();

  bool _animationsEnabled = true;
  bool _isInitialized = false;

  /// Inicializar el gestor de animaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _animationsEnabled = await AppSettings.getAnimationsEnabled();
      _isInitialized = true;
      debugPrint('✨ AnimationManager inicializado - Animaciones: ${_animationsEnabled ? "ON" : "OFF"}');
    } catch (e) {
      debugPrint('❌ Error inicializando AnimationManager: $e');
      _isInitialized = false;
    }
  }

  /// Obtener duración de animación según configuración
  Duration getDuration(Duration defaultDuration) {
    if (!_animationsEnabled) return Duration.zero;
    return defaultDuration;
  }

  /// Obtener curva de animación según configuración
  Curve getCurve(Curve defaultCurve) {
    if (!_animationsEnabled) return Curves.linear;
    return defaultCurve;
  }

  /// Crear PageRouteBuilder con tipos genéricos
  PageRouteBuilder<T> createRoute<T extends Object?>(Widget page, {
    Duration? duration,
    RouteTransitionType type = RouteTransitionType.slide,
  }) {
    final animDuration = getDuration(duration ?? AnimationConstants.pageTransition);
    
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: animDuration,
      reverseTransitionDuration: animDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (!_animationsEnabled) {
          return child; // Sin animación
        }
        
        return _buildTransition(type, animation, secondaryAnimation, child);
      },
    );
  }

  /// Construir transición según el tipo
  Widget _buildTransition(
    RouteTransitionType type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case RouteTransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: getCurve(Curves.easeInOut),
          )),
          child: child,
        );
        
      case RouteTransitionType.fade:
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: getCurve(Curves.easeInOut),
          ),
          child: child,
        );
        
      case RouteTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: getCurve(Curves.easeOutCubic),
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
        
      case RouteTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: getCurve(Curves.easeOutCubic),
          )),
          child: child,
        );
    }
  }

  /// Crear AnimatedContainer con duración controlada
  Widget animatedContainer({
    required Widget child,
    Duration? duration,
    Curve? curve,
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Clip clipBehavior = Clip.none,
    VoidCallback? onEnd,
  }) {
    return AnimatedContainer(
      key: key,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      duration: getDuration(duration ?? AnimationConstants.fast),
      curve: getCurve(curve ?? Curves.easeInOut),
      clipBehavior: clipBehavior,
      onEnd: onEnd,
      child: child,
    );
  }

  /// Crear AnimatedOpacity con duración controlada
  Widget animatedOpacity({
    required Widget child,
    required double opacity,
    Duration? duration,
    Curve? curve,
    Key? key,
    VoidCallback? onEnd,
    bool alwaysIncludeSemantics = false,
  }) {
    return AnimatedOpacity(
      key: key,
      opacity: opacity,
      duration: getDuration(duration ?? AnimationConstants.fast),
      curve: getCurve(curve ?? Curves.easeInOut),
      onEnd: onEnd,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
      child: child,
    );
  }

  /// Crear AnimatedScale con duración controlada
  Widget animatedScale({
    required Widget child,
    required double scale,
    Duration? duration,
    Curve? curve,
    Key? key,
    Alignment? alignment,
    FilterQuality? filterQuality,
    VoidCallback? onEnd,
  }) {
    return AnimatedScale(
      key: key,
      scale: scale,
      duration: getDuration(duration ?? AnimationConstants.fast),
      curve: getCurve(curve ?? Curves.easeInOut),
      alignment: alignment ?? Alignment.center,
      filterQuality: filterQuality,
      onEnd: onEnd,
      child: child,
    );
  }

  /// Crear TweenAnimationBuilder con duración controlada
  Widget tweenAnimationBuilder<T>({
    required Tween<T> tween,
    required Widget Function(BuildContext context, T value, Widget? child) builder,
    Duration? duration,
    Curve? curve,
    Widget? child,
    Key? key,
    VoidCallback? onEnd,
  }) {
    return TweenAnimationBuilder<T>(
      key: key,
      tween: tween,
      duration: getDuration(duration ?? AnimationConstants.medium),
      curve: getCurve(curve ?? Curves.easeInOut),
      onEnd: onEnd,
      builder: builder,
      child: child,
    );
  }

  /// Habilitar/deshabilitar animaciones
  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    await AppSettings.setAnimationsEnabled(enabled);
    debugPrint('✨ Animaciones ${enabled ? "habilitadas" : "deshabilitadas"}');
  }

  /// Getters
  bool get isAnimationsEnabled => _animationsEnabled;
  bool get isInitialized => _isInitialized;

  /// Recargar configuración
  Future<void> reloadSettings() async {
    _animationsEnabled = await AppSettings.getAnimationsEnabled();
    debugPrint('🔄 Configuración de animaciones recargada: ${_animationsEnabled ? "ON" : "OFF"}');
  }
}

/// Tipos de transición para rutas
enum RouteTransitionType {
  slide,      // Deslizamiento horizontal
  fade,       // Desvanecimiento
  scale,      // Escalado con fade
  slideUp,    // Deslizamiento vertical
}

/// Extension con tipos genéricos
extension AnimationManagerExtension on BuildContext {
  AnimationManager get animationManager => AnimationManager.instance;
  
  /// Navegar con animación controlada
  Future<T?> pushWithAnimation<T extends Object?>(
    Widget page, {
    RouteTransitionType type = RouteTransitionType.slide,
    Duration? duration,
  }) {
    return Navigator.of(this).push<T>(
      AnimationManager.instance.createRoute<T>(
        page,
        duration: duration,
        type: type,
      ),
    );
  }

  /// Reemplazar con animación controlada
  Future<T?> pushReplacementWithAnimation<T extends Object?, TO extends Object?>(
    Widget page, {
    RouteTransitionType type = RouteTransitionType.slide,
    Duration? duration,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      AnimationManager.instance.createRoute<T>(
        page,
        duration: duration,
        type: type,
      ),
      result: result,
    );
  }
}