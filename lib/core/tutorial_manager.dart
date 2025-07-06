import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/screens/tutorial/tutorial_screen.dart';
import '../ui/screens/tutorial/tutorial_game_screen.dart';

class TutorialManager {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const bool _forceShowTutorial = false; // Cambiar a true para testing, false para producción
  
  /// Modo desarrollo - fuerza mostrar tutorial siempre
  static bool get isDevMode => _forceShowTutorial;
  
  /// Verifica si el usuario ha completado el tutorial
  static Future<bool> hasCompletedTutorial() async {
    if (_forceShowTutorial) return false; // Para desarrollo/testing
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }
  
  /// Marca el tutorial como completado
  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }
  
  /// Resetea el tutorial (útil para testing y configuraciones)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
  }
  
  /// Inicia el tutorial manualmente
  static void startTutorial(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TutorialScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Transición suave estilo iOS
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
  
  /// Inicia el juego tutorial (4x4 vs IA fácil)
  static void startTutorialGame(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TutorialGameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Transición suave hacia la derecha
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
  
  /// Verifica si debe mostrar el tutorial y lo inicia automáticamente
  /// Retorna true si se mostró el tutorial, false si no
  static Future<bool> checkAndShowTutorialIfNeeded(BuildContext context) async {
    try {
      final completed = await hasCompletedTutorial();
      
      if (!completed) {
        // Asegurarse de que el contexto sigue siendo válido
        if (context.mounted) {
          startTutorial(context);
          return true; // Se mostró el tutorial
        }
      }
      
      return false; // No se mostró el tutorial
    } catch (e) {
      // En caso de error, asumir que no se ha completado
      // y mostrar el tutorial para estar seguro
      if (context.mounted) {
        startTutorial(context);
        return true;
      }
      return false;
    }
  }
  
  /// Verifica el estado del tutorial para debugging
  static Future<Map<String, dynamic>> getTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'completed': prefs.getBool(_tutorialCompletedKey) ?? false,
      'devMode': _forceShowTutorial,
      'shouldShow': !(prefs.getBool(_tutorialCompletedKey) ?? false) || _forceShowTutorial,
    };
  }
  
  /// Para configuración avanzada (desarrollo)
  static Future<void> setTutorialCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    if (completed) {
      await prefs.setBool(_tutorialCompletedKey, true);
    } else {
      await prefs.remove(_tutorialCompletedKey);
    }
  }
}