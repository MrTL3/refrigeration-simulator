import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Renderizador volumétrico 3D del Condensador de tiro forzado con aletas de aluminio y ventilador axial.
///
/// Modela:
/// - Envolvente de chapa galvanizada con profundidad isométrica y patas de fijación.
/// - Paquete compacto de aletas de aluminio con serpentín de tubos de cobre y curvas de retorno.
/// - Tobera aerodinámica con rejilla de protección de alambre concéntrica.
/// - Ventilador axial de 4 palas con volumen girando a la velocidad real calculada del aire.
/// - Vectores de disipación de calor (Qc) hacia el ambiente cuando la capa CALOR está activa.
class Condenser3DRenderer {
  static void paint({
    required Canvas canvas,
    required Rect condRect,
    required SimulationState state,
    required double fanAngleRad,
    required bool isSelected,
    required bool showHeatVectors,
  }) {
    final fanRpm = state.condenserAirFlow.fanRpm;
    final isFanOperational = (state.circuit.condenser?.fanOperational ?? true) && state.condenserFanSpeedOverride > 0.05;
    final isFanRunning = isFanOperational && fanRpm > 10.0;
    const depthOffset = Offset(22, -16);

    // 0. Sombra arrojada sobre la pared y suelo
    final shadowPath = Path()
      ..addRect(Rect.fromLTWH(condRect.left + 10, condRect.top + 8, condRect.width, condRect.height));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 1. Carcasa superior (perspectiva 3D)
    final topFace = Path()
      ..moveTo(condRect.left, condRect.top)
      ..lineTo(condRect.right, condRect.top)
      ..lineTo(condRect.right + depthOffset.dx, condRect.top + depthOffset.dy)
      ..lineTo(condRect.left + depthOffset.dx, condRect.top + depthOffset.dy)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64748B), Color(0xFF334155)],
        ).createShader(topFace.getBounds()),
    );

    // 2. Lateral derecho
    final rightFace = Path()
      ..moveTo(condRect.right, condRect.top)
      ..lineTo(condRect.right + depthOffset.dx, condRect.top + depthOffset.dy)
      ..lineTo(condRect.right + depthOffset.dx, condRect.bottom + depthOffset.dy)
      ..lineTo(condRect.right, condRect.bottom)
      ..close();
    canvas.drawPath(
      rightFace,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ).createShader(rightFace.getBounds()),
    );

    // 3. Bastidor frontal de chapa galvanizada
    final frontBody = RRect.fromRectAndRadius(condRect, const Radius.circular(8));
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF111827)],
      ).createShader(condRect);
    canvas.drawRRect(frontBody, bodyPaint);

    final borderPaint = Paint()
      ..color = isSelected ? ScadaColors.highPressureDischarge : const Color(0xFF475569)
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(frontBody, borderPaint);

    // 4. Bloque de aletas de aluminio y serpentín condensador
    final coilRect = Rect.fromLTWH(condRect.left + 16, condRect.top + 16, condRect.width - 32, condRect.height - 32);
    canvas.drawRRect(RRect.fromRectAndRadius(coilRect, const Radius.circular(6)), Paint()..color = const Color(0xFF0B132B));

    // Aletas verticales de disipación de calor
    final finPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.75)
      ..strokeWidth = 1.0;
    for (double x = coilRect.left + 4; x < coilRect.right; x += 4.5) {
      canvas.drawLine(Offset(x, coilRect.top), Offset(x, coilRect.bottom), finPaint);
    }

    // Tubos horizontales de cobre con cambio de fase (Vapor caliente -> Mezcla -> Líquido subenfriado)
    final numPasses = 4;
    final passHeight = coilRect.height / (numPasses + 1);

    for (int i = 1; i <= numPasses; i++) {
      final y = coilRect.top + i * passHeight;
      // Interpolación de color: de rojo vivo de descarga (arriba) a naranja-rojo de líquido (abajo)
      final colorPass = Color.lerp(
        ScadaColors.highPressureDischarge,
        ScadaColors.highPressureLiquid,
        (i - 1) / (numPasses - 1),
      )!;

      canvas.drawLine(
        Offset(coilRect.left + 12, y),
        Offset(coilRect.right - 12, y),
        Paint()
          ..color = colorPass
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round,
      );

      // Codos de retorno en los extremos
      if (i < numPasses) {
        final nextY = coilRect.top + (i + 1) * passHeight;
        final isRightBend = i.isOdd;
        final bendCenterX = isRightBend ? (coilRect.right - 12) : (coilRect.left + 12);
        final bendRect = Rect.fromCenter(
          center: Offset(bendCenterX, (y + nextY) / 2),
          width: nextY - y,
          height: nextY - y,
        );
        final startAngle = isRightBend ? (-math.pi / 2) : (math.pi / 2);

        canvas.drawArc(
          bendRect,
          startAngle,
          math.pi,
          false,
          Paint()
            ..color = colorPass
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.0,
        );
      }
    }

    // 5. Ventilador axial frontal con tobera y rejilla
    final fanCenter = Offset(condRect.center.dx, condRect.center.dy);
    final fanRadius = condRect.width * 0.28;

    // Tobera circular
    canvas.drawCircle(fanCenter, fanRadius + 4, Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.85));
    canvas.drawCircle(
      fanCenter,
      fanRadius + 4,
      Paint()
        ..color = isFanOperational ? const Color(0xFF64748B) : ScadaColors.dangerRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Rejilla concéntrica de seguridad
    final gridPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(fanCenter, fanRadius * 0.45, gridPaint);
    canvas.drawCircle(fanCenter, fanRadius * 0.75, gridPaint);
    // Radios de la rejilla
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3.0;
      canvas.drawLine(
        Offset(fanCenter.dx + 8 * math.cos(a), fanCenter.dy + 8 * math.sin(a)),
        Offset(fanCenter.dx + fanRadius * math.cos(a), fanCenter.dy + fanRadius * math.sin(a)),
        gridPaint,
      );
    }

    // 4 Aspas helicoidales con volumen rotando según fanAngleRad
    final numBlades = 4;
    final bladePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          isFanRunning ? const Color(0xFFF97316) : const Color(0xFF475569),
          const Color(0xFF0F172A),
        ],
      ).createShader(Rect.fromCircle(center: fanCenter, radius: fanRadius));

    for (int i = 0; i < numBlades; i++) {
      final a = fanAngleRad + (i * 2.0 * math.pi / numBlades);
      final bladePath = Path()
        ..moveTo(fanCenter.dx + 6 * math.cos(a + 0.35), fanCenter.dy + 6 * math.sin(a + 0.35))
        ..quadraticBezierTo(
          fanCenter.dx + fanRadius * 0.75 * math.cos(a + 0.25),
          fanCenter.dy + fanRadius * 0.75 * math.sin(a + 0.25),
          fanCenter.dx + (fanRadius - 3) * math.cos(a),
          fanCenter.dy + (fanRadius - 3) * math.sin(a),
        )
        ..lineTo(fanCenter.dx + (fanRadius - 4) * math.cos(a - 0.2), fanCenter.dy + (fanRadius - 4) * math.sin(a - 0.2))
        ..quadraticBezierTo(
          fanCenter.dx + fanRadius * 0.55 * math.cos(a - 0.1),
          fanCenter.dy + fanRadius * 0.55 * math.sin(a - 0.1),
          fanCenter.dx + 6 * math.cos(a - 0.25),
          fanCenter.dy + 6 * math.sin(a - 0.25),
        )
        ..close();
      canvas.drawPath(bladePath, bladePaint);
    }

    // Cubo / rotor central
    canvas.drawCircle(fanCenter, 8.0, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawCircle(fanCenter, 4.0, Paint()..color = const Color(0xFFCBD5E1));

    // Si el ventilador está parado/averiado, mostrar cartelito de alarma
    if (!isFanOperational) {
      final warnRect = Rect.fromCenter(center: Offset(fanCenter.dx, fanCenter.dy + fanRadius * 0.65), width: 110, height: 18);
      canvas.drawRRect(RRect.fromRectAndRadius(warnRect, const Radius.circular(4)), Paint()..color = ScadaColors.dangerRed.withValues(alpha: 0.9));
      final tp = TextPainter(
        text: const TextSpan(
          text: 'VENTILADOR PARADO',
          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(warnRect.center.dx - tp.width / 2, warnRect.center.dy - tp.height / 2));
    }

    // 6. Vectores de disipación de calor hacia el exterior (Qc) si la capa CALOR está activa
    if (showHeatVectors && state.isRunning) {
      final qcKw = state.heatingCapacityWatts / 1000.0;
      _drawHeatRejectionVectors(canvas, condRect, qcKw);
    }
  }

  static void _drawHeatRejectionVectors(Canvas canvas, Rect rect, double qcKw) {
    final arrowPaint = Paint()
      ..color = ScadaColors.highPressureDischarge.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = ScadaColors.highPressureDischarge
      ..style = PaintingStyle.fill;

    // Flechas ascendentes expulsando calor hacia arriba de la batería
    for (double x = rect.left + 35; x <= rect.right - 35; x += 45) {
      final startY = rect.top - 6;
      final endY = rect.top - 28;
      canvas.drawLine(Offset(x, startY), Offset(x, endY), arrowPaint);

      final head = Path()
        ..moveTo(x, endY - 4)
        ..lineTo(x - 4, endY + 4)
        ..lineTo(x + 4, endY + 4)
        ..close();
      canvas.drawPath(head, headPaint);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: 'Q_c = ${qcKw.toStringAsFixed(2)} kW',
        style: const TextStyle(
          color: ScadaColors.highPressureDischarge,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          backgroundColor: Color(0xCC1E293B),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.top - 42));
  }
}
