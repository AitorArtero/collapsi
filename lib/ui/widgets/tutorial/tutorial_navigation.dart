import 'package:flutter/material.dart';

class TutorialNavigation extends StatefulWidget {
  final int currentIndex;
  final int totalSteps;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onFinish;

  const TutorialNavigation({
    Key? key,
    required this.currentIndex,
    required this.totalSteps,
    this.onNext,
    this.onPrevious,
    this.onFinish,
  }) : super(key: key);

  @override
  State<TutorialNavigation> createState() => _TutorialNavigationState();
}

class _TutorialNavigationState extends State<TutorialNavigation>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  void _onButtonTapDown() {
    _buttonController.forward();
  }

  void _onButtonTapUp() {
    _buttonController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = widget.currentIndex == widget.totalSteps - 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Indicadores de progreso estilo iOS
          _buildProgressDots(),
          
          const SizedBox(height: 32),
          
          // Botones de navegación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón anterior (invisible si es el primer paso)
              _buildPreviousButton(),
              
              // Botón siguiente/empezar
              _buildNextButton(isLastStep),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.totalSteps, (index) {
        final isActive = index == widget.currentIndex;
        final isCompleted = index < widget.currentIndex;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive || isCompleted
                ? const Color(0xFF007AFF)
                : const Color(0xFFE5E5EA),
          ),
        );
      }),
    );
  }

  Widget _buildPreviousButton() {
    return SizedBox(
      width: 80,
      child: widget.currentIndex > 0
          ? TextButton(
              onPressed: widget.onPrevious,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                'Anterior',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF007AFF),
                  letterSpacing: -0.2,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNextButton(bool isLastStep) {
    return GestureDetector(
      onTapDown: (_) => _onButtonTapDown(),
      onTapUp: (_) => _onButtonTapUp(),
      onTapCancel: () => _onButtonTapUp(),
      onTap: isLastStep ? widget.onFinish : widget.onNext,
      child: AnimatedBuilder(
        animation: _buttonScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _buttonScaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                isLastStep ? '¡Empecemos!' : 'Siguiente',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}