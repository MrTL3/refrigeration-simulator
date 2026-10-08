import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Renderizador volumétrico 3D del Evaporador cúbico comercial de techo.
///
/// Modela:
/// - Carcasa cúbica suspendida en perfiles de techo con textura de aluminio lacado.
/// - Paquete de aletas de aluminio y curvas en horquilla de tubos de cobre con cambio de fase.
/// - Doble tobera axial con hélices tridimensionales girando a la velocidad real del solver.
/// - Bandeja inferior de recogida de condensados con pendiente y tubo de desagüe exterior.
/// - Distribuidor de líquido refrigerante Venturi.
class Evaporator3DRenderer {
  static void paint({
    required Canvas canvas,
    required Rect evapRect,
    required SimulationState state,
    required double fanAngleRad,
    required bool isSelected,
    required bool showHeatVectors,
  }) {
    final fanRpm = state.evaporatorAirFlow.fanRpm;
    final isFanRunning = fanRpm > 10.0;
    const depthOffset = Offset(18, -12);

    // 0. Sombra arrojada del evaporador en la pared trasera de la cámara
    final shadowPath = Path()
      ..addRect(Rect.fromLTWH(evapRect.left + 8, evapRect.top + 8, evapRect.width, evapRect.height));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 1. Carcasa superior / techo del evaporador (perspectiva 3D)
    final topFace = Path()
      ..moveTo(evapRect.left, evapRect.top)
      ..lineTo(evapRect.right, evapRect.top)
      ..lineTo(evapRect.right + depthOffset.dx, evapRect.top + depthOffset.dy)
      ..lineTo(evapRect.left + depthOffset.dx, evapRect.top + depthOffset.dy)
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

    // 2. Lateral derecho del evaporador
    final rightFace = Path()
      ..moveTo(evapRect.right, evapRect.top)
      ..lineTo(evapRect.right + depthOffset.dx, evapRect.top + depthOffset.dy)
      ..lineTo(evapRect.right + depthOffset.dx, evapRect.bottom + depthOffset.dy)
      ..lineTo(evapRect.right, evapRect.bottom)
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

    // 3. Frontal del evaporador: Carcasa metálica con compartimento para serpentín y ventiladores
    final frontBody = RRect.fromRectAndRadius(evapRect, const Radius.circular(8));
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(evapRect);
    canvas.drawRRect(frontBody, bodyPaint);

    final borderPaint = Paint()
      ..color = isSelected ? ScadaColors.cyanAccent : const Color(0xFF475569)
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(frontBody, borderPaint);

    // 4. Paquete de aletas y serpentín (zona superior-central)
    final coilRect = Rect.fromLTWH(evapRect.left + 14, evapRect.top + 14, evapRect.width - 28, 54);
    canvas.drawRRect(RRect.fromRectAndRadius(coilRect, const Radius.circular(4)), Paint()..color = const Color(0xFF0B132B));

    // Aletas verticales de aluminio
    final finPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    for (double x = coilRect.left + 4; x < coilRect.right; x += 4.5) {
      canvas.drawLine(Offset(x, coilRect.top), Offset(x, coilRect.bottom), finPaint);
    }

    // Tubos horizontales de cobre (con evaporación bifásica: azul cian frío)
    final tubePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
      ).createShader(coilRect)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final yTube1 = coilRect.top + 14;
    final yTube2 = coilRect.top + 28;
    final yTube3 = coilRect.top + 42;

    canvas.drawLine(Offset(coilRect.left + 10, yTube1), Offset(coilRect.right - 10, yTube1), tubePaint);
    canvas.drawLine(Offset(coilRect.left + 10, yTube2), Offset(coilRect.right - 10, yTube2), tubePaint);
    canvas.drawLine(Offset(coilRect.left + 10, yTube3), Offset(coilRect.right - 10, yTube3), tubePaint);

    // Codos de retorno en los extremos
    final bendPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawArc(Rect.fromCenter(center: Offset(coilRect.right - 10, (yTube1 + yTube2) / 2), width: 14, height: 14), -math.pi / 2, math.pi, false, bendPaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(coilRect.left + 10, (yTube2 + yTube3) / 2), width: 14, height: 14), math.pi / 2, math.pi, false, bendPaint);

    // 5. Doble Ventilador Axial 3D
    final fan1Center = Offset(evapRect.left + evapRect.width * 0.30, evapRect.bottom - 44);
    final fan2Center = Offset(evapRect.left + evapRect.width * 0.70, evapRect.bottom - 44);
    const fanRadius = 26.0;

    _drawAxialFan(canvas, fan1Center, fanRadius, fanAngleRad, isFanRunning);
    _drawAxialFan(canvas, fan2Center, fanRadius, -fanAngleRad + 0.5, isFanRunning);

    // 6. Bandeja de condensados inferior con pendiente
    final trayRect = Rect.fromLTWH(evapRect.left + 6, evapRect.bottom - 10, evapRect.width - 12, 12);
    final trayPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF475569), Color(0xFF1E293B)],
      ).createShader(trayRect);
    canvas.drawRRect(RRect.fromRectAndRadius(trayRect, const Radius.circular(3)), trayPaint);

    // Tubo de purga / desagüe con sifón saliendo a la izquierda
    final drainPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final drainPath = Path()
      ..moveTo(evapRect.left + 16, evapRect.bottom - 2)
      ..lineTo(evapRect.left + 16, evapRect.bottom + 14)
      ..lineTo(evapRect.left + 26, evapRect.bottom + 14)
      ..lineTo(evapRect.left + 26, evapRect.bottom + 26)
      ..lineTo(evapRect.left - 10, evapRect.bottom + 26);
    canvas.drawPath(drainPath, drainPaint);

    // 7. Flechas de calor absorbido (Qe) si la capa CALOR está activa
    if (showHeatVectors && state.isRunning) {
      final qeKw = state.coolingCapacityWatts / 1000.0;
      _drawHeatAbsorptionVectors(canvas, evapRect, qeKw);
    }
  }

  static void _drawAxialFan(Canvas canvas, Offset center, double radius, double angleRad, bool isRunning) {
    // Tobera circular con bisel
    canvas.drawCircle(center, radius + 2, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..color = const Color(0xFF475569)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Rejilla de protección concéntrica
    final guardPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.55, guardPaint);
    canvas.drawCircle(center, radius * 0.85, guardPaint);

    // Aspas tridimensionales rotando
    final numBlades = 4;
    final bladePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          isRunning ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
          const Color(0xFF0F172A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (int i = 0; i < numBlades; i++) {
      final a = angleRad + (i * 2.0 * math.pi / numBlades);
      final bladePath = Path()
        ..moveTo(center.dx + 5 * math.cos(a + 0.4), center.dy + 5 * math.sin(a + 0.4))
        ..quadraticBezierTo(
          center.dx + radius * 0.7 * math.cos(a + 0.3),
          center.dy + radius * 0.7 * math.sin(a + 0.3),
          center.dx + (radius - 2) * math.cos(a),
          center.dy + (radius - 2) * math.sin(a),
        )
        ..lineTo(center.dx + (radius - 3) * math.cos(a - 0.2), center.dy + (radius - 3) * math.sin(a - 0.2))
        ..quadraticBezierTo(
          center.dx + radius * 0.5 * math.cos(a - 0.1),
          center.dy + radius * 0.5 * math.sin(a - 0.1),
          center.dx + 5 * math.cos(a - 0.3),
          center.dy + 5 * math.sin(a - 0.3),
        )
        ..close();
      canvas.drawPath(bladePath, bladePaint);
    }

    // Cubo / ojiva central metálica
    canvas.drawCircle(center, 6.0, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawCircle(center, 3.0, Paint()..color = const Color(0xFFCBD5E1));
  }

  static void _drawHeatAbsorptionVectors(Canvas canvas, Rect rect, double qeKw) {
    final arrowPaint = Paint()
      ..color = ScadaColors.cyanAccent.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = ScadaColors.cyanAccent
      ..style = PaintingStyle.fill;

    // Flechas ascendentes entrando en el evaporador desde el recinto
    for (double x = rect.left + 35; x <= rect.right - 35; x += 45) {
      final startY = rect.bottom + 28;
      final endY = rect.bottom + 4;
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
        text: 'Q_e = ${qeKw.toStringAsFixed(2)} kW',
        style: const TextStyle(
          color: ScadaColors.cyanAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          backgroundColor: Color(0xCC0B132B),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.bottom + 32));
  }
}
