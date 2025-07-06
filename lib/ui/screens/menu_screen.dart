import 'package:flutter/material.dart';
import '../widgets/zen_button.dart';
import '../widgets/zen_page_scaffold.dart';
import '../../config/ui_constants.dart';
import '../../config/theme_manager.dart';
import '../../core/haptic_manager.dart';
import '../../core/sound_manager.dart';
import '../../core/animation_manager.dart';
import '../../core/tutorial_manager.dart';
import 'quick_game_setup_screen.dart';
import 'local_game_setup_screen.dart';
import 'tournament_screen.dart';
import 'settings_screen.dart';
import 'dart:math' as math;

/// Pantalla principal del menú con diseño zen minimalista y feedback mejorado
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones de entrada suaves
    _animationController = AnimationController(
      duration: AnimationConstants.slow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConstants.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConstants.easeOut,
    ));
    
    // VERIFICAR TUTORIAL AL INICIALIZAR
    _checkTutorial();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // VERIFICAR Y MOSTRAR TUTORIAL
  void _checkTutorial() async {
    // Pequeño delay para asegurar que la pantalla esté completamente cargada
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!_tutorialChecked && mounted) {
      _tutorialChecked = true;
      
      // Verificar si debe mostrar el tutorial
      final showed = await TutorialManager.checkAndShowTutorialIfNeeded(context);
      
      if (!showed) {
        // Si no se mostró el tutorial, iniciar animación normal del menú
        _animationController.forward();
      }
      // Si se mostró el tutorial, no necesitamos animar el menú ya que no se verá
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZenPageScaffold(
      child: AnimatedBuilder(
        animation: context.themeManager,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMenuOptions(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing24,
        vertical: UIConstants.spacing48,
      ),
      child: Column(
        children: [
          // Título principal con espaciado zen
          Text(
            'COLLAPSI',
            style: ZenTextStyles.title,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: UIConstants.spacing12),
          
          // Subtítulo descriptivo
          Text(
            'Juego de estrategia minimalista',
            style: ZenTextStyles.caption.copyWith(
              color: UIColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Partida rápida
          _buildMenuCard(
            icon: Icons.flash_on_rounded,
            title: 'Partida Rápida',
            subtitle: 'Juega contra la IA',
            isPrimary: true,
            onTap: () => _navigateToQuickGame(),
          ),
          
          const SizedBox(height: UIConstants.spacing16),
          
          // Vs Amigo
          _buildMenuCard(
            icon: Icons.people_rounded,
            title: 'Vs Amigo',
            subtitle: 'Juego local para 2 jugadores',
            onTap: () => _navigateToLocalGame(),
          ),
          
          const SizedBox(height: UIConstants.spacing24),
          
          // TORNEO
          _buildTournamentCard(),
          
          const SizedBox(height: UIConstants.spacing32),
          
          // Ajustes
          ZenButton(
            text: 'Ajustes',
            onPressed: () => _navigateToSettings(),
            variant: ZenButtonVariant.secondary,
            size: ZenButtonSize.medium,
            fullWidth: true,
            icon: Icons.settings_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UIConstants.radiusLarge + 4),
            boxShadow: [
              BoxShadow(
                color: UIColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Card(
            elevation: 8,
            shadowColor: UIColors.primary.withOpacity(0.4),
            child: InkWell(
              onTap: () => _navigateToTournament(),
              borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.spacing24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.6),
                    width: 2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber.withOpacity(0.15),
                      UIColors.primary.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Icono animado más grande
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.withOpacity(0.3),
                            Colors.orange.withOpacity(0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: 1.0 + (0.1 * (1.0 + math.sin(animation * 4 * math.pi)) / 2),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.amber,
                          size: 30,
                        ),
                      ),
                    ),
  
                    const SizedBox(height: UIConstants.spacing8),
  
                    // Título con efecto brillante
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.amber, Colors.orange, Colors.amber],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        '🏆 TORNEO 🏆',
                        style: ZenTextStyles.title.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
  
                    const SizedBox(height: UIConstants.spacing4),
  
                    // Subtítulo
                    Text(
                      'Desafía niveles progresivos y conviértete en campeón',
                      style: ZenTextStyles.body.copyWith(
                        color: UIColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
  
                    const SizedBox(height: UIConstants.spacing4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: AnimationConstants.medium,
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Card(
            elevation: isPrimary ? 4 : 2,
            shadowColor: isPrimary ? UIColors.primary.withOpacity(0.2) : UIColors.shadow,
            child: InkWell(
              onTap: () async {
                // FEEDBACK AL TOCAR CARD
                await HapticManager.instance.selection();
                await SoundManager.instance.playButtonTap();
                onTap();
              },
              onTapDown: (_) => _animateCardPress(true),
              onTapUp: (_) => _animateCardPress(false),
              onTapCancel: () => _animateCardPress(false),
              borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
              splashFactory: NoSplash.splashFactory,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.spacing24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
                  border: isPrimary 
                    ? Border.all(color: UIColors.primary.withOpacity(0.3), width: 1)
                    : null,
                  gradient: isPrimary 
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          UIColors.primary.withOpacity(0.05),
                          UIColors.primaryLight.withOpacity(0.02),
                        ],
                      )
                    : null,
                ),
                child: Row(
                  children: [
                    // Icono
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPrimary 
                          ? UIColors.primary.withOpacity(0.1)
                          : UIColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                      ),
                      child: Icon(
                        icon,
                        color: isPrimary ? UIColors.primary : UIColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: UIConstants.spacing16),
                    
                    // Textos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: ZenTextStyles.buttonLarge.copyWith(
                              color: isPrimary ? UIColors.primary : UIColors.textPrimary,
                              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: UIConstants.spacing4),
                          Text(
                            subtitle,
                            style: ZenTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow indicator
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isPrimary ? UIColors.primary : UIColors.textTertiary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  // Animación sutil de presión de carta
  void _animateCardPress(bool pressed) {
    // Esta función podría usarse para futuras animaciones de feedback táctil
    // Por ahora mantenemos el diseño zen sin animaciones excesivas
  }

  // NAVEGACIÓN CON ANIMACIONES Y FEEDBACK
  void _navigateToQuickGame() async {
    await HapticManager.instance.navigation();
    if (mounted) {
      context.pushWithAnimation(
        const QuickGameSetupScreen(),
        type: RouteTransitionType.slide,
      );
    }
  }

  void _navigateToLocalGame() async {
    await HapticManager.instance.navigation();
    if (mounted) {
      context.pushWithAnimation(
        const LocalGameSetupScreen(),
        type: RouteTransitionType.slide,
      );
    }
  }

  void _navigateToTournament() async {
    await HapticManager.instance.navigation();
    await SoundManager.instance.playButtonTap();
    if (mounted) {
      context.pushWithAnimation(
        const TournamentScreen(),
        type: RouteTransitionType.slideUp,
      );
    }
  }

  void _navigateToSettings() async {
    await HapticManager.instance.navigation();
    if (mounted) {
      context.pushWithAnimation(
        const SettingsScreen(),
        type: RouteTransitionType.fade,
      );
    }
  }
}