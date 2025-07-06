import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ui_constants.dart';

/// Gestor de temas de la aplicación con feedback mejorado
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.neon;
  
  AppTheme get currentTheme => _currentTheme;
  
  /// Información sobre cada tema
  static const Map<AppTheme, ThemeInfo> themeInfo = {
    AppTheme.zen: ThemeInfo(
      name: 'Zen',
      description: 'Minimalista y relajante',
      emoji: '🧘',
      preview: Color(0xFF4299E1),
    ),
    AppTheme.dark: ThemeInfo(
      name: 'Oscuro',
      description: 'Elegante y moderno',
      emoji: '🌙',
      preview: Color(0xFF60A5FA),
    ),
    AppTheme.neon: ThemeInfo(
      name: 'Neón',
      description: 'Vibrante y energético',
      emoji: '🌈',
      preview: Color(0xFF8B5CF6),
    ),
  };
  
  /// Inicializar el gestor de temas
  Future<void> initialize() async {
    await _loadTheme();
  }
  
  /// Cargar tema guardado
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? AppTheme.neon.index;
      
      // Validar que el índice sea válido
      if (themeIndex >= 0 && themeIndex < AppTheme.values.length) {
        _currentTheme = AppTheme.values[themeIndex];
      } else {
        _currentTheme = AppTheme.neon;
      }
      
      // Aplicar tema a UIColors
      UIColors.setTheme(_currentTheme);
      notifyListeners();
    } catch (e) {
      // Si hay error, usar tema por defecto
      _currentTheme = AppTheme.neon;
      UIColors.setTheme(_currentTheme);
    }
  }
  
  /// Cambiar tema con feedback opcional
  Future<void> setTheme(AppTheme theme, {bool withFeedback = false}) async {
    if (_currentTheme == theme) return;
    
    _currentTheme = theme;
    UIColors.setTheme(theme);
    
    // Feedback opcional al cambiar tema
    if (withFeedback) {
      try {
        // Importar dinámicamente para evitar dependencias circulares
        final hapticManager = await _getHapticManager();
        final soundManager = await _getSoundManager();
        
        await hapticManager?.themeChange();
        await soundManager?.playThemeChange();
      } catch (e) {
        debugPrint('⚠️ Error aplicando feedback de tema: $e');
      }
    }
    
    // Guardar en preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      debugPrint('Error guardando tema: $e');
    }
    
    notifyListeners();
  }
  
  /// Obtener HapticManager dinámicamente
  Future<dynamic> _getHapticManager() async {
    try {
      // Usar reflection para evitar dependencia circular
      final Type? hapticManagerType = _findType('HapticManager');
      if (hapticManagerType != null) {
        final dynamic instance = _getStaticProperty(hapticManagerType, 'instance');
        return instance;
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo acceder a HapticManager: $e');
    }
    return null;
  }
  
  /// Obtener SoundManager dinámicamente
  Future<dynamic> _getSoundManager() async {
    try {
      // Usar reflection para evitar dependencia circular
      final Type? soundManagerType = _findType('SoundManager');
      if (soundManagerType != null) {
        final dynamic instance = _getStaticProperty(soundManagerType, 'instance');
        return instance;
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo acceder a SoundManager: $e');
    }
    return null;
  }
  
  /// Helper para buscar tipos dinámicamente
  Type? _findType(String typeName) {
    // En un entorno real, podrías usar mirrors o registrar los tipos
    // Por ahora, devolvemos null para evitar errores
    return null;
  }
  
  /// Helper para obtener propiedades estáticas
  dynamic _getStaticProperty(Type type, String propertyName) {
    // En un entorno real, usarías mirrors
    // Por ahora, devolvemos null
    return null;
  }
  
  /// Obtener el siguiente tema (para cambio rápido)
  AppTheme getNextTheme() {
    final currentIndex = _currentTheme.index;
    final nextIndex = (currentIndex + 1) % AppTheme.values.length;
    return AppTheme.values[nextIndex];
  }
  
  /// Cambiar al siguiente tema con feedback
  Future<void> cycleTheme({bool withFeedback = true}) async {
    await setTheme(getNextTheme(), withFeedback: withFeedback);
  }
  
  /// Obtener ThemeData de Flutter según el tema actual
  ThemeData getFlutterThemeData() {
    return _buildThemeData(_currentTheme);
  }
  
  /// Construir ThemeData específico para un tema
  ThemeData _buildThemeData(AppTheme theme) {
    // Temporalmente establecer el tema para obtener los colores
    final originalTheme = _currentTheme;
    UIColors.setTheme(theme);
    
    final themeData = ThemeData(
      // Color scheme adaptativo
      colorScheme: ColorScheme.light(
        brightness: theme == AppTheme.dark ? Brightness.dark : Brightness.light,
        primary: UIColors.primary,
        secondary: UIColors.primaryLight,
        surface: UIColors.surface,
        background: UIColors.background,
        error: UIColors.error,
        onPrimary: theme == AppTheme.dark ? Colors.black : Colors.white,
        onSecondary: UIColors.textPrimary,
        onSurface: UIColors.textPrimary,
        onBackground: UIColors.textPrimary,
        onError: Colors.white,
      ),
      
      // Tipografía con fuente del sistema
      fontFamily: 'SF Pro Display',
      
      // Material Design 3
      useMaterial3: true,
      
      // AppBar theme adaptativo
      appBarTheme: AppBarTheme(
        backgroundColor: UIColors.background,
        foregroundColor: UIColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: ZenTextStyles.heading,
        iconTheme: IconThemeData(
          color: UIColors.textSecondary,
          size: 24,
        ),
      ),
      
      // Scaffold theme
      scaffoldBackgroundColor: UIColors.background,
      
      // Elevated Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UIColors.buttonPrimary,
          foregroundColor: theme == AppTheme.dark ? Colors.black : Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
          minimumSize: const Size(double.infinity, UIConstants.buttonHeight),
          textStyle: ZenTextStyles.buttonLarge,
          splashFactory: NoSplash.splashFactory,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return UIColors.ripple;
              }
              return null;
            },
          ),
        ),
      ),
      
      // Text Button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UIColors.textSecondary,
          textStyle: ZenTextStyles.body,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
          ),
          minimumSize: const Size(0, UIConstants.buttonHeightSmall),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: UIColors.surface,
        elevation: UIConstants.cardElevation,
        shadowColor: UIColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        ),
        margin: const EdgeInsets.all(UIConstants.spacing8),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: UIColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        ),
        titleTextStyle: ZenTextStyles.heading,
        contentTextStyle: ZenTextStyles.body,
      ),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: UIColors.textSecondary,
        size: 24,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return UIColors.primary;
          }
          return UIColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return UIColors.primary.withOpacity(0.5);
          }
          return UIColors.border;
        }),
      ),
    );
    
    // Restaurar tema original
    UIColors.setTheme(originalTheme);
    
    return themeData;
  }
  
  /// Verificar si es tema oscuro
  bool get isDark => _currentTheme == AppTheme.dark;
  
  /// Verificar si es tema colorido
  bool get isColorful => _currentTheme == AppTheme.neon;
  
  /// Verificar si es tema zen
  bool get isZen => _currentTheme == AppTheme.zen;
  
  /// Obtener información del tema actual
  ThemeInfo get currentThemeInfo => themeInfo[_currentTheme]!;
  
  /// Verificar si un tema está disponible
  bool isThemeAvailable(AppTheme theme) => themeInfo.containsKey(theme);
  
  /// Obtener lista de temas disponibles
  List<AppTheme> get availableThemes => AppTheme.values;
}

/// Información sobre un tema
class ThemeInfo {
  final String name;
  final String description;
  final String emoji;
  final Color preview;
  
  const ThemeInfo({
    required this.name,
    required this.description,
    required this.emoji,
    required this.preview,
  });
  
  /// Convertir a Map para debugging
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'emoji': emoji,
      'preview': '#${preview.value.toRadixString(16).padLeft(8, '0')}',
    };
  }
}

/// Widget provider para el gestor de temas
class ThemeProvider extends InheritedNotifier<ThemeManager> {
  const ThemeProvider({
    super.key,
    required ThemeManager themeManager,
    required super.child,
  }) : super(notifier: themeManager);
  
  static ThemeManager? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()?.notifier;
  }
  
  static ThemeManager of2(BuildContext context) {
    final result = of(context);
    assert(result != null, 'No ThemeProvider found in context');
    return result!;
  }
}

/// Extension para fácil acceso al theme manager
extension ThemeContext on BuildContext {
  ThemeManager get themeManager => ThemeProvider.of2(this);
  AppTheme get currentTheme => themeManager.currentTheme;
  bool get isDarkTheme => themeManager.isDark;
  bool get isColorfulTheme => themeManager.isColorful;
  ThemeInfo get currentThemeInfo => themeManager.currentThemeInfo;
}