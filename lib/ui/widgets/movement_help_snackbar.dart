import 'package:flutter/material.dart';
import '../../config/ui_constants.dart';

/// Widget para mostrar mensajes informativos cuando se activa/desactiva la ayuda de movimiento
class MovementHelpSnackbar {
  /// Mostrar mensaje cuando se activa la ayuda de movimiento
  static void showActivated(BuildContext context) {
    _showSnackbar(
      context,
      icon: null, // Por si en un futuro quiero poner icono
      title: 'Ayuda de Movimiento Activada',
      message: 'Las casillas válidas se resaltarán después de un breve delay.\nPuedes modificar esta configuración en Ajustes.',
      color: UIColors.success,
    );
  }

  /// Mostrar mensaje cuando se desactiva la ayuda de movimiento
  static void showDeactivated(BuildContext context) {
    _showSnackbar(
      context,
      icon: null, // Por si en un futuro quiero poner icono
      title: 'Ayuda de Movimiento Desactivada',
      message: 'Ya no se resaltarán las casillas válidas.\nPuedes reactivarla cuando quieras desde Ajustes.',
      color: UIColors.warning,
    );
  }

  /// Mostrar mensaje cuando se modifica el delay en ajustes
  static void showDelayUpdated(BuildContext context, double delaySeconds) {
    String delayText;
    if (delaySeconds == 0) {
      delayText = 'inmediatamente';
    } else if (delaySeconds == 1) {
      delayText = 'después de 1 segundo';
    } else {
      delayText = 'después de ${delaySeconds.toInt()} segundos';
    }

    _showSnackbar(
      context,
      icon: Icons.schedule_rounded, // Mantiene el icono de reloj
      title: 'Tiempo de Ayuda Actualizado',
      message: 'Ahora las casillas se resaltarán $delayText.',
      color: UIColors.info,
    );
  }

  

  /// Método interno para mostrar el snackbar personalizado
  static void _showSnackbar(
    BuildContext context, {
    required IconData? icon, // Puede ser null
    required String title,
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: UIConstants.spacing8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Solo mostrar icono si no es null
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: UIConstants.spacing12),
              ],
              
              // Contenido - ahora ocupa más espacio cuando no hay icono
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: ZenTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: ZenTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4), // Más tiempo para leer el mensaje completo
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        ),
        margin: const EdgeInsets.all(UIConstants.spacing16),
        elevation: 8,
      ),
    );
  }
}