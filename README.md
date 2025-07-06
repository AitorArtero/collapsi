# Collapsi

Un juego estratégico desarrollado en Flutter donde dos jugadores compiten por ser el último en poder moverse en un tablero que colapsa progresivamente.

## 🎮 Descripción del Juego

Collapsi es un juego de estrategia por turnos donde:
- Cada celda del tablero contiene un número que indica exactamente cuántas casillas debes moverte
- Después de cada movimiento, la casilla donde estabas se bloquea permanentemente
- El objetivo es dejar a tu oponente sin movimientos válidos disponibles
- Los movimientos pueden atravesar los bordes del tablero (wrap-around/túneles)

## ✨ Características

### Modos de Juego
- **Humano vs Humano**: Partidas locales entre dos jugadores
- **Humano vs IA**: 4 niveles de dificultad (Fácil, Medio, Difícil, Experto)
- **Modo torneo**: Sistema de progresión con múltiples niveles

### Configuraciones
- **Múltiples tamaños de tablero**: 4×4, 5×5, 6×6
- **Niveles de dificultad**: Fácil, Medio, Difícil y Experto
- **Ayuda visual de movimientos**: Resalta casillas válidas con delay configurable
- **Sistema de sonido**: Efectos sonoros y música de fondo
- **Retroalimentación háptica**: Vibraciones en dispositivos móviles

### Características Técnicas
- **Interfaz responsiva**: Optimizada para dispositivos móviles
- **Animaciones fluidas**: Transiciones suaves y efectos visuales
- **Persistencia de datos**: Guarda configuración y progreso del torneo
- **PathFinder inteligente**: Cálculo automático de rutas válidas para movimientos complejos

### Persistencia
Todas las configuraciones se guardan automáticamente usando `SharedPreferences` y se restauran al reiniciar la aplicación.

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                           # Punto de entrada de la aplicación
├── ai/
│   ├── ai_manager.dart                 # Coordinador de estrategias de IA
│   └── strategies/
│       ├── greedy_ai.dart              # IA nivel Fácil
│       ├── heuristic_ai.dart           # IA niveles Medio/Difícil
│       └── minimax_ai.dart             # IA nivel Experto
├── config/
│   ├── app_settings.dart               # Gestión de configuración persistente
│   ├── game_constants.dart             # Constantes del juego
│   ├── theme_manager.dart              # Gestión de temas claro/oscuro
│   └── ui_constants.dart               # Constantes de interfaz
├── core/
│   ├── animation_manager.dart          # Control de animaciones del juego
│   ├── background_music_manager.dart   # Gestión de música de fondo
│   ├── collapsi_engine.dart            # Motor principal del juego
│   ├── haptic_manager.dart             # Control de retroalimentación háptica
│   ├── path_finder.dart                # Algoritmo de búsqueda de rutas
│   ├── sound_manager.dart              # Gestión de efectos sonoros
│   ├── tournament_manager.dart         # Gestión del sistema de torneo
│   ├── tutorial_constants.dart         # Configuración del tutorial
│   └── tutorial_manager.dart           # Control del progreso del tutorial
├── models/                             # Modelos de datos (vacío actualmente)
├── ui/
│   ├── panels/
│   │   └── settings_panel.dart         # Panel de configuración
│   ├── screens/
│   │   ├── ai_details/                 # Pantallas de información de IA
│   │   │   ├── greedy_ai_detail_screen.dart
│   │   │   ├── heuristic_hard_detail_screen.dart
│   │   │   ├── heuristic_medium_detail_screen.dart
│   │   │   └── minimax_detail_screen.dart
│   │   ├── game_screen.dart            # Pantalla de juego principal
│   │   ├── local_game_setup_screen.dart # Configuración partida local
│   │   ├── menu_screen.dart            # Pantalla principal del menú
│   │   ├── quick_game_setup_screen.dart # Configuración partida rápida
│   │   ├── settings_screen.dart        # Pantalla de configuración
│   │   ├── tournament_screen.dart      # Pantalla del torneo
│   │   └── tutorial/
│   │       ├── tutorial_game_screen.dart # Partida de práctica tutorial
│   │       └── tutorial_screen.dart    # Pantalla de tutorial paso a paso
│   └── widgets/
│       ├── animated_piece.dart         # Pieza del juego con animaciones
│       ├── game_board.dart             # Tablero de juego principal
│       ├── game_cell.dart              # Celda individual del tablero
│       ├── game_result_overlay.dart    # Overlay de resultado de partida
│       ├── movement_help_snackbar.dart # Mensajes de ayuda visual
│       ├── theme_toggle_button.dart    # Botón para cambiar tema
│       ├── tutorial/
│       │   ├── tutorial_board_example.dart # Ejemplos animados del tutorial
│       │   ├── tutorial_card.dart      # Tarjetas de contenido tutorial
│       │   └── tutorial_navigation.dart # Navegación del tutorial
│       ├── zen_button.dart             # Botones con estilo personalizado
│       ├── zen_option_selector.dart    # Selector de opciones personalizado
│       └── zen_page_scaffold.dart      # Scaffold base para pantallas
└── utils/                              # Utilidades (vacío actualmente)
```

## 🚀 Instalación y Configuración

### Prerrequisitos

1. **Flutter SDK**: Versión 3.32 o superior
   ```bash
   # Verificar instalación
   flutter --version
   ```

2. **Dart SDK**: Versión 3.8 o superior (incluido con Flutter)

3. **Android Studio** (para desarrollo Android):
   - Android SDK
   - Android Emulator o dispositivo físico

4. **Xcode** (para desarrollo iOS - solo macOS):
   - iOS Simulator o dispositivo físico

### Pasos de Instalación

1. **Clonar el repositorio**:
   ```bash
   git clone <url-del-repositorio>
   cd collapsi
   ```

2. **Limpiar y obtener dependencias**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Verificar configuración**:
   ```bash
   flutter doctor
   ```

### Ejecución en Desarrollo

**Para pruebas en PC/móvil**:
```bash
flutter run
```

**Para pruebas en navegador web**:
```bash
flutter run -d chrome
```

**Para dispositivo específico**:
```bash
flutter devices                    # Ver dispositivos disponibles
flutter run -d <device-id>        # Ejecutar en dispositivo específico
```

### Compilación para Producción

**Android APK**:
```bash
flutter build apk --release
```
El archivo se genera en: `build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle** (recomendado para Google Play):
```bash
flutter build appbundle --release
```

**iOS** (solo en macOS):
```bash
flutter build ios --release
```

**Web**:
```bash
flutter build web --release
```

## 📦 Dependencias Principales

### Dependencias de Producción
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2              # Gestión de estado
  shared_preferences: ^2.3.3    # Persistencia de configuración
  audioplayers: ^6.3.0          # Reproducción de sonidos
```

### Dependencias de Desarrollo
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0         # Análisis de código
```

## 🤖 Sistema de "IA"

Aunque he etiquetado estos oponentes como "IA" ya que hoy en día todo el mundo esta familiarizado con este término, en realidad he implementado tres algoritmos clásicos de teoría de juegos. Esta decisión ofrece ventajas significativas sobre el machine learning tradicional: resultados más predecibles, menor complejidad de implementación, tiempo de respuesta instantáneo y ninguna necesidad de entrenamiento.

### Algoritmos Implementados
- **Greedy (Fácil)**: Selecciona el movimiento que maximiza las opciones disponibles inmediatamente
- **Heurístico (Medio/Difícil)**: Combina evaluación posicional con búsqueda limitada en profundidad
- **Minimax (Experto)**: Implementación completa con poda alfa-beta para explorar el árbol de juego

Dentro del juego, en el segundo tab de ajustes he implementado un apartado que explica de una manera mas detallada y beginner-friendly (con metaforas) como funcionan estos diferentes algoritmos.


## 📱 Compatibilidad

- **Android**: API 21+ (Android 5.0) - Completamente desarrollado y optimizado
- **iOS**: Potencialmente compatible, pero no probado ni optimizado específicamente
- **Web/Desktop**: Flutter permite compilación para estas plataformas, pero el desarrollo se ha centrado en Android

**Nota**: El desarrollo se ha enfocado exclusivamente en Android. Aunque Flutter es multiplataforma y teóricamente debería funcionar en iOS, web y desktop, no se han realizado pruebas ni optimizaciones específicas para estas plataformas.

## 📄 Licencia

Este proyecto está bajo la [Licencia MIT](LICENSE) - mira el archivo [LICENSE](LICENSE) para más detalles.

## 🎨 Experiencia de Usuario

### Interfaz
- **Diseño responsivo**: Se adapta automáticamente a diferentes tamaños de pantalla
- **Orientación vertical**: Optimizada para uso móvil
- **Animaciones fluidas**: 60 FPS con transiciones suaves
- **Retroalimentación visual**: Estados claros para todas las interacciones

### Accesibilidad
- **Contraste alto**: Colores diferenciados para jugadores y estados
- **Retroalimentación múltiple**: Visual, auditiva y háptica
- **Texto legible**: Tamaños de fuente apropiados para dispositivos móviles

---

## 📝 Nota Personal

Este juego está basado en un juego de cartas llamado "Collapsi". [Vi un video de este juego en YouTube](https://www.youtube.com/watch?v=6vYEHdjlw3g) y pensé que sería interesante crear un script básico donde diferentes algoritmos pudieran competir entre sí como, side project. El proyecto ha derivado en este juego completo, y estoy bastante orgulloso del resultado final.

Cualquier persona que quiera hacerle un fork al repositorio o proponer mejoras, ¡bienvenido sea! 😊