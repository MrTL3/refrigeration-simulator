import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';
import '../contracts/physical_visualizer.dart';

/// Visualizador cinemático 2.5D del compresor alternativo hermético.
/// La cinemática de biela-manivela, el desplazamiento del pistón, la apertura de válvulas
/// y la coloración del gas en la cámara de compresión proceden estrictamente de la física del solver.
class CompressorVisualizer implements PhysicalVisualizer {
  double currentRpm = 0.0;
  double suctionPressureBar = 0.0;
  double dischargePressureBar = 0.0;
  double suctionTempC = 0.0;
  double dischargeTempC = 0.0;
  double electricalPowerWatts = 0.0;
  bool isRunning = false;

  @override
  void updateFromState(SimulationState state) {
    currentRpm = state.dynamicRpm;
    suctionPressureBar = state.evaporatingPressurePa / 1e5;
    dischargePressureBar = state.condensingPressurePa / 1e5;
    suctionTempC = state.state1Suction.temperature - 273.15;
    dischargeTempC = state.state2Discharge.temperature - 273.15;
    electricalPowerWatts = state.electricalState.activePowerWatts;
    isRunning = state.isRunning;
  }

  /// Dibuja la sección mecánica en corte del compresor con ángulo de cigüeñal theta
  void paint(Canvas canvas, Size size, double crankAngleRad) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;

