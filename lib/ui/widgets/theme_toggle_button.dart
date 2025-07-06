import 'package:flutter/material.dart';
import '../../config/ui_constants.dart';
import '../../config/theme_manager.dart';

/// Widget para cambio rápido de tema
class ThemeToggleButton extends StatefulWidget {
  final bool showLabel;
  final MainAxisSize mainAxisSize;
  
  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConstants.themeTransition,
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
    if (widget.showLabel) {
      return _buildButtonWithLabel();
    } else {
      return _buildIconButton();
    }
  }

  Widget _buildIconButton() {
    final currentTheme = context.currentTheme;
    final info = ThemeManager.themeInfo[currentTheme]!;
    
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Material(
            color: UIColors.surface,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            elevation: 1,
            shadowColor: UIColors.shadow,
            child: InkWell(
              onTap: _cycleTheme,
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              splashFactory: NoSplash.splashFactory,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                  border: Border.all(
                    color: UIColors.borderLight,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    info.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonWithLabel() {
    final currentTheme = context.currentTheme;
    final info = ThemeManager.themeInfo[currentTheme]!;
    
    return Material(
      color: UIColors.surface,
      borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      elevation: 1,
      shadowColor: UIColors.shadow,
      child: InkWell(
        onTap: _cycleTheme,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        splashFactory: NoSplash.splashFactory,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing16,
            vertical: UIConstants.spacing12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            border: Border.all(
              color: UIColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: widget.mainAxisSize,
            children: [
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Text(
                      info.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                },
              ),
              const SizedBox(width: UIConstants.spacing8),
              Text(
                info.name,
                style: ZenTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: UIColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleTheme() async {
    _animationController.forward().then((_) {
      _animationController.reset();
    });
    
    await context.themeManager.cycleTheme();
  }
}

/// Widget para mostrar todos los temas disponibles en un menú desplegable
class ThemeSelector extends StatelessWidget {
  final bool isExpanded;
  
  const ThemeSelector({
    super.key,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.currentTheme;
    
    if (isExpanded) {
      return Container(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        decoration: BoxDecoration(
          color: UIColors.surface,
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
          border: Border.all(color: UIColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: UIColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tema Visual',
              style: ZenTextStyles.buttonLarge.copyWith(
                color: UIColors.primary,
              ),
            ),
            const SizedBox(height: UIConstants.spacing12),
            ...AppTheme.values.map((theme) {
              final info = ThemeManager.themeInfo[theme]!;
              final isSelected = theme == currentTheme;
              
              return Container(
                margin: const EdgeInsets.only(bottom: UIConstants.spacing8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                  child: InkWell(
                    onTap: () => _selectTheme(context, theme),
                    borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                    splashFactory: NoSplash.splashFactory,
                    child: Container(
                      padding: const EdgeInsets.all(UIConstants.spacing12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? info.preview.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                        border: isSelected
                            ? Border.all(color: info.preview, width: 1)
                            : Border.all(color: UIColors.borderLight, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            info.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: UIConstants.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info.name,
                                  style: ZenTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? info.preview : UIColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  info.description,
                                  style: ZenTextStyles.caption.copyWith(
                                    color: isSelected ? info.preview : UIColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: info.preview,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      );
    } else {
      return ThemeToggleButton(showLabel: true);
    }
  }

  void _selectTheme(BuildContext context, AppTheme theme) async {
    await context.themeManager.setTheme(theme);
  }
}