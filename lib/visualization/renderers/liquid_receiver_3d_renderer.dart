import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Renderizador volumétrico 3D de los elementos auxiliares de la línea de líquido:
/// - Recipiente de líquido vertical (calderín) con fondos bombeados toriesféricos.
/// - Filtro deshidratador molecular con cuerpo de acero y flecha de sentido de flujo.
/// - Visor de líquido con mirilla de cristal, corona indicadora de humedad (verde/amarillo)
///   y animación de burbujas de vapor flash cuando el subenfriamiento es bajo (SC < 2 K).
/// - Caudalímetro másico de refrigerante.
class LiquidReceiver3DRenderer {
  static void paint({
    required Canvas canvas,
    required Rect receiverRect,
    required Rect filterRect,
    required Rect sightGlassRect,
    required Rect flowmeterRect,
    required SimulationState state,
    required double bubblePhase,
  }) {
    final sc = state.subcoolingKelvin;
    final isRunning = state.isRunning;
    final hasFlashGas = sc < 2.0 && isRunning;

    // ==========================================
    // 1. RECIPIENTE DE LÍQUIDO VERTICAL (CALDERÍN)
    // ==========================================
    // Sombra del calderín
    canvas.drawOval(
      Rect.fromCenter(center: Offset(receiverRect.center.dx, receiverRect.bottom + 6), width: receiverRect.width * 1.1, height: 14),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Cuerpo cilíndrico de acero (fondo bombeado arriba y abajo)
    final receiverShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF1E293B),
        Color(0xFF475569),
        Color(0xFF94A3B8), // Reflejo cilíndrico
        Color(0xFF334155),
        Color(0xFF0F172A),
      ],
      stops: [0.0, 0.25, 0.55, 0.85, 1.0],
    ).createShader(receiverRect);

    final receiverRRect = RRect.fromRectAndRadius(receiverRect, const Radius.circular(16));
    canvas.drawRRect(receiverRRect, Paint()..shader = receiverShader);
    canvas.drawRRect(
      receiverRRect,
      Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Visor de nivel vertical en el cuerpo del calderín
    final levelRect = Rect.fromCenter(
      center: Offset(receiverRect.center.dx, receiverRect.center.dy),
      width: 10,
      height: receiverRect.height * 0.65,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(levelRect, const Radius.circular(5)), Paint()..color = const Color(0xFF0F172A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(levelRect, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Columna de refrigerante líquido acumulado (65% del calderín)
    final liquidLevelHeight = levelRect.height * 0.65;
    final liquidLevelRect = Rect.fromLTWH(
      levelRect.left + 1,
      levelRect.bottom - liquidLevelHeight,
      levelRect.width - 2,
      liquidLevelHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(liquidLevelRect, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
        ).createShader(liquidLevelRect),
    );

    // Etiqueta del calderín
    final tpRec = TextPainter(
      text: const TextSpan(
        text: 'RECIPIENTE LÍQUIDO',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpRec.paint(canvas, Offset(receiverRect.center.dx - tpRec.width / 2, receiverRect.bottom + 10));

    // ==========================================
    // 2. FILTRO DESHIDRATADOR MOLECULAR
    // ==========================================
    final filterShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF334155),
        Color(0xFF64748B),
        Color(0xFF1E293B),
      ],
    ).createShader(filterRect);

    final filterRRect = RRect.fromRectAndRadius(filterRect, const Radius.circular(6));
    canvas.drawRRect(filterRRect, Paint()..shader = filterShader);
    canvas.drawRRect(
      filterRRect,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Flecha de sentido de flujo sobre el filtro
    final arrowPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(filterRect.left + 8, filterRect.center.dy),
      Offset(filterRect.right - 8, filterRect.center.dy),
      arrowPaint,
    );
    final arrHead = Path()
      ..moveTo(filterRect.right - 12, filterRect.center.dy - 4)
      ..lineTo(filterRect.right - 6, filterRect.center.dy)
      ..lineTo(filterRect.right - 12, filterRect.center.dy + 4);
    canvas.drawPath(arrHead, arrowPaint);

    final tpFilter = TextPainter(
      text: const TextSpan(
        text: 'FILTRO',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpFilter.paint(canvas, Offset(filterRect.center.dx - tpFilter.width / 2, filterRect.top - 12));

    // ==========================================
    // 3. VISOR DE LÍQUIDO CON INDICADOR DE HUMEDAD
    // ==========================================
    final sgCenter = sightGlassRect.center;
    final sgRadius = sightGlassRect.width / 2.0;

    // Cuerpo de latón
    canvas.drawCircle(sgCenter, sgRadius + 2.5, Paint()..color = const Color(0xFFD97706));
    canvas.drawCircle(
      sgCenter,
      sgRadius + 2.5,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Cristal de mirilla interior
    canvas.drawCircle(sgCenter, sgRadius, Paint()..color = const Color(0xFF0F172A));

    // Corona química indicadora de humedad:
    // Verde = Seco (óptimo), Amarillo = Húmedo (filtro saturado)
    final moistureRingColor = const Color(0xFF22C55E); // Circuito seco
    canvas.drawCircle(
      sgCenter,
      sgRadius * 0.70,
      Paint()
        ..color = moistureRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Líquido refrigerante en el visor (rojo anaranjado de alta presión)
    canvas.drawCircle(
      sgCenter,
      sgRadius * 0.45,
      Paint()..color = ScadaColors.highPressureLiquid.withValues(alpha: 0.85),
    );

    // Si hay flash gas (falta de subenfriamiento SC < 2 K), dibujar burbujas animadas
    if (hasFlashGas) {
      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (int i = 0; i < 3; i++) {
        final bAngle = bubblePhase * 2.0 * math.pi + (i * 2.0 * math.pi / 3.0);
        final bDist = (sgRadius * 0.3) * (0.5 + 0.5 * math.sin(bubblePhase * math.pi));
        final bx = sgCenter.dx + bDist * math.cos(bAngle);
        final by = sgCenter.dy + bDist * math.sin(bAngle);
        canvas.drawCircle(Offset(bx, by), 2.0, bubblePaint);
        canvas.drawCircle(Offset(bx, by), 1.0, Paint()..color = Colors.white.withValues(alpha: 0.6));
      }
    }

    // Reflejo elíptico del cristal
    canvas.drawOval(
      Rect.fromCenter(center: Offset(sgCenter.dx - 3, sgCenter.dy - 3), width: 6, height: 4),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    final tpSg = TextPainter(
      text: const TextSpan(
        text: 'VISOR',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSg.paint(canvas, Offset(sgCenter.dx - tpSg.width / 2, sightGlassRect.top - 12));

    // ==========================================
    // 4. CAUDALÍMETRO MÁSICO DE REFRIGERANTE
    // ==========================================
    final flowShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F766E), Color(0xFF115E59)],
    ).createShader(flowmeterRect);

    final flowRRect = RRect.fromRectAndRadius(flowmeterRect, const Radius.circular(4));
    canvas.drawRRect(flowRRect, Paint()..shader = flowShader);
    canvas.drawRRect(
      flowRRect,
      Paint()
        ..color = const Color(0xFF2DD4BF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Pantalla digital del caudalímetro
    final flowDisplayRect = Rect.fromCenter(center: flowmeterRect.center, width: flowmeterRect.width - 8, height: flowmeterRect.height - 8);
    canvas.drawRect(flowDisplayRect, Paint()..color = const Color(0xFF042F2E));

    final mDotGs = state.massFlowKgPerSec * 1000.0;
    final tpFlow = TextPainter(
      text: TextSpan(
        text: '${mDotGs.toStringAsFixed(1)}\ng/s',
        style: const TextStyle(
          color: Color(0xFF2DD4BF),
          fontSize: 6.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          height: 1.0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tpFlow.paint(canvas, Offset(flowmeterRect.center.dx - tpFlow.width / 2, flowmeterRect.center.dy - tpFlow.height / 2));
  }
}
