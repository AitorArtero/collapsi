import 'package:flutter/material.dart';
import '../../widgets/zen_page_scaffold.dart';
import '../../../config/ui_constants.dart';

/// Pantalla de detalle para IA Fácil - Novato con Errores
class GreedyAIDetailScreen extends StatelessWidget {
  const GreedyAIDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZenPageScaffold(
      title: 'Novato con Errores (Fácil)',
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
      title: '🛒 LA METÁFORA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como un comprador compulsivo en el supermercado: siempre va por la oferta con MÁS descuentos, pero se distrae con otras cosas y a veces elige lo que no era.',
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
              '"Veo tres ofertas buenas... ¡pero esa de allá también se ve interesante! ¿Cuál era la que más me convenía?"',
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
            '1. EVALUACIÓN BÁSICA',
            [
              'Mira todos sus movimientos posibles',
              'Cuenta cuántas opciones tendría en el próximo turno',
              'Puntúa cada movimiento según cantidad de futuras opciones',
              '"¿Dónde tendré más ofertas después?"'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '2. SISTEMA DE ERRORES (25%)',
            [
              '75% del tiempo: Va al movimiento óptimo',
              '25% del tiempo: Se distrae y comete errores',
              'Simula comportamiento humano real',
              'Añade variación de ±15% a sus cálculos'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '3. TIPOS DE DISTRACCIONES',
            [
              '40% de las veces: Elige el 2do mejor movimiento',
              '30% de las veces: Elige el 3er mejor movimiento', 
              '30% de las veces: Elige uno completamente aleatorio',
              'Como confundirse entre productos similares'
            ],
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          _buildSubSection(
            '4. RUIDO MENTAL',
            [
              'Sus cálculos varían ligeramente cada vez',
              'Simula incertidumbre humana típica',
              '"¿Era esta la oferta buena o la otra?"',
              'No tiene memoria perfecta de evaluaciones'
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
            'DEMASIADAS OPCIONES',
            'Ponle 3-4 movimientos buenos y se confundirá entre ellos. Como mostrarle muchas ofertas similares, no sabrá cuál elegir.',
            UIColors.warning,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'NO VE EL PRECIO TOTAL',
            'Solo mira la oferta inmediata, no calcula si le saldrá caro después. Perfecto para trampas de 2+ turnos.',
            UIColors.error,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'SIEMPRE BUSCA CANTIDAD',
            'Predecible: ofrécele el camino con más opciones para guiarlo exactamente donde quieres.',
            UIColors.info,
          ),
          const SizedBox(height: UIConstants.spacing16),
          
          _buildWeakPoint(
            'EXPLOTA SUS DESPISTES',
            'En momentos de presión es más probable que "elija mal". Créale situaciones complejas.',
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