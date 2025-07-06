import 'package:flutter/material.dart';
import '../../config/ui_constants.dart';
import '../../core/tournament_manager.dart';
import '../screens/game_screen.dart';
import 'zen_button.dart';
import 'zen_page_scaffold.dart';

/// Diálogo animado mejorado para mostrar resultados del torneo
class _AnimatedResultDialog extends StatefulWidget {
  final TournamentLevel level;
  final GameResult result;
  final int stars;
  final bool improved;
  final VoidCallback onContinue;

  const _AnimatedResultDialog({
    required this.level,
    required this.result,
    required this.stars,
    required this.improved,
    required this.onContinue,
  });

  @override
  State<_AnimatedResultDialog> createState() => _AnimatedResultDialogState();
}

class _AnimatedResultDialogState extends State<_AnimatedResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _starsController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animación principal más ligera
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Animación de estrellas separada
    _starsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));
    
    _startAnimations();
  }

  void _startAnimations() async {
    // Animación principal inmediata
    _mainController.forward();
    
    // Estrellas después de un breve delay
    if (widget.result.humanWon) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _starsController.forward();
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildDialogContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent() {
    final isVictory = widget.result.humanWon;
    
    return Container(
      margin: const EdgeInsets.all(UIConstants.spacing24),
      padding: const EdgeInsets.all(UIConstants.spacing32),
      decoration: BoxDecoration(
        color: UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono principal con animación sutil
          _buildResultIcon(),
          const ZenSpacer.large(),
          
          // Título y nivel
          _buildTitleSection(),
          const ZenSpacer.medium(),
          
          // Información de movimientos
          _buildStatsSection(),
          
          // Estrellas con animación
          if (isVictory) ...[
            const ZenSpacer.large(),
            _buildStarsSection(),
          ],
          
          // Mensaje adicional si mejoró
          if (widget.improved) ...[
            const ZenSpacer.medium(),
            _buildImprovementBadge(),
          ],
          
          const ZenSpacer.large(),
          const ZenSpacer.small(),
          
          // Botones
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildResultIcon() {
    final isVictory = widget.result.humanWon;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * value),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isVictory 
                  ? UIColors.success.withOpacity(0.1)
                  : UIColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVictory 
                  ? Icons.emoji_events_rounded
                  : Icons.refresh_rounded,
              size: 40,
              color: isVictory ? UIColors.success : UIColors.error,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleSection() {
    final isVictory = widget.result.humanWon;
    
    return Column(
      children: [
        Text(
          isVictory ? '¡Nivel Completado!' : '¡Inténtalo otra vez!',
          style: ZenTextStyles.title.copyWith(
            color: isVictory ? UIColors.success : UIColors.error,
          ),
          textAlign: TextAlign.center,
        ),
        const ZenSpacer.small(),
        Text(
          widget.level.name,
          style: ZenTextStyles.bodySecondary.copyWith(
            color: UIColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: UIColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.timer_rounded,
            label: 'Movimientos',
            value: '${widget.result.moveCount}',
          ),
          if (widget.level.bestMoves > 0)
            _buildStatItem(
              icon: Icons.emoji_events_rounded,
              label: 'Mejor',
              value: '${widget.level.bestMoves}',
              color: UIColors.success,
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color ?? UIColors.textSecondary,
        ),
        const ZenSpacer.small(),
        Text(
          value,
          style: ZenTextStyles.bodySecondary.copyWith(
            color: color ?? UIColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: ZenTextStyles.caption.copyWith(
            color: UIColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStarsSection() {
    return AnimatedBuilder(
      animation: _starsController,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              'Puntuación',
              style: ZenTextStyles.body.copyWith(
                color: UIColors.textSecondary,
              ),
            ),
            const ZenSpacer.small(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final starAnimation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _starsController,
                  curve: Interval(delay, 1.0, curve: Curves.elasticOut),
                ));
                
                return AnimatedBuilder(
                  animation: starAnimation,
                  builder: (context, child) {
                    final isEarned = index < widget.stars;
                    return Transform.scale(
                      scale: isEarned ? starAnimation.value : 0.7,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isEarned ? UIColors.warning : UIColors.textTertiary,
                          size: 32,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImprovementBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: UIConstants.spacing8,
      ),
      decoration: BoxDecoration(
        color: UIColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        border: Border.all(
          color: UIColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 20,
            color: UIColors.success,
          ),
          const ZenSpacer.horizontal(),
          Text(
            '¡Nuevo récord personal!',
            style: ZenTextStyles.caption.copyWith(
              color: UIColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isVictory = widget.result.humanWon;
    
    return Row(
      children: [
        if (!isVictory) ...[
          Expanded(
            child: ZenButton(
              text: 'Volver',
              onPressed: widget.onContinue,
              variant: ZenButtonVariant.secondary,
            ),
          ),
        ] else ...[
          Expanded(
            child: ZenButton(
              text: 'Continuar',
              onPressed: widget.onContinue,
              variant: ZenButtonVariant.primary,
            ),
          ),
        ],
      ],
    );
  }
}