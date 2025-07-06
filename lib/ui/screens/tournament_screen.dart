import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/zen_button.dart';
import '../widgets/zen_page_scaffold.dart';
import '../../config/ui_constants.dart';
import '../../core/collapsi_engine.dart';
import '../../core/tournament_manager.dart';
import 'game_screen.dart';

class StreakColors {
  // Gradiente principal de fuego/oro
  static const Color fireOrange = Color(0xFFFF6B35);
  static const Color fireRed = Color(0xFFE63946);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFF176);
  static const Color goldDark = Color(0xFFFFB000);
  
  // Gradientes
  static const LinearGradient fireGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [fireOrange, fireRed],
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );
  
  static const LinearGradient completedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
  );
}

/// Estados del botón de streak
enum ButtonState { 
  completed, 
  available, 
  locked 
}

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

/// Pantalla del modo torneo con 3 bloques COLAPSABLES organizados
class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TournamentManager _tournamentManager;
  
  bool _isLoading = true;

  // Estado de expansión de bloques
  Map<int, bool> _blockExpanded = {
    1: true,  // Bloque 1 expandido por defecto
    2: false, // Bloque 2 colapsado por defecto
    3: false, // Bloque 3 colapsado por defecto
  };

  // Variable para recordar el último bloque donde se jugó un streak
  int? _lastStreakBlock;

  // Variable para rastrear si el bloque YA tenía estrella ANTES del streak actual
  Map<int, bool> _blockHadStreakStarBeforeStart = {};

  // Controladores de animación para cada bloque
  late Map<int, AnimationController> _blockAnimationControllers;
  late Map<int, Animation<double>> _blockAnimations;

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

    // Inicializar controladores de animación para bloques
    _blockAnimationControllers = {};
    _blockAnimations = {};
    
    for (int blockNumber = 1; blockNumber <= 3; blockNumber++) {
      _blockAnimationControllers[blockNumber] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      
      _blockAnimations[blockNumber] = CurvedAnimation(
        parent: _blockAnimationControllers[blockNumber]!,
        curve: Curves.easeInOut,
      );

      // Expandir inicialmente si está marcado como expandido
      if (_blockExpanded[blockNumber] == true) {
        _blockAnimationControllers[blockNumber]!.value = 1.0;
      }
    }
    
    _tournamentManager = TournamentManager();
    _initializeTournament();
  }

  @override
  void dispose() {
    _animationController.dispose();
    
    // Disposed de controladores de bloques
    for (var controller in _blockAnimationControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _initializeTournament() async {
    await _tournamentManager.initialize();
    
    if (mounted) {
      // Lógica inteligente de expansión inicial
      _applySmartExpansionLogic();
      
      setState(() {
        _isLoading = false;
      });
      
      // Iniciar animación después de cargar
      Future.delayed(AnimationConstants.fast, () {
        if (mounted) {
          _animationController.forward();
        }
      });
    }
  }

  // Lógica inteligente para decidir qué bloques expandir
  void _applySmartExpansionLogic() {
    final currentLevel = _tournamentManager.currentLevel;
  final hasActiveStreak = _tournamentManager.hasActiveStreak;
  
  // Si hay un streak activo, expandir solo ese bloque
  if (hasActiveStreak) {
    final currentStreak = _tournamentManager.currentActiveStreak;
    if (currentStreak != null) {
      _lastStreakBlock = currentStreak.blockNumber; // Recordar el bloque
      
      for (int blockNumber = 1; blockNumber <= 3; blockNumber++) {
        final shouldExpand = blockNumber == currentStreak.blockNumber;
        _blockExpanded[blockNumber] = shouldExpand;
        
        if (shouldExpand) {
          _blockAnimationControllers[blockNumber]!.forward();
        } else {
          _blockAnimationControllers[blockNumber]!.reverse();
        }
      }
      return;
    }
  }
  
  // Si acabamos de salir de un streak, mantener expandido ese bloque
    if (_lastStreakBlock != null) {
      for (int blockNumber = 1; blockNumber <= 3; blockNumber++) {
        final shouldExpand = blockNumber == _lastStreakBlock;
        _blockExpanded[blockNumber] = shouldExpand;
        
        if (shouldExpand) {
          _blockAnimationControllers[blockNumber]!.forward();
        } else {
          _blockAnimationControllers[blockNumber]!.reverse();
        }
      }
      
      // Limpiar la variable después de aplicar la lógica
      _lastStreakBlock = null;
      return;
    }
    
    if (currentLevel != null) {
      // Expandir el bloque del nivel actual y colapsar los demás
      for (int blockNumber = 1; blockNumber <= 3; blockNumber++) {
        final shouldExpand = blockNumber == currentLevel.block;
        _blockExpanded[blockNumber] = shouldExpand;
        
        if (shouldExpand) {
          _blockAnimationControllers[blockNumber]!.forward();
        } else {
          _blockAnimationControllers[blockNumber]!.reverse();
        }
      }
    } else if (_tournamentManager.isChampion) {
      // Si es campeón, expandir todos los bloques para mostrar el logro
      for (int blockNumber = 1; blockNumber <= 3; blockNumber++) {
        _blockExpanded[blockNumber] = true;
        _blockAnimationControllers[blockNumber]!.forward();
      }
    }
  }


  // Toggle del estado de expansión de un bloque
  void _toggleBlockExpansion(int blockNumber) {
    setState(() {
      _blockExpanded[blockNumber] = !_blockExpanded[blockNumber]!;
    });

    if (_blockExpanded[blockNumber]!) {
      _blockAnimationControllers[blockNumber]!.forward();
    } else {
      _blockAnimationControllers[blockNumber]!.reverse();
    }
  }

  int _calculateStars(int moveCount, TournamentLevel level) {
    final thresholds = _getStarThresholdsForLevel(level);
    
    if (moveCount <= thresholds['gold']!) {
      return 3;
    } else if (moveCount <= thresholds['silver']!) {
      return 2;
    } else {
      return 1;
    }
  }

  Map<String, int> _getStarThresholdsForLevel(TournamentLevel level) {
    int base = level.gridSize * 3;
    
    double multiplier = 1.0;
    switch (level.aiDifficulty) {
      case 'Fácil': multiplier = 0.8; break;
      case 'Medio': multiplier = 1.0; break;
      case 'Difícil': multiplier = 1.2; break;
      case 'Experto': multiplier = 1.5; break;
    }
    
    int adjustedBase = (base * multiplier).round();
    
    return {
      'gold': (adjustedBase * 0.7).round(),
      'silver': (adjustedBase * 0.9).round(),
      'bronze': adjustedBase * 2,
    };
  }

  Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ZenPageScaffold(
        title: 'Torneo',
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ZenPageScaffold(
      title: 'Torneo',
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildTournamentHeader(),
            Expanded(
              child: _buildTournamentContent(),
            ),
            _buildTournamentFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentHeader() {
    final progress = _tournamentManager.overallProgress;
    final completedLevels = _tournamentManager.levels.where((l) => l.isCompleted).length;
    final totalLevels = _tournamentManager.levels.length;
    final stars = _tournamentManager.totalStars;
    final maxStars = _tournamentManager.maxStars;
    final isChampion = _tournamentManager.isChampion;
    
    // Estrellas de streak
    final streakStars = _tournamentManager.totalStreakStars;
    final maxStreakStars = _tournamentManager.maxStreakStars;
    
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing24),
      child: Column(
        children: [
          // Solo la tarjeta de progreso combinada
          _buildCombinedProgressCard(
            progress, 
            completedLevels, 
            totalLevels, 
            stars, 
            maxStars, 
            streakStars, 
            maxStreakStars,
            isChampion,
          ),
        ],
      ),
    );
  }

  // Método para la tarjeta combinada
  Widget _buildCombinedProgressCard(
    double progress, 
    int completed, 
    int total, 
    int stars, 
    int maxStars, 
    int streakStars, 
    int maxStreakStars,
    bool isChampion,
  ) {
    final allStreaksCompleted = streakStars == maxStreakStars && maxStreakStars > 0;

    return ZenCard(
      backgroundColor: isChampion 
          ? UIColors.warning.withOpacity(0.1) 
          : allStreaksCompleted
              ? StreakColors.gold.withOpacity(0.05)
              : UIColors.surfaceVariant,
      border: isChampion 
          ? Border.all(color: UIColors.warning.withOpacity(0.3), width: 2)
          : allStreaksCompleted
              ? Border.all(color: StreakColors.gold.withOpacity(0.3), width: 2)
              : null,
      child: Column(
        children: [
          // PROGRESO GENERAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progreso General', style: ZenTextStyles.body),
                  Text(
                    '$completed/$total niveles',
                    style: ZenTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isChampion ? UIColors.warning : UIColors.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: UIColors.warning, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$stars/$maxStars',
                        style: ZenTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: UIColors.warning,
                        ),
                      ),
                    ],
                  ),
                  Text('estrellas', style: ZenTextStyles.caption),
                ],
              ),
            ],
          ),

          const ZenSpacer.small(),

          // Barra de progreso general
          ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: UIColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isChampion ? UIColors.warning : UIColors.primary,
              ),
              minHeight: 8,
            ),
          ),

          // MENSAJES ESPECIALES (solo si corresponde)
          if (isChampion && allStreaksCompleted) ...[
            const ZenSpacer.medium(),
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    UIColors.warning.withOpacity(0.15),
                    const Color(0xFF1976D2).withOpacity(0.1), // Azul diamante
                  ],
                ),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(color: UIColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 3),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 2 * pi,
                        child: Text('💎', style: TextStyle(fontSize: 20)),
                      );
                    },
                  ),
                  const ZenSpacer.horizontal(),
                  Text(
                    '¡Leyenda Diamante de Collapsi!',
                    style: ZenTextStyles.body.copyWith(
                      color: UIColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (allStreaksCompleted) ...[
            const ZenSpacer.medium(),
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1976D2).withOpacity(0.15), // Azul diamante
                    const Color(0xFF42A5F5).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💎', style: TextStyle(fontSize: 20)),
                  const ZenSpacer.horizontal(),
                  Text(
                    '¡Coleccionista de Diamantes!',
                    style: ZenTextStyles.body.copyWith(
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

  Widget _buildTournamentContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing24),
      children: [
        // Construir cada bloque CON ANIMACIÓN DE COLAPSO
        for (int blockNumber = 1; blockNumber <= 3; blockNumber++)
          _buildTournamentBlockCollapsible(blockNumber),
      ],
    );
  }

  // Bloque de torneo con funcionalidad de colapso
  Widget _buildTournamentBlockCollapsible(int blockNumber) {
    final blockInfo = _tournamentManager.getBlockInfo(blockNumber);
    final blockLevels = _tournamentManager.getLevelsInBlock(blockNumber);
    final blockProgress = _tournamentManager.getBlockProgress(blockNumber);
    final isBlockCompleted = _tournamentManager.isBlockCompleted(blockNumber);
    final isExpanded = _blockExpanded[blockNumber] ?? false;
    final canStartStreak = _tournamentManager.canStartBlockStreak(blockNumber);
    final hasStreakStar = _tournamentManager.hasBlockStreakStar(blockNumber);

    if (blockInfo == null || blockLevels.isEmpty) return const SizedBox.shrink();

    // Colores por bloque
    Color blockColor;
    IconData blockIcon;
    switch (blockNumber) {
      case 1:
        blockColor = UIColors.success;
        blockIcon = Icons.school_rounded;
        break;
      case 2:
        blockColor = UIColors.warning;
        blockIcon = Icons.trending_up_rounded;
        break;
      case 3:
        blockColor = UIColors.error;
        blockIcon = Icons.military_tech_rounded;
        break;
      default:
        blockColor = UIColors.primary;
        blockIcon = Icons.circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing24),
      child: ZenCard(
        backgroundColor: isBlockCompleted 
            ? blockColor.withOpacity(0.05)
            : UIColors.surface,
        border: Border.all(
          color: isBlockCompleted 
              ? blockColor.withOpacity(0.3)
              : UIColors.borderLight,
          width: isBlockCompleted ? 2 : 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header clicable del bloque
            InkWell(
              onTap: () => _toggleBlockExpansion(blockNumber),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.spacing4),
                child: _buildBlockHeader(
                  blockInfo, 
                  blockColor, 
                  blockIcon, 
                  blockProgress, 
                  isBlockCompleted,
                  isExpanded,
                  blockLevels.length,
                ),
              ),
            ),

            // Botón de streak (ANTES del contenido animado)
            if (canStartStreak || hasStreakStar)
              _buildStreakButton(blockNumber, blockColor, canStartStreak, hasStreakStar),
          
            // Contenido animado (niveles)
            AnimatedBuilder(
              animation: _blockAnimations[blockNumber]!,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: _blockAnimations[blockNumber]!.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  const ZenSpacer.medium(),
                  // Niveles del bloque
                  ...blockLevels.map((level) => _buildLevelCard(level)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakButton(int blockNumber, Color blockColor, bool canStart, bool hasStreakStar) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: UIConstants.spacing12,
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1200),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, animationValue, child) {
          return _buildAnimatedStreakButton(
            blockNumber, 
            blockColor, 
            canStart, 
            hasStreakStar, 
            animationValue,
          );
        },
      ),
    );
  }

  Widget _buildAnimatedStreakButton(int blockNumber, Color blockColor, bool canStart, bool hasStreakStar, double animationValue) {
    // Determinar estado visual - ahora "completed" es diferente de "available"
    final ButtonState buttonState;

    if (hasStreakStar && !canStart) {
      // Caso imposible: tiene estrella pero no puede empezar (hay otro streak activo)
      buttonState = ButtonState.completed;
    } else if (hasStreakStar && canStart) {
      // Tiene estrella Y puede empezar = rejugable
      buttonState = ButtonState.completed; // Visualmente completado pero funcional
    } else if (canStart) {
      // Puede empezar por primera vez
      buttonState = ButtonState.available;
    } else {
      // No puede empezar (bloque no completado o hay streak activo)
      buttonState = ButtonState.locked;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge + 4),
        gradient: _getButtonGradient(buttonState),
        boxShadow: _getButtonShadows(buttonState, animationValue),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge + 4),
        child: InkWell(
          // Permitir click tanto en available como en completed (si puede empezar)
          onTap: canStart ? () => _startBlockStreak(blockNumber) : null,
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge + 4),
          splashFactory: NoSplash.splashFactory,
          child: Container(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UIConstants.radiusLarge + 4),
              border: Border.all(
                color: _getBorderColor(buttonState).withOpacity(0.4),
                width: 2,
              ),
              // Overlay de brillo sutil
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(buttonState == ButtonState.completed ? 0.2 : 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                // Icono mejorado con efectos
                _buildButtonIcon(buttonState, animationValue),
                const SizedBox(width: UIConstants.spacing16),
                // Contenido principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título principal
                      Text(
                        _getButtonTitle(buttonState, hasStreakStar),
                        style: ZenTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _getTextColor(buttonState),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Subtítulo/descripción
                      Text(
                        _getButtonSubtitle(buttonState, hasStreakStar),
                        style: ZenTextStyles.caption.copyWith(
                          color: _getTextColor(buttonState).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicador de acción
                _buildButtonActionIndicator(buttonState, animationValue),
              ],
            ),
          ),
        ),
      ),
    );
  }


  LinearGradient _getButtonGradient(ButtonState state) {
    switch (state) {
      case ButtonState.completed:
        return StreakColors.completedGradient;
      case ButtonState.available:
        return StreakColors.fireGradient;
      case ButtonState.locked:
        return LinearGradient(
          colors: [
            UIColors.surfaceVariant,
            UIColors.surface,
          ],
        );
    }
  }

  List<BoxShadow> _getButtonShadows(ButtonState state, double animationValue) {
    switch (state) {
      case ButtonState.completed:
        return [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ];
      case ButtonState.available:
        final pulseIntensity = (1.0 + sin(animationValue * 4 * pi)) / 2;
        return [
          BoxShadow(
            color: StreakColors.fireOrange.withOpacity(0.3 + (0.1 * pulseIntensity)),
            blurRadius: 15 + (5 * pulseIntensity),
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: StreakColors.fireRed.withOpacity(0.1),
            blurRadius: 25,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ];
      case ButtonState.locked:
        return [
          BoxShadow(
            color: UIColors.shadow.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ];
    }
  }

  Color _getBorderColor(ButtonState state) {
    switch (state) {
      case ButtonState.completed:
        return const Color(0xFF81C784);
      case ButtonState.available:
        return StreakColors.goldLight;
      case ButtonState.locked:
        return UIColors.border;
    }
  }

  Color _getTextColor(ButtonState state) {
    switch (state) {
      case ButtonState.completed:
      case ButtonState.available:
        return Colors.white;
      case ButtonState.locked:
        return UIColors.textTertiary;
    }
  }

  String _getButtonTitle(ButtonState state, bool hasStreakStar) {
    switch (state) {
      case ButtonState.completed:
        return hasStreakStar 
            ? '💎 ¡Bloque Perfecto Completado!'
            : '🏆 ¡Bloque Perfecto Completado!';
      case ButtonState.available:
        return '🔥 Modo Bloque Perfecto';
      case ButtonState.locked:
        return '🔒 Bloque Perfecto Bloqueado';
    }
  }

  String _getButtonSubtitle(ButtonState state, bool hasStreakStar) {
    switch (state) {
      case ButtonState.completed:
        return hasStreakStar 
            ? 'Diamante ganado - Rejugar para diversión'
            : 'Has dominado este bloque completamente';
      case ButtonState.available:
        return 'Pasa 5 niveles seguidos sin perder';
      case ButtonState.locked:
        return 'Completa el bloque para desbloquear';
    }
  }

  Widget _buildButtonIcon(ButtonState state, double animationValue) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 3),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, pulseValue, child) {
        final scale = state == ButtonState.available 
            ? 1.0 + (0.1 * sin(pulseValue * 2 * pi))
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _getIconGradient(state),
              boxShadow: state == ButtonState.available
                  ? [
                      BoxShadow(
                        color: StreakColors.goldLight.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _getButtonIcon(state),
              size: 24,
              color: state == ButtonState.locked 
                  ? UIColors.textTertiary
                  : Colors.white,
            ),
          ),
        );
      },
    );
  }

  RadialGradient _getIconGradient(ButtonState state) {
    switch (state) {
      case ButtonState.completed:
        return const RadialGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
        );
      case ButtonState.available:
        return const RadialGradient(
          colors: [StreakColors.goldLight, StreakColors.goldDark],
        );
      case ButtonState.locked:
        return RadialGradient(
          colors: [UIColors.surfaceVariant, UIColors.border],
        );
    }
  }

  IconData _getButtonIcon(ButtonState state) {
    switch (state) {
      case ButtonState.completed:
        return Icons.emoji_events_rounded;
      case ButtonState.available:
        return Icons.local_fire_department_rounded;
      case ButtonState.locked:
        return Icons.lock_rounded;
    }
  }

  Widget _buildButtonActionIndicator(ButtonState state, double animationValue) {
    if (state == ButtonState.locked) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: UIColors.surfaceVariant,
        ),
        child: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: UIColors.textTertiary,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final pulseScale = 1.0 + (0.2 * sin(value * 3 * pi));

        return Transform.scale(
          scale: state == ButtonState.available ? pulseScale : 1.0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              state == ButtonState.completed 
                  ? Icons.check_rounded
                  : Icons.play_arrow_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  // Header del bloque con indicador de expansión
  Widget _buildBlockHeader(
    TournamentBlock blockInfo, 
    Color blockColor, 
    IconData blockIcon, 
    double progress, 
    bool isCompleted,
    bool isExpanded,
    int levelCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing8),
              decoration: BoxDecoration(
                color: blockColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
              ),
              child: Icon(blockIcon, color: blockColor, size: 20),
            ),
            const ZenSpacer.horizontal(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bloque ${blockInfo.blockNumber}: ${blockInfo.name}',
                        style: ZenTextStyles.buttonLarge.copyWith(
                          color: blockColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    blockInfo.description,
                    style: ZenTextStyles.caption,
                  ),
                ],
              ),
            ),
            // Indicador de expansión y contador
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacing4),
                  decoration: BoxDecoration(
                    color: blockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                  ),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: blockColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$levelCount niveles',
                  style: ZenTextStyles.hint.copyWith(
                    fontSize: 10,
                    color: blockColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const ZenSpacer.small(),
        
        // Barra de progreso del bloque
        ClipRRect(
          borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: UIColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(blockColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(TournamentLevel level) {
    final canPlay = level.isUnlocked;
    final isNext = level.isUnlocked && !level.isCompleted;
    final isReplay = level.isCompleted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12, top: UIConstants.spacing8),
      child: ZenCard(
        onTap: canPlay ? () => _startLevel(level) : null,
        backgroundColor: _getLevelCardColor(level, isNext, isReplay),
        border: _getLevelCardBorder(level, isNext, isReplay),
        child: Column(
          children: [
            // Contenido principal del nivel
            Row(
              children: [
                // Indicador de estado del nivel
                _buildLevelIndicator(level, isNext),
                
                const ZenSpacer.horizontal(),
                
                // Información del nivel
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primera fila: Número de nivel y estrellas
                      Row(
                        children: [
                          Text(
                            'Nivel ${level.id}',
                            style: ZenTextStyles.caption.copyWith(
                              color: UIColors.textTertiary,
                            ),
                          ),
                          if (level.isBlockBoss) ...[
                            const ZenSpacer(width: 4),
                            Icon(
                              Icons.emoji_events_rounded,
                              color: UIColors.warning,
                              size: 16,
                            ),
                          ],
                          const Spacer(),
                          _buildStarsIndicator(level),
                        ],
                      ),
                      const ZenSpacer(height: 2),
                      
                      // Nombre del nivel
                      Text(
                        level.name,
                        style: ZenTextStyles.buttonLarge.copyWith(
                          color: level.isUnlocked 
                              ? UIColors.textPrimary 
                              : UIColors.textTertiary,
                          fontSize: 16,
                        ),
                      ),
                      const ZenSpacer.small(),
                      
                      // Descripción
                      Text(
                        level.description,
                        style: ZenTextStyles.caption,
                      ),
                      const ZenSpacer.small(),
                      
                      // Especificaciones del nivel
                      Row(
                        children: [
                          _buildSpecChip('${level.gridSize}×${level.gridSize}', Icons.grid_4x4_rounded),
                          const ZenSpacer.horizontal(),
                          _buildSpecChip(level.aiDifficulty, _getDifficultyIcon(level.aiDifficulty)),
                          // Solo mostrar movimientos si está completado y tiene un récord válido
                          if (level.isCompleted && level.bestMoves > 0) ...[
                            const ZenSpacer.horizontal(),
                            _buildSpecChip('${level.bestMoves} mov.', Icons.timer_rounded),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Indicador de acción
                if (canPlay)
                  Container(
                    padding: const EdgeInsets.all(UIConstants.spacing12),
                    decoration: BoxDecoration(
                      color: isReplay 
                          ? UIColors.warning.withOpacity(0.2)
                          : UIColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                      border: Border.all(
                        color: isReplay 
                            ? UIColors.warning.withOpacity(0.4)
                            : UIColors.primary.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isReplay ? UIColors.warning : UIColors.primary).withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isReplay ? Icons.replay_rounded : Icons.play_arrow_rounded,
                      color: isReplay 
                          ? _getDarkerColor(UIColors.warning)
                          : _getDarkerColor(UIColors.primary),
                      size: 26,
                    ),
                  )
                else if (!level.isUnlocked)
                  Container(
                    padding: const EdgeInsets.all(UIConstants.spacing12),
                    decoration: BoxDecoration(
                      color: UIColors.textTertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                      border: Border.all(
                        color: UIColors.textTertiary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: UIColors.textTertiary,
                      size: 20,
                    ),
                  ),
              ],
            ),
            
            // Criterios de estrellas (expandible)
            if (level.isUnlocked)
              _buildStarCriteria(level),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(TournamentLevel level, bool isNext) {
    Color color;
    IconData icon;
    
    if (level.isCompleted) {
      color = UIColors.success;
      icon = Icons.check_circle_rounded;
    } else if (isNext) {
      color = UIColors.primary;
      icon = Icons.play_circle_filled_rounded;
    } else if (level.isUnlocked) {
      color = UIColors.warning;
      icon = Icons.radio_button_unchecked_rounded;
    } else {
      color = UIColors.textTertiary;
      icon = Icons.lock_rounded;
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(isNext ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: color.withOpacity(isNext ? 0.6 : 0.3),
          width: isNext ? 2 : 1,
        ),
      ),
      child: Icon(
        icon,
        color: isNext ? _getDarkerColor(color) : color,
        size: 24,
      ),
    );
  }

  Widget _buildStarsIndicator(TournamentLevel level) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Icon(
          index < level.starsEarned 
              ? Icons.star_rounded 
              : Icons.star_border_rounded,
          color: index < level.starsEarned 
              ? UIColors.warning 
              : UIColors.textTertiary,
          size: 16,
        );
      }),
    );
  }

  Widget _buildSpecChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing8,
        vertical: UIConstants.spacing4,
      ),
      decoration: BoxDecoration(
        color: UIColors.surfaceVariant,
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
        border: Border.all(color: UIColors.borderLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: UIColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: ZenTextStyles.hint.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarCriteria(TournamentLevel level) {
    final thresholds = _getStarThresholdsForDisplay(level);
    
    return Container(
      margin: const EdgeInsets.only(top: UIConstants.spacing12),
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        color: UIColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
        border: Border.all(color: UIColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Criterios de estrellas:',
            style: ZenTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: UIColors.textSecondary,
            ),
          ),
          const ZenSpacer(height: 6),
          
          _buildStarCriterion(
            3, 
            'Oro', 
            '≤ ${thresholds['gold']} movimientos', 
            UIColors.warning,
            level.starsEarned >= 3,
          ),
          _buildStarCriterion(
            2, 
            'Plata', 
            '≤ ${thresholds['silver']} movimientos', 
            Colors.grey[600]!,
            level.starsEarned >= 2,
          ),
          _buildStarCriterion(
            1, 
            'Bronce', 
            'Completar el nivel', 
            Colors.orange[800]!,
            level.starsEarned >= 1,
          ),
        ],
      ),
    );
  }

  Widget _buildStarCriterion(int stars, String name, String requirement, Color color, bool achieved) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(stars, (index) {
              return Icon(
                achieved ? Icons.star_rounded : Icons.star_border_rounded,
                color: achieved ? color : UIColors.textTertiary,
                size: 14,
              );
            }),
          ),
          
          const ZenSpacer(width: 8),
          
          Text(
            name,
            style: ZenTextStyles.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: achieved ? color : UIColors.textTertiary,
            ),
          ),
          
          const ZenSpacer(width: 4),
          
          Expanded(
            child: Text(
              '- $requirement',
              style: ZenTextStyles.caption.copyWith(
                color: achieved ? UIColors.textSecondary : UIColors.textTertiary,
              ),
            ),
          ),
          
          if (achieved)
            Icon(
              Icons.check_circle_rounded,
              color: color,
              size: 16,
            ),
        ],
      ),
    );
  }

  Map<String, int> _getStarThresholdsForDisplay(TournamentLevel level) {
    int base = level.gridSize * 3;
    
    double multiplier = 1.0;
    switch (level.aiDifficulty) {
      case 'Fácil': multiplier = 0.8; break;
      case 'Medio': multiplier = 1.0; break;
      case 'Difícil': multiplier = 1.2; break;
      case 'Experto': multiplier = 1.5; break;
    }
    
    int adjustedBase = (base * multiplier).round();
    
    return {
      'gold': (adjustedBase * 0.7).round(),
      'silver': (adjustedBase * 0.9).round(),
      'bronze': adjustedBase * 2,
    };
  }

  Color _getLevelCardColor(TournamentLevel level, bool isNext, bool isReplay) {
    if (isReplay) {
      return UIColors.warning.withOpacity(0.8);
    } else if (level.isCompleted) {
      return UIColors.success.withOpacity(0.8);
    } else if (isNext) {
      return UIColors.primary.withOpacity(0.8);
    } else {
      return UIColors.surface;
    }
  }

  Border _getLevelCardBorder(TournamentLevel level, bool isNext, bool isReplay) {
    if (isReplay) {
      return Border.all(color: UIColors.warning.withOpacity(0.3), width: 1.5);
    } else if (level.isCompleted) {
      return Border.all(color: UIColors.success.withOpacity(0.3), width: 1.5);
    } else if (isNext) {
      return Border.all(color: UIColors.primary.withOpacity(0.3), width: 1.5);
    } else {
      return Border.all(color: UIColors.borderLight, width: 1);
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'Fácil': return Icons.child_care_rounded;
      case 'Medio': return Icons.psychology_rounded;
      case 'Difícil': return Icons.trending_up_rounded;
      case 'Experto': return Icons.precision_manufacturing_rounded;
      default: return Icons.help_rounded;
    }
  }

  Widget _buildTournamentFooter() {
    final currentLevel = _tournamentManager.currentLevel;
    final canImproveStars = _tournamentManager.levels.any((level) => 
        level.isCompleted && level.starsEarned < 3);
    
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing24),
      child: Column(
        children: [
          if (currentLevel != null && !_tournamentManager.isChampion) ...[
            ZenButton(
              text: 'Continuar: ${currentLevel.name}',
              onPressed: () => _startLevel(currentLevel),
              variant: ZenButtonVariant.primary,
              size: ZenButtonSize.large,
              fullWidth: true,
              icon: Icons.play_arrow_rounded,
            ),
          ] else if (_tournamentManager.isChampion && canImproveStars) ...[
            ZenButton(
              text: 'Perfeccionar Estrellas',
              onPressed: () {
                final levelToImprove = _tournamentManager.levels.firstWhere(
                  (level) => level.isCompleted && level.starsEarned < 3,
                );
                _startLevel(levelToImprove);
              },
              variant: ZenButtonVariant.secondary,
              size: ZenButtonSize.large,
              fullWidth: true,
              icon: Icons.star_border_rounded,
            ),
          ],
          
          if (_tournamentManager.isChampion && !canImproveStars) ...[
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing16),
              decoration: BoxDecoration(
                color: UIColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(color: UIColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events_rounded, color: UIColors.warning, size: 32),
                  const ZenSpacer.small(),
                  Text(
                    '¡Perfección Absoluta!',
                    style: ZenTextStyles.body.copyWith(
                      color: UIColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Has obtenido todas las estrellas posibles',
                    style: ZenTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startLevel(TournamentLevel level) {
    final game = CollapsiEngine();
    game.setGridSize(level.gridSize);
    game.toggleAIMode();
    
    final isReplay = level.isCompleted;
    
    debugPrint('🚀 Iniciando nivel ${level.id}: ${level.name}');
    debugPrint('   Grid: ${level.gridSize}x${level.gridSize}');
    debugPrint('   Dificultad: ${level.aiDifficulty}');
    debugPrint('   Es rejuego: $isReplay');
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            GameScreen(
              game: game,
              allowUndo: false,
              allowRestart: false,
              isReplay: isReplay,
              tournamentLevelId: level.id,
              // Callback que pasa el juego para análisis
              onGameEndWithResult: (result) => _onLevelCompletedWithGame(level, result, game),
            ),
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

  // Calcular tamaño de fuente para botones
  double _calculateButtonFontSize(double availableWidth) {
    if (availableWidth < 80) {
      return 12.0;
    } else if (availableWidth < 120) {
      return 14.0;
    } else {
      return 16.0;
    }
  }

  // Calcular padding para botones
  double _calculateButtonPadding(double availableWidth) {
    if (availableWidth < 80) {
      return 8.0;
    } else if (availableWidth < 120) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  // Botón responsivo para análisis (sin emoticono, con color)
  Widget _buildResponsiveAnalysisButton({required VoidCallback onPressed}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = _calculateButtonFontSize(constraints.maxWidth);
        double padding = _calculateButtonPadding(constraints.maxWidth);
        
        return Container(
          height: UIConstants.buttonHeight,
          decoration: BoxDecoration(
            color: UIColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            border: Border.all(color: UIColors.warning, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: padding),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Analizar',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: UIColors.warning,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Botón responsivo para continuar
  Widget _buildResponsiveContinueButton({required VoidCallback onPressed}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = _calculateButtonFontSize(constraints.maxWidth);
        double padding = _calculateButtonPadding(constraints.maxWidth);
        
        return Container(
          height: UIConstants.buttonHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [UIColors.primary, UIColors.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: UIColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: padding),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Habilitar modo análisis en la misma pantalla (no navegar)
  void _enableAnalysisMode(TournamentLevel level, GameResult result) {
    Navigator.of(context).pop(); // Cerrar el diálogo de resultado
    
    // Usar el juego guardado o crear uno nuevo como fallback
    final analysisGame = _currentGameForAnalysis ?? (() {
      final fallbackGame = CollapsiEngine();
      fallbackGame.setGridSize(level.gridSize);
      fallbackGame.toggleAIMode();
      return fallbackGame;
    })();
    
    // Navegar al GameScreen en modo análisis
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            GameScreen(
              game: analysisGame,
              allowUndo: false,
              allowRestart: false,
              isAnalysisMode: true, // Modo análisis
              tournamentLevelId: level.id,
              onAnalysisComplete: () {
                Navigator.of(context).pop(); // Volver al torneo
              },
              onRetryLevel: () {
                Navigator.of(context).pop(); // Salir del análisis
                _startLevel(level); // Reiniciar nivel
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AnimationConstants.fast,
      ),
    );
  }
  
  // Navegar al juego con controles post-game cuando se pierde
  void _navigateToGameWithPostGameControls(TournamentLevel level) {
    final game = CollapsiEngine();
    game.setGridSize(level.gridSize);
    game.toggleAIMode();
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            GameScreen(
              game: game,
              allowUndo: false,
              allowRestart: false,
              tournamentLevelId: level.id,
              showPostGameControls: true, // Mostrar controles post-juego
              onRetryLevel: () => _retryLevel(level),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AnimationConstants.fast,
      ),
    );
  }

  // Método para retry level
  void _retryLevel(TournamentLevel level) {
    Navigator.of(context).pop(); // Salir del GameScreen actual
    _startLevel(level); // Iniciar el nivel de nuevo
  }

  Future<void> _onLevelCompleted(TournamentLevel level, GameResult result) async {
    debugPrint('🏆 Nivel ${level.id} finalizado con resultado:');
    debugPrint('   Humano ganó: ${result.humanWon}');
    debugPrint('   Movimientos: ${result.moveCount}');
    debugPrint('   Era rejuego: ${level.isCompleted}');

    if (!result.humanWon) {
      debugPrint('❌ Nivel no completado (humano perdió)');
      // Mostrar controles post-juego en la misma pantalla
      if (mounted) {
        _navigateToGameWithPostGameControls(level);
      }
      return;
    }

    try {
      final improved = await _tournamentManager.completeLevel(level.id, result.moveCount);
      
      debugPrint('✅ Progreso guardado automáticamente');
      debugPrint('   Mejora lograda: $improved');
      
      final dataIntegrity = _tournamentManager.verifyDataIntegrity();
      if (!dataIntegrity) {
        debugPrint('⚠️ Problema de integridad detectado después del guardado');
      }

      if (mounted) {
        // Pausa adicional después del overlay animado
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Actualizar lógica de expansión después de completar nivel
        _applySmartExpansionLogic();
        
        setState(() {
          // Refresh UI con nuevo progreso
        });
        
        // Pasar información del juego para análisis
        _showLevelCompletedDialog(level, result, improved);
      }
    } catch (e) {
      debugPrint('❌ Error completando nivel: $e');
      
      try {
        await _tournamentManager.forceSave();
        debugPrint('🔄 Guardado manual ejecutado como fallback');
      } catch (saveError) {
        debugPrint('❌ Error crítico en guardado manual: $saveError');
      }
      
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando progreso. Reintenta el nivel.'),
            backgroundColor: UIColors.error,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _onLevelCompletedWithGame(TournamentLevel level, GameResult result, CollapsiEngine currentGame) async {
    // Guardar una referencia al juego actual para análisis
    _currentGameForAnalysis = currentGame.createAnalysisCopy();
    
    // Llamar al método original
    await _onLevelCompleted(level, result);
  }

  // Variable para almacenar el juego para análisis
  CollapsiEngine? _currentGameForAnalysis;

  void _showLevelCompletedDialog(TournamentLevel level, GameResult result, bool improved) {
    final stars = _calculateStars(result.moveCount, level);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultDialog(level, result, stars, improved),
    );
  }

  // Construir el diálogo de resultado con botón de análisis
  Widget _buildResultDialog(TournamentLevel level, GameResult result, int stars, bool improved) {
    final isVictory = result.humanWon;
    
    // Determinar si mostrar el récord basado en si es la primera vez o no
    final bool isFirstCompletion = level.bestMoves == 0;
    final int? displayRecord = isFirstCompletion ? null : level.bestMoves;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
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
            // Icono principal
            Container(
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
            
            const ZenSpacer.large(),
            
            // Título
            Text(
              isVictory ? '¡Nivel Completado!' : '¡Inténtalo otra vez!',
              style: ZenTextStyles.title.copyWith(
                color: isVictory ? UIColors.success : UIColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            
            const ZenSpacer.small(),
            
            Text(
              level.name,
              style: ZenTextStyles.bodySecondary.copyWith(
                color: UIColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const ZenSpacer.medium(),
            
            // Estadísticas
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing16),
              decoration: BoxDecoration(
                color: UIColors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: displayRecord != null ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Icon(Icons.timer_rounded, size: 24, color: UIColors.textSecondary),
                      const ZenSpacer.small(),
                      Text(
                        '${result.moveCount}',
                        style: ZenTextStyles.bodySecondary.copyWith(
                          color: UIColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Movimientos',
                        style: ZenTextStyles.caption.copyWith(
                          color: UIColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Solo mostrar récord si no es la primera vez
                  if (displayRecord != null)
                    Column(
                      children: [
                        Icon(Icons.emoji_events_rounded, size: 24, color: UIColors.success),
                        const ZenSpacer.small(),
                        Text(
                          '$displayRecord',
                          style: ZenTextStyles.bodySecondary.copyWith(
                            color: UIColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Récord',
                          style: ZenTextStyles.caption.copyWith(
                            color: UIColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Estrellas si ganó
            if (isVictory) ...[
              const ZenSpacer.large(),
              Column(
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
                      final isEarned = index < stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isEarned ? UIColors.warning : UIColors.textTertiary,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
            
            // Badge de mejora (solo si no es la primera vez)
            if (improved && !isFirstCompletion) ...[
              const ZenSpacer.medium(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.spacing16,
                  vertical: UIConstants.spacing8,
                ),
                decoration: BoxDecoration(
                  color: UIColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
                  border: Border.all(
                    color: UIColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 20,
                      color: UIColors.warning,
                    ),
                    const ZenSpacer.horizontal(),
                    Text(
                      '¡Nuevo récord personal!',
                      style: ZenTextStyles.caption.copyWith(
                        color: UIColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const ZenSpacer.large(),
            const ZenSpacer.small(),
            
            // Botones con análisis para victoria
            if (isVictory) ...[
              Row(
                children: [
                  // Botón Analizar Partida (sin emoticono, con color)
                  Expanded(
                    child: _buildResponsiveAnalysisButton(
                      onPressed: () => _enableAnalysisMode(level, result),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón Continuar más ancho (flex: 2)
                  Expanded(
                    flex: 2, // Más ancho como pidió el usuario
                    child: _buildResponsiveContinueButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Para derrotas (este caso ya no se ejecutará normalmente)
              Row(
                children: [
                  Expanded(
                    child: ZenButton(
                      text: 'Volver',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      variant: ZenButtonVariant.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // === FUNCIONES DE STREAK (sin modificar) ===
  Future<void> _startBlockStreak(int blockNumber) async {
    // Guardar el estado ANTES de iniciar el streak
    _blockHadStreakStarBeforeStart[blockNumber] = _tournamentManager.hasBlockStreakStar(blockNumber);

    // Mostrar diálogo de confirmación
    final confirmed = await _showStreakConfirmationDialog(blockNumber);
    if (!confirmed) return;

    // Iniciar el streak
    final success = await _tournamentManager.startBlockStreak(blockNumber);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo iniciar el Modo Bloque Perfecto'),
            backgroundColor: UIColors.error,
          ),
        );
      }
      return;
    }

    // Navegar al primer nivel del streak
    final firstLevel = _tournamentManager.getCurrentStreakLevel();
    if (firstLevel != null && mounted) {
      _startStreakLevel(firstLevel);
    }
  }

  Future<bool> _showStreakConfirmationDialog(int blockNumber) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => _buildStreakConfirmationDialog(blockNumber),
    ) ?? false;
  }

  Widget _buildStreakConfirmationDialog(int blockNumber) {
    return Dialog(
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
              child: _buildDialogContent(blockNumber),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            StreakColors.goldLight,
            StreakColors.fireOrange,
            StreakColors.fireRed,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: StreakColors.fireOrange.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: StreakColors.fireRed.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        Icons.local_fire_department_rounded,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDialogContent(int blockNumber) {
    return Container(
      margin: const EdgeInsets.all(UIConstants.spacing24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        border: Border.all(
          color: StreakColors.fireOrange.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: StreakColors.fireOrange.withOpacity(0.1),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                UIColors.surface,
                UIColors.surfaceVariant.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    UIConstants.spacing32,
                    UIConstants.spacing32,
                    UIConstants.spacing32,
                    UIConstants.spacing24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogHeader(),
                      const ZenSpacer.large(),
                      _buildDialogTitle(blockNumber),
                      const ZenSpacer.medium(),
                      _buildDialogDescription(blockNumber),
                      const ZenSpacer.large(),
                      _buildRulesCard(),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(UIConstants.spacing32),
                decoration: BoxDecoration(
                  color: UIColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: UIColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: _buildDialogActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogActions() {
    return Row(
      children: [
        Expanded(
          child: _buildResponsiveSecondaryButton(
            text: 'Volver',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        const ZenSpacer.horizontal(),
        Expanded(
          flex: 2,
          child: _buildResponsivePrimaryButton(
            text: 'Empezar Desafío',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveSecondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: UIConstants.buttonHeight + 8,
      decoration: BoxDecoration(
        color: UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(color: UIColors.border, width: 1),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildResponsiveText(
              text, 
              UIColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsivePrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: UIConstants.buttonHeight + 8,
      decoration: BoxDecoration(
        gradient: StreakColors.fireGradient,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: StreakColors.fireOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildResponsiveText(
              text, 
              Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveText(String text, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        double baseFontSize;
        if (screenWidth < 350) {
          baseFontSize = 13.0;
        } else if (screenWidth < 400) {
          baseFontSize = 15.0;
        } else {
          baseFontSize = 17.0;
        }

        String displayText = text;
        double fontSize = baseFontSize;

        if (constraints.maxWidth < 120) {
          if (text == 'Volver') {
            displayText = 'Salir';
          } else if (text == 'Empezar Desafío') {
            displayText = 'Empezar';
            fontSize = baseFontSize - 1;
          }
        } else if (constraints.maxWidth < 160) {
          if (text == 'Empezar Desafío') {
            displayText = 'Empezar';
          }
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
            ),
            child: Text(
              displayText,
              style: ZenTextStyles.buttonLarge.copyWith(
                fontSize: fontSize,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogTitle(int blockNumber) {
    return Column(
      children: [
        Text(
          'Modo Bloque Perfecto',
          style: ZenTextStyles.title.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: UIColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const ZenSpacer.small(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing16,
            vertical: UIConstants.spacing8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                StreakColors.fireOrange.withOpacity(0.1),
                StreakColors.fireRed.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
            border: Border.all(
              color: StreakColors.fireOrange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Bloque $blockNumber',
            style: ZenTextStyles.body.copyWith(
              color: StreakColors.fireRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogDescription(int blockNumber) {
    return Text(
      '¿Estás listo para el desafío definitivo?\nCompleta los 5 niveles del Bloque $blockNumber sin perder ninguno.',
      style: ZenTextStyles.body.copyWith(
        color: UIColors.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing24),
      decoration: BoxDecoration(
        color: UIColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        border: Border.all(
          color: UIColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: UIColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: UIColors.warning,
                ),
              ),
              const ZenSpacer.horizontal(),
              Text(
                'Reglas del Desafío',
                style: ZenTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: UIColors.textPrimary,
                ),
              ),
            ],
          ),
          const ZenSpacer.medium(),
          ..._buildRulesList(),
        ],
      ),
    );
  }

  List<Widget> _buildRulesList() {
    final rules = [
      ('🎯', 'Debes ganar los 5 niveles consecutivos'),
      ('❌', 'Si pierdes cualquier nivel, empiezas de nuevo'),
      ('🚪', 'Si sales del juego, pierdes el progreso'),
    ];

    return rules.map((rule) {
      return Padding(
        padding: const EdgeInsets.only(bottom: UIConstants.spacing12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: UIConstants.spacing12),
              decoration: BoxDecoration(
                color: UIColors.surface,
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                border: Border.all(
                  color: UIColors.borderLight,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  rule.$1,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: Text(
                rule.$2,
                style: ZenTextStyles.body.copyWith(
                  fontSize: 14,
                  color: UIColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _startStreakLevel(TournamentLevel level) {
    final game = CollapsiEngine();
    game.setGridSize(level.gridSize);
    game.toggleAIMode();
    
    debugPrint('🔥 Iniciando nivel de streak ${level.id}: ${level.name}');
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            GameScreen(
              game: game,
              allowUndo: false, // Sin undo en modo streak
              allowRestart: false, // Sin reinicio en modo streak
              isStreakMode: true,
              tournamentLevelId: level.id,
              streakState: _tournamentManager.currentActiveStreak,
              onStreakLevelComplete: (levelId, result) => _onStreakLevelCompleted(levelId, result),
            ),
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
  
  // Añadir método para manejar completado de nivel de streak
  Future<void> _onStreakLevelCompleted(int levelId, GameResult result) async {
    if (levelId == -1) {
      debugPrint('🚪 Usuario salió del streak');
      await _tournamentManager.cancelActiveStreak('user_exit');
      return;
    }

    debugPrint('🔥 Nivel de streak $levelId finalizado - Ganó: ${result.humanWon}');

    // Actualizar progreso del streak
    final success = await _tournamentManager.updateStreakProgress(levelId, result.humanWon);

    if (!result.humanWon) {
      // STREAK FALLIDO
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showStreakFailedDialog();
      }
      return;
    }

    if (!success) {
      // Error en el streak
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el streak. Intenta de nuevo.'),
            backgroundColor: UIColors.error,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Nivel completado exitosamente
    final currentStreak = _tournamentManager.currentActiveStreak;

    if (currentStreak == null) {
      // Streak completado
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        _showStreakCompletedDialog(); // Ya detecta automáticamente si es primera vez
      }
      return;
    }

    // Continuar al siguiente nivel
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      _showContinueStreakDialog(currentStreak);
    }
  }

  // Diálogo de streak fallido
  void _showStreakFailedDialog() {
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
                child: _buildStreakFailedDialogContent(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStreakFailedDialogContent() {
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
                // Icono estático (sin animaciones)
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
                    Icons.local_fire_department_outlined,
                    size: 40,
                    color: UIColors.error,
                  ),
                ),

                const ZenSpacer.large(),

                // Título
                Text(
                  'Streak Perdido',
                  style: ZenTextStyles.title.copyWith(
                    color: UIColors.error,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const ZenSpacer.medium(),

                // Mensaje reducido
                Text(
                  'El desafío se reinicia.\n¡Inténtalo de nuevo!',
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

          // Botón
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: _buildResponsiveErrorButton(
              text: 'Volver al Torneo',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildResponsiveErrorButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: UIConstants.buttonHeight + 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                UIColors.error,
                UIColors.error.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: UIColors.error.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: ZenTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  // Diálogo de streak completado
  void _showStreakCompletedDialog() {
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
                child: _buildStreakCompletedDialogContent(),
              ),
            );
          },
        ),
      ),
    );
  }


  
Widget _buildStreakCompletedDialogContent() {
    // Detectar si es primera vez o rejuego
  final activeStreak = _tournamentManager.currentActiveStreak;
  final blockNumber = activeStreak?.blockNumber ?? 1;
  final wasAlreadyCompleted = _blockHadStreakStarBeforeStart[blockNumber] ?? false;
  final isFirstTime = !wasAlreadyCompleted;

  return Container(
    margin: const EdgeInsets.all(UIConstants.spacing24),
    decoration: BoxDecoration(
      // Gradiente dorado más intenso para primera vez
      gradient: isFirstTime 
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                StreakColors.goldLight.withOpacity(0.95), // Mucho más dorado
                StreakColors.gold.withOpacity(0.92),
                StreakColors.goldDark.withOpacity(0.88),
                UIColors.surface.withOpacity(0.95),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                UIColors.surface,
                StreakColors.gold.withOpacity(0.1),
              ],
            ),
      borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
      border: Border.all(
        color: isFirstTime 
            ? StreakColors.gold.withOpacity(0.6) // Borde más dorado para primera vez
            : StreakColors.gold.withOpacity(0.4),
        width: isFirstTime ? 4 : 3, // Borde más grueso para primera vez
      ),
      boxShadow: [
        BoxShadow(
          color: StreakColors.gold.withOpacity(isFirstTime ? 0.4 : 0.3),
          blurRadius: isFirstTime ? 40 : 30, // Sombra más intensa para primera vez
          spreadRadius: isFirstTime ? 2 : 0,
          offset: const Offset(0, 15),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
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
              // Icono épico estático (sin animaciones)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      StreakColors.goldLight,
                      StreakColors.gold,
                      StreakColors.goldDark,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: StreakColors.gold.withOpacity(isFirstTime ? 0.6 : 0.5),
                      blurRadius: isFirstTime ? 35 : 25,
                      spreadRadius: isFirstTime ? 4 : 3,
                    ),
                    BoxShadow(
                      color: StreakColors.goldLight.withOpacity(0.4),
                      blurRadius: 45,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.diamond_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const ZenSpacer.large(),

              // Título diferente según primera vez o rejuego
              Text(
                isFirstTime 
                    ? '💎 ¡Primer Diamante Ganado! 💎'
                    : '🎉 ¡Bloque Perfecto de Nuevo! 🎉',
                style: ZenTextStyles.title.copyWith(
                  color: isFirstTime 
                      ? Color(0xFFF57F17) // Más dorado para primera vez
                      : StreakColors.goldDark,
                  fontSize: isFirstTime ? 26 : 24,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

              const ZenSpacer.medium(),

              // Mensaje diferente según primera vez o rejuego
              Container(
                padding: const EdgeInsets.all(UIConstants.spacing16),
                decoration: BoxDecoration(
                  color: isFirstTime 
                      ? StreakColors.gold.withOpacity(0.25) // Más opaco para primera vez
                      : StreakColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                  border: Border.all(
                    color: StreakColors.gold.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  isFirstTime 
                      ? '¡Increíble! Has completado el\nBloque Perfecto, toma tu diamante!'
                      : '¡Excelente! Has vuelto a dominar\neste bloque completamente.',
                  style: ZenTextStyles.body.copyWith(
                    color: isFirstTime 
                        ? Color(0xFFF57F17) // Más dorado para primera vez
                        : StreakColors.goldDark,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Separador dorado más visible
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  StreakColors.gold.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Botón épico con actualización automática
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: _buildResponsiveGoldButton(
              text: isFirstTime ? '¡Increíble!' : '¡Genial!',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                // Actualizar automáticamente la pantalla del torneo
                _refreshTournamentState();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Actualizar automáticamente el estado del torneo después de completar un streak
  Future<void> _refreshTournamentState() async {
    try {
      // Recargar el progreso del tournament manager
      await _tournamentManager.initialize();

      // Aplicar la lógica de expansión inteligente
      _applySmartExpansionLogic();

      // Forzar actualización de la UI
      if (mounted) {
        setState(() {
          // Esto fuerza la reconstrucción completa de la pantalla
        });
      }

      debugPrint('✅ Estado del torneo actualizado automáticamente');
    } catch (e) {
      debugPrint('❌ Error actualizando estado del torneo: $e');
    }
  }



  Widget _buildResponsiveGoldButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: UIConstants.buttonHeight + 12,
          decoration: BoxDecoration(
            gradient: StreakColors.goldGradient,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: StreakColors.gold.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: StreakColors.goldLight.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: ZenTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // Diálogo para continuar streak
  void _showContinueStreakDialog(BlockStreakState streakState) {
    final nextLevel = _tournamentManager.getNextStreakLevel();

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
                child: _buildContinueStreakDialogContent(streakState, nextLevel),
              ),
            );
          },
        ),
      ),
    );
  }

  
  Widget _buildContinueStreakDialogContent(BlockStreakState streakState, TournamentLevel? nextLevel) {
    return Container(
      margin: const EdgeInsets.all(UIConstants.spacing24),
      decoration: BoxDecoration(
        // Fondo más opaco para mejor legibilidad
        color: UIColors.surface, // Fondo sólido en lugar de gradiente
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        border: Border.all(
          color: UIColors.success.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: UIColors.success.withOpacity(0.1),
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
                // Icono de progreso estático (sin animaciones)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        UIColors.success.withOpacity(0.2),
                        UIColors.success.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: UIColors.success.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 40,
                    color: UIColors.success,
                  ),
                ),

                const ZenSpacer.large(),

                // Título
                Text(
                  '¡Nivel Ganado!',
                  style: ZenTextStyles.title.copyWith(
                    color: UIColors.success,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const ZenSpacer.medium(),

                // Progreso con fondo más contrastado
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacing16),
                  decoration: BoxDecoration(
                    color: UIColors.success.withOpacity(0.15), // Más opaco para mejor contraste
                    borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                    border: Border.all(
                      color: UIColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        streakState.progressText,
                        style: ZenTextStyles.body.copyWith(
                          color: UIColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (nextLevel != null) ...[
                        const ZenSpacer.small(),
                        Text(
                          'Siguiente: ${nextLevel.name}',
                          style: ZenTextStyles.caption.copyWith(
                            color: UIColors.textPrimary, // Más contrastado
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Separador
          Container(
            height: 1,
            color: UIColors.borderLight,
          ),

          // Solo botón continuar (sin cancelar)
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: _buildResponsiveSuccessButton(
              text: 'Continuar Streak',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                if (nextLevel != null) {
                  _startStreakLevel(nextLevel);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveSuccessButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: UIConstants.buttonHeight + 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                UIColors.success,
                UIColors.success.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: UIColors.success.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: ZenTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
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