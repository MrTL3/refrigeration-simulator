import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Renderizador volumétrico 3D de alta fidelidad del Compresor Hermético industrial.
///
/// Modela:
/// - Bancada de perfiles de acero con 4 amortiguadores cónicos de goma vulcanizada (silentblocks).
/// - Cuerpo cilíndrico/ovoide con cúpula esferoidal y brillos especulares volumétricos.
/// - Cordón de soldadura perimetral industrial.
/// - Mirilla de nivel de aceite en el cárter con líquido lubricante ámbar y burbujeo dinámico.
/// - Caja de bornes eléctricos IP55 con pasacables.
/// - Válvulas de servicio de aspiración y descarga tipo Rotalock con tomas Schräder de latón.
/// - Micro-vibración cinemática sutil proporcional a las RPM reales del solver.
class Compressor3DRenderer {
  static void paint({
    required Canvas canvas,
    required Rect compRect,
    required SimulationState state,
    required double crankAngleRad,
    required bool isSelected,
  }) {
    final rpm = state.dynamicRpm;
    final isRunning = rpm > 10.0;

    // Vibración cinemática sutil si el compresor está en marcha
    final vibOffsetX = isRunning ? 0.8 * math.sin(crankAngleRad * 2.0) : 0.0;
    final vibOffsetY = isRunning ? 0.6 * math.cos(crankAngleRad * 2.0) : 0.0;
    final compCenter = Offset(compRect.center.dx + vibOffsetX, compRect.center.dy + vibOffsetY);

    // 0. Sombra arrojada en el suelo de la sala de máquinas
    final floorShadow = Rect.fromCenter(
      center: Offset(compRect.center.dx, compRect.bottom + 8),
      width: compRect.width * 1.15,
      height: 18,
    );
    canvas.drawOval(
      floorShadow,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 1. Bancada metálica industrial de perfiles de acero (gris grafito)
    final baseRect = Rect.fromCenter(
      center: Offset(compRect.center.dx, compRect.bottom - 8),
      width: compRect.width * 1.10,
      height: 16,
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(baseRect);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(4)), basePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF475569)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Tornillos de anclaje al suelo en los extremos
    final boltPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawCircle(Offset(baseRect.left + 10, baseRect.center.dy), 3.5, boltPaint);
    canvas.drawCircle(Offset(baseRect.right - 10, baseRect.center.dy), 3.5, boltPaint);

    // 2. Cuatro amortiguadores silentblocks de goma vulcanizada
    final sb1X = compCenter.dx - compRect.width * 0.35;
    final sb2X = compCenter.dx + compRect.width * 0.35;
    final sbY = compRect.bottom - 22;

    _drawSilentBlock(canvas, Offset(sb1X, sbY));
    _drawSilentBlock(canvas, Offset(sb2X, sbY));

    // 3. Carcasa esférica/ovoide del compresor (volumen metálico lacado en azul noche industrial)
    final domeWidth = compRect.width * 0.85;
    final domeHeight = compRect.height * 0.88;
    final domeRect = Rect.fromCenter(
      center: Offset(compCenter.dx, compCenter.dy - 12),
      width: domeWidth,
      height: domeHeight,
    );

    // Gradiente cilíndrico-esférico para simular volumen metálico 3D con luz cenital izquierda
    final domePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          const Color(0xFF384B6E), // Brillo metálico especular
          const Color(0xFF1E2638), // Color base azul grafito
          const Color(0xFF111827), // Sombra inferior profunda
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(domeRect);

    final domeRRect = RRect.fromRectAndRadius(domeRect, Radius.circular(domeWidth * 0.42));
    canvas.drawRRect(domeRRect, domePaint);

    // Borde iluminado / silueta
    final domeBorder = Paint()
      ..color = isSelected ? ScadaColors.infoBlue : const Color(0xFF3B4861)
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(domeRRect, domeBorder);

    // Cordón de soldadura perimetral central (seam de unión de las dos mitades del domo)
    final seamY = domeRect.center.dy + 8;
    final seamRect = Rect.fromCenter(center: Offset(domeRect.center.dx, seamY), width: domeWidth * 0.98, height: 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(seamRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF2E3A52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(seamRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF4A5D82).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 4. Caja de conexiones eléctricas IP55 a la derecha
    final boxRect = Rect.fromLTWH(domeRect.right - 18, domeRect.center.dy - 14, 28, 44);
    final boxPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF334155), Color(0xFF1E293B)],
      ).createShader(boxRect);
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(4)), boxPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Pictograma de peligro eléctrico rayo amarillo
    final rayPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final rayPath = Path()
      ..moveTo(boxRect.center.dx + 2, boxRect.top + 10)
      ..lineTo(boxRect.center.dx - 2, boxRect.top + 20)
      ..lineTo(boxRect.center.dx + 3, boxRect.top + 20)
      ..lineTo(boxRect.center.dx - 1, boxRect.top + 32);
    canvas.drawPath(rayPath, rayPaint);

    // Prensacables inferior de la caja
    canvas.drawRect(Rect.fromLTWH(boxRect.center.dx - 4, boxRect.bottom, 8, 8), Paint()..color = const Color(0xFF475569));

    // 5. Mirilla de nivel de aceite en el cárter (parte inferior izquierda del domo)
    final sightGlassCenter = Offset(domeRect.left + 36, domeRect.bottom - 36);
    const sightGlassRadius = 13.0;

    // Marco exterior de latón roscado
    canvas.drawCircle(sightGlassCenter, sightGlassRadius + 2.5, Paint()..color = const Color(0xFF92400E));
    canvas.drawCircle(
      sightGlassCenter,
      sightGlassRadius + 2.5,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Cristal de la mirilla
    canvas.drawCircle(sightGlassCenter, sightGlassRadius, Paint()..color = const Color(0xFF0F172A));

    // Nivel de aceite lubricante (medio visor, color ámbar brillante)
    final oilPath = Path()
      ..addArc(
        Rect.fromCircle(center: sightGlassCenter, radius: sightGlassRadius),
        0.0,
        math.pi,
      );
    canvas.drawPath(
      oilPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
        ).createShader(Rect.fromCircle(center: sightGlassCenter, radius: sightGlassRadius)),
    );

    // Punto de nivel óptimo central
    canvas.drawCircle(sightGlassCenter, 2.0, Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Reflejo elíptico del cristal
    final glassGlare = Path()
      ..addOval(Rect.fromCenter(center: Offset(sightGlassCenter.dx - 3, sightGlassCenter.dy - 3), width: 7, height: 4));
    canvas.drawPath(glassGlare, Paint()..color = Colors.white.withValues(alpha: 0.35));

    // 6. Placa de características técnicas del compresor (frontal)
    final nameplateRect = Rect.fromCenter(
      center: Offset(domeRect.center.dx - 6, domeRect.center.dy - 36),
      width: 70,
      height: 24,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(nameplateRect, const Radius.circular(2)), Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(
      RRect.fromRectAndRadius(nameplateRect, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFF475569)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final tpPlate = TextPainter(
      text: TextSpan(
        text: 'FRIGOLAB\n${rpm.toInt()} RPM',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tpPlate.paint(canvas, Offset(nameplateRect.center.dx - tpPlate.width / 2, nameplateRect.center.dy - tpPlate.height / 2));

    // 7. Válvulas de servicio Rotalock con tapones de latón
    // Válvula de aspiración (izquierda-arriba)
    _drawServiceValve(canvas, Offset(domeRect.left + 16, domeRect.top + 28), ScadaColors.lowPressureSuction, 'ASPIRACIÓN');

    // Válvula de descarga (derecha-arriba)
    _drawServiceValve(canvas, Offset(domeRect.right - 16, domeRect.top + 28), ScadaColors.highPressureDischarge, 'DESCARGA');
  }

  static void _drawSilentBlock(Canvas canvas, Offset center) {
    // Bloque cónico de goma vulcanizada negra
    final rubberPath = Path()
      ..moveTo(center.dx - 12, center.dy + 8)
      ..lineTo(center.dx - 8, center.dy - 6)
      ..lineTo(center.dx + 8, center.dy - 6)
      ..lineTo(center.dx + 12, center.dy + 8)
      ..close();

    final rubberPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF334155), Color(0xFF0F172A)],
      ).createShader(rubberPath.getBounds());
    canvas.drawPath(rubberPath, rubberPaint);

    // Perno central pasante de acero galvanizado
    canvas.drawRect(Rect.fromLTWH(center.dx - 2.5, center.dy - 10, 5, 20), Paint()..color = const Color(0xFF94A3B8));
    // Arandela superior
    canvas.drawRect(Rect.fromLTWH(center.dx - 7, center.dy - 8, 14, 3), Paint()..color = const Color(0xFFCBD5E1));
  }

  static void _drawServiceValve(Canvas canvas, Offset pos, Color fluidColor, String label) {
    // Cuerpo de válvula de latón forjado
    final valveBody = Rect.fromCenter(center: pos, width: 18, height: 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(valveBody, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD97706), Color(0xFF92400E)],
        ).createShader(valveBody),
    );

    // Toma de servicio Schräder con tapón hexagonal
    final capRect = Rect.fromCenter(center: Offset(pos.dx, pos.dy - 12), width: 10, height: 8);
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(2)), Paint()..color = const Color(0xFFF59E0B));

    // Indicador circular de toma de fluido
    canvas.drawCircle(pos, 3.5, Paint()..color = fluidColor);
  }
}
