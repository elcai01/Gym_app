import 'package:flutter/material.dart';
import '../utils/body_composition_calculator.dart';
import '../models/scale_reading.dart';

class BodyCompositionReportScreen extends StatelessWidget {
  final BodyCompositionResult result;
  final ScaleReading? previousReading;

  const BodyCompositionReportScreen({
    Key? key, 
    required this.result,
    this.previousReading,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'bajo':
        return Colors.blueAccent;
      case 'standard':
      case 'bueno':
        return Colors.green;
      case 'alto':
      case 'sobrepeso':
      case 'over':
        return Colors.orangeAccent;
      case 'muy alto':
      case 'obeso':
      case 'very high':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reporte de peso', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Composición corporal',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (previousReading != null) ...[
              const SizedBox(height: 8),
              _buildComparisonBanner(),
            ],
            const SizedBox(height: 12),
            _buildTopSummaryCard(),
            const SizedBox(height: 16),
            _buildMainCard(),
            const SizedBox(height: 16),
            _buildGridMetrics(),
            const SizedBox(height: 16),
            _buildBodyTypeCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonBanner() {
    if (previousReading == null) return const SizedBox.shrink();
    final prev = previousReading!;
    
    final weightDiff = (prev.peso != null) ? result.peso - prev.peso! : null;
    final fatDiff = (prev.porcentajeGrasa != null) ? result.fatPercentage - prev.porcentajeGrasa! : null;
    final muscleDiff = (prev.porcentajeMuscular != null) ? result.musclePercentage - prev.porcentajeMuscular! : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: Color(0xFFD4AF37), size: 16),
              const SizedBox(width: 6),
              Text(
                'vs medición anterior (${prev.fechaPesaje.day.toString().padLeft(2, '0')}/${prev.fechaPesaje.month.toString().padLeft(2, '0')}/${prev.fechaPesaje.year})',
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (weightDiff != null) _buildDeltaChip('Peso', weightDiff, 'kg', invertColors: false),
              if (fatDiff != null) _buildDeltaChip('Grasa', fatDiff, '%', invertColors: false),
              if (muscleDiff != null) _buildDeltaChip('Músculo', muscleDiff, '%', invertColors: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaChip(String label, double diff, String unit, {bool invertColors = false}) {
    if (diff.abs() < 0.1) {
      return Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 2),
          const Text('=', style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
          const Text('Sin cambio', style: TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      );
    }
    
    final isPositive = diff > 0;
    Color color;
    if (invertColors) {
      color = isPositive ? Colors.green : Colors.redAccent;
    } else {
      color = isPositive ? Colors.redAccent : Colors.green;
    }
    
    final icon = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final sign = isPositive ? '+' : '';
    
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            Text(
              '$sign${diff.toStringAsFixed(1)}$unit',
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Puntuación
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Puntuación', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    result.bodyScore.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '/100',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          // Peso
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Peso actual', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    result.peso.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kg',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              if (previousReading != null)
                _buildComparisonWidget(result.peso, previousReading!.peso, invertColors: false, unit: 'kg') ?? const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Graphic Placeholder
          Expanded(
            flex: 1,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.accessibility_new_rounded,
                size: 100,
                color: Colors.blueAccent,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMainMetricRow(result.bodyWaterMass, 'Masa de agua'),
                const SizedBox(height: 16),
                _buildMainMetricRow(result.fatMass, 'Masa de grasa'),
                const SizedBox(height: 16),
                _buildMainMetricRow(result.boneMineralContent, 'Contenido mineral óseo'),
                const SizedBox(height: 16),
                _buildMainMetricRow(result.proteinMass, 'Masa de proteína'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetricRow(double value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Text(
              'kg',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildGridMetrics() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25, // Reducido para dar más espacio vertical
      children: [
        _buildMetricCard(
          result.fatPercentage.toStringAsFixed(1), '%', 'Grasa corporal', result.getStatusGrasa(),
          comparison: _buildComparisonWidget(result.fatPercentage, previousReading?.porcentajeGrasa, invertColors: false, unit: '%')
        ),
        _buildMetricCard(
          result.imc.toStringAsFixed(1), '', 'IMC', result.getStatusImc(),
          comparison: _buildComparisonWidget(result.imc, previousReading?.imc, invertColors: false, unit: '')
        ),
        _buildMetricCard(
          result.muscleMass.toStringAsFixed(1), 'kg', 'Masa muscular', result.getStatusMusculo(),
          comparison: _buildComparisonWidget(result.muscleMass, previousReading?.porcentajeMuscular != null ? (previousReading!.peso! * (previousReading!.porcentajeMuscular! / 100)) : null, invertColors: true, unit: 'kg')
        ),
        _buildMetricCard(
          result.musclePercentage.toStringAsFixed(1), '%', 'Porcentaje muscular', result.getStatusMusculo(),
          comparison: _buildComparisonWidget(result.musclePercentage, previousReading?.porcentajeMuscular, invertColors: true, unit: '%')
        ),
        _buildMetricCard(
          result.waterPercentage.toStringAsFixed(1), '%', 'Agua corporal', result.getStatusAgua(),
          comparison: _buildComparisonWidget(result.waterPercentage, previousReading?.porcentajeLiquidos, invertColors: true, unit: '%')
        ),
        _buildMetricCard(
          result.proteinPercentage.toStringAsFixed(1), '%', 'Porcentaje de proteína', result.getStatusProteina(),
        ),
        _buildMetricCard(
          result.bonePercentage.toStringAsFixed(1), '%', 'Porcentaje mineral óseo', result.getStatusOseo(),
          comparison: _buildComparisonWidget(result.bonePercentage, previousReading?.porcentajeOseo, invertColors: true, unit: '%')
        ),
        _buildMetricCard(
          result.skeletalMuscleMass.toStringAsFixed(1), 'kg', 'Masa muscular esquelética', 'Standard'
        ),
        
        // Tarjeta de grasa visceral con descripción
        _buildMetricCard(
          result.visceralFatRating.toString(), 
          '', 
          'Grasa visceral', 
          result.getStatusVisceral(),
          description: _getVisceralFatDescription(result.visceralFatRating),
        ),
        
        _buildMetricCard(result.basalMetabolicRate.toString(), 'Kcal', 'Metabolismo basal', 'Standard'),
        _buildMetricCard(
          result.waistToHipRatio.toStringAsFixed(2), '', 'Relación cintura-cadera', 'Standard'
        ),
        _buildMetricCard(result.bodyAge.toString(), 'años', 'Edad corporal', ''),
        _buildMetricCard(result.fatFreeBodyWeight.toStringAsFixed(1), 'kg', 'Peso libre de grasa', ''),
      ],
    );
  }

  String _getVisceralFatDescription(int rating) {
    if (rating <= 9) {
      return "Óptimo. Grasa saludable.\nSigue así con tus hábitos actuales.";
    } else if (rating <= 14) {
      return "Elevado. Riesgo moderado.\nReduce carbohidratos y haz más cardio.";
    } else {
      return "Peligroso. Alto riesgo.\nUrge dieta estricta y ejercicio diario.";
    }
  }

  Widget? _buildComparisonWidget(double current, double? previous, {bool invertColors = false, String unit = ''}) {
    if (previous == null || previous == 0) return null;
    double diff = current - previous;
    if (diff.abs() < 0.1) return null; // No change

    bool isPositive = diff > 0;
    
    // Normal: Bajar peso/grasa es verde (bueno). Subir es rojo (malo).
    // Inverted: Subir músculo/agua es verde (bueno). Bajar es rojo (malo).
    Color color;
    if (invertColors) {
      color = isPositive ? Colors.green : Colors.redAccent;
    } else {
      color = isPositive ? Colors.redAccent : Colors.green;
    }

    IconData icon = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 2),
          Text(
            '${diff.abs().toStringAsFixed(1)}$unit',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String unit, String title, String status, {String? description, Widget? comparison}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (status.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (comparison != null) comparison,
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.15),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyTypeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tipo de cuerpo',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Icon(Icons.info_outline, color: Colors.white54, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar for body type
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTypeSegment('Atlético', result.bodyType == 'Atlético', Colors.green)),
                Expanded(child: _buildTypeSegment('Sobrepeso', result.bodyType == 'Sobrepeso', Colors.orange)),
                Expanded(child: _buildTypeSegment('Obeso', result.bodyType == 'Obeso', Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tu tipo de cuerpo es ${result.bodyType}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment(String label, bool isSelected, Color activeColor) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white38,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
