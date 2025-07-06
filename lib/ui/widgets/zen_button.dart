import 'package:flutter/material.dart';
import '../../config/ui_constants.dart';
import '../../core/haptic_manager.dart';
import '../../core/sound_manager.dart';

/// Variantes del botón zen
enum ZenButtonVariant {
  primary,     // Botón principal con color de acción
  secondary,   // Botón secundario con borde
  text,        // Botón de texto sin fondo
  destructive, // Botón para acciones destructivas
}

/// Tamaños del botón zen
enum ZenButtonSize {
  small,  // Para acciones menores
  medium, // Tamaño estándar
  large,  // Para acciones principales
}

/// Botón personalizado con diseño zen minimalista y feedback mejorado
class ZenButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ZenButtonVariant variant;
  final ZenButtonSize size;
  final IconData? icon;
  final bool iconAfter;
  final bool fullWidth;
  final bool loading;
  final bool enableFeedback; // Controlar si tiene feedback

  const ZenButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ZenButtonVariant.primary,
    this.size = ZenButtonSize.medium,
    this.icon,
    this.iconAfter = false,
    this.fullWidth = false,
    this.loading = false,
    this.enableFeedback = true, // Por defecto habilitado
  });

  @override
  State<ZenButton> createState() => _ZenButtonState();
}

class _ZenButtonState extends State<ZenButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConstants.buttonPress,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConstants.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildButton(),
        );
      },
    );
  }

  Widget _buildButton() {
    final isEnabled = widget.onPressed != null && !widget.loading;
    final colors = _getColors();
    final dimensions = _getDimensions();

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: dimensions.height,
      child: Material(
        color: colors.background,
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
        elevation: _getElevation(),
        shadowColor: colors.shadowColor,
        child: InkWell(
          onTap: isEnabled ? () => _handleTap() : null,
          onTapDown: isEnabled ? (_) => _handleTapDown() : null,
          onTapUp: isEnabled ? (_) => _handleTapUp() : null,
          onTapCancel: isEnabled ? () => _handleTapUp() : null,
          borderRadius: BorderRadius.circular(dimensions.borderRadius),
          splashFactory: NoSplash.splashFactory,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(dimensions.borderRadius),
              border: colors.borderColor != null
                  ? Border.all(color: colors.borderColor!, width: 1)
                  : null,
            ),
            child: Center(
              child: widget.loading
                  ? _buildLoadingIndicator(colors)
                  : _buildContent(colors, dimensions),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(_ButtonColors colors, _ButtonDimensions dimensions) {
    final textStyle = TextStyle(
      fontSize: dimensions.fontSize,
      fontWeight: dimensions.fontWeight,
      color: colors.foreground,
      letterSpacing: 0.1,
    );

    if (widget.icon == null) {
      return Text(widget.text, style: textStyle);
    }

    final iconSize = dimensions.fontSize;
    final icon = Icon(
      widget.icon,
      size: iconSize,
      color: colors.foreground,
    );

    final text = Text(widget.text, style: textStyle);
    const spacing = SizedBox(width: UIConstants.spacing8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.iconAfter
          ? [text, spacing, icon]
          : [icon, spacing, text],
    );
  }

  Widget _buildLoadingIndicator(_ButtonColors colors) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
      ),
    );
  }

  _ButtonColors _getColors() {
    final isEnabled = widget.onPressed != null && !widget.loading;
    
    switch (widget.variant) {
      case ZenButtonVariant.primary:
        return _ButtonColors(
          background: isEnabled ? UIColors.primary : UIColors.buttonDisabled,
          foreground: isEnabled ? Colors.white : UIColors.textHint,
          shadowColor: UIColors.primary.withOpacity(0.3),
        );
        
      case ZenButtonVariant.secondary:
        return _ButtonColors(
          background: isEnabled ? UIColors.surface : UIColors.surfaceVariant,
          foreground: isEnabled ? UIColors.textPrimary : UIColors.textHint,
          borderColor: isEnabled ? UIColors.border : UIColors.borderLight,
          shadowColor: UIColors.shadow,
        );
        
      case ZenButtonVariant.text:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: isEnabled ? UIColors.textSecondary : UIColors.textHint,
        );
        
      case ZenButtonVariant.destructive:
        return _ButtonColors(
          background: isEnabled ? UIColors.error : UIColors.buttonDisabled,
          foreground: isEnabled ? Colors.white : UIColors.textHint,
          shadowColor: UIColors.error.withOpacity(0.3),
        );
    }
  }

  _ButtonDimensions _getDimensions() {
    switch (widget.size) {
      case ZenButtonSize.small:
        return _ButtonDimensions(
          height: UIConstants.buttonHeightSmall,
          fontSize: UIConstants.fontSizeSmall,
          fontWeight: FontWeight.w500,
          borderRadius: UIConstants.radiusSmall,
        );
        
      case ZenButtonSize.medium:
        return _ButtonDimensions(
          height: UIConstants.buttonHeight,
          fontSize: UIConstants.fontSizeMedium,
          fontWeight: FontWeight.w500,
          borderRadius: UIConstants.radiusMedium,
        );
        
      case ZenButtonSize.large:
        return _ButtonDimensions(
          height: UIConstants.buttonHeight + 8,
          fontSize: UIConstants.fontSizeLarge,
          fontWeight: FontWeight.w600,
          borderRadius: UIConstants.radiusMedium,
        );
    }
  }

  double _getElevation() {
    if (widget.variant == ZenButtonVariant.text) return 0;
    if (widget.variant == ZenButtonVariant.secondary) return 1;
    return _isPressed ? 1 : 2;
  }

  /// Manejar tap con feedback completo
  Future<void> _handleTap() async {
    if (widget.enableFeedback) {
      // Feedback según el tipo de botón
      if (widget.variant == ZenButtonVariant.destructive) {
        await HapticManager.instance.error();
      } else {
        await HapticManager.instance.buttonTap();
      }
      
      await SoundManager.instance.playButtonTap();
    }
    
    // Ejecutar callback original
    widget.onPressed?.call();
  }

  void _handleTapDown() {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
}

/// Clase para almacenar colores del botón
class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final Color? shadowColor;

  _ButtonColors({
    required this.background,
    required this.foreground,
    this.borderColor,
    this.shadowColor,
  });
}

/// Clase para almacenar dimensiones del botón
class _ButtonDimensions {
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;

  _ButtonDimensions({
    required this.height,
    required this.fontSize,
    required this.fontWeight,
    required this.borderRadius,
  });
}