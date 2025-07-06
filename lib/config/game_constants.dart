/// Estados de celda
enum CellState {
  empty,
  blue,
  red,
  blocked,
}

/// Configuración de juego
class GameConstants {
  static const int gridSize = 4;
  static const double aiThinkDuration = 1.0;
  static const int maxHistorySize = 20;
  static const List<int> initialValues = [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 99, 100];
  static const double touchTimeout = 0.5;
}
