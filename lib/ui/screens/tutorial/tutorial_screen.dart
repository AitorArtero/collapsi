import 'package:flutter/material.dart';
import '../../widgets/tutorial/tutorial_card.dart';
import '../../widgets/tutorial/tutorial_navigation.dart';
import '../../../core/tutorial_constants.dart';
import '../../../core/tutorial_manager.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> 
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones suaves estilo iOS
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Iniciar animaciones con delay
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentIndex < TutorialConstants.tutorialSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finishTutorial() {
    TutorialManager.startTutorialGame(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Fondo muy suave estilo iOS
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildTutorialCards(),
                ),
                _buildNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        children: [
          // Título principal estilo iOS
          Text(
            'Bienvenido a Collapsi',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1C1E),
              letterSpacing: -0.5,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCards() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: TutorialConstants.tutorialSteps.length,
      itemBuilder: (context, index) {
        final step = TutorialConstants.tutorialSteps[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: TutorialCard(
              title: step['title'],
              description: step['description'],
              exampleType: step['exampleType'],
              stepNumber: index + 1,
              totalSteps: TutorialConstants.tutorialSteps.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: TutorialNavigation(
        currentIndex: _currentIndex,
        totalSteps: TutorialConstants.tutorialSteps.length,
        onNext: _nextStep,
        onPrevious: _previousStep,
        onFinish: _finishTutorial,
      ),
    );
  }
}