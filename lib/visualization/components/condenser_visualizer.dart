import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';
import '../contracts/physical_visualizer.dart';

/// Visualizador físico 2.5D del condensador de tubos de cobre con aletas de aluminio y ventilador axial.
class CondenserVisualizer implements PhysicalVisualizer {
  double condensingPressureBar = 0.0;
  double condensingTempC = 0.0;
  double heatRejectionWatts = 0.0;
  double fanRpm = 0.0;
  double airDeltaTKelvin = 0.0;
  double subcoolingKelvin = 0.0;
  bool isFanOperational = true;

  @override
  void updateFromState(SimulationState state) {
    condensingPressureBar = state.condensingPressurePa / 1e5;
    condensingTempC = state.condensingTemperatureK - 273.15;
    heatRejectionWatts = state.heatingCapacityWatts;
    fanRpm = state.condenserAirFlow.fanRpm;
    airDeltaTKelvin = state.condenserAirFlow.deltaTAirKelvin;
    subcoolingKelvin = state.subcoolingKelvin;
    isFanOperational = (state.circuit.condenser?.fanOperational ?? true) && state.condenserFanSpeedOverride > 0.05;
  }

  void paint(Canvas canvas, Size size, double fanAngleRad) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;

    // 1. Bastidor / Marco exterior del condensador
    final frameRect = Rect.fromCenter(center: Offset(cx, cy), width: 170, height: 140);
    final framePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(8)), framePaint);

    final frameBorder = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(8)), frameBorder);

    // 2. Bloque de aletas de aluminio (rayado vertical)
    final finBlockRect = Rect.fromCenter(center: Offset(cx, cy), width: 140, height: 110);
    canvas.drawRect(finBlockRect, Paint()..color = const Color(0xFF0F172A));

    final finPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.0;
    for (double x = finBlockRect.left + 4; x < finBlockRect.right; x += 5) {
      canvas.drawLine(Offset(x, finBlockRect.top), Offset(x, finBlockRect.bottom), finPaint);
    }

    // 3. Serpentín de tubos de cobre con cambio de fase visible
    // 4 pasos de tubo horizontales interconectados por codos de 180°
    const tubeRadius = 4.5;
    final y1 = cy - 40; // Entrada gas caliente
    final y2 = cy - 15; // Desrecalentamiento
    final y3 = cy + 15; // Condensación bifásica
    final y4 = cy + 40; // Líquido subenfriado

    // Colores según estado del fluido en cada paso
    final colorPass1 = ScadaColors.highPressureDischarge; // Vapor caliente
    final colorPass2 = Color.lerp(ScadaColors.highPressureDischarge, const Color(0xFFFF7875), 0.5)!;
    final colorPass3 = Color.lerp(const Color(0xFFFF7875), ScadaColors.highPressureLiquid, 0.7)!;
    final colorPass4 = ScadaColors.highPressureLiquid;    // Líquido subenfriado

    // Tubos horizontales
    canvas.drawLine(Offset(cx - 60, y1), Offset(cx + 60, y1), Paint()..color = colorPass1..strokeWidth = tubeRadius * 2);
    canvas.drawLine(Offset(cx - 60, y2), Offset(cx + 60, y2), Paint()..color = colorPass2..strokeWidth = tubeRadius * 2);
    canvas.drawLine(Offset(cx - 60, y3), Offset(cx + 60, y3), Paint()..color = colorPass3..strokeWidth = tubeRadius * 2);
    canvas.drawLine(Offset(cx - 60, y4), Offset(cx + 60, y4), Paint()..color = colorPass4..strokeWidth = tubeRadius * 2);

    // Codos de retorno en los extremos
    final bendPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = tubeRadius * 2;
    // Codo 1-2 (derecha)
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 60, (y1 + y2) / 2), width: y2 - y1, height: y2 - y1), -math.pi / 2, math.pi, false, bendPaint..color = colorPass1);
    // Codo 2-3 (izquierda)
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 60, (y2 + y3) / 2), width: y3 - y2, height: y3 - y2), math.pi / 2, math.pi, false, bendPaint..color = colorPass2);
    // Codo 3-4 (derecha)
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 60, (y3 + y4) / 2), width: y4 - y3, height: y4 - y3), -math.pi / 2, math.pi, false, bendPaint..color = colorPass3);

    // 4. Ventilador axial frontal
    final fanCenter = Offset(cx, cy);
    const fanRadius = 42.0;

    // Aro protector del ventilador
    canvas.drawCircle(
      fanCenter,
      fanRadius,
      Paint()
        ..color = const Color(0xFF64748B).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 4 Aspas aerodinámicas rotando con fanAngleRad
    final bladePaint = Paint()
      ..color = (fanRpm > 10.0) ? ScadaColors.infoBlue.withValues(alpha: 0.75) : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = fanAngleRad + (i * math.pi / 2.0);
      final bladePath = Path();
      bladePath.moveTo(fanCenter.dx, fanCenter.dy);
      bladePath.lineTo(
        fanCenter.dx + (fanRadius - 4) * math.cos(angle - 0.25),
        fanCenter.dy + (fanRadius - 4) * math.sin(angle - 0.25),
      );
      bladePath.lineTo(
        fanCenter.dx + (fanRadius - 2) * math.cos(angle + 0.25),
        fanCenter.dy + (fanRadius - 2) * math.sin(angle + 0.25),
      );
      bladePath.close();
      canvas.drawPath(bladePath, bladePaint);
    }

    // Cubo central del motor del ventilador
    canvas.drawCircle(fanCenter, 10.0, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(fanCenter, 6.0, Paint()..color = const Color(0xFF94A3B8));

    // 5. Pluma de aire caliente expulsado (ondas térmicas naranjas si hay ventilación)
    if (fanRpm > 20.0 && heatRejectionWatts > 10.0) {
      final plumePaint = Paint()
        ..color = ScadaColors.warningAmber.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 0; i < 3; i++) {
        final offset = (fanAngleRad * 12 + i * 15) % 35;
        canvas.drawCircle(fanCenter, fanRadius + offset, plumePaint);
      }
    }

    // 6. Leyenda de estado del ventilador y calor
    final textPainter = TextPainter(
      text: TextSpan(
        text: fanRpm > 10.0
            ? '${fanRpm.toStringAsFixed(0)} RPM | +${airDeltaTKelvin.toStringAsFixed(1)} K Aire'
            : (isFanOperational ? 'VENTILADOR PARADO' : '¡VENTILADOR AVERIADO!'),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: (fanRpm > 10.0)
              ? ScadaColors.runningGreen
              : (isFanOperational ? ScadaColors.textMuted : ScadaColors.dangerRed),
          fontFamily: 'monospace',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(cx - textPainter.width / 2.0, cy + 56));
  }
}
