import 'package:flutter/material.dart';
import '../../config/ui_constants.dart';
import '../../core/collapsi_engine.dart';

/// Panel de configuración desplegable para Collapsi - Versión zen
class SettingsPanel extends StatefulWidget {
  final CollapsiEngine game;
  final VoidCallback? onRebuildBoard;

  const SettingsPanel({
    super.key,
    required this.game,
    this.onRebuildBoard,
  });

  @override
  State<SettingsPanel> createState() => SettingsPanelState();
}

class SettingsPanelState extends State<SettingsPanel>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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
      animation: _animationController,
      builder: (context, child) {
        return ClipRect(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isExpanded ? null : 0.0,
            constraints: _isExpanded 
                ? const BoxConstraints(maxHeight: 120.0)
                : const BoxConstraints(maxHeight: 0.0),
            child: SingleChildScrollView(
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: _isExpanded ? _buildSettings() : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing24,
        vertical: UIConstants.spacing8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del panel
          Text(
            '⚙️ CONFIGURACIÓN',
            style: ZenTextStyles.body.copyWith(
              color: UIColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),

          // Configuración de tamaño del grid
          _buildGridSettings(),
          const SizedBox(height: UIConstants.spacing8),

          // Configuración de dificultad IA (solo si está en modo IA)
          if (widget.game.aiMode) ...[
            _buildAISettings(),
          ],
        ],
      ),
    );
  }

  Widget _buildGridSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📐 Tamaño del Tablero:',
          style: ZenTextStyles.caption.copyWith(
            color: UIColors.textSecondary,
          ),
        ),
        const SizedBox(height: UIConstants.spacing4),
        Row(
          children: [4, 5, 6].map((size) {
            final isSelected = size == widget.game.gridSize;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () => _changeGridSize(size),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? UIColors.primary
                        : UIColors.surfaceVariant,
                    foregroundColor: isSelected 
                        ? Colors.white 
                        : UIColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    ),
                    splashFactory: NoSplash.splashFactory,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Text(
                    '${size}x$size',
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAISettings() {
    const difficulties = [
      ('Fácil', 'easy'),
      ('Medio', 'medium'),
      ('Difícil', 'hard'),
      ('Experto', 'expert'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤖 Dificultad de la IA:',
          style: ZenTextStyles.caption.copyWith(
            color: UIColors.textSecondary,
          ),
        ),
        const SizedBox(height: UIConstants.spacing4),
        Row(
          children: difficulties.map((difficulty) {
            final text = difficulty.$1;
            final value = difficulty.$2;
            final isSelected = value == widget.game.aiDifficulty;
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: ElevatedButton(
                  onPressed: () => _changeAIDifficulty(value),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? UIColors.primary
                        : UIColors.surfaceVariant,
                    foregroundColor: isSelected 
                        ? Colors.white 
                        : UIColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    ),
                    splashFactory: NoSplash.splashFactory,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 10.0),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _changeGridSize(int size) {
    debugPrint("🔧 Cambiando tamaño de grid a ${size}x$size");
    if (size != widget.game.gridSize) {
      widget.game.setGridSize(size);
      widget.onRebuildBoard?.call();
      setState(() {});
      debugPrint("✅ Grid cambiado exitosamente a ${size}x$size");
    } else {
      debugPrint("⚠️ El grid ya es ${size}x$size");
    }
  }

  void _changeAIDifficulty(String difficulty) {
    debugPrint("🎯 Cambiando dificultad IA a: $difficulty");
    widget.game.setAIDifficulty(difficulty);
    setState(() {});
    debugPrint("✅ Dificultad cambiada a: $difficulty");
  }

  void togglePanel() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      debugPrint("🔼 Expandiendo panel...");
      _animationController.forward();
    } else {
      debugPrint("🔽 Contrayendo panel...");
      _animationController.reverse();
    }
  }

  bool get isExpanded => _isExpanded;

  void closePanel() {
    if (_isExpanded) {
      debugPrint("🚪 Cerrando panel...");
      setState(() {
        _isExpanded = false;
      });
      _animationController.reverse();
    }
  }

  Map<String, dynamic> getDifficultyInfo() {
    const difficultyInfo = {
      'easy': {
        'name': 'Fácil',
        'emoji': '🤖',
        'ai_type': 'Greedy',
        'description': 'IA simple que busca maximizar opciones inmediatas',
      },
      'medium': {
        'name': 'Medio',
        'emoji': '🧠',
        'ai_type': 'Heurística',
        'description': 'IA balanceada con estrategia equilibrada',
      },
      'hard': {
        'name': 'Difícil',
        'emoji': '🎯',
        'ai_type': 'Heurística Agresiva',
        'description': 'IA experta con máxima agresividad estratégica',
      },
      'expert': {
        'name': 'Experto',
        'emoji': '🧠',
        'ai_type': 'Minimax',
        'description': 'IA perfecta con algoritmo Minimax y poda Alpha-Beta',
      },
    };

    return difficultyInfo[widget.game.aiDifficulty] ??
        difficultyInfo['medium']!;
  }
}