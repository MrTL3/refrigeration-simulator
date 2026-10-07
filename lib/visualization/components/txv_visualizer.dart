import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';
import '../contracts/physical_visualizer.dart';

/// Visualizador técnico en corte de la Válvula de Expansión Termostática (TXV).
/// Muestra el diafragma flexible, el cono estrangulador móvil dependiente del % de apertura,
/// el resorte de ajuste y el bulbo termostático conectado a la aspiración.
class TxvVisualizer implements PhysicalVisualizer {
  double valveOpeningPercent = 45.0;
  double bulbTempC = 0.0;
  double targetSuperheatK = 7.0;
  double deltaPValveBar = 0.0;
  bool isAutomatic = true;

  @override
  void updateFromState(SimulationState state) {
    valveOpeningPercent = state.circuit.expansionDevice?.openingPercent ?? 45.0;
    bulbTempC = state.dynamicBulbTempK - 273.15;
    targetSuperheatK = state.circuit.expansionDevice?.targetSuperheatKelvin ?? 7.0;
    deltaPValveBar = (state.condensingPressurePa - state.evaporatingPressurePa) / 1e5;
    isAutomatic = state.circuit.expansionDevice?.isAutomatic ?? true;
  }

  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;

    // 1. Cabezal termostático superior (Cúpula del diafragma)
    final domeRect = Rect.fromCenter(center: Offset(cx, cy - 42), width: 64, height: 26);
    final domePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    canvas.drawArc(domeRect, math.pi, math.pi, true, domePaint);
    canvas.drawArc(domeRect, math.pi, math.pi, false, Paint()..color = const Color(0xFF94A3B8)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Diafragma metálico interior (línea curva que se flecta según apertura)
    final diaphragmFlex = ((valveOpeningPercent - 50.0) / 100.0) * 4.0;
    final diaphragmPath = Path();
    diaphragmPath.moveTo(cx - 28, cy - 42);
    diaphragmPath.quadraticBezierTo(cx, cy - 42 + diaphragmFlex, cx + 28, cy - 42);
    canvas.drawPath(diaphragmPath, Paint()..color = const Color(0xFFE2E8F0)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Tubo capilar que sale de la cúpula hacia el bulbo
    final capillaryPath = Path();
    capillaryPath.moveTo(cx, cy - 55);
    capillaryPath.cubicTo(cx - 30, cy - 75, cx - 60, cy - 65, cx - 75, cy - 50);
    canvas.drawPath(capillaryPath, Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Bulbo termostático cilíndrico en el extremo del capilar
    final bulbRect = Rect.fromCenter(center: Offset(cx - 85, cy - 50), width: 22, height: 10);
    canvas.drawRRect(RRect.fromRectAndRadius(bulbRect, const Radius.circular(5)), Paint()..color = const Color(0xFFB45309));
    canvas.drawRRect(RRect.fromRectAndRadius(bulbRect, const Radius.circular(5)), Paint()..color = const Color(0xFFFDE68A)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // 2. Cuerpo de latón forjado en corte
    final bodyPath = Path();
    bodyPath.moveTo(cx - 18, cy - 35);
    bodyPath.lineTo(cx + 18, cy - 35);
    bodyPath.lineTo(cx + 18, cy - 12);
    // Boca de salida (derecha, baja presión)
    bodyPath.lineTo(cx + 42, cy - 12);
    bodyPath.lineTo(cx + 42, cy + 12);
    bodyPath.lineTo(cx + 16, cy + 12);
    // Vástago inferior y resorte
    bodyPath.lineTo(cx + 16, cy + 42);
    bodyPath.lineTo(cx - 16, cy + 42);
    bodyPath.lineTo(cx - 16, cy + 12);
    // Boca de entrada (izquierda, alta presión)
    bodyPath.lineTo(cx - 42, cy + 12);
    bodyPath.lineTo(cx - 42, cy - 12);
    bodyPath.lineTo(cx - 18, cy - 12);
    bodyPath.close();

    final brassPaint = Paint()
      ..color = const Color(0xFF854D0E)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, brassPaint);

    final brassBorder = Paint()
      ..color = const Color(0xFFCA8A04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(bodyPath, brassBorder);

    // 3. Conducto de paso del refrigerante
    // Líquido alta presión entrando por la izquierda
    canvas.drawLine(Offset(cx - 40, cy), Offset(cx - 6, cy), Paint()..color = ScadaColors.highPressureLiquid..strokeWidth = 8.0);

    // 4. Orificio de estrangulación calibrado y aguja cónica móvil
    // Desplazamiento de la aguja: mayor apertura = aguja baja más separándose del asiento
    final needleLift = ((valveOpeningPercent / 100.0) * 7.0).clamp(1.0, 7.0);

    // Asiento del orificio (dos labios en la cámara)
    canvas.drawLine(Offset(cx - 6, cy - 4), Offset(cx - 2, cy - 4), Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 2.5);
    canvas.drawLine(Offset(cx + 2, cy - 4), Offset(cx + 6, cy - 4), Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 2.5);

    // Cono de la aguja
    final coneY = cy - 4 + needleLift;
    final needlePath = Path();
    needlePath.moveTo(cx - 4, coneY);
    needlePath.lineTo(cx + 4, coneY);
    needlePath.lineTo(cx, coneY - 6);
    needlePath.close();
    canvas.drawPath(needlePath, Paint()..color = const Color(0xFFE2E8F0));

    // Vástago transmisor desde el diafragma
    canvas.drawLine(Offset(cx, cy - 42 + diaphragmFlex), Offset(cx, coneY - 6), Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 2.5);

    // 5. Salida de mezcla bifásica (expansión flash gas por la derecha)
    canvas.drawLine(Offset(cx + 2, cy), Offset(cx + 40, cy), Paint()..color = ScadaColors.lowPressureTwoPhase..strokeWidth = 8.0);

    // 6. Resorte de ajuste de recalentamiento (espirales inferiores)
    final springPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (double y = cy + 14; y < cy + 38; y += 6) {
      canvas.drawLine(Offset(cx - 8, y), Offset(cx + 8, y + 3), springPaint);
      canvas.drawLine(Offset(cx + 8, y + 3), Offset(cx - 8, y + 6), springPaint);
    }

    // Tornillo de regulación de recalentamiento inferior
    canvas.drawRect(Rect.fromLTWH(cx - 7, cy + 42, 14, 8), Paint()..color = const Color(0xFF475569));

    // 7. Etiqueta con apertura y estado del bulbo
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'TXV: ${valveOpeningPercent.toStringAsFixed(0)}% ABR\nBulbo: ${bulbTempC.toStringAsFixed(1)} °C',
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: ScadaColors.cyanAccent,
          fontFamily: 'monospace',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(cx - textPainter.width / 2.0, cy + 54));
  }
}
