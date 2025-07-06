import 'package:flutter/material.dart';
import '../../widgets/zen_page_scaffold.dart';
import '../../../config/ui_constants.dart';

/// Pantalla de detalle para IA Experto - Maestro Telepático
class MinimaxDetailScreen extends StatelessWidget {
  const MinimaxDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZenPageScaffold(
      title: 'Maestro Telepático (Experto)',
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
      title: '🔮 LA METÁFORA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como un maestro telepático de juegos mentales: lee TODOS tus pensamientos futuros hasta los próximos 4 movimientos, asume que también eres telepático, y aún así encuentra la jugada perfecta para ganarte.',
            style: ZenTextStyles.body.copyWith(height: 1.6),
          ),
          const SizedBox(height: UIConstants.spacing16),
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            decoration: BoxDecoration(
              color: UIColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              border: Border.all(
                color: UIColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '"Veo todos tus pensamientos futuros. Incluso si juegas perfecto, ya encontré la secuencia ganadora de entre las miles de posibilidades."',
              style: ZenTextStyles.body.copyWith(
                fontStyle: FontStyle.italic,
                color: UIColors.primary,
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
            '1. ALGORITMO MINIMAX',
            [
              'Explora TODAS las ramas posibles del juego',
              '4 turnos de profundidad exhaustiva',
              'Millones de cálculos por movimiento',
              'Matemáticamente perfecto'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '2. LECTURA MENTAL COMPLETA',
            [
              'Ve todos tus movimientos posibles hasta 4 turnos',
              'Asume que juegas de forma óptima',
              'Encuentra la mejor línea de juego incluso contra perfección',
              'No hay secretos en tu mente'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '3. PODA ALPHA-BETA',
            [
              'Descarta ramas imposibles para optimizar',
              'Mantiene precisión perfecta',
              'Reduce tiempo de cálculo sin perder calidad',
              'Inteligencia pura sin desperdicios'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '4. EVALUACIÓN MULTI-FACTOR',
            [
              'Movilidad vs Bloqueo de rival',
              'Supervivencia vs Control del juego',
              'Posición actual vs Potencial futuro',
              'Perfectamente equilibrado, como todo debe estar'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '5. PERFECCIÓN MATEMÁTICA',
            [
              '0% errores - imposible que cometa fallos',
              'Juego óptimo garantizado',
              'Decisiones irrefutables',
              'La respuesta perfecta siempre existe'
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
            'ASUME TU PERFECCIÓN',
            'Cree que juegas como él. Movimientos "subóptimos" pueden confundir sus cálculos perfectos porque no los espera.',
            UIColors.warning,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'LÍMITE DE 4 TURNOS',
            'Estrategias a 5+ turnos están fuera de su alcance telepático. Su vista perfecta tiene un horizonte, aunque lejano.',
            UIColors.info,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'JUGADAS "LOCAS"',
            'Su lógica perfecta no espera movimientos aparentemente malos que son parte de una estrategia más grande que él no ve.',
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