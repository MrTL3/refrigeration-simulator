import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';
import '../contracts/physical_visualizer.dart';

/// Visualizador físico 2.5D del evaporador de tiro forzado dentro de la cámara frigorífica.
class EvaporatorVisualizer implements PhysicalVisualizer {
  double evaporatingPressureBar = 0.0;
  double evaporatingTempC = 0.0;
  double roomTempC = 0.0;
  double coolingCapacityWatts = 0.0;
  double fanRpm = 0.0;
  double airDeltaTKelvin = 0.0;
  double superheatKelvin = 0.0;

  @override
  void updateFromState(SimulationState state) {
    evaporatingPressureBar = state.evaporatingPressurePa / 1e5;
    evaporatingTempC = state.evaporatingTemperatureK - 273.15;
    roomTempC = state.coldRoom.temperatureKelvin - 273.15;
    coolingCapacityWatts = state.coolingCapacityWatts;
    fanRpm = state.evaporatorAirFlow.fanRpm;
    airDeltaTKelvin = state.evaporatorAirFlow.deltaTAirKelvin;
    superheatKelvin = state.superheatKelvin;
  }

  void paint(Canvas canvas, Size size, double fanAngleRad) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;

    // 1. Recinto de la Cámara Frigorífica (Paredes aisladas de panel sándwich)
    final roomRect = Rect.fromCenter(center: Offset(cx, cy), width: 180, height: 160);
    final roomPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(roomRect, const Radius.circular(8)), roomPaint);

    // Contorno térmico de la cámara
    final roomBorder = Paint()
      ..color = (roomTempC < 0.0) ? const Color(0xFF38BDF8) : const Color(0xFF334155)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(roomRect, const Radius.circular(8)), roomBorder);

    // 2. Mueble del evaporador cúbico colgado del techo
    final evapBoxRect = Rect.fromCenter(center: Offset(cx, cy - 25), width: 140, height: 80);
    final evapPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(evapBoxRect, const Radius.circular(6)), evapPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(evapBoxRect, const Radius.circular(6)), Paint()..color = const Color(0xFF475569)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // 3. Aletas de aluminio y tubos de ebullición
    final finRect = Rect.fromLTWH(cx - 60, cy - 55, 75, 60);
    canvas.drawRect(finRect, Paint()..color = const Color(0xFF020617));

    // Aletas verticales
    final finPaint = Paint()..color = const Color(0xFF334155)..strokeWidth = 1.0;
    for (double x = finRect.left + 3; x < finRect.right; x += 4) {
      canvas.drawLine(Offset(x, finRect.top), Offset(x, finRect.bottom), finPaint);
    }

    // Tubos con ebullición: Entrada bifásica fría (cian) -> vapor sobrecalentado (azul)
    final tubeY1 = cy - 45; // Entrada bifásica desde TXV
    final tubeY2 = cy - 25; // Ebullición latente
    final tubeY3 = cy - 5;  // Vapor sobrecalentado hacia aspiración

    const tRadius = 4.0;
    canvas.drawLine(Offset(finRect.left + 4, tubeY1), Offset(finRect.right - 4, tubeY1), Paint()..color = ScadaColors.lowPressureTwoPhase..strokeWidth = tRadius * 2);
    canvas.drawLine(Offset(finRect.left + 4, tubeY2), Offset(finRect.right - 4, tubeY2), Paint()..color = Color.lerp(ScadaColors.lowPressureTwoPhase, ScadaColors.lowPressureSuction, 0.5)!..strokeWidth = tRadius * 2);
    canvas.drawLine(Offset(finRect.left + 4, tubeY3), Offset(finRect.right - 4, tubeY3), Paint()..color = ScadaColors.lowPressureSuction..strokeWidth = tRadius * 2);

    // Codos de retorno
    final bendPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = tRadius * 2;
    canvas.drawArc(Rect.fromCenter(center: Offset(finRect.right - 4, (tubeY1 + tubeY2) / 2), width: tubeY2 - tubeY1, height: tubeY2 - tubeY1), -math.pi / 2, math.pi, false, bendPaint..color = ScadaColors.lowPressureTwoPhase);
    canvas.drawArc(Rect.fromCenter(center: Offset(finRect.left + 4, (tubeY2 + tubeY3) / 2), width: tubeY3 - tubeY2, height: tubeY3 - tubeY2), math.pi / 2, math.pi, false, bendPaint..color = ScadaColors.lowPressureSuction);

    // 4. Ventilador de tiro forzado (derecha de la batería)
    final fanCenter = Offset(cx + 40, cy - 25);
    const fanRadius = 26.0;

    canvas.drawCircle(fanCenter, fanRadius, Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final bladePaint = Paint()
      ..color = (fanRpm > 10.0) ? const Color(0xFF38BDF8).withValues(alpha: 0.8) : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = fanAngleRad + (i * math.pi / 2.0);
      final bladePath = Path();
      bladePath.moveTo(fanCenter.dx, fanCenter.dy);
      bladePath.lineTo(
        fanCenter.dx + (fanRadius - 3) * math.cos(angle - 0.3),
        fanCenter.dy + (fanRadius - 3) * math.sin(angle - 0.3),
      );
      bladePath.lineTo(
        fanCenter.dx + (fanRadius - 1) * math.cos(angle + 0.3),
        fanCenter.dy + (fanRadius - 1) * math.sin(angle + 0.3),
      );
      bladePath.close();
      canvas.drawPath(bladePath, bladePaint);
    }
    canvas.drawCircle(fanCenter, 6.0, Paint()..color = const Color(0xFF0F172A));

    // 5. Corriente de aire frío soplado hacia el suelo de la cámara
    if (fanRpm > 20.0 && coolingCapacityWatts > 10.0) {
      final coldAirPaint = Paint()
        ..color = const Color(0xFF00D2D3).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 0; i < 3; i++) {
        final dropY = cy + 25 + ((fanAngleRad * 20 + i * 22) % 45);
        canvas.drawLine(Offset(cx + 25, dropY), Offset(cx + 55, dropY + 8), coldAirPaint);
      }
    }

    // 6. Indicador de temperatura interior de la cámara
    final roomTempBadge = Rect.fromLTWH(cx - 80, cy + 50, 160, 22);
    canvas.drawRRect(RRect.fromRectAndRadius(roomTempBadge, const Radius.circular(4)), Paint()..color = const Color(0xFF1E293B));

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CÁMARA: ${roomTempC.toStringAsFixed(1)} °C | P₀: ${evaporatingPressureBar.toStringAsFixed(1)} bar',
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: ScadaColors.infoBlue,
          fontFamily: 'monospace',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(cx - textPainter.width / 2.0, cy + 54));
  }
}
