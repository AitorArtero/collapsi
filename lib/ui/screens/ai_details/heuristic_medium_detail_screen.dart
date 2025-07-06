import 'package:flutter/material.dart';
import '../../widgets/zen_page_scaffold.dart';
import '../../../config/ui_constants.dart';

/// Pantalla de detalle para IA Medio - Competidor Equilibrado
class HeuristicMediumDetailScreen extends StatelessWidget {
  const HeuristicMediumDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZenPageScaffold(
      title: 'Competidor Equilibrado (Medio)',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetaphorSection(),
            const SizedBox(height: UIConstants.spacing32),
            _buildHowItWorksSection(),
            const SizedBox(height: UIConstants.spacing32),
            _buildWeakPointsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaphorSection() {
    return _buildSection(
      title: '🍳 LA METÁFORA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como un chef bajo presión en una cocina profesional: conoce todas las técnicas, balancea perfectamente los sabores, pero con las prisas se le escapa algún detalle de vez en cuando.',
            style: ZenTextStyles.body.copyWith(height: 1.6),
          ),
          const SizedBox(height: UIConstants.spacing16),
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            decoration: BoxDecoration(
              color: UIColors.warning.withOpacity(0.05),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              border: Border.all(
                color: UIColors.warning.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '"Tengo que balancear la sal, la pimienta, el tiempo de cocción y servir 5 platos a la vez... ¡90% perfecto, pero a veces pongo una pizca demás!"',
              style: ZenTextStyles.body.copyWith(
                fontStyle: FontStyle.italic,
                color: UIColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return _buildSection(
      title: 'CÓMO FUNCIONA EN DETALLE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubSection(
            '1. EVALUACIÓN MULTI-FACTOR',
            [
              '35% Mis futuras opciones (movilidad)',
              '35% Bloquear al rival (estrategia)',
              '25% Supervivencia a largo plazo',
              '5% Libertad de movimiento local',
              'Balance perfecto como una receta'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '2. BALANCE PERFECTO',
            [
              'No se enfoca solo en atacar',
              'No se enfoca solo en defenderse',
              'Equilibra todos los aspectos del juego',
              'Como un chef que no se olvida de ningún ingrediente'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '3. PEQUEÑOS DESPISTES (15%)',
            [
              '85% del tiempo: Ejecución perfecta',
              '15% del tiempo: Elige entre los 3 mejores por presión',
              'Como cuando el chef está agobiado y duda',
              'No son errores graves, solo pequeñas vacilaciones'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '4. HEURÍSTICA INTELIGENTE',
            [
              'Simula movimientos futuros antes de decidir',
              'Evalúa múltiples factores simultáneamente',
              'Toma decisiones fundamentadas y pensadas',
              'Como seguir una receta compleja paso a paso'
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeakPointsSection() {
    return _buildSection(
      title: 'PUNTOS DÉBILES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeakPoint(
            'PRESIÓN EN LA COCINA',
            'En situaciones complejas a veces duda entre recetas buenas. Su error del 15% se activa en momentos críticos.',
            UIColors.warning,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'LIMITACIÓN DE VISTA',
            'Solo mira 1 turno adelante, puede caer en trampas de 2+ movimientos. Como un chef concentrado en el plato actual.',
            UIColors.error,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'DEMASIADO EQUILIBRADO',
            'A veces necesita ser más agresivo o defensivo, pero siempre busca el balance. Su 35%-35%-25%-5% es predecible.',
            UIColors.info,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'PATRONES PREDECIBLES',
            'Su equilibrio constante es explotable. Como un chef que siempre usa las mismas proporciones, puedes anticipar sus "recetas".',
            UIColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UIConstants.spacing24),
      decoration: BoxDecoration(
        color: UIColors.surface,
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        border: Border.all(color: UIColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: UIColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ZenTextStyles.heading.copyWith(
              color: UIColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: UIConstants.spacing16),
          child,
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ZenTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: UIColors.textPrimary,
          ),
        ),
        const SizedBox(height: UIConstants.spacing8),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: UIConstants.spacing4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 8, right: UIConstants.spacing8),
                decoration: BoxDecoration(
                  color: UIColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  point,
                  style: ZenTextStyles.body,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildWeakPoint(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ZenTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          Text(
            description,
            style: ZenTextStyles.body.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}