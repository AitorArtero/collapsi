import 'package:flutter/material.dart';
import '../../config/ui_constants.dart';

/// Selector de opciones con diseño zen minimalista
class ZenOptionSelector<T> extends StatefulWidget {
  final List<T> options;
  final T selectedOption;
  final ValueChanged<T> onOptionSelected;
  final Widget Function(T option, bool isSelected) optionBuilder;
  final bool isHorizontal;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const ZenOptionSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.optionBuilder,
    this.isHorizontal = true,
    this.spacing = UIConstants.spacing12,
    this.padding,
  });

  @override
  State<ZenOptionSelector<T>> createState() => _ZenOptionSelectorState<T>();
}

class _ZenOptionSelectorState<T> extends State<ZenOptionSelector<T>>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );
    
    // Crear animaciones escalonadas para cada opción
    _itemAnimations = List.generate(
      widget.options.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          (index + 1) * 0.1 + 0.5,
          curve: AnimationConstants.easeOut,
        ),
      )),
    );
    
    // Iniciar animación
    Future.delayed(AnimationConstants.fast, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: widget.isHorizontal
          ? _buildHorizontalLayout()
          : _buildVerticalLayout(),
    );
  }

  Widget _buildHorizontalLayout() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _buildOptionWidgets(),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: _buildOptionWidgets(),
    );
  }

  List<Widget> _buildOptionWidgets() {
    final widgets = <Widget>[];
    
    for (int i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];
      final isSelected = option == widget.selectedOption;
      
      if (i > 0) {
        widgets.add(SizedBox(
          width: widget.isHorizontal ? widget.spacing : null,
          height: widget.isHorizontal ? null : widget.spacing,
        ));
      }
      
      widgets.add(
        AnimatedBuilder(
          animation: _itemAnimations[i],
          builder: (context, child) {
            return FadeTransition(
              opacity: _itemAnimations[i],
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: widget.isHorizontal 
                      ? const Offset(0.2, 0) 
                      : const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_itemAnimations[i]),
                child: _buildOptionItem(option, isSelected, i),
              ),
            );
          },
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildOptionItem(T option, bool isSelected, int index) {
    return TweenAnimationBuilder<double>(
      duration: AnimationConstants.fast,
      tween: Tween(begin: 1.0, end: 1.0),
      curve: AnimationConstants.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            child: InkWell(
              onTap: () => _selectOption(option),
              onTapDown: (_) => _animatePress(true),
              onTapUp: (_) => _animatePress(false),
              onTapCancel: () => _animatePress(false),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              splashFactory: NoSplash.splashFactory,
              child: AnimatedContainer(
                duration: AnimationConstants.fast,
                curve: AnimationConstants.easeInOut,
                child: widget.optionBuilder(option, isSelected),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectOption(T option) {
    if (option != widget.selectedOption) {
      widget.onOptionSelected(option);
      
      // Pequeña animación de feedback
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _animatePress(bool pressed) {
    // Esta función puede implementar animaciones de presión en el futuro
    // Por ahora mantenemos el diseño zen sin animaciones excesivas
  }
}

/// Variante simplificada para opciones de texto simple
class ZenTextOptionSelector extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onOptionSelected;
  final bool isHorizontal;
  final double spacing;

  const ZenTextOptionSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    this.isHorizontal = true,
    this.spacing = UIConstants.spacing12,
  });

  @override
  Widget build(BuildContext context) {
    return ZenOptionSelector<String>(
      options: options,
      selectedOption: selectedOption,
      onOptionSelected: onOptionSelected,
      isHorizontal: isHorizontal,
      spacing: spacing,
      optionBuilder: (option, isSelected) => _buildTextOption(option, isSelected),
    );
  }

  Widget _buildTextOption(String option, bool isSelected) {
    return AnimatedContainer(
      duration: AnimationConstants.fast,
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: UIConstants.spacing12,
      ),
      decoration: BoxDecoration(
        color: isSelected 
            ? UIColors.primary
            : UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: isSelected 
              ? UIColors.primary
              : UIColors.border,
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: UIColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        option,
        style: ZenTextStyles.body.copyWith(
          color: isSelected ? Colors.white : UIColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Variante para opciones con iconos
class ZenIconOptionSelector<T> extends StatelessWidget {
  final List<T> options;
  final T selectedOption;
  final ValueChanged<T> onOptionSelected;
  final IconData Function(T option) iconBuilder;
  final String Function(T option) labelBuilder;
  final bool isHorizontal;
  final double spacing;

  const ZenIconOptionSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.iconBuilder,
    required this.labelBuilder,
    this.isHorizontal = true,
    this.spacing = UIConstants.spacing16,
  });

  @override
  Widget build(BuildContext context) {
    return ZenOptionSelector<T>(
      options: options,
      selectedOption: selectedOption,
      onOptionSelected: onOptionSelected,
      isHorizontal: isHorizontal,
      spacing: spacing,
      optionBuilder: (option, isSelected) => _buildIconOption(option, isSelected),
    );
  }

  Widget _buildIconOption(T option, bool isSelected) {
    final icon = iconBuilder(option);
    final label = labelBuilder(option);
    
    return AnimatedContainer(
      duration: AnimationConstants.fast,
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: isSelected 
            ? UIColors.primary.withOpacity(0.1)
            : UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: isSelected 
              ? UIColors.primary
              : UIColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? UIColors.primary : UIColors.textSecondary,
            size: 32,
          ),
          const SizedBox(height: UIConstants.spacing8),
          Text(
            label,
            style: ZenTextStyles.caption.copyWith(
              color: isSelected ? UIColors.primary : UIColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}