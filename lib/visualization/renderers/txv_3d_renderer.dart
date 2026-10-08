import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Renderizador volumétrico 3D de la Válvula de Expansión Termostática (TXV).
///
/// Modela:
/// - Cuerpo macizo de forja de latón dorado en ángulo de 90° con tuercas hexagonales.
/// - Cámara termostática superior de membrana/fuelle en acero inoxidable brillante.
/// - Tubo capilar de cobre flexible en espiral tridimensional hacia el bulbo palpador.
/// - Bulbo palpador cilíndrico de cobre fijado con abrazaderas a la línea de aspiración.
/// - Tornillo inferior de ajuste de recalentamiento estático con capuchón hexagonal.
/// - Representación del orificio modulante según la apertura física calculada.
class Txv3DRenderer {
  static void paint({
    required Canvas canvas,
    required Rect txvRect,
    required SimulationState state,
    required Offset bulbPosition,
    required bool isSelected,
  }) {
    final exp = state.circuit.expansionDevice;
    final openingPercent = exp?.openingPercent ?? 50.0;
    final isAuto = exp?.isAutomatic ?? true;
    final center = txvRect.center;

    // 0. Sombra arrojada de la válvula en la pared
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 6, center.dy + 8), width: txvRect.width * 0.9, height: 16),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 1. Cuerpo de latón forjado en ángulo de 90° (dorado metálico con volumen)
    final brassShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFDE68A), // Brillo dorado especular
        Color(0xFFD97706), // Latón forjado base
        Color(0xFF78350F), // Sombra de latón profunda
      ],
      stops: [0.0, 0.45, 1.0],
    ).createShader(txvRect);

    final brassPaint = Paint()..shader = brassShader;

    // Rama vertical del cuerpo
    final vertBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 6), width: 26, height: 48),
      const Radius.circular(4),
    );
    canvas.drawRRect(vertBody, brassPaint);

    // Rama horizontal de salida (hacia la izquierda, entrando en la cámara)
    final horizBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx - 16, center.dy + 12), width: 36, height: 22),
      const Radius.circular(3),
    );
    canvas.drawRRect(horizBody, brassPaint);

    // Tuercas abocardadas de conexión
    _drawHexNut(canvas, Offset(center.dx, center.dy + 32), 22, 10);      // Entrada líquido (abajo)
    _drawHexNut(canvas, Offset(center.dx - 32, center.dy + 12), 10, 20); // Salida bifásica (izquierda)

    // Borde de selección
    if (isSelected) {
      canvas.drawRRect(
        vertBody,
        Paint()
          ..color = ScadaColors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // 2. Cabezal termostático superior (membrana / elemento de potencia en acero inoxidable)
    final headRect = Rect.fromCenter(center: Offset(center.dx, center.dy - 24), width: 44, height: 22);
    final headPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFCBD5E1), Color(0xFF64748B), Color(0xFF334155)],
      ).createShader(headRect);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(10)), headPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Cordón de soldadura láser de la membrana
    canvas.drawLine(
      Offset(headRect.left + 3, headRect.center.dy),
      Offset(headRect.right - 3, headRect.center.dy),
      Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 1.0,
    );

    // 3. Tornillo inferior de ajuste de recalentamiento con capuchón
    final stemRect = Rect.fromCenter(center: Offset(center.dx, center.dy + 42), width: 14, height: 12);
    canvas.drawRRect(RRect.fromRectAndRadius(stemRect, const Radius.circular(2)), brassPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + 45), 2.5, Paint()..color = const Color(0xFF451A03));

    // 4. Tubo capilar en espiral de cobre que va desde el cabezal hacia el bulbo palpador
    final capColor = const Color(0xFFB45309);
    final capPaint = Paint()
      ..color = capColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startCap = Offset(center.dx, headRect.top);
    final capPath = Path()..moveTo(startCap.dx, startCap.dy);

    // Rizo/espiral amortiguador de 2 vueltas
    final r1Center = Offset(startCap.dx - 12, startCap.dy - 10);
    capPath.arcTo(Rect.fromCircle(center: r1Center, radius: 8), 0.0, -math.pi * 1.5, false);
    final r2Center = Offset(startCap.dx - 22, startCap.dy - 16);
    capPath.arcTo(Rect.fromCircle(center: r2Center, radius: 8), 0.0, math.pi * 1.4, false);

    // Trazado hacia el bulbo sensor fijado a la salida del evaporador
    capPath.cubicTo(
      bulbPosition.dx + 40,
      r2Center.dy - 20,
      bulbPosition.dx + 20,
      bulbPosition.dy - 30,
      bulbPosition.dx,
      bulbPosition.dy,
    );
    canvas.drawPath(capPath, capPaint);

    // 5. Bulbo palpador cilíndrico de cobre sobre la tubería de aspiración
    final bulbRect = Rect.fromCenter(center: bulbPosition, width: 34, height: 14);
    final bulbPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBBF24), Color(0xFFB45309), Color(0xFF78350F)],
      ).createShader(bulbRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bulbRect, const Radius.circular(5)), bulbPaint);

    // Abrazaderas metálicas fijando el bulbo a la tubería
    final clampPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawRect(Rect.fromLTWH(bulbRect.left + 5, bulbRect.top - 2, 4, bulbRect.height + 4), clampPaint);
    canvas.drawRect(Rect.fromLTWH(bulbRect.right - 9, bulbRect.top - 2, 4, bulbRect.height + 4), clampPaint);

    // 6. Placa indicadora de apertura de la válvula
    final badgeRect = Rect.fromCenter(center: Offset(center.dx, center.dy + 6), width: 32, height: 12);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(2)), Paint()..color = const Color(0xFF0F172A));
    final tp = TextPainter(
      text: TextSpan(
        text: isAuto ? 'AUTO' : '${openingPercent.toInt()}%',
        style: TextStyle(
          color: isAuto ? ScadaColors.cyanAccent : ScadaColors.warningAmber,
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(badgeRect.center.dx - tp.width / 2, badgeRect.center.dy - tp.height / 2));
  }

  static void _drawHexNut(Canvas canvas, Offset pos, double w, double h) {
    final rect = Rect.fromCenter(center: pos, width: w, height: h);
    final nutPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDE68A), Color(0xFFB45309)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), nutPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFF78350F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }
}
