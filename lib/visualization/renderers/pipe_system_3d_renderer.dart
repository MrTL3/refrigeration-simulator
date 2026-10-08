import 'package:flutter/material.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Renderizador volumétrico 3D del trazado continuo de tuberías frigoríficas.
///
/// Modela tuberías con volumen cilíndrico real:
/// - Gradientes transversales de iluminación (luz cenital especular + sombra difusa inferior).
/// - Codos de radio amplio de 90° con continuidad volumétrica.
/// - Coquilla aislante de elastómero negro (Armaflex) en la línea de aspiración para evitar condensaciones.
/// - Bucle antivibrador (omega) en la descarga del compresor.
/// - Bridas y pasamuros sellados en el paso a través de la pared de la cámara frigorífica.
class PipeSystem3DRenderer {
  static void paint({
    required Canvas canvas,
    required SimulationState state,
    required Offset compSuctionPort,
    required Offset compDischargePort,
    required Offset condInletPort,
    required Offset condOutletPort,
    required Offset receiverInletPort,
    required Offset receiverOutletPort,
    required Offset filterInletPort,
    required Offset filterOutletPort,
    required Offset txvInletPort,
    required Offset txvOutletPort,
    required Offset evapInletPort,
    required Offset evapOutletPort,
    required double wallX,
    required bool showTemperatures,
  }) {
    // ==========================================
    // 1. LÍNEA DE DESCARGA (COMPRESOR -> CONDENSADOR)
    // ==========================================
    // Sale de la culata del compresor, hace un bucle omega antivibrador y sube al condensador
    final dischargePath = Path()..moveTo(compDischargePort.dx, compDischargePort.dy);

    final p1 = Offset(compDischargePort.dx + 25, compDischargePort.dy - 10);
    // Bucle omega antivibratorio
    final omegaTop = Offset(p1.dx + 20, p1.dy - 35);
    final omegaBot = Offset(p1.dx + 40, p1.dy);

    dischargePath.lineTo(p1.dx, p1.dy);
    dischargePath.quadraticBezierTo(p1.dx + 10, omegaTop.dy, omegaTop.dx, omegaTop.dy);
    dischargePath.quadraticBezierTo(omegaTop.dx + 10, omegaTop.dy, omegaBot.dx, omegaBot.dy);

    final dischargeCornerX = condInletPort.dx - 30;
    final dischargeCornerY = condInletPort.dy;

    dischargePath.lineTo(dischargeCornerX, omegaBot.dy);
    dischargePath.lineTo(dischargeCornerX, dischargeCornerY);
    dischargePath.lineTo(condInletPort.dx, condInletPort.dy);

    _drawVolumetricPipe(
      canvas: canvas,
      path: dischargePath,
      pipeDiameter: 10.0,
      baseColor: ScadaColors.highPressureDischarge,
      highlightColor: const Color(0xFFFFA39E),
      shadowColor: const Color(0xFF7A0E0E),
    );

    // ==========================================
    // 2. LÍNEA DE LÍQUIDO CONDENSADO (CONDENSADOR -> CALDERÍN)
    // ==========================================
    final condToRecPath = Path()
      ..moveTo(condOutletPort.dx, condOutletPort.dy)
      ..lineTo(condOutletPort.dx, receiverInletPort.dy - 20)
      ..lineTo(receiverInletPort.dx, receiverInletPort.dy - 20)
      ..lineTo(receiverInletPort.dx, receiverInletPort.dy);

    _drawVolumetricPipe(
      canvas: canvas,
      path: condToRecPath,
      pipeDiameter: 8.0,
      baseColor: ScadaColors.highPressureLiquid,
      highlightColor: const Color(0xFFFFBB96),
      shadowColor: const Color(0xFF871400),
    );

    // ==========================================
    // 3. LÍNEA DE LÍQUIDO (CALDERÍN -> FILTRO -> VISOR -> TXV)
    // ==========================================
    final recToTxvPath = Path()
      ..moveTo(receiverOutletPort.dx, receiverOutletPort.dy)
      ..lineTo(receiverOutletPort.dx, filterInletPort.dy)
      ..lineTo(filterInletPort.dx, filterInletPort.dy);

    _drawVolumetricPipe(
      canvas: canvas,
      path: recToTxvPath,
      pipeDiameter: 8.0,
      baseColor: ScadaColors.highPressureLiquid,
      highlightColor: const Color(0xFFFFBB96),
      shadowColor: const Color(0xFF871400),
    );

    final filterToTxvPath = Path()
      ..moveTo(filterOutletPort.dx, filterOutletPort.dy)
      ..lineTo(txvInletPort.dx, filterOutletPort.dy)
      ..lineTo(txvInletPort.dx, txvInletPort.dy);

    _drawVolumetricPipe(
      canvas: canvas,
      path: filterToTxvPath,
      pipeDiameter: 8.0,
      baseColor: ScadaColors.highPressureLiquid,
      highlightColor: const Color(0xFFFFBB96),
      shadowColor: const Color(0xFF871400),
    );

    // ==========================================
    // 4. LÍNEA DE EXPANSIÓN (TXV -> EVAPORADOR)
    // ==========================================
    // Atraviesa la pared de la cámara hacia el distribuidor del evaporador
    final expPath = Path()
      ..moveTo(txvOutletPort.dx, txvOutletPort.dy)
      ..lineTo(evapInletPort.dx, txvOutletPort.dy)
      ..lineTo(evapInletPort.dx, evapInletPort.dy);

    _drawVolumetricPipe(
      canvas: canvas,
      path: expPath,
      pipeDiameter: 7.0,
      baseColor: ScadaColors.cyanAccent,
      highlightColor: const Color(0xFFE0F2FE),
      shadowColor: const Color(0xFF0369A1),
    );

    // Pasamuros sellado en el panel de la cámara para la línea de expansión
    _drawWallGrommet(canvas, Offset(wallX, txvOutletPort.dy));

    // ==========================================
    // 5. LÍNEA DE ASPIRACIÓN (EVAPORADOR -> COMPRESOR)
    // ==========================================
    // Sale del evaporador, atraviesa la pared con pasamuros, y baja hacia el compresor con coquilla Armaflex
    final suctionPath = Path()
      ..moveTo(evapOutletPort.dx, evapOutletPort.dy)
      ..lineTo(evapOutletPort.dx - 35, evapOutletPort.dy)
      ..lineTo(evapOutletPort.dx - 35, compSuctionPort.dy - 35)
      ..lineTo(compSuctionPort.dx, compSuctionPort.dy - 35)
      ..lineTo(compSuctionPort.dx, compSuctionPort.dy);

    // 5.1 Capa de coquilla aislante Armaflex (negra gruesa) en el tramo exterior a la cámara
    _drawArmaflexInsulation(
      canvas: canvas,
      path: suctionPath,
      insulationThickness: 16.0,
      wallX: wallX,
    );

    // 5.2 Núcleo de cobre de la tubería de aspiración (visible en corte o transparencias)
    _drawVolumetricPipe(
      canvas: canvas,
      path: suctionPath,
      pipeDiameter: 12.0,
      baseColor: ScadaColors.lowPressureSuction,
      highlightColor: const Color(0xFF93C5FD),
      shadowColor: const Color(0xFF1E3A8A),
    );

    // Pasamuros sellado en el panel para la línea de aspiración
    _drawWallGrommet(canvas, Offset(wallX, evapOutletPort.dy));
  }

  /// Dibuja un tubo con gradiente volumétrico cilíndrico (luz cenital, centro brillante, base oscura)
  static void _drawVolumetricPipe({
    required Canvas canvas,
    required Path path,
    required double pipeDiameter,
    required Color baseColor,
    required Color highlightColor,
    required Color shadowColor,
  }) {
    // Sombra del tubo
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..strokeWidth = pipeDiameter + 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Sombra inferior del cilindro
    canvas.drawPath(
      path,
      Paint()
        ..color = shadowColor
        ..strokeWidth = pipeDiameter
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Color base intermedio
    canvas.drawPath(
      path,
      Paint()
        ..color = baseColor
        ..strokeWidth = pipeDiameter * 0.70
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Brillo cilíndrico especular superior
    canvas.drawPath(
      path,
      Paint()
        ..color = highlightColor.withValues(alpha: 0.85)
        ..strokeWidth = pipeDiameter * 0.25
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Dibuja coquilla aislante Armaflex con textura de espuma elastomérica negra y abrazaderas
  static void _drawArmaflexInsulation({
    required Canvas canvas,
    required Path path,
    required double insulationThickness,
    required double wallX,
  }) {
    // Capa exterior de elastómero negro mate
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = insulationThickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Sombra interior de la coquilla
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = insulationThickness * 0.85
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Línea de costura adhesiva longitudinal
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF334155).withValues(alpha: 0.6)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Dibuja pasamuros de estanqueidad en el panel sándwich de la cámara
  static void _drawWallGrommet(Canvas canvas, Offset center) {
    final grommetRect = Rect.fromCenter(center: center, width: 14, height: 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(grommetRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF334155),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(grommetRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Masilla selladora de poliuretano
    canvas.drawCircle(center, 4.0, Paint()..color = const Color(0xFF0F172A));
  }
}
