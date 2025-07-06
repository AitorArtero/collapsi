import 'package:flutter/material.dart';
import '../../widgets/zen_page_scaffold.dart';
import '../../../config/ui_constants.dart';

/// Pantalla de detalle para IA Difícil - Estratega Avanzado
class HeuristicHardDetailScreen extends StatelessWidget {
  const HeuristicHardDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZenPageScaffold(
      title: 'Estratega Avanzado (Difícil)',
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
      title: '🦅 LA METÁFORA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como un halcón cazador experto: vuela alto viendo todo el territorio, predice el PRÓXIMO movimiento de su presa, planifica 2 pasos por delante y ataca en el momento exacto sin fallar.',
            style: ZenTextStyles.body.copyWith(height: 1.6),
          ),
          const SizedBox(height: UIConstants.spacing16),
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            decoration: BoxDecoration(
              color: UIColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              border: Border.all(
                color: UIColors.error.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '"Veo todo desde las alturas. Sé exactamente dónde vas a moverte y ya planeé mi respuesta. Dos pasos por delante, presa."',
              style: ZenTextStyles.body.copyWith(
                fontStyle: FontStyle.italic,
                color: UIColors.error,
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
            '1. PREDICCIÓN DE RIVAL',
            [
              'Simula cómo piensas tú como humano',
              'Predice tu PRÓXIMO movimiento más probable',
              'Adapta su estrategia según tu patrón',
              'Solo ve un paso por delante de ti, no más'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '2. ANTICIPACIÓN DE 2 TURNOS',
            [
              '"Si muevo aquí..."',
              '"Tú moverás allá..."',
              '"Entonces yo podré..."',
              'Planifica su secuencia de 2 movimientos'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '3. DETECCIÓN DE TRAMPAS',
            [
              'Jaque mate inmediato: +200 puntos',
              'Trampa crítica (1 opción rival): +100 puntos',
              'Presión alta (pocas opciones): +50 puntos',
              'Busca activamente cómo acorralarte'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '4. FACTOR AGRESIVIDAD ELEVADO',
            [
              '25% Mis opciones futuras',
              '50% Bloquear rival (muy agresivo)',
              '20% Supervivencia',
              '5% Libertad local'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '5. EJECUCIÓN PERFECTA',
            [
              '0% errores - nunca comete errores tácticos',
              'Ejecución perfecta de su estrategia',
              'No se distrae ni duda',
              'Cada movimiento tiene propósito específico'
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
            'PREDICCIÓN LIMITADA',
            'Solo predice tu primer movimiento siguiente. Si cambias estrategia repentinamente o juegas de forma inconsistente, lo confundes.',
            UIColors.warning,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'VISTA DE 2 TURNOS',
            'Trampas de 3+ turnos pueden sorprenderlo aún. ¡Adelántate a su predicción!',
            UIColors.error,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'DEMASIADO AGRESIVO',
            'Su enfoque en bloquear (50%) a veces sacrifica su propia posición. Puede ser manipulado con "señuelos".',
            UIColors.info,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'PREDECIBLE EN PATRONES',
            'Si entiendes que siempre busca bloquearte primero, úsalo para llevarlo exactamente donde quieras que vaya.',
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