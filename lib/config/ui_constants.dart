import 'package:flutter/material.dart';

/// Tipos de tema disponibles
enum AppTheme {
  zen,
  dark,
  neon,
}

/// Tamaños adaptativos para diseño zen
class UIConstants {
  // Tamaños de celda y elementos del juego
  static const double cellSize = 80.0;
  static const double cellPadding = 4.0;
  static const double gridPadding = 20.0;
  
  // Tipografía zen - jerarquía clara
  static const double fontSizeTitle = 32.0;      // Títulos principales
  static const double fontSizeHeading = 24.0;    // Subtítulos
  static const double fontSizeLarge = 20.0;      // Botones importantes
  static const double fontSizeMedium = 16.0;     // Texto normal
  static const double fontSizeSmall = 14.0;      // Texto secundario
  static const double fontSizeCaption = 12.0;    // Captions y hints
  
  // Espaciado zen - ritmo visual
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  
  // Radios de borde - suavidad
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Alturas de elementos
  static const double buttonHeight = 56.0;
  static const double buttonHeightSmall = 44.0;
  static const double cardElevation = 2.0;
  
  // Breakpoints responsivos
  static const double phoneBreakpoint = 400.0;
  static const double tabletBreakpoint = 600.0;
}

/// Sistema de colores adaptativo según el tema
class UIColors {
  static AppTheme _currentTheme = AppTheme.zen;
  
  static void setTheme(AppTheme theme) {
    _currentTheme = theme;
  }
  
  static AppTheme get currentTheme => _currentTheme;
  
  // Getters adaptativos que cambian según el tema
  static Color get background => _getColor('background');
  static Color get surface => _getColor('surface');
  static Color get surfaceVariant => _getColor('surfaceVariant');
  
  static Color get textPrimary => _getColor('textPrimary');
  static Color get textSecondary => _getColor('textSecondary');
  static Color get textTertiary => _getColor('textTertiary');
  static Color get textHint => _getColor('textHint');
  
  static Color get primary => _getColor('primary');
  static Color get primaryLight => _getColor('primaryLight');
  static Color get primaryDark => _getColor('primaryDark');
  
  static Color get player1 => _getColor('player1');
  static Color get player2 => _getColor('player2');
  static Color get player1Light => _getColor('player1Light');
  static Color get player2Light => _getColor('player2Light');
  
  static Color get success => _getColor('success');
  static Color get warning => _getColor('warning');
  static Color get error => _getColor('error');
  static Color get info => _getColor('info');
  
  static Color get border => _getColor('border');
  static Color get borderLight => _getColor('borderLight');
  static Color get shadow => _getColor('shadow');
  static Color get overlay => _getColor('overlay');
  
  static Color get buttonPrimary => _getColor('buttonPrimary');
  static Color get buttonSecondary => _getColor('buttonSecondary');
  static Color get buttonDisabled => _getColor('buttonDisabled');
  static Color get ripple => _getColor('ripple');
  
  static Color get validMove => _getColor('validMove');
  static Color get gridBackground => _getColor('gridBackground');
  static Color get cellEmpty => _getColor('cellEmpty');
  static Color get cellBorder => _getColor('cellBorder');
  
  // Método interno para obtener color según tema actual con fallback
  static Color _getColor(String colorKey) {
    Map<String, Color> colorMap;
    
    switch (_currentTheme) {
      case AppTheme.zen:
        colorMap = _zenColors;
        break;
      case AppTheme.dark:
        colorMap = _darkColors;
        break;
      case AppTheme.neon:
        colorMap = _neonColors;
        break;
    }
    
    return colorMap[colorKey] ?? _zenColors[colorKey] ?? const Color(0xFF4299E1);
  }
  
  // TEMA ZEN
  static final Map<String, Color> _zenColors = {
    'background': const Color(0xFFF8F9FA),
    'surface': const Color(0xFFFFFFFF),
    'surfaceVariant': const Color(0xFFF1F3F4),

    'textPrimary': const Color(0xFF2D3748),
    'textSecondary': const Color(0xFF4A5568),
    'textTertiary': const Color(0xFF718096),
    'textHint': const Color(0xFFA0AEC0),

    'primary': const Color(0xFF2B6CB0),
    'primaryLight': const Color(0xFF4299E1),
    'primaryDark': const Color(0xFF1A5490),

    'player1': const Color(0xFF2B6CB0),
    'player2': const Color(0xFFE53E3E),
    'player1Light': const Color(0xFFBEE3F8),
    'player2Light': const Color(0xFFFED7D7),

    'success': const Color(0xFF2F855A),
    'warning': const Color(0xFFB7791F),
    'error': const Color(0xFFE53E3E),
    'info': const Color(0xFF2C5282),

    'border': const Color(0xFFE2E8F0),
    'borderLight': const Color(0xFFF7FAFC),
    'shadow': const Color(0x1A000000),
    'overlay': const Color(0x80000000),

    'buttonPrimary': const Color(0xFF2B6CB0),
    'buttonSecondary': const Color(0xFFF7FAFC),
    'buttonDisabled': const Color(0xFFE2E8F0),
    'ripple': const Color(0x1F2B6CB0),

    'validMove': const Color(0x3F2B6CB0),
    'gridBackground': const Color(0xFFF1F3F4),
    'cellEmpty': const Color(0xFFFFFFFF),
    'cellBorder': const Color(0xFFE2E8F0),
  };

  // TEMA OSCURO
  static final Map<String, Color> _darkColors = {
    'background': const Color(0xFF0F0F0F),
    'surface': const Color(0xFF1A1A1A),
    'surfaceVariant': const Color(0xFF2D2D2D),

    'textPrimary': const Color(0xFFFFFFFF),
    'textSecondary': const Color(0xFFE0E0E0),
    'textTertiary': const Color(0xFFB0B0B0),
    'textHint': const Color(0xFF808080),

    'primary': const Color(0xFF93C5FD),
    'primaryLight': const Color(0xFFBFDBFE),
    'primaryDark': const Color(0xFF60A5FA),

    'player1': const Color(0xFF93C5FD),
    'player2': const Color(0xFFF87171),
    'player1Light': const Color(0xFF1E3A8A),
    'player2Light': const Color(0xFF991B1B),

    'success': const Color(0xFF34D399),
    'warning': const Color(0xFFFBBF24),
    'error': const Color(0xFFEF4444),
    'info': const Color(0xFF06B6D4),

    'border': const Color(0xFF374151),
    'borderLight': const Color(0xFF4B5563),
    'shadow': const Color(0x40000000),
    'overlay': const Color(0xCC000000),

    'buttonPrimary': const Color(0xFF93C5FD),
    'buttonSecondary': const Color(0xFF374151),
    'buttonDisabled': const Color(0xFF4B5563),
    'ripple': const Color(0x1F93C5FD),

    'validMove': const Color(0x4093C5FD),
    'gridBackground': const Color(0xFF2D2D2D),
    'cellEmpty': const Color(0xFF1A1A1A),
    'cellBorder': const Color(0xFF374151),
  };

  // TEMA NEÓN
  static final Map<String, Color> _neonColors = {
    'background': const Color(0xFFF8F4FF),
    'surface': const Color(0xFFFFFFFF),
    'surfaceVariant': const Color(0xFFF1E6FF),

    'textPrimary': const Color(0xFF1A1A2E),
    'textSecondary': const Color(0xFF16213E),
    'textTertiary': const Color(0xFF533483),
    'textHint': const Color(0xFF9B59B6),

    'primary': const Color(0xFF7C3AED),
    'primaryLight': const Color(0xFF8B5CF6),
    'primaryDark': const Color(0xFF6D28D9),

    'player1': const Color(0xFF0891B2),
    'player2': const Color(0xFFDB2777),
    'player1Light': const Color(0xFFCFFAFE),
    'player2Light': const Color(0xFFFCE7F3),

    'success': const Color(0xFF059669),
    'warning': const Color(0xFFD97706),
    'error': const Color(0xFFDC2626),
    'info': const Color(0xFF2563EB),

    'border': const Color(0xFFD8B4FE),
    'borderLight': const Color(0xFFEDE9FE),
    'shadow': const Color(0x20000000),
    'overlay': const Color(0x80000000),

    'buttonPrimary': const Color(0xFF7C3AED),
    'buttonSecondary': const Color(0xFFEDE9FE),
    'buttonDisabled': const Color(0xFFD8B4FE),
    'ripple': const Color(0x1F7C3AED),

    'validMove': const Color(0x407C3AED),
    'gridBackground': const Color(0xFFF1E6FF),
    'cellEmpty': const Color(0xFFFFFFFF),
    'cellBorder': const Color(0xFFD8B4FE),
  };
  
  // Gradientes adaptativos
  static LinearGradient get primaryGradient {
    switch (_currentTheme) {
      case AppTheme.zen:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4299E1), Color(0xFF3182CE)],
        );
      case AppTheme.dark:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
        );
      case AppTheme.neon:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        );
    }
  }
  
  static LinearGradient get backgroundGradient {
    switch (_currentTheme) {
      case AppTheme.zen:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
        );
      case AppTheme.dark:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
        );
      case AppTheme.neon:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F4FF), Color(0xFFF1E6FF)],
        );
    }
  }
}

/// Configuración de animaciones zen - suaves y naturales
class AnimationConstants {
  // Duraciones siguiendo principios de material design pero más suaves
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);      // Para feedback inmediato
  static const Duration medium = Duration(milliseconds: 250);    // Para transiciones normales
  static const Duration slow = Duration(milliseconds: 350);     // Para cambios importantes
  static const Duration verySlow = Duration(milliseconds: 500); // Para animaciones destacadas
  static const Duration extremelySlow = Duration(milliseconds: 1000); // Para animaciones destacadas
  
  // Curvas de animación zen - naturales y orgánicas
  static const Curve easeOut = Curves.easeOut;           // Para entrada de elementos
  static const Curve easeIn = Curves.easeIn;             // Para salida de elementos
  static const Curve easeInOut = Curves.easeInOut;       // Para transformaciones
  static const Curve bounce = Curves.elasticOut;         // Para feedback positivo
  static const Curve gentle = Curves.decelerate;         // Para movimientos suaves
  
  // Configuraciones específicas
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration modalAnimation = Duration(milliseconds: 250);
  static const Duration tooltipAnimation = Duration(milliseconds: 150);
  static const Duration themeTransition = Duration(milliseconds: 400);
  
  // Distancias para gestos
  static const double minTouchDistance = 10.0;
  static const double swipeThreshold = 100.0;
}

/// Tipografía adaptativa según el tema
class ZenTextStyles {
  // Base font family
  static const String fontFamily = 'SF Pro Display'; // Fallback a system font
  
  // Títulos principales
  static TextStyle get title => TextStyle(
    fontSize: UIConstants.fontSizeTitle,
    fontWeight: FontWeight.w300,  // Light weight para elegancia
    color: UIColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  // Subtítulos
  static TextStyle get heading => TextStyle(
    fontSize: UIConstants.fontSizeHeading,
    fontWeight: FontWeight.w400,  // Regular weight
    color: UIColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  // Botones importantes
  static TextStyle get buttonLarge => TextStyle(
    fontSize: UIConstants.fontSizeLarge,
    fontWeight: FontWeight.w500,  // Medium weight para claridad
    color: UIColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.2,
  );
  
  // Texto normal
  static TextStyle get body => TextStyle(
    fontSize: UIConstants.fontSizeMedium,
    fontWeight: FontWeight.w400,
    color: UIColors.textPrimary,
    letterSpacing: 0.0,
    height: 1.5,
  );
  
  // Texto secundario
  static TextStyle get bodySecondary => TextStyle(
    fontSize: UIConstants.fontSizeMedium,
    fontWeight: FontWeight.w400,
    color: UIColors.textSecondary,
    letterSpacing: 0.0,
    height: 1.5,
  );
  
  // Texto pequeño
  static TextStyle get caption => TextStyle(
    fontSize: UIConstants.fontSizeSmall,
    fontWeight: FontWeight.w400,
    color: UIColors.textTertiary,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  // Hints y placeholders
  static TextStyle get hint => TextStyle(
    fontSize: UIConstants.fontSizeCaption,
    fontWeight: FontWeight.w400,
    color: UIColors.textHint,
    letterSpacing: 0.2,
    height: 1.3,
  );
}

/// Sombras adaptativas según el tema
class ZenShadows {
  static BoxShadow get subtle => BoxShadow(
    color: UIColors.shadow,
    blurRadius: 4,
    offset: const Offset(0, 2),
  );
  
  static BoxShadow get medium => BoxShadow(
    color: UIColors.shadow,
    blurRadius: 8,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow get elevated => BoxShadow(
    color: UIColors.shadow,
    blurRadius: 16,
    offset: const Offset(0, 8),
  );
  
  static List<BoxShadow> get card => [
    BoxShadow(
      color: UIColors.shadow.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: UIColors.shadow.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get button => [
    BoxShadow(
      color: UIColors.shadow.withOpacity(0.1),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
}