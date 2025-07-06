import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/zen_button.dart';
import '../widgets/zen_page_scaffold.dart';
import '../../config/ui_constants.dart';
import '../../config/theme_manager.dart';
import '../../config/app_settings.dart';
import '../../core/tournament_manager.dart';
import '../../core/sound_manager.dart';
import '../../core/haptic_manager.dart';
import '../../core/animation_manager.dart';
import '../../core/background_music_manager.dart';
import 'ai_details/greedy_ai_detail_screen.dart';
import 'ai_details/heuristic_medium_detail_screen.dart';
import 'ai_details/heuristic_hard_detail_screen.dart';
import 'ai_details/minimax_detail_screen.dart';
import '../../core/tutorial_manager.dart';


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

/// Widget para mostrar preview de tema en ajustes
class ThemePreviewCard extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemePreviewCard({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = ThemeManager.themeInfo[theme]!;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimationManager.instance.animatedContainer(
        duration: AnimationConstants.fast,
        padding: const EdgeInsets.all(UIConstants.spacing16),
        decoration: BoxDecoration(
          color: isSelected 
              ? info.preview.withOpacity(0.1)
              : UIColors.surfaceVariant,
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? info.preview : UIColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: info.preview.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview del tema
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                border: Border.all(
                  color: info.preview.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall - 1),
                child: _buildThemePreview(theme),
              ),
            ),
            
            const ZenSpacer.small(),
            
            // Solo nombre del tema (sin descripción)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  info.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const ZenSpacer(width: 4),
                Text(
                  info.name,
                  style: ZenTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? info.preview : UIColors.textPrimary,
                  ),
                ),
              ],
            ),
            
            // Indicador de selección
            if (isSelected) ...[
              const ZenSpacer.small(),
              Icon(
                Icons.check_circle_rounded,
                color: info.preview,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemePreview(AppTheme theme) {
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
        );
    }
  }
}

/// Pantalla de configuraciones y ajustes - VERSIÓN FUSIONADA CON MÚSICA DE FONDO
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  late TournamentManager _tournamentManager;

  // SE CARGAN DESDE PERSISTENCIA
  int _defaultGridSize = 4;
  String _defaultDifficulty = 'Medio';
  
  // CONFIGURACIONES DE EXPERIENCIA DE USUARIO
  bool _appSoundEnabled = true;
  bool _gameHapticsEnabled = true;
  bool _appHapticsEnabled = true;
  bool _animationsEnabled = true;
  bool _movementHelpEnabled = false;
  double _movementHelpDelay = 3.0;
  
  // CONFIGURACIONES DE MÚSICA DE FONDO
  bool _backgroundMusicEnabled = true;
  BackgroundMusicTrack _backgroundMusicTrack = BackgroundMusicTrack.lofi_piano;
  double _backgroundMusicVolume = 0.3;

  // Estado de carga
  bool _isLoading = true;

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
    
    _tabController = TabController(length: 2, vsync: this);
    _tournamentManager = TournamentManager();
    
    // Inicializar gestores
    _initializeManagers();
    
    // CARGAR CONFIGURACIONES DESDE PERSISTENCIA
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Inicializar gestores de sonido, vibración, animaciones y música
  Future<void> _initializeManagers() async {
    try {
      await SoundManager.instance.initialize();
      await HapticManager.instance.initialize();
      await AnimationManager.instance.initialize();
      await BackgroundMusicManager.instance.initialize();
      debugPrint('✅ Gestores de experiencia inicializados');
    } catch (e) {
      debugPrint('❌ Error inicializando gestores: $e');
    }
  }

  /// Cargar todas las configuraciones desde AppSettings
  Future<void> _loadSettings() async {
    try {
      // Cargar configuraciones por defecto desde persistencia
      final defaultSettings = await AppSettings.getDefaultSettings();
      
      // Cargar configuraciones de experiencia de usuario
      final experienceSettings = await AppSettings.getExperienceSettings();
      
      // CARGAR CONFIGURACIONES DE MÚSICA DE FONDO
      final musicSettings = await AppSettings.getBackgroundMusicSettings();
      
      // Inicializar tournament manager
      await _tournamentManager.initialize();
      
      if (mounted) {
        setState(() {
          _defaultGridSize = defaultSettings['gridSize'] as int;
          _defaultDifficulty = defaultSettings['difficulty'] as String;
          
          _appSoundEnabled = experienceSettings['gameSound'] as bool;
          _gameHapticsEnabled = experienceSettings['gameHaptics'] as bool;
          _appHapticsEnabled = experienceSettings['appHaptics'] as bool;
          _animationsEnabled = experienceSettings['animations'] as bool;
          _movementHelpEnabled = experienceSettings['movementHelp'] as bool;
          _movementHelpDelay = experienceSettings['movementHelpDelay'] as double;
          
          // ASIGNAR CONFIGURACIONES DE MÚSICA DE FONDO
          _backgroundMusicEnabled = musicSettings['enabled'] as bool;
          _backgroundMusicTrack = BackgroundMusicTrack.values.firstWhere(
            (track) => track.name == musicSettings['track'],
            orElse: () => BackgroundMusicTrack.lofi_piano,
          );
          _backgroundMusicVolume = (musicSettings['volume'] as double).clamp(0.0, 1.0);
          
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
          _defaultGridSize = 4;
          _defaultDifficulty = 'Medio';
          _appSoundEnabled = true;
          _gameHapticsEnabled = true;
          _appHapticsEnabled = true;
          _animationsEnabled = true;
          _movementHelpEnabled = true;
          _movementHelpDelay = 3.0;
          _backgroundMusicEnabled = true;
          _backgroundMusicTrack = BackgroundMusicTrack.lofi_piano;
          _backgroundMusicVolume = 0.3;
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

  /// Guardar configuración específica inmediatamente
  Future<void> _saveGridSize(int size) async {
    try {
      await AppSettings.setDefaultGridSize(size);
    } catch (e) {
      // Error manejado silenciosamente
    }
  }

  /// Guardar dificultad específica inmediatamente
  Future<void> _saveDifficulty(String difficulty) async {
    try {
      await AppSettings.setDefaultDifficulty(difficulty);
    } catch (e) {
      // Error manejado silenciosamente
    }
  }

  /// Guardar configuración de sonido de toda la app
  Future<void> _saveAppSound(bool enabled) async {
    try {
      await AppSettings.setGameSoundEnabled(enabled);
      await SoundManager.instance.setSoundEnabled(enabled);
    } catch (e) {
      debugPrint('❌ Error guardando configuración de sonido: $e');
    }
  }

  /// Guardar configuración de vibración en partidas
  Future<void> _saveGameHaptics(bool enabled) async {
    try {
      await AppSettings.setGameHapticsEnabled(enabled);
      await HapticManager.instance.setGameHapticsEnabled(enabled);
    } catch (e) {
      debugPrint('❌ Error guardando configuración de vibración en partidas: $e');
    }
  }

  /// Guardar configuración de vibración de la app
  Future<void> _saveAppHaptics(bool enabled) async {
    try {
      await AppSettings.setAppHapticsEnabled(enabled);
      await HapticManager.instance.setAppHapticsEnabled(enabled);
    } catch (e) {
      debugPrint('❌ Error guardando configuración de vibración de la app: $e');
    }
  }

  /// Guardar configuración de animaciones
  Future<void> _saveAnimations(bool enabled) async {
    try {
      await AppSettings.setAnimationsEnabled(enabled);
      await AnimationManager.instance.setAnimationsEnabled(enabled);
    } catch (e) {
      debugPrint('❌ Error guardando configuración de animaciones: $e');
    }
  }

  /// Guardar configuración de ayuda de movimiento
  Future<void> _saveMovementHelp(bool enabled) async {
    try {
      await AppSettings.setMovementHelpEnabled(enabled);

      // No mostrar mensajes cuando se cambia desde ajustes
      // MovementHelpSnackbar.showActivated/showDeactivated ya no se llaman aquí

    } catch (e) {
      debugPrint('❌ Error guardando configuración de ayuda de movimiento: $e');
    }
  }


  /// Guardar delay de ayuda de movimiento
  Future<void> _saveMovementHelpDelay(double delay) async {
    try {
      await AppSettings.setMovementHelpDelay(delay);
      
      // No mostrar mensaje cuando se cambia desde ajustes
      // MovementHelpSnackbar.showDelayUpdated ya no se llama aquí
      
    } catch (e) {
      debugPrint('❌ Error guardando delay de ayuda de movimiento: $e');
    }
  }


  /// Guardar configuración de música de fondo habilitada
  Future<void> _saveBackgroundMusicEnabled(bool enabled) async {
    try {
      await AppSettings.setBackgroundMusicEnabled(enabled);
      await BackgroundMusicManager.instance.setMusicEnabled(enabled);
    } catch (e) {
      debugPrint('❌ Error guardando configuración de música de fondo: $e');
    }
  }

  /// Guardar pista de música de fondo seleccionada
  Future<void> _saveBackgroundMusicTrack(BackgroundMusicTrack track) async {
    try {
      await AppSettings.setBackgroundMusicTrack(track.name);
      await BackgroundMusicManager.instance.setMusicTrack(track);
    } catch (e) {
      debugPrint('❌ Error guardando pista de música de fondo: $e');
    }
  }

  /// Guardar volumen de música de fondo
  Future<void> _saveBackgroundMusicVolume(double volume) async {
    try {
      await AppSettings.setBackgroundMusicVolume(volume);
      await BackgroundMusicManager.instance.setVolume(volume);
    } catch (e) {
      debugPrint('❌ Error guardando volumen de música de fondo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar indicador de carga mientras se cargan las configuraciones
    if (_isLoading) {
      return ZenPageScaffold(
        title: 'Ajustes',
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ZenPageScaffold(
      title: 'Ajustes',
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConfigurationTab(),
                  _buildAIInfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing24),
      child: Container(
        decoration: BoxDecoration(
          color: UIColors.surfaceVariant,
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: UIColors.primary,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: UIColors.textSecondary,
          labelStyle: ZenTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          unselectedLabelStyle: ZenTextStyles.body,
          splashFactory: NoSplash.splashFactory,
          tabs: const [
            Tab(text: 'Configuración'),
            Tab(text: 'IA'),
          ],
        ),
      ),
    );
  }

  /// Pestaña fusionada con configuraciones + tema + experiencia + música
  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CONFIGURACIONES POR DEFECTO
          _buildSectionHeader(
            'Configuraciones por Defecto',
            'Estas configuraciones se aplicarán automáticamente en partidas rápidas',
            Icons.settings_rounded,
          ),
          const ZenSpacer.large(),
          
          _buildDefaultGridSizeSection(),
          const ZenSpacer.large(),
          
          _buildDefaultDifficultySection(),
          const ZenSpacer.large(),
          
          // TEMA VISUAL
          _buildSectionHeader(
            'Tema Visual',
            'Personaliza el aspecto de la aplicación',
            Icons.palette_rounded,
          ),
          const ZenSpacer.large(),
          
          _buildThemeSection(),
          const ZenSpacer.large(),
          
          // EXPERIENCIA DE USUARIO
          _buildSectionHeader(
            'Experiencia de Usuario',
            'Personaliza cómo interactúas con la aplicación',
            Icons.tune_rounded,
          ),
          const ZenSpacer.large(),
          
          _buildExperienceSettings(),
          const ZenSpacer.large(),
          
          // ℹACERCA DE
          _buildSectionHeader(
            'Acerca de Collapsi',
            'Información de la aplicación y tu progreso',
            Icons.info_rounded,
          ),
          const ZenSpacer.large(),
          
          _buildAboutSection(),
          const ZenSpacer.large(),

          // OPEN SOURCE
          _buildOpenSourceSection(),
          const ZenSpacer.large(),

          
          // ACCIONES
          _buildSectionHeader(
            'Acciones',
            'Restablecer configuraciones y progreso',
            Icons.build_rounded,
          ),
          const ZenSpacer.large(),
          
          _buildActionsSection(),
        ],
      ),
    );
  }

  /// Pestaña de IA con navegación a pantallas de detalle
  Widget _buildAIInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Información de las IAs',
            'Conoce cómo funciona cada nivel de dificultad',
            Icons.psychology_rounded,
          ),
          const ZenSpacer.large(),
          
          // FÁCIL
          _buildAILevelCard(
            level: 'Fácil',
            name: 'Novato con Errores',
            metaforaCorta: 'Como un comprador compulsivo: busca las mejores ofertas pero se distrae',
            errorRate: '25% errores',
            onTap: () => _navigateToAIDetail(const GreedyAIDetailScreen()),
            color: UIColors.success,
          ),
          
          // MEDIO
          _buildAILevelCard(
            level: 'Medio',
            name: 'Competidor Equilibrado',
            metaforaCorta: 'Como un chef bajo presión: domina todas las técnicas, pequeños despistes ocasionales',
            errorRate: '15% errores',
            onTap: () => _navigateToAIDetail(const HeuristicMediumDetailScreen()),
            color: UIColors.warning,
          ),
          
          // DIFÍCIL
          _buildAILevelCard(
            level: 'Difícil',
            name: 'Estratega Avanzado',
            metaforaCorta: 'Como un halcón cazador: predice tu próximo movimiento y planifica 2 turnos adelante',
            errorRate: '0% errores',
            onTap: () => _navigateToAIDetail(const HeuristicHardDetailScreen()),
            color: UIColors.error,
          ),
          
          // EXPERTO
          _buildAILevelCard(
            level: 'Experto',
            name: 'Maestro Telepático',
            metaforaCorta: 'Lee todos tus pensamientos futuros hasta 4 turnos adelante con precisión matemática',
            errorRate: '0% errores',
            onTap: () => _navigateToAIDetail(const MinimaxDetailScreen()),
            color: UIColors.primary,
          ),
        ],
      ),
    );
  }

  /// Método para navegar a pantallas de detalle de IA
  void _navigateToAIDetail(Widget screen) async {
    await HapticManager.instance.selection();
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => screen,
        ),
      );
    }
  }

  /// Tarjeta de nivel de IA con navegación y metáforas
  Widget _buildAILevelCard({
    required String level,
    required String name,
    required String metaforaCorta,
    required String errorRate,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
      child: ZenCard(
        onTap: onTap,
        backgroundColor: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nivel y tipo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing12,
                    vertical: UIConstants.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: ZenTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const ZenSpacer.horizontal(),
                Expanded(
                  child: Text(
                    name,
                    style: ZenTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing8,
                    vertical: UIConstants.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                  ),
                  child: Text(
                    errorRate,
                    style: ZenTextStyles.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const ZenSpacer.medium(),
            
            // Metáfora corta
            Text(
              metaforaCorta,
              style: ZenTextStyles.body.copyWith(height: 1.4),
            ),
            
            const ZenSpacer.medium(),
            
            // Call to action
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Toca para conocer sus estrategias y puntos débiles',
                    style: ZenTextStyles.caption.copyWith(
                      color: UIColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: UIColors.primary, size: 24),
            const ZenSpacer.horizontal(),
            Text(title, style: ZenTextStyles.heading),
          ],
        ),
        const ZenSpacer.small(),
        Text(subtitle, style: ZenTextStyles.caption),
      ],
    );
  }

  Widget _buildThemeSection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona tu tema preferido', style: ZenTextStyles.buttonLarge),
          const ZenSpacer.large(),
          
          // Selector de temas con previews
          Row(
            children: AppTheme.values.map((theme) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ThemePreviewCard(
                    theme: theme,
                    isSelected: context.currentTheme == theme,
                    onTap: () => _changeTheme(theme),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const ZenSpacer.medium(),
          
          // Información del tema actual
          _buildCurrentThemeInfo(),
        ],
      ),
    );
  }

  Widget _buildCurrentThemeInfo() {
    final currentTheme = context.currentTheme;
    final info = ThemeManager.themeInfo[currentTheme]!;
    
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        color: info.preview.withOpacity(0.05),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: info.preview.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            info.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const ZenSpacer.horizontal(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema Actual: ${info.name}',
                  style: ZenTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: info.preview,
                  ),
                ),
                Text(
                  info.description,
                  style: ZenTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Abrir repositorio de GitHub
Future<void> _openGitHubRepository() async {
  try {
    await HapticManager.instance.selection();
    const url = 'https://github.com/AitorArtero/collapsi';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo abrir el repositorio'),
            backgroundColor: UIColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            ),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('❌ Error abriendo repositorio: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al abrir el repositorio'),
          backgroundColor: UIColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
        ),
      );
    }
  }
}

  /// Sección de código abierto
  Widget _buildOpenSourceSection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ícono de código
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      UIColors.primary.withOpacity(0.1),
                      UIColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                  border: Border.all(
                    color: UIColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.code_rounded,
                  color: UIColors.primary,
                  size: 20,
                ),
              ),
              const ZenSpacer.horizontal(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open Source',
                      style: ZenTextStyles.buttonLarge,
                    ),
                    const ZenSpacer(height: 2),
                    Text(
                      'Hecho con ❤️ y Flutter',
                      style: ZenTextStyles.caption.copyWith(
                        color: UIColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const ZenSpacer.medium(),

          // Descripción
          Text(
            'Collapsi es un proyecto de código abierto (FOSS, Free Open Source Software). Comenzó como un side project personal para explorar algoritmos de IA y diseño de juegos. Puedes ver el código fuente, reportar bugs, o contribuir al desarrollo en GitHub.',
            style: ZenTextStyles.body.copyWith(
              height: 1.4,
              color: UIColors.textSecondary,
            ),
          ),

          const ZenSpacer.large(),

          // Botón del repositorio
          GestureDetector(
            onTap: _openGitHubRepository,
            child: AnimationManager.instance.animatedContainer(
              duration: AnimationConstants.fast,
              width: double.infinity,
              padding: const EdgeInsets.all(UIConstants.spacing16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF24292e), // GitHub dark
                    const Color(0xFF1a1e22),
                  ],
                ),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF24292e).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo de GitHub (usando un ícono similar)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Color(0xFF24292e),
                      size: 16,
                    ),
                  ),
                  const ZenSpacer.horizontal(),
                  Text(
                    'Ver en GitHub',
                    style: ZenTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const ZenSpacer.horizontal(),
                  Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const ZenSpacer.medium(),

          // Información adicional
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing12),
            decoration: BoxDecoration(
              color: UIColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              border: Border.all(
                color: UIColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: UIColors.error,
                  size: 16,
                ),
                const ZenSpacer(width: 8),
                Expanded(
                  child: Text(
                    'Si te gusta el juego, ¡dale una estrella en GitHub!',
                    style: ZenTextStyles.caption.copyWith(
                      color: UIColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultGridSizeSection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tamaño de Tablero por Defecto', style: ZenTextStyles.buttonLarge),
          const ZenSpacer.small(),
          Text(
            'Se usará automáticamente en partidas rápidas',
            style: ZenTextStyles.caption,
          ),
          const ZenSpacer.medium(),
          
          // Opciones de tamaño en ancho completo
          Column(
            children: [
              _buildFullWidthGridSizeOption('4×4', 4, 'Rápido'),
              const ZenSpacer.small(),
              _buildFullWidthGridSizeOption('5×5', 5, 'Estándar'),
              const ZenSpacer.small(),
              _buildFullWidthGridSizeOption('6×6', 6, 'Estratégico'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthGridSizeOption(String label, int size, String description) {
    final isSelected = _defaultGridSize == size;
    
    return GestureDetector(
      onTap: () async {
        await HapticManager.instance.selection();
        
        setState(() {
          _defaultGridSize = size;
        });
        await _saveGridSize(size);
        _showSettingsSavedSnackbar();
      },
      child: AnimationManager.instance.animatedContainer(
        duration: AnimationConstants.fast,
        width: double.infinity,
        padding: const EdgeInsets.all(UIConstants.spacing16),
        decoration: BoxDecoration(
          color: isSelected 
              ? UIColors.primary.withOpacity(0.1)
              : UIColors.surfaceVariant,
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? UIColors.primary : UIColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? UIColors.primary
                    : UIColors.textSecondary,
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeSmall,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const ZenSpacer.horizontal(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tablero $label',
                    style: ZenTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? UIColors.primary : UIColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: ZenTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: UIColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultDifficultySection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dificultad de IA por Defecto', style: ZenTextStyles.buttonLarge),
          const ZenSpacer.small(),
          Text(
            'Nivel de desafío inicial para partidas rápidas',
            style: ZenTextStyles.caption,
          ),
          const ZenSpacer.medium(),
          
          // Opciones de dificultad en ancho completo
          Column(
            children: [
              _buildFullWidthDifficultyOption('Fácil', 'IA básica, ideal para principiantes'),
              const ZenSpacer.small(),
              _buildFullWidthDifficultyOption('Medio', 'IA balanceada, buen desafío'),
              const ZenSpacer.small(),
              _buildFullWidthDifficultyOption('Difícil', 'IA avanzada con múltiples estrategias'),
              const ZenSpacer.small(),
              _buildFullWidthDifficultyOption('Experto', 'IA máxima con algoritmo Minimax'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthDifficultyOption(String difficulty, String description) {
    final isSelected = _defaultDifficulty == difficulty;
    
    return GestureDetector(
      onTap: () async {
        await HapticManager.instance.selection();
        
        setState(() {
          _defaultDifficulty = difficulty;
        });
        await _saveDifficulty(difficulty);
        _showSettingsSavedSnackbar();
      },
      child: AnimationManager.instance.animatedContainer(
        duration: AnimationConstants.fast,
        width: double.infinity,
        padding: const EdgeInsets.all(UIConstants.spacing16),
        decoration: BoxDecoration(
          color: isSelected 
              ? UIColors.primary.withOpacity(0.1)
              : UIColors.surfaceVariant,
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? UIColors.primary : UIColors.border,
            width: isSelected ? 2 : 1,
          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty,
                    style: ZenTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? UIColors.primary : UIColors.textPrimary,
                    ),
                  ),
                  const ZenSpacer(height: 2),
                  Text(
                    description,
                    style: ZenTextStyles.caption,
                  ),
                ],
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
    );
  }

  /// Configuraciones de experiencia unificadas + música
  Widget _buildExperienceSettings() {
    return Column(
      children: [
        // Configuraciones de Audio y Vibración
        ZenCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Audio y Vibración', style: ZenTextStyles.buttonLarge),
              const ZenSpacer.medium(),
              
              _buildSwitchTile(
                'Sonidos de la App',
                'Efectos de sonido y música de fondo',
                Icons.volume_up_rounded,
                _appSoundEnabled,
                (value) async {
                  setState(() => _appSoundEnabled = value);
                  await _saveAppSound(value);
                },
              ),
              
              _buildSwitchTile(
                'Vibración en Partidas',
                'Feedback háptico durante las partidas',
                Icons.videogame_asset_rounded,
                _gameHapticsEnabled,
                (value) async {
                  setState(() => _gameHapticsEnabled = value);
                  await _saveGameHaptics(value);
                },
              ),
              
              _buildSwitchTile(
                'Vibración de la App',
                'Feedback háptico al navegar por la app',
                Icons.vibration_rounded,
                _appHapticsEnabled,
                (value) async {
                  setState(() => _appHapticsEnabled = value);
                  await _saveAppHaptics(value);
                },
              ),
              
              _buildSwitchTile(
                'Transiciones Suaves',
                'Animaciones entre pantallas',
                Icons.slideshow_rounded,
                _animationsEnabled,
                (value) async {
                  setState(() => _animationsEnabled = value);
                  await _saveAnimations(value);
                },
              ),

              _buildSwitchTile(
                'Ayuda de Movimiento',
                'Resaltar casillas a las que puedes moverte',
                Icons.help_outline_rounded,
                _movementHelpEnabled,
                (value) async {
                  setState(() => _movementHelpEnabled = value);
                  await _saveMovementHelp(value);
                },
              ),
              if (_movementHelpEnabled) ...[
                const SizedBox(height: 16),
                _buildMovementHelpDelayControl(),
              ],
            ],
          ),
        ),
        
        const ZenSpacer.large(),
        
        // Música de Fondo
        _buildBackgroundMusicSection(),
      ],
    );
  }

  /// Configuración de música de fondo
  Widget _buildBackgroundMusicSection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded, color: UIColors.primary, size: 24),
              const ZenSpacer.horizontal(),
              Text('Música de Fondo', style: ZenTextStyles.buttonLarge),
            ],
          ),
          const ZenSpacer.medium(),
          
          // Switch para habilitar/deshabilitar música
          _buildSwitchTile(
            'Música de Fondo',
            'Reproducir música ambiental mientras juegas',
            Icons.library_music_rounded,
            _backgroundMusicEnabled,
            (value) async {
              setState(() => _backgroundMusicEnabled = value);
              await _saveBackgroundMusicEnabled(value);
            },
          ),
          
          // Solo mostrar opciones si la música está habilitada
          if (_backgroundMusicEnabled) ...[
            const ZenSpacer.medium(),
            
            // Selector de pista de música
            Text(
              'Selecciona tu ambiente sonoro',
              style: ZenTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
            const ZenSpacer.small(),
            
            // Opciones de pistas de música
            ...BackgroundMusicTrack.values.map((track) => 
              _buildMusicTrackOption(track)
            ).toList(),
            
            const ZenSpacer.medium(),
            
            // Control de volumen
            _buildVolumeControl(),
          ],
        ],
      ),
    );
  }

  /// Widget para cada opción de pista musical
  Widget _buildMusicTrackOption(BackgroundMusicTrack track) {
    final isSelected = _backgroundMusicTrack == track;
    
    return GestureDetector(
      onTap: () async {
        await HapticManager.instance.selection();
        setState(() => _backgroundMusicTrack = track);
        await _saveBackgroundMusicTrack(track);
        _showSettingsSavedSnackbar();
      },
      child: AnimationManager.instance.animatedContainer(
        duration: AnimationConstants.fast,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: UIConstants.spacing8),
        padding: const EdgeInsets.all(UIConstants.spacing12),
        decoration: BoxDecoration(
          color: isSelected 
              ? UIColors.primary.withOpacity(0.1)
              : UIColors.surfaceVariant,
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? UIColors.primary : UIColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji de la pista
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? UIColors.primary.withOpacity(0.2)
                    : UIColors.border.withOpacity(0.1),
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
              ),
              child: Center(
                child: Text(
                  track.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            
            const ZenSpacer.horizontal(),
            
            // Información de la pista
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.displayName,
                    style: ZenTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? UIColors.primary : UIColors.textPrimary,
                    ),
                  ),
                  const ZenSpacer(height: 2),
                  Text(
                    track.description,
                    style: ZenTextStyles.caption,
                  ),
                ],
              ),
            ),
            
            // Indicador de selección
            if (isSelected)
              Icon(
                Icons.radio_button_checked_rounded,
                color: UIColors.primary,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: UIColors.border,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  /// Control deslizante para el volumen
  Widget _buildVolumeControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Volumen de la música',
              style: ZenTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '${(_backgroundMusicVolume * 100).round()}%',
              style: ZenTextStyles.caption.copyWith(
                color: UIColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const ZenSpacer.small(),
        
        // Slider personalizado
        Container(
          decoration: BoxDecoration(
            color: UIColors.surfaceVariant,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: UIColors.primary,
              inactiveTrackColor: UIColors.border,
              thumbColor: UIColors.primary,
              overlayColor: UIColors.primary.withOpacity(0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _backgroundMusicVolume,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (value) {
                setState(() => _backgroundMusicVolume = value);
              },
              onChangeEnd: (value) async {
                await _saveBackgroundMusicVolume(value);
              },
            ),
          ),
        ),
        
        // Indicadores de volumen
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.volume_mute_rounded, 
                    color: UIColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text('0%', style: ZenTextStyles.caption),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.volume_up_rounded, 
                    color: UIColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text('100%', style: ZenTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Control deslizante para el delay de ayuda de movimiento
  Widget _buildMovementHelpDelayControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, color: UIColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo de Ayuda',
                    style: ZenTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Tiempo antes de resaltar las casillas válidas',
                    style: ZenTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text(
              _movementHelpDelay == 0 
                  ? 'Inmediato' 
                  : '${_movementHelpDelay.toInt()}s',
              style: ZenTextStyles.caption.copyWith(
                color: UIColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Slider personalizado
        Container(
          decoration: BoxDecoration(
            color: UIColors.surfaceVariant,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: UIColors.primary,
              inactiveTrackColor: UIColors.border,
              thumbColor: UIColors.primary,
              overlayColor: UIColors.primary.withOpacity(0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _movementHelpDelay,
              min: 0.0,
              max: 20.0,
              divisions: 20,
              onChanged: (value) {
                setState(() => _movementHelpDelay = value);
              },
              onChangeEnd: (value) async {
                await _saveMovementHelpDelay(value);
              },
            ),
          ),
        ),

        // Indicadores de tiempo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flash_on_rounded, 
                    color: UIColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text('0s (Inmediato)', style: ZenTextStyles.caption),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded, 
                    color: UIColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text('20s (Muy lento)', style: ZenTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildAboutSection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información de la Aplicación', style: ZenTextStyles.buttonLarge),
          const ZenSpacer.medium(),
          _buildInfoRow('Versión', '1.0.0'),
          _buildInfoRow('Desarrollado en', 'Flutter'),
          
          // Estadísticas del torneo
          if (_tournamentManager.isLoaded) ...[
            const ZenSpacer.medium(),
            Text('Progreso del Torneo', style: ZenTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const ZenSpacer.small(),
            _buildInfoRow('Niveles completados', 
                '${_tournamentManager.levels.where((l) => l.isCompleted).length}/${_tournamentManager.levels.length}'),
            _buildInfoRow('Estrellas obtenidas', 
                '${_tournamentManager.totalStars}/${_tournamentManager.maxStars}'),
            _buildInfoRow('Bloques perfectos completados', 
              '${_tournamentManager.totalStreakStars}/${_tournamentManager.maxStreakStars}'),

            if (_tournamentManager.isChampion)
              Container(
                margin: const EdgeInsets.only(top: UIConstants.spacing8),
                padding: const EdgeInsets.all(UIConstants.spacing8),
                decoration: BoxDecoration(
                  color: UIColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                  border: Border.all(color: UIColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: UIColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '¡Gran Maestro!',
                      style: ZenTextStyles.caption.copyWith(
                        color: UIColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (_tournamentManager.totalStreakStars == _tournamentManager.maxStreakStars && 
                _tournamentManager.maxStreakStars > 0)
              Container(
                margin: const EdgeInsets.only(top: UIConstants.spacing8),
                padding: const EdgeInsets.all(UIConstants.spacing8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1976D2).withOpacity(0.15), // Azul diamante
                      const Color(0xFF42A5F5).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                  border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Text('💎', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      '¡Coleccionista de Diamantes!',
                      style: ZenTextStyles.caption.copyWith(
                        color: const Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showTutorial() async {
    await HapticManager.instance.navigation();
    if (mounted) {
      TutorialManager.startTutorial(context);
    }
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        ZenButton(
          text: 'Ver tutorial',
          onPressed: _showTutorial,
          variant: ZenButtonVariant.secondary,
          fullWidth: true,
          icon: Icons.school_rounded,
        ),
        const ZenSpacer.medium(),
        ZenButton(
          text: 'Restablecer Configuraciones',
          onPressed: _resetSettings,
          variant: ZenButtonVariant.secondary,
          fullWidth: true,
          icon: Icons.restore_rounded,
        ),
        const ZenSpacer.medium(),
        ZenButton(
          text: 'Restablecer Progreso del Torneo',
          onPressed: _resetTournamentProgress,
          variant: ZenButtonVariant.destructive,
          fullWidth: true,
          icon: Icons.delete_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      child: Row(
        children: [
          Icon(icon, color: UIColors.textSecondary, size: 20),
          const ZenSpacer.horizontal(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZenTextStyles.body),
                Text(subtitle, style: ZenTextStyles.caption),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (newValue) async {
              await HapticManager.instance.switchToggle();
              onChanged(newValue);
            },
            activeColor: UIColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ZenTextStyles.body),
          Text(
            value,
            style: ZenTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              color: UIColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _changeTheme(AppTheme theme) async {
    await HapticManager.instance.themeChange();
    await SoundManager.instance.playThemeChange();
    
    final themeManager = context.themeManager;
    await themeManager.setTheme(theme);
    
    // Mostrar feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tema cambiado a ${ThemeManager.themeInfo[theme]!.name}'),
          backgroundColor: UIColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
        ),
      );
    }
  }

  /// Mostrar snackbar de guardado
  void _showSettingsSavedSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuración guardada'),
          backgroundColor: UIColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
        ),
      );
    }
  }

  void _resetSettings() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: TweenAnimationBuilder<double>(
          duration: AnimationConstants.medium,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.7 + (0.3 * value),
              child: Opacity(
                opacity: value,
                child: _buildResetSettingsDialogContent(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResetSettingsDialogContent() {
    return Container(
      margin: const EdgeInsets.all(UIConstants.spacing24),
      decoration: BoxDecoration(
        color: UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        border: Border.all(
          color: UIColors.warning.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: UIColors.warning.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing32),
            child: Column(
              children: [
                // Icono
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        UIColors.warning.withOpacity(0.2),
                        UIColors.warning.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: UIColors.warning.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.restore_rounded,
                    size: 40,
                    color: UIColors.warning,
                  ),
                ),

                const ZenSpacer.large(),

                // Título
                Text(
                  'Restablecer Configuraciones',
                  style: ZenTextStyles.title.copyWith(
                    color: UIColors.warning,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const ZenSpacer.medium(),

                // Mensaje
                Text(
                  '¿Estás seguro de que quieres restablecer todas las configuraciones a sus valores por defecto?',
                  style: ZenTextStyles.body.copyWith(
                    color: UIColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Separador
          Container(
            height: 1,
            color: UIColors.borderLight,
          ),

          // Botones
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: Row(
              children: [
                // Botón Cancelar
                Expanded(
                  child: _buildSettingsDialogButton(
                    text: 'Cancelar',
                    isPrimary: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Restablecer
                Expanded(
                  child: _buildSettingsDialogButton(
                    text: 'Restablecer',
                    isPrimary: true,
                    onPressed: () async {
                      // Restablecer todas las configuraciones
                      await AppSettings.resetAllSettings();

                      setState(() {
                        _defaultGridSize = 4;
                        _defaultDifficulty = 'Medio';
                        _appSoundEnabled = true;
                        _gameHapticsEnabled = true;
                        _appHapticsEnabled = true;
                        _animationsEnabled = true;
                        _movementHelpEnabled = true;
                        _movementHelpDelay = 3.0;
                        _backgroundMusicEnabled = true;
                        _backgroundMusicTrack = BackgroundMusicTrack.lofi_piano;
                        _backgroundMusicVolume = 0.3;
                      });

                      // Recargar gestores
                      await SoundManager.instance.reloadSettings();
                      await HapticManager.instance.reloadSettings();
                      await AnimationManager.instance.reloadSettings();
                      await BackgroundMusicManager.instance.reloadSettings();

                      // Restablecer tema también
                      await context.themeManager.setTheme(AppTheme.neon);

                      if (mounted) Navigator.of(context).pop();
                      _showSettingsSavedSnackbar();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _resetTournamentProgress() {
    showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        duration: AnimationConstants.medium,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.7 + (0.3 * value),
            child: Opacity(
              opacity: value,
              child: _buildResetTournamentDialogContent(),
            ),
          );
        },
      ),
    ),
  );
  }

  
  Widget _buildResetTournamentDialogContent() {
    return Container(
      margin: const EdgeInsets.all(UIConstants.spacing24),
      decoration: BoxDecoration(
        color: UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        border: Border.all(
          color: UIColors.error.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: UIColors.error.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing32),
            child: Column(
              children: [
                // Icono
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        UIColors.error.withOpacity(0.2),
                        UIColors.error.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: UIColors.error.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 40,
                    color: UIColors.error,
                  ),
                ),

                const ZenSpacer.large(),

                // Título
                Text(
                  'Restablecer Progreso del Torneo',
                  style: ZenTextStyles.title.copyWith(
                    color: UIColors.error,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const ZenSpacer.medium(),

                // Mensaje
                Text(
                  '¿Estás seguro de que quieres eliminar todo tu progreso del torneo? Esta acción no se puede deshacer.',
                  style: ZenTextStyles.body.copyWith(
                    color: UIColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Separador
          Container(
            height: 1,
            color: UIColors.borderLight,
          ),

          // Botones
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: Row(
              children: [
                // Botón Cancelar
                Expanded(
                  child: _buildSettingsDialogButton(
                    text: 'Cancelar',
                    isPrimary: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Eliminar con actualización automática
                Expanded(
                  child: _buildSettingsDialogButton(
                    text: 'Eliminar',
                    isPrimary: true,
                    isDestructive: true,
                    onPressed: () async {
                      await _tournamentManager.resetProgress();

                      // Actualizar automáticamente el estado de la UI
                      setState(() {
                        // Esto fuerza la actualización de las estadísticas mostradas
                      });

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Progreso del torneo eliminado'),
                            backgroundColor: UIColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsDialogButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Color buttonColor;
        if (isPrimary) {
          buttonColor = isDestructive ? UIColors.error : UIColors.warning;
        } else {
          buttonColor = UIColors.textSecondary;
        }

        return Container(
          height: UIConstants.buttonHeight + 8,
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      buttonColor,
                      buttonColor.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isPrimary ? null : UIColors.surface,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            border: isPrimary 
                ? null 
                : Border.all(color: UIColors.border, width: 1),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              splashFactory: NoSplash.splashFactory,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: ZenTextStyles.buttonLarge.copyWith(
                      color: isPrimary ? Colors.white : UIColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


}