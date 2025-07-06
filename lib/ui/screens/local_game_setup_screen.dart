import 'package:flutter/material.dart';
import '../widgets/zen_button.dart';
import '../widgets/zen_page_scaffold.dart';
import '../widgets/zen_option_selector.dart';
import '../../config/ui_constants.dart';
import '../../config/app_settings.dart';
import '../../core/collapsi_engine.dart';
import 'game_screen.dart';

/// Pantalla de configuración para partidas locales (vs amigo)
class LocalGameSetupScreen extends StatefulWidget {
  const LocalGameSetupScreen({super.key});

  @override
  State<LocalGameSetupScreen> createState() => _LocalGameSetupScreenState();
}

// Widget helper ZenCard
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

// Widget helper ZenSpacer
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

class _LocalGameSetupScreenState extends State<LocalGameSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Configuraciones seleccionadas - AHORA EL TAMAÑO SE CARGA DESDE PERSISTENCIA
  int _selectedGridSize = 4; // Valor por defecto temporal
  String _player1Name = 'Jugador Azul';
  String _player2Name = 'Jugador Rojo';
  
  // Estado de carga
  bool _isLoading = true;
  
  // Controladores de texto
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();
  
  // Opciones disponibles
  final List<int> _gridSizes = [4, 5, 6];

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
    
    // Inicializar controladores
    _player1Controller.text = _player1Name;
    _player2Controller.text = _player2Name;
    
    // CARGAR TAMAÑO DE TABLERO GUARDADO
    _loadSavedGridSize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  /// Cargar tamaño de tablero guardado desde persistencia
  Future<void> _loadSavedGridSize() async {
    try {
      final savedGridSize = await AppSettings.getDefaultGridSize();
      
      if (mounted) {
        setState(() {
          _selectedGridSize = savedGridSize;
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
      // En caso de error, usar valor por defecto
      if (mounted) {
        setState(() {
          _selectedGridSize = 4;
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

  @override
  Widget build(BuildContext context) {
    // Mostrar indicador de carga mientras se carga la configuración
    if (_isLoading) {
      return ZenPageScaffold(
        title: 'Vs Amigo',
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ZenPageScaffold(
      title: 'Vs Amigo',
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
                      _buildPlayersSection(),
                      const ZenSpacer.large(),
                      _buildGridSizeSection(),
                      const ZenSpacer.large(),
                      _buildGameRulesSection(),
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
          Icons.people_rounded,
          size: 48,
          color: UIColors.primary,
        ),
        const ZenSpacer.medium(),
        Text(
          'Juego Local',
          style: ZenTextStyles.heading,
          textAlign: TextAlign.center,
        ),
        const ZenSpacer.small(),
        Text(
          'Configura una partida para 2 jugadores en el mismo dispositivo',
          style: ZenTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlayersSection() {
    return ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jugadores',
            style: ZenTextStyles.buttonLarge,
          ),
          const ZenSpacer.small(),
          Text(
            'Personaliza los nombres de los jugadores',
            style: ZenTextStyles.caption,
          ),
          const ZenSpacer.large(),
          
          // Jugador 1 (Azul)
          _buildPlayerInput(
            controller: _player1Controller,
            label: 'Jugador Azul',
            color: UIColors.player1,
            icon: Icons.person_rounded,
            onChanged: (value) => _player1Name = value,
          ),
          
          const ZenSpacer.medium(),
          
          // Jugador 2 (Rojo)
          _buildPlayerInput(
            controller: _player2Controller,
            label: 'Jugador Rojo',
            color: UIColors.player2,
            icon: Icons.person_rounded,
            onChanged: (value) => _player2Name = value,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInput({
    required TextEditingController controller,
    required String label,
    required Color color,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        color: color.withOpacity(0.05),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: ZenTextStyles.body,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: ZenTextStyles.bodySecondary.copyWith(color: color),
          prefixIcon: Icon(icon, color: color, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing16,
            vertical: UIConstants.spacing12,
          ),
          fillColor: Colors.transparent,
          filled: true,
        ),
        maxLength: 20,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
          return null; // Ocultar contador
        },
      ),
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
            'Selecciona el tamaño que prefieras para vuestra partida',
            style: ZenTextStyles.caption,
          ),
          const ZenSpacer.medium(),
          ZenOptionSelector<int>(
            options: _gridSizes,
            selectedOption: _selectedGridSize,
            onOptionSelected: (size) async {
              setState(() {
                _selectedGridSize = size;
              });
              // GUARDAR CONFIGURACIÓN
              await _saveGridSize(size);
            },
            optionBuilder: (size, isSelected) => _buildGridSizeOption(size, isSelected),
            isHorizontal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGridSizeOption(int size, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isSelected 
                ? UIColors.primary.withOpacity(0.1)
                : UIColors.surfaceVariant,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            border: isSelected
                ? Border.all(color: UIColors.primary, width: 2)
                : Border.all(color: UIColors.border, width: 1),
          ),
          child: Center(
            child: Text(
              '${size}×$size',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: isSelected ? UIColors.primary : UIColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameRulesSection() {
    return ZenCard(
      backgroundColor: UIColors.surfaceVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: UIColors.textSecondary,
                size: 20,
              ),
              const ZenSpacer.horizontal(),
              Text(
                'Reglas Rápidas',
                style: ZenTextStyles.body,
              ),
            ],
          ),
          const ZenSpacer.medium(),
          _buildRuleItem('🎯', 'Objetivo: Bloquear al oponente para que no pueda moverse'),
          _buildRuleItem('🔄', 'Los jugadores se turnan para ocupar casillas'),
          _buildRuleItem('✨', 'Solo puedes moverte a casillas resaltadas'),
          _buildRuleItem('🏆', 'Gana quien deje sin movimientos al rival'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const ZenSpacer.horizontal(),
          Expanded(
            child: Text(
              text,
              style: ZenTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasValidNames = _player1Name.trim().isNotEmpty && 
                         _player2Name.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing24),
      child: ZenButton(
        text: 'Iniciar Partida',
        onPressed: hasValidNames ? _startGame : null,
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
    // No activar modo IA para partidas locales
    
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