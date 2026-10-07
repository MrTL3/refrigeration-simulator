import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/transient_metrics.dart';
import '../theme/scada_colors.dart';

enum ChartVariableMode {
  pressures('Presiones (P₀ y Pₖ)'),
  temperatures('Temperaturas (T_asp, T_desc, T_cámara)'),
  powers('Caudal y Potencia Frío');

  final String label;
  const ChartVariableMode(this.label);
}

/// Gráfica técnica temporal en tiempo real para visualizar transitorios.
class TransientChartWidget extends StatefulWidget {
  final List<TimeSeriesSample> history;

  const TransientChartWidget({super.key, required this.history});

  @override
  State<TransientChartWidget> createState() => _TransientChartWidgetState();
}

class _TransientChartWidgetState extends State<TransientChartWidget> {
  ChartVariableMode _mode = ChartVariableMode.pressures;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de magnitudes
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart, size: 16, color: ScadaColors.infoBlue),
                  SizedBox(width: 8),
                  Text(
                    'EVOLUCIÓN TRANSITORIA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: ScadaColors.textPrimary,
                    ),
                  ),
                ],
              ),
              DropdownButton<ChartVariableMode>(
                value: _mode,
                dropdownColor: ScadaColors.surfaceCard,
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(fontSize: 11, color: ScadaColors.infoBlue),
                items: ChartVariableMode.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _mode = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Lienzo de la gráfica
          SizedBox(
            height: 160,
            child: widget.history.length < 2
                ? const Center(
                    child: Text(
                      'Recopilando datos de simulación...',
                      style: TextStyle(fontSize: 11, color: ScadaColors.textMuted),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _TimeSeriesPainter(
                      history: widget.history,
                      mode: _mode,
                    ),
                  ),
          ),
          const SizedBox(height: 6),

          // Leyenda de colores
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    switch (_mode) {
      case ChartVariableMode.pressures:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: ScadaColors.lowPressureSuction, label: 'P₀ Baja (bar)'),
            SizedBox(width: 16),
            _LegendItem(color: ScadaColors.highPressureDischarge, label: 'Pₖ Alta (bar)'),
          ],
        );
      case ChartVariableMode.temperatures:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: ScadaColors.lowPressureSuction, label: 'T_aspiración (°C)'),
            SizedBox(width: 12),
            _LegendItem(color: ScadaColors.highPressureDischarge, label: 'T_descarga (°C)'),
            SizedBox(width: 12),
            _LegendItem(color: ScadaColors.runningGreen, label: 'T_cámara (°C)'),
          ],
        );
      case ChartVariableMode.powers:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: ScadaColors.lowPressureTwoPhase, label: 'Q_frío (kW)'),
            SizedBox(width: 16),
            _LegendItem(color: ScadaColors.warningAmber, label: 'Caudal (g/s)'),
          ],
        );
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary, fontFamily: 'monospace')),
      ],
    );
  }
}

class _TimeSeriesPainter extends CustomPainter {
  final List<TimeSeriesSample> history;
  final ChartVariableMode mode;

  _TimeSeriesPainter({required this.history, required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final w = size.width;
    final h = size.height;

    // Fondo y cuadrícula
    final gridPaint = Paint()
      ..color = ScadaColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = h * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final tMin = history.first.timeSeconds;
    final tMax = history.last.timeSeconds;
    final tRange = math.max(1.0, tMax - tMin);

    switch (mode) {
      case ChartVariableMode.pressures:
        // Rango de 0 a 20 bar
        _drawCurve(
          canvas,
          size,
          history.map((s) => Offset(s.timeSeconds, s.evaporatingPressureBar)).toList(),
          tMin,
          tRange,
          0.0,
          20.0,
          ScadaColors.lowPressureSuction,
        );
        _drawCurve(
          canvas,
          size,
          history.map((s) => Offset(s.timeSeconds, s.condensingPressureBar)).toList(),
          tMin,
          tRange,
          0.0,
          20.0,
          ScadaColors.highPressureDischarge,
        );
      case ChartVariableMode.temperatures:
        // Rango de -25 a 90 °C
        _drawCurve(
          canvas,
          size,
          history.map((s) => Offset(s.timeSeconds, s.suctionTemperatureCelsius)).toList(),
          tMin,
          tRange,
          -25.0,
          90.0,
          ScadaColors.lowPressureSuction,
        );
        _drawCurve(
          canvas,
          size,
          history.map((s) => Offset(s.timeSeconds, s.dischargeTemperatureCelsius)).toList(),
          tMin,
          tRange,
          -25.0,
          90.0,
          ScadaColors.highPressureDischarge,
        );
        _drawCurve(
          canvas,
          size,
          history.map((s) => Offset(s.timeSeconds, s.roomTemperatureCelsius)).toList(),
          tMin,
          tRange,
          -25.0,
          90.0,
          ScadaColors.runningGreen,
        );
      case ChartVariableMode.powers:
        // Rango de 0 a 10 kW / caudal
        _drawCurve(
          canvas,
          size,
          history.map((s) => Offset(s.timeSeconds, s.coolingCapacityKw)).toList(),
          tMin,
          tRange,
          0.0,
          8.0,
          ScadaColors.lowPressureTwoPhase,
        );
        _drawCurve(
          canvas,
          size,
          history.map((s) => Offset(s.timeSeconds, s.massFlowGramsPerSec / 5.0)).toList(),
          tMin,
          tRange,
          0.0,
          8.0,
          ScadaColors.warningAmber,
        );
    }
  }

  void _drawCurve(
    Canvas canvas,
    Size size,
    List<Offset> points,
    double tMin,
    double tRange,
    double yMin,
    double yMax,
    Color color,
  ) {
    final path = Path();
    final yRange = yMax - yMin;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final normX = ((pt.dx - tMin) / tRange).clamp(0.0, 1.0) * size.width;
      final normY = size.height - (((pt.dy - yMin) / yRange).clamp(0.0, 1.0) * size.height);

      if (i == 0) {
        path.moveTo(normX, normY);
      } else {
        path.lineTo(normX, normY);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TimeSeriesPainter oldDelegate) => true;
}
