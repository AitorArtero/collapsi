import 'package:flutter/material.dart';
import 'tutorial_board_example.dart';

class TutorialCard extends StatefulWidget {
  final String title;
  final String description;
  final String exampleType;
  final int stepNumber;
  final int totalSteps;

  const TutorialCard({
    Key? key,
    required this.title,
    required this.description,
    required this.exampleType,
    required this.stepNumber,
    required this.totalSteps,
  }) : super(key: key);

  @override
  State<TutorialCard> createState() => _TutorialCardState();
}

class _TutorialCardState extends State<TutorialCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Animación de entrada con delay
    Future.delayed(const Duration(milliseconds: 200), () {
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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive breakpoints
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth < 600;
    final isShortScreen = screenHeight < 700;
    
    // Responsive dimensions
    final cardMaxWidth = isSmallScreen ? screenWidth * 0.9 : isMediumScreen ? 400.0 : 420.0;
    final cardMaxHeight = isShortScreen ? screenHeight * 0.75 : screenHeight * 0.8;
    final boardSize = isSmallScreen ? 200.0 : isMediumScreen ? 240.0 : 280.0;
    final horizontalPadding = isSmallScreen ? 16.0 : isMediumScreen ? 20.0 : 24.0;
    final verticalPadding = isSmallScreen ? 20.0 : isMediumScreen ? 24.0 : 28.0;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: cardMaxWidth,
                maxHeight: cardMaxHeight,
              ),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ejemplo visual del tablero
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFF2F2F7),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: TutorialBoardExample(
                                exampleType: widget.exampleType,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isShortScreen ? 16 : 24),
                          
                          // Título
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : isMediumScreen ? 22 : 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C1C1E),
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: isShortScreen ? 8 : 12),
                          
                          // Descripción
                          Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : isMediumScreen ? 16 : 17,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF3C3C43),
                              letterSpacing: -0.2,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          // Añadir espacio extra para asegurar que no se corte el contenido
                          SizedBox(height: isShortScreen ? 8 : 16),
                        ],
                      ),
                    ),
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