class TutorialConstants {
  static const List<Map<String, dynamic>> tutorialSteps = [
    {
      'title': 'Movimiento básico',
      'description': 'Solo puedes moverte a casillas adyacentes (arriba, abajo, izquierda, derecha). Los movimientos en diagonal no están permitidos.',
      'exampleType': 'movement',
    },
    {
      'title': 'Límite de movimientos',
      'description': 'Debes usar exactamente la cantidad de movimientos que indica el número en tu casilla actual. Ni más, ni menos.',
      'exampleType': 'moves_limit',
    },
    {
      'title': 'Casillas bloqueadas',
      'description': 'Después de moverte, la casilla donde estabas se bloquea permanentemente. Nadie puede volver a usarla.',
      'exampleType': 'blocked_tiles',
    },
    {
      'title': 'Túneles en los bordes',
      'description': 'Si tu movimiento te lleva fuera del tablero, aparecerás en el lado opuesto de la misma fila o columna.',
      'exampleType': 'corner_teleport',
    },
    {
      'title': 'Objetivo del juego',
      'description': '¡Gana siendo el último en moverse! Tu objetivo es dejar a tu oponente sin movimientos válidos disponibles.',
      'exampleType': 'win_condition',
    },
  ];
  
  /// Configuración del juego tutorial
  static const int tutorialBoardSize = 4; // Tablero 4x4
  static const String tutorialAiLevel = 'easy'; // IA nivel fácil
  
  /// Textos adicionales para el tutorial
  static const String welcomeTitle = 'Bienvenido a Collapsi';
  static const String welcomeSubtitle = 'Aprende a jugar en solo 5 pasos';
  
  static const String tutorialGameTitle = 'Partida de práctica';
  static const String tutorialGameSubtitle = 'Tablero 4×4 contra IA nivel fácil';
  
  static const String completionTitle = '¡Tutorial completado!';
  static const String completionMessage = 'Ahora estás listo para jugar partidas completas y disfrutar de todos los modos de juego.';
  
  static const String nextButtonText = 'Siguiente';
  static const String previousButtonText = 'Anterior';
  static const String startButtonText = '¡Empecemos!';
  static const String menuButtonText = 'Ir al menú principal';
  
  /// Configuración de animaciones
  static const Duration cardAnimationDuration = Duration(milliseconds: 500);
  static const Duration navigationAnimationDuration = Duration(milliseconds: 400);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 600);
  
  /// Colores específicos del tutorial (en caso de no tener tema definido)
  static const int primaryBlue = 0xFF007AFF;
  static const int successGreen = 0xFF34C759;
  static const int warningOrange = 0xFFFF9500;
  static const int dangerRed = 0xFFFF3B30;
  static const int purple = 0xFFAF52DE;
  static const int gray = 0xFF8E8E93;
  static const int lightGray = 0xFFE5E5EA;
  
  /// Configuración de espaciado
  static const double cardPadding = 32.0;
  static const double cardMargin = 24.0;
  static const double buttonSpacing = 16.0;
  static const double sectionSpacing = 32.0;
}