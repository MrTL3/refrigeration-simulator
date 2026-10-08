import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Renderizador volumétrico 3D / Isométrico de la Cámara Frigorífica industrial.
///
/// Modela una cámara de conservación comercial en perspectiva con corte transversal:
/// - Paredes sándwich de 100 mm con textura de panel frigorífico lacado y perfiles sanitarios.
/// - Suelo técnico aislado con rodapié curvo.
/// - Puerta frigorífica semiabierta con bisagras industriales y maneta de seguridad con cerrojo.
/// - Techo aislante suspendido donde se ancla el evaporador.
/// - Iluminación interior fría de cámara LED (azul tenue / blanco).
/// - Termómetro digital exterior en el dintel de la puerta que muestra la temperatura real de la cámara.
class ColdRoom3DRenderer {
  static void paint({
    required Canvas canvas,
    required Rect roomRect,
    required SimulationState state,
    required bool isSelected,
  }) {
    final tCamC = state.coldRoom.temperatureKelvin - 273.15;
    final depthOffset = const Offset(28, -20); // Vector de proyección isométrica hacia atrás/arriba

    // 0. Sombra arrojada de la cámara en el suelo de la sala
    final floorShadowPath = Path()
      ..moveTo(roomRect.left + 15, roomRect.bottom + 6)
      ..lineTo(roomRect.right + depthOffset.dx + 10, roomRect.bottom + 6)
      ..lineTo(roomRect.right + depthOffset.dx + 4, roomRect.bottom + depthOffset.dy + 12)
      ..lineTo(roomRect.left + depthOffset.dx, roomRect.bottom + depthOffset.dy + 12)
      ..close();
    canvas.drawPath(
      floorShadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 1. Suelo interior de la cámara (perspectiva)
    final floorPath = Path()
      ..moveTo(roomRect.left + 24, roomRect.bottom - 16)
      ..lineTo(roomRect.right - 24, roomRect.bottom - 16)
      ..lineTo(roomRect.right - 24 + depthOffset.dx, roomRect.bottom - 16 + depthOffset.dy)
      ..lineTo(roomRect.left + 24 + depthOffset.dx, roomRect.bottom - 16 + depthOffset.dy)
      ..close();
    canvas.drawPath(
      floorPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E2638), Color(0xFF2C394F)],
        ).createShader(floorPath.getBounds()),
    );

    // Textura antideslizante del suelo de la cámara (rejilla metálica tenue)
    final floorGridPaint = Paint()
      ..color = const Color(0xFF3B4861).withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    for (double i = roomRect.left + 40; i < roomRect.right; i += 30) {
      canvas.drawLine(
        Offset(i, roomRect.bottom - 16),
        Offset(i + depthOffset.dx * 0.8, roomRect.bottom - 16 + depthOffset.dy * 0.8),
        floorGridPaint,
      );
    }

    // 2. Pared trasera interior de la cámara
    final backWallPath = Path()
      ..moveTo(roomRect.left + 24 + depthOffset.dx, roomRect.top + 24 + depthOffset.dy)
      ..lineTo(roomRect.right - 24 + depthOffset.dx, roomRect.top + 24 + depthOffset.dy)
      ..lineTo(roomRect.right - 24 + depthOffset.dx, roomRect.bottom - 16 + depthOffset.dy)
      ..lineTo(roomRect.left + 24 + depthOffset.dx, roomRect.bottom - 16 + depthOffset.dy)
      ..close();
    canvas.drawPath(
      backWallPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF162138)],
        ).createShader(backWallPath.getBounds()),
    );

    // Líneas de paneles sándwich verticales en pared trasera
    final panelJointPaint = Paint()
      ..color = const Color(0xFF24334C).withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    for (double x = roomRect.left + 60; x < roomRect.right; x += 65) {
      canvas.drawLine(
        Offset(x + depthOffset.dx, roomRect.top + 24 + depthOffset.dy),
        Offset(x + depthOffset.dx, roomRect.bottom - 16 + depthOffset.dy),
        panelJointPaint,
      );
    }

    // Resplandor de frío interior (luz LED azulada dentro de la cámara)
    final coldGlowPath = Path()..addRect(Rect.fromLTRB(
      roomRect.left + 24,
      roomRect.top + 24,
      roomRect.right - 24,
      roomRect.bottom - 16,
    ));
    canvas.drawPath(
      coldGlowPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.4),
          radius: 0.8,
          colors: [
            const Color(0xFF06B6D4).withValues(alpha: state.isRunning ? 0.08 : 0.03),
            Colors.transparent,
          ],
        ).createShader(coldGlowPath.getBounds()),
    );

    // 3. Estructura exterior / Marco frontal cortado de paneles sándwich
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF222F43), Color(0xFF17202F)],
      ).createShader(roomRect);

    // Pared izquierda
    final leftWall = Path()
      ..moveTo(roomRect.left, roomRect.top)
      ..lineTo(roomRect.left + 24, roomRect.top + 24)
      ..lineTo(roomRect.left + 24, roomRect.bottom - 16)
      ..lineTo(roomRect.left, roomRect.bottom)
      ..close();
    canvas.drawPath(leftWall, wallPaint);

    // Pared derecha
    final rightWall = Path()
      ..moveTo(roomRect.right - 24, roomRect.top + 24)
      ..lineTo(roomRect.right, roomRect.top)
      ..lineTo(roomRect.right, roomRect.bottom)
      ..lineTo(roomRect.right - 24, roomRect.bottom - 16)
      ..close();
    canvas.drawPath(rightWall, wallPaint);

    // Techo
    final ceilingPath = Path()
      ..moveTo(roomRect.left, roomRect.top)
      ..lineTo(roomRect.right, roomRect.top)
      ..lineTo(roomRect.right - 24, roomRect.top + 24)
      ..lineTo(roomRect.left + 24, roomRect.top + 24)
      ..close();
    canvas.drawPath(
      ceilingPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF334460), Color(0xFF1E2838)],
        ).createShader(ceilingPath.getBounds()),
    );

    // Suelo exterior
    final floorFront = Path()
      ..moveTo(roomRect.left, roomRect.bottom)
      ..lineTo(roomRect.left + 24, roomRect.bottom - 16)
      ..lineTo(roomRect.right - 24, roomRect.bottom - 16)
      ..lineTo(roomRect.right, roomRect.bottom)
      ..close();
    canvas.drawPath(floorFront, wallPaint);

    // Bordes y biseles metálicos de la cámara
    final borderPaint = Paint()
      ..color = isSelected ? ScadaColors.runningGreen : const Color(0xFF3B82F6).withValues(alpha: 0.6)
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(roomRect, borderPaint);

    // 4. Puerta frigorífica semiabierta a la izquierda
    final doorRect = Rect.fromLTWH(roomRect.left - 18, roomRect.top + 60, 22, roomRect.height - 110);
    final doorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF475569), Color(0xFF334155), Color(0xFF1E293B)],
      ).createShader(doorRect);
    canvas.drawRRect(RRect.fromRectAndRadius(doorRect, const Radius.circular(4)), doorPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(doorRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Maneta de desbloqueo y bisagras de alta resistencia
    final hingePaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(doorRect.left + 3, doorRect.top + 30, 8, 16), const Radius.circular(2)), hingePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(doorRect.left + 3, doorRect.bottom - 46, 8, 16), const Radius.circular(2)), hingePaint);
    // Maneta central
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(doorRect.right - 6, doorRect.top + doorRect.height / 2 - 14, 10, 28), const Radius.circular(3)), Paint()..color = const Color(0xFFCBD5E1));

    // 5. Termómetro LED digital en el dintel exterior
    final ledRect = Rect.fromCenter(center: Offset(roomRect.center.dx, roomRect.top + 12), width: 140, height: 22);
    canvas.drawRRect(RRect.fromRectAndRadius(ledRect, const Radius.circular(4)), Paint()..color = const Color(0xFF0F172A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(ledRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final ledText = 'CÁMARA: ${tCamC.toStringAsFixed(1)} °C';
    final tpLed = TextPainter(
      text: TextSpan(
        text: ledText,
        style: const TextStyle(
          color: ScadaColors.cyanAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLed.paint(canvas, Offset(ledRect.center.dx - tpLed.width / 2, ledRect.center.dy - tpLed.height / 2));
  }
}
