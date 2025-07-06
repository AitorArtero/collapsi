import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/ui_constants.dart';
import '../../config/theme_manager.dart';

class ZenPageScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? bottomSheet;
  final bool extendBodyBehindAppBar;

  const ZenPageScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.bottomSheet,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: context.themeManager,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor ?? UIColors.background,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          
          appBar: title != null || showBackButton || actions != null
              ? _buildZenAppBar(context)
              : null,
          
          body: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: UIColors.backgroundGradient,
              ),
              child: child,
            ),
          ),
          
          floatingActionButton: floatingActionButton,
          bottomSheet: bottomSheet,
        );
      },
    );
  }

  PreferredSizeWidget _buildZenAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: UIColors.currentTheme == AppTheme.dark 
          ? SystemUiOverlayStyle.light 
          : SystemUiOverlayStyle.dark,
      
      leading: showBackButton && Navigator.of(context).canPop()
          ? _buildBackButton(context)
          : null,
      
      title: title != null
          ? Text(
              title!,
              style: ZenTextStyles.heading.copyWith(
                fontWeight: FontWeight.w400,
              ),
            )
          : null,
      
      centerTitle: true,
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: UIConstants.spacing8),
            ]
          : null,
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: UIConstants.spacing8),
      child: Material(
        color: UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        elevation: 1,
        shadowColor: UIColors.shadow,
        child: InkWell(
          onTap: onBackPressed ?? () => Navigator.of(context).pop(),
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
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: UIColors.textSecondary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class ZenCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final Border? border;

  const ZenCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cardChild = Container(
      padding: padding ?? const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: backgroundColor ?? UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        border: border ?? Border.all(color: UIColors.borderLight, width: 1),
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: UIColors.shadow,
                  blurRadius: elevation! * 2,
                  offset: Offset(0, elevation!),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: UIConstants.spacing8),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
            splashFactory: NoSplash.splashFactory,
            child: cardChild,
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: UIConstants.spacing8),
      child: cardChild,
    );
  }
}

class ZenSpacer extends StatelessWidget {
  final double? height;
  final double? width;

  const ZenSpacer({
    super.key,
    this.height,
    this.width,
  });

  const ZenSpacer.small({super.key}) : height = UIConstants.spacing8, width = null;
  const ZenSpacer.medium({super.key}) : height = UIConstants.spacing16, width = null;
  const ZenSpacer.large({super.key}) : height = UIConstants.spacing32, width = null;
  const ZenSpacer.horizontal({super.key}) : height = null, width = UIConstants.spacing16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
    );
  }
}