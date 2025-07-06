import 'package:flutter/material.dart';
import '../widgets/zen_button.dart';
import '../widgets/zen_page_scaffold.dart';
import '../../config/ui_constants.dart';
import '../../config/app_settings.dart';
import '../../core/collapsi_engine.dart';
import 'game_screen.dart';

// Widgets helper locales
class ZenCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Border? border;

  const ZenCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
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
        boxShadow: [
          BoxShadow(
            color: UIColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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

  const ZenSpacer({super.key, this.height, this.width});
  const ZenSpacer.small({super.key}) : height = UIConstants.spacing8, width = null;
  const ZenSpacer.medium({super.key}) : height = UIConstants.spacing16, width = null;
  const ZenSpacer.large({super.key}) : height = UIConstants.spacing32, width = null;
  const ZenSpacer.horizontal({super.key}) : height = null, width = UIConstants.spacing16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: width);
  }
}

/// Pantalla de configuración para partidas rápidas contra IA
class QuickGameSetupScreen extends StatefulWidget {
  const QuickGameSetupScreen({super.key});

  @override
  State<QuickGameSetupScreen> createState() => _QuickGameSetupScreenState();
}

class _QuickGameSetupScreenState extends State<QuickGameSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Configuraciones seleccionadas - AHORA SE CARGAN DESDE PERSISTENCIA
  int _selectedGridSize = 4; // Valor por defecto temporal
  String _selectedDifficulty = 'Medio'; // Valor por defecto temporal
  
  // Estado de carga
  bool _isLoading = true;
  
  // Opciones disponibles
  final List<int> _gridSizes = [4, 5, 6];
  final List<String> _difficulties = ['Fácil', 'Medio', 'Difícil', 'Experto'];

  @override
  void initState() {
    super.initState();
    
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
    
    // CARGAR CONFIGURACIONES GUARDADAS
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Cargar configuraciones guardadas desde persistencia
  Future<void> _loadSavedSettings() async {
    try {
      final settings = await AppSettings.getDefaultSettings();
      
      if (mounted) {
        setState(() {
          _selectedGridSize = settings['gridSize'] as int;
          _selectedDifficulty = settings['difficulty'] as String;
          _isLoading = false;
        });

        // Iniciar animación después de cargar
        Future.delayed(AnimationConstants.fast, () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    } catch (e) {
      // En caso de error, usar valores por defecto
      if (mounted) {
        setState(() {
          _selectedGridSize = 4;
          _selectedDifficulty = 'Medio';
          _isLoading = false;
        });

        // Iniciar animación incluso en caso de error
        Future.delayed(AnimationConstants.fast, () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    }
  }

  /// Guardar configuración de tamaño de grid
  Future<void> _saveGridSize(int size) async {
    try {
      await AppSettings.setDefaultGridSize(size);
    } catch (e) {
      // Manejar error silenciosamente por ahora
      // En una app de producción podrías mostrar un snackbar
    }
  }

  /// Guardar configuración de dificultad
  Future<void> _saveDifficulty(String difficulty) async {
    try {
      await AppSettings.setDefaultDifficulty(difficulty);
    } catch (e) {
      // Manejar error silenciosamente por ahora
      // En una app de producción podrías mostrar un snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar indicador de carga mientras se cargan las configuraciones
    if (_isLoading) {
      return ZenPageScaffold(
        title: 'Partida Rápida',
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ZenPageScaffold(
      title: 'Partida Rápida',
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(UIConstants.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const ZenSpacer.large(),
                      _buildGridSizeSection(),
                      const ZenSpacer.large(),
                      _buildDifficultySection(),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.smart_toy_rounded,
          size: 48,
          color: UIColors.primary,
        ),
        const ZenSpacer.medium(),
        Text(
          'Juega contra la IA',
          style: ZenTextStyles.heading,
          textAlign: TextAlign.center,
        ),
        const ZenSpacer.small(),
        Text(
          'Configura tu partida y pon a prueba tu estrategia',
          style: ZenTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGridSizeSection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tamaño del Tablero',
            style: ZenTextStyles.buttonLarge,
          ),
          const ZenSpacer.small(),
          Text(
            'Elige el tamaño que prefieras para tu estrategia',
            style: ZenTextStyles.caption,
          ),
          const ZenSpacer.medium(),
          Row(
            children: _gridSizes.map((size) {
              final isSelected = size == _selectedGridSize;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => _selectedGridSize = size);
                      // GUARDAR CONFIGURACIÓN
                      await _saveGridSize(size);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? UIColors.primary.withOpacity(0.1)
                            : UIColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                        border: isSelected
                            ? Border.all(color: UIColors.primary, width: 2)
                            : Border.all(color: UIColors.border, width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${size}×$size',
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeMedium,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? UIColors.primary : UIColors.textSecondary,
                            ),
                          ),
                          const ZenSpacer.small(),
                          Text(
                            _getGridSizeDescription(size),
                            style: TextStyle(
                              fontSize: UIConstants.fontSizeCaption,
                              color: isSelected ? UIColors.primary : UIColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getGridSizeDescription(int size) {
    switch (size) {
      case 4:
        return 'Rápido';
      case 5:
        return 'Estándar';
      case 6:
        return 'Estratégico';
      default:
        return '';
    }
  }

  Widget _buildDifficultySection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dificultad de la IA',
            style: ZenTextStyles.buttonLarge,
          ),
          const ZenSpacer.small(),
          Text(
            'Ajusta el nivel de desafío según tu experiencia',
            style: ZenTextStyles.caption,
          ),
          const ZenSpacer.medium(),
          ..._difficulties.map((difficulty) {
            final isSelected = difficulty == _selectedDifficulty;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () async {
                  setState(() => _selectedDifficulty = difficulty);
                  // GUARDAR CONFIGURACIÓN
                  await _saveDifficulty(difficulty);
                },
                child: Container(
                  padding: const EdgeInsets.all(UIConstants.spacing16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? UIColors.primary.withOpacity(0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                    border: isSelected
                        ? Border.all(color: UIColors.primary, width: 1)
                        : Border.all(color: UIColors.borderLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isSelected ? UIColors.primary : UIColors.border,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const ZenSpacer.horizontal(),
                      Expanded(
                        child: Text(
                          difficulty,
                          style: ZenTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected ? UIColors.primary : UIColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: UIColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing24),
      child: ZenButton(
        text: 'Iniciar Partida',
        onPressed: _startGame,
        variant: ZenButtonVariant.primary,
        size: ZenButtonSize.large,
        fullWidth: true,
        icon: Icons.play_arrow_rounded,
      ),
    );
  }

  void _startGame() {
    // Crear motor del juego con configuraciones seleccionadas
    final game = CollapsiEngine();
    game.setGridSize(_selectedGridSize);
    game.toggleAIMode(); // Activar modo IA
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            GameScreen(game: game), // Usar GameScreen con el game configurado
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: AnimationConstants.pageTransition,
      ),
    );
  }
}