    // 1. Carcasa hermética de acero (forma ovalada típica)
    final shellRect = Rect.fromCenter(center: Offset(cx, cy), width: 150, height: 170);
    final shellPaint = Paint()
      ..color = const Color(0xFF1E2638)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(shellRect, const Radius.circular(40)), shellPaint);

    final shellBorder = Paint()
      ..color = const Color(0xFF384666)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(shellRect, const Radius.circular(40)), shellBorder);

    // Muelles antivibratorios inferiores
    final springPaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 45, cy + 85), Offset(cx - 45, cy + 95), springPaint);
    canvas.drawLine(Offset(cx + 45, cy + 85), Offset(cx + 45, cy + 95), springPaint);

    // 2. Estator y Bobinado del motor eléctrico
    final statorRect = Rect.fromCenter(center: Offset(cx, cy + 25), width: 100, height: 60);
    final statorPaint = Paint()
      ..color = const Color(0xFF2B3A55)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(statorRect, const Radius.circular(8)), statorPaint);

    // Haces de cobre del bobinado
    final copperPaint = Paint()
      ..color = (currentRpm > 10.0) ? const Color(0xFFB45309) : const Color(0xFF78350F)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx - 45, cy + 10, 16, 30), copperPaint);
    canvas.drawRect(Rect.fromLTWH(cx + 29, cy + 10, 16, 30), copperPaint);

    // 3. Cilindro de compresión superior
    final cylinderLeft = cx - 24;
    final cylinderRight = cx + 24;
    final cylinderTop = cy - 65;
    final cylinderBottom = cy - 15;

    // Interior de la cámara de compresión (fondo con gradiente según presión)
    final cylinderRect = Rect.fromLTRB(cylinderLeft, cylinderTop, cylinderRight, cylinderBottom);
    canvas.drawRect(cylinderRect, Paint()..color = const Color(0xFF0F172A));

    // 4. Cinemática de biela-manivela (Crank-slider)
    const crankR = 12.0; // Radio de la manivela
    const rodL = 36.0;   // Longitud de la biela

    final crankCenter = Offset(cx, cy + 15);
    final crankPin = Offset(
      crankCenter.dx + crankR * math.sin(crankAngleRad),
      crankCenter.dy - crankR * math.cos(crankAngleRad),
    );

    // Posición del bulón del pistón
    final sinTheta = math.sin(crankAngleRad);
    final pistonPinY = crankCenter.dy - (crankR * math.cos(crankAngleRad) + math.sqrt(rodL * rodL - crankR * crankR * sinTheta * sinTheta));
    final pistonPin = Offset(cx, pistonPinY);

    // 5. Gas atrapado en la cámara: color dinámico de azul aspiración a rojo descarga
    // Fracción de compresión: 0.0 en PMI (fondo) a 1.0 en PMS (cabeza)
    final compressionFraction = ((pistonPinY - cylinderTop) / (cylinderBottom - cylinderTop)).clamp(0.0, 1.0);
    final chamberGasColor = Color.lerp(
      ScadaColors.highPressureDischarge,
      ScadaColors.lowPressureSuction,
      compressionFraction,
    )!.withValues(alpha: currentRpm > 10.0 ? 0.85 : 0.3);

    final chamberGasRect = Rect.fromLTRB(cylinderLeft, cylinderTop, cylinderRight, pistonPinY - 8);
    if (chamberGasRect.height > 0) {
      canvas.drawRect(chamberGasRect, Paint()..color = chamberGasColor);
    }

    // Paredes del cilindro
    final wallPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cylinderLeft, cylinderTop), Offset(cylinderLeft, cylinderBottom), wallPaint);
    canvas.drawLine(Offset(cylinderRight, cylinderTop), Offset(cylinderRight, cylinderBottom), wallPaint);

    // 6. Culata y placa de válvulas
    final headRect = Rect.fromLTWH(cylinderLeft - 6, cylinderTop - 8, 60, 8);
    canvas.drawRect(headRect, Paint()..color = const Color(0xFF64748B));

    // Válvula de aspiración (abre cuando el pistón baja) y descarga (abre cuando sube)
    final isSuctionStroke = math.sin(crankAngleRad) > 0;
    final suctionValveOpen = isSuctionStroke && currentRpm > 10.0;
    final dischargeValveOpen = !isSuctionStroke && currentRpm > 10.0;

    // Lámina de aspiración
    final reedSuction = Paint()
      ..color = suctionValveOpen ? ScadaColors.lowPressureSuction : const Color(0xFF94A3B8)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(cx - 14, cylinderTop),
      Offset(cx - 8, cylinderTop + (suctionValveOpen ? 4 : 0)),
      reedSuction,
    );

    // Lámina de descarga
    final reedDischarge = Paint()
      ..color = dischargeValveOpen ? ScadaColors.highPressureDischarge : const Color(0xFF94A3B8)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(cx + 8, cylinderTop),
      Offset(cx + 14, cylinderTop - (dischargeValveOpen ? 4 : 0)),
      reedDischarge,
    );

    // 7. Pistón de aluminio
    final pistonTop = pistonPinY - 10;
    final pistonRect = Rect.fromLTWH(cylinderLeft + 2, pistonTop, 44, 20);
    final pistonPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(pistonRect, const Radius.circular(2)), pistonPaint);

    // Segmentos del pistón
    final ringPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cylinderLeft + 2, pistonTop + 4), Offset(cylinderRight - 2, pistonTop + 4), ringPaint);
    canvas.drawLine(Offset(cylinderLeft + 2, pistonTop + 8), Offset(cylinderRight - 2, pistonTop + 8), ringPaint);

    // 8. Biela
    final rodPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(crankPin, pistonPin, rodPaint);

    // Bulón del pistón
    canvas.drawCircle(pistonPin, 3.5, Paint()..color = const Color(0xFF1E293B));

    // 9. Manivela / Cigüeñal y contrapeso
    final crankPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(crankCenter, crankPin, crankPaint);

    // Eje central del rotor
    canvas.drawCircle(crankCenter, 6.0, Paint()..color = const Color(0xFF334155));
    canvas.drawCircle(crankPin, 4.0, Paint()..color = const Color(0xFF1E293B));

    // 10. Conexiones de servicio exteriores
    // Tubo de aspiración (izquierda, baja presión)
    final suctionPipePaint = Paint()
      ..color = ScadaColors.lowPressureSuction
      ..strokeWidth = 6.0;
    canvas.drawLine(Offset(cx - 75, cy - 20), Offset(cx - 50, cy - 20), suctionPipePaint);

    // Tubo de descarga (derecha, alta presión)
    final dischargePipePaint = Paint()
      ..color = ScadaColors.highPressureDischarge
      ..strokeWidth = 5.0;
    canvas.drawLine(Offset(cx + 50, cy - 50), Offset(cx + 75, cy - 50), dischargePipePaint);

    // 11. Etiqueta informativa de régimen
    final textPainter = TextPainter(
      text: TextSpan(
        text: currentRpm > 10.0 ? '${currentRpm.toStringAsFixed(0)} RPM\n${electricalPowerWatts.toStringAsFixed(0)} W' : 'DETENIDO (0 RPM)',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: currentRpm > 10.0 ? ScadaColors.runningGreen : ScadaColors.textMuted,
          fontFamily: 'monospace',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(cx - textPainter.width / 2.0, cy + 62));
  }
}
