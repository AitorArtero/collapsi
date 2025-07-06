import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/menu_screen.dart';
import 'config/ui_constants.dart';
import 'config/theme_manager.dart';
import 'core/sound_manager.dart';
import 'core/haptic_manager.dart';
import 'core/animation_manager.dart';
import 'core/background_music_manager.dart';

void main() async {
  // Configurar orientación vertical para móvil
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar modo inmersivo completo
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Inicializar gestor de temas
  final themeManager = ThemeManager();
  await themeManager.initialize();
  
  // Inicializar gestores de experiencia de usuario (incluye música de fondo)
  await _initializeExperienceManagers();
  
  runApp(CollapsiApp(themeManager: themeManager));
}

/// Inicializar todos los gestores de experiencia de usuario
Future<void> _initializeExperienceManagers() async {
  try {
    // Inicializar en paralelo para mejor rendimiento
    await Future.wait([
      SoundManager.instance.initialize(),
      HapticManager.instance.initialize(),
      AnimationManager.instance.initialize(),
      BackgroundMusicManager.instance.initialize(),
    ]);
    
    debugPrint('✅ Todos los gestores de experiencia inicializados correctamente');
  } catch (e) {
    debugPrint('❌ Error inicializando gestores de experiencia: $e');
    // La app puede continuar funcionando sin estos gestores
  }
}

class CollapsiApp extends StatelessWidget {
  final ThemeManager themeManager;

  const CollapsiApp({
    super.key,
    required this.themeManager,
  });

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeManager: themeManager,
      child: AnimatedBuilder(
        animation: themeManager,
        builder: (context, child) {
          return MaterialApp(
            title: 'Collapsi',
            theme: themeManager.getFlutterThemeData(),
            home: const MenuScreen(),
            debugShowCheckedModeBanner: false,
            
            // Configurar transiciones de página con animationmanager
            onGenerateRoute: (settings) {
              return AnimationManager.instance.createRoute(
                const MenuScreen(), // Por defecto, devolver MenuScreen si no se encuentra la ruta
                type: RouteTransitionType.fade,
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget helper para manejar transiciones de tema con feedback
class ThemeTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  
  const ThemeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<ThemeTransition> createState() => _ThemeTransitionState();
}

class _ThemeTransitionState extends State<ThemeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ThemeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar animationmanager para controlar la duración
    // final duration = AnimationManager.instance.getDuration(widget.duration);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      },
    );
  }
}

/// Widget para mostrar preview de tema con feedback mejorado
class ThemePreview extends StatelessWidget {
  final AppTheme theme;
  final double size;
  final bool isSelected;
  
  const ThemePreview({
    super.key,
    required this.theme,
    this.size = 60,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final info = ThemeManager.themeInfo[theme]!;
    
    return GestureDetector(
      onTap: () async {
        // Feedback al seleccionar tema
        await HapticManager.instance.selection();
        await SoundManager.instance.playButtonTap();
      },
      child: AnimationManager.instance.animatedContainer(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 6),
          border: Border.all(
            color: isSelected 
                ? info.preview
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: info.preview.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 6 - 2),
          child: _buildThemePreview(theme, size),
        ),
      ),
    );
  }
  
  Widget _buildThemePreview(AppTheme theme, double size) {
    switch (theme) {
      case AppTheme.zen:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF8F9FA),
                Color(0xFF4299E1),
              ],
            ),
          ),
          child: const Center(
            child: Text('🧘', style: TextStyle(fontSize: 24)),
          ),
        );
        
      case AppTheme.dark:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0F0F),
                Color(0xFF1A1A1A),
                Color(0xFF60A5FA),
              ],
            ),
          ),
          child: const Center(
            child: Text('🌙', style: TextStyle(fontSize: 24)),
          ),
        );
        
      case AppTheme.neon:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F4FF),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
              ],
            ),
          ),
          child: const Center(
            child: Text('🌈', style: TextStyle(fontSize: 24)),
          ),
        );
    }
  }
}