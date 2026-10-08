import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';
import '../models/installation_instrument.dart';

/// Renderizador volumétrico 3D de la instrumentación física in situ.
///
/// Modela con alto realismo:
/// - Manómetros Bourdon de esfera con bisel cromado, cristal curvado, graduación en bar y aguja indicadora móvil.
/// - Termómetros de contacto industrial en tuberías con sonda de inmersión y display LED digital.
/// - Presostato combinado Danfoss KP15 con fuelles de alta y baja presión y rearme manual.
/// - Indicadores visuales interactivos con halos y resaltados para selección.
class Instruments3DRenderer {
  static void paint({
    required Canvas canvas,
    required SimulationState state,
    required PressureUnit pUnit,
    required TemperatureUnit tUnit,
    required List<InstallationInstrument> instruments,
    required String? selectedInstrumentId,
    required bool highlightInstrumentsLayer,
  }) {
    for (final inst in instruments) {
      final isSelected = inst.id == selectedInstrumentId;

      // Halo pulsante si está seleccionado o si la capa INSTRUMENTOS está activa
      if (isSelected || highlightInstrumentsLayer) {
        _drawSelectionHalo(canvas, inst.worldPosition, inst.hitRadius, isSelected ? ScadaColors.cyanAccent : inst.type.primaryColor);
      }

      switch (inst.type) {
        case InstrumentType.lowPressureGauge:
          _drawBourdonGauge(
            canvas: canvas,
            center: inst.worldPosition,
            pressureBar: state.evaporatingPressurePa / 1e5,
            maxScaleBar: 10.0,
            label: 'Po',
            color: ScadaColors.lowPressureSuction,
            tSatC: state.evaporatingTemperatureK - 273.15,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.highPressureGauge:
          _drawBourdonGauge(
            canvas: canvas,
            center: inst.worldPosition,
            pressureBar: state.condensingPressurePa / 1e5,
            maxScaleBar: 30.0,
            label: 'Pk',
            color: ScadaColors.highPressureDischarge,
            tSatC: state.condensingTemperatureK - 273.15,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.dischargeThermometer:
          _drawPipeThermometer(
            canvas: canvas,
            pos: inst.worldPosition,
            tempC: state.state2Discharge.temperature - 273.15,
            tag: 'T_dis',
            color: ScadaColors.highPressureDischarge,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.liquidThermometer:
          _drawPipeThermometer(
            canvas: canvas,
            pos: inst.worldPosition,
            tempC: state.state3Liquid.temperature - 273.15,
            tag: 'T_liq',
            color: ScadaColors.highPressureLiquid,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.evaporatorInletThermometer:
          _drawPipeThermometer(
            canvas: canvas,
            pos: inst.worldPosition,
            tempC: state.state4EvapInlet.temperature - 273.15,
            tag: 'T_evap',
            color: ScadaColors.cyanAccent,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.suctionThermometer:
          _drawPipeThermometer(
            canvas: canvas,
            pos: inst.worldPosition,
            tempC: state.state1Suction.temperature - 273.15,
            tag: 'T_asp',
            color: ScadaColors.infoBlue,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.coldRoomThermometer:
          _drawWallSensorPill(
            canvas: canvas,
            pos: inst.worldPosition,
            valueText: '${(state.coldRoom.temperatureKelvin - 273.15).toStringAsFixed(1)} °C',
            tag: 'T_cám',
            color: ScadaColors.runningGreen,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.ambientThermometer:
          _drawWallSensorPill(
            canvas: canvas,
            pos: inst.worldPosition,
            valueText: '${((state.circuit.condenser?.ambientTemperatureKelvin ?? 298.15) - 273.15).toStringAsFixed(0)} °C',
            tag: 'T_amb',
            color: ScadaColors.warningAmber,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.dualPressureSwitch:
          _drawDualPressureSwitch(
            canvas: canvas,
            pos: inst.worldPosition,
            poBar: state.evaporatingPressurePa / 1e5,
            pkBar: state.condensingPressurePa / 1e5,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.massFlowMeter:
          // Dibujado como caja de flujo en liquid_receiver_renderer, aquí dibujamos su etiqueta de inspección
          _drawInstrumentTag(canvas, inst.worldPosition, 'CAUDALÍMETRO', ScadaColors.cyanAccent, isSelected);
          break;

        case InstrumentType.sightGlass:
          _drawInstrumentTag(canvas, inst.worldPosition, 'VISOR LÍQUIDO', ScadaColors.highPressureLiquid, isSelected);
          break;

        case InstrumentType.oilSightGlass:
          _drawInstrumentTag(canvas, inst.worldPosition, 'ACEITE CÁRTER', ScadaColors.warningAmber, isSelected);
          break;

        case InstrumentType.electricalClamp:
          _drawElectricalSensorPill(
            canvas: canvas,
            pos: inst.worldPosition,
            amps: state.electricalState.currentAmps,
            kw: state.electricalPowerWatts / 1000.0,
            isSelected: isSelected,
          );
          break;

        case InstrumentType.vacuumGauge:
          if (state.vacuumState.isPumpRunning || state.vacuumState.pressurePa < 95000.0) {
            _drawWallSensorPill(
              canvas: canvas,
              pos: inst.worldPosition,
              valueText: '${state.vacuumState.pressureMbar.toStringAsFixed(1)} mbar',
              tag: 'VACÍO',
              color: ScadaColors.infoBlue,
              isSelected: isSelected,
            );
          }
          break;
      }
    }
  }

  /// Manómetro Bourdon 3D con esfera graduada, bisel cromado, cristal convexo y aguja roja móvil
  static void _drawBourdonGauge({
    required Canvas canvas,
    required Offset center,
    required double pressureBar,
    required double maxScaleBar,
    required String label,
    required Color color,
    required double tSatC,
    required bool isSelected,
  }) {
    const radius = 22.0;

    // Sombra del manómetro
    canvas.drawCircle(
      Offset(center.dx + 2, center.dy + 3),
      radius + 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Bisel exterior cromado con volumen cilíndrico
    canvas.drawCircle(
      center,
      radius + 3.0,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFE2E8F0),
            Color(0xFF64748B),
            Color(0xFFCBD5E1),
            Color(0xFF475569),
            Color(0xFFE2E8F0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 3)),
    );

    // Esfera interior blanca/marfil técnica
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF8FAFC));

    // Arco graduado con marcas de escala
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Arco de 240° (desde 150° hasta 390°)
    const startAngleRad = 150.0 * math.pi / 180.0;
    const sweepAngleRad = 240.0 * math.pi / 180.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4.5),
      startAngleRad,
      sweepAngleRad,
      false,
      arcPaint,
    );

    // Ticks de división en la esfera
    final tickPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 8; i++) {
      final a = startAngleRad + (i / 8.0) * sweepAngleRad;
      final pOut = Offset(center.dx + (radius - 3) * math.cos(a), center.dy + (radius - 3) * math.sin(a));
      final pIn = Offset(center.dx + (radius - 6.5) * math.cos(a), center.dy + (radius - 6.5) * math.sin(a));
      canvas.drawLine(pIn, pOut, tickPaint);
    }

    // Aguja roja indicadora de acero
    final pClamped = pressureBar.clamp(0.0, maxScaleBar);
    final needleFraction = (pClamped / maxScaleBar).clamp(0.0, 1.0);
    final needleAngleRad = startAngleRad + needleFraction * sweepAngleRad;

    final needleLength = radius - 5.0;
    final needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngleRad),
      center.dy + needleLength * math.sin(needleAngleRad),
    );

    // Sombra de la aguja
    canvas.drawLine(
      Offset(center.dx + 1, center.dy + 1),
      Offset(needleTip.dx + 1, needleTip.dy + 1),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = 1.8,
    );

    // Aguja
    canvas.drawLine(
      center,
      needleTip,
      Paint()
        ..color = const Color(0xFFDC2626)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // Eje central de latón
    canvas.drawCircle(center, 3.5, Paint()..color = const Color(0xFFD97706));
    canvas.drawCircle(center, 1.8, Paint()..color = const Color(0xFFFEF3C7));

    // Reflejo elíptico del cristal superior
    final glassGlare = Path()
      ..addOval(Rect.fromCenter(center: Offset(center.dx - 5, center.dy - 6), width: 14, height: 8));
    canvas.drawPath(glassGlare, Paint()..color = Colors.white.withValues(alpha: 0.45));

    // Placa inferior con el valor digital y Tsat
    final badgeRect = Rect.fromCenter(center: Offset(center.dx, center.dy + radius + 11), width: 68, height: 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
      Paint()..color = const Color(0xEE0F172A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
      Paint()
        ..color = isSelected ? ScadaColors.cyanAccent : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.5 : 1.0,
    );

    final tpBadge = TextPainter(
      text: TextSpan(
        text: '$label: ${pressureBar.toStringAsFixed(2)} bar\n(${(tSatC).toStringAsFixed(1)}°C)',
        style: TextStyle(
          color: color,
          fontSize: 7.2,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tpBadge.paint(canvas, Offset(badgeRect.center.dx - tpBadge.width / 2, badgeRect.center.dy - tpBadge.height / 2));
  }

  /// Termómetro de contacto montado sobre tubería con collarín y display digital
  static void _drawPipeThermometer({
    required Canvas canvas,
    required Offset pos,
    required double tempC,
    required String tag,
    required Color color,
    required bool isSelected,
  }) {
    // Sonda de inmersión / vástago de acero inoxidable
    canvas.drawLine(
      Offset(pos.dx, pos.dy - 6),
      Offset(pos.dx, pos.dy + 6),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 3.0,
    );

    // Collarín / abrazadera a la tubería
    canvas.drawCircle(pos, 5.0, Paint()..color = const Color(0xFFD97706));

    // Píldora digital del termómetro
    final pillRect = Rect.fromCenter(center: Offset(pos.dx, pos.dy - 16), width: 64, height: 16);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(4)), Paint()..color = const Color(0xEE0F172A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(4)),
      Paint()
        ..color = isSelected ? ScadaColors.cyanAccent : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.8 : 1.0,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '$tag: ${tempC.toStringAsFixed(1)} °C',
        style: TextStyle(
          color: color,
          fontSize: 8.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pillRect.center.dx - tp.width / 2, pillRect.center.dy - tp.height / 2));
  }

  /// Píldora de sensor de pared / ambiente
  static void _drawWallSensorPill({
    required Canvas canvas,
    required Offset pos,
    required String valueText,
    required String tag,
    required Color color,
    required bool isSelected,
  }) {
    final pillRect = Rect.fromCenter(center: pos, width: 78, height: 18);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(4)), Paint()..color = const Color(0xEE0F172A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(4)),
      Paint()
        ..color = isSelected ? ScadaColors.cyanAccent : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.8 : 1.0,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '$tag: $valueText',
        style: TextStyle(
          color: color,
          fontSize: 8.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pillRect.center.dx - tp.width / 2, pillRect.center.dy - tp.height / 2));
  }

  /// Presostato combinado Danfoss KP15 en perspectiva técnica
  static void _drawDualPressureSwitch({
    required Canvas canvas,
    required Offset pos,
    required double poBar,
    required double pkBar,
    required bool isSelected,
  }) {
    final bodyRect = Rect.fromCenter(center: pos, width: 34, height: 38);

    // Carcasa de plástico técnico azul Danfoss / gris oscuro
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
      ).createShader(bodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)), bodyPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()
        ..color = isSelected ? ScadaColors.cyanAccent : const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.2,
    );

    // Dos ventanitas de ajuste de escala: LP (izquierda) y HP (derecha)
    final lpWin = Rect.fromLTWH(bodyRect.left + 4, bodyRect.top + 8, 11, 14);
    final hpWin = Rect.fromLTWH(bodyRect.right - 15, bodyRect.top + 8, 11, 14);
    canvas.drawRect(lpWin, Paint()..color = const Color(0xFF0284C7));
    canvas.drawRect(hpWin, Paint()..color = const Color(0xFFDC2626));

    // Botón de rearme manual superior
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(pos.dx, bodyRect.top - 3), width: 8, height: 6), const Radius.circular(1)), Paint()..color = const Color(0xFFEF4444));

    // Capilares de cobre que entran por debajo
    canvas.drawLine(Offset(pos.dx - 6, bodyRect.bottom), Offset(pos.dx - 6, bodyRect.bottom + 12), Paint()..color = const Color(0xFFB45309)..strokeWidth = 2);
    canvas.drawLine(Offset(pos.dx + 6, bodyRect.bottom), Offset(pos.dx + 6, bodyRect.bottom + 12), Paint()..color = const Color(0xFFB45309)..strokeWidth = 2);

    // Etiqueta
    final badgeRect = Rect.fromCenter(center: Offset(pos.dx, bodyRect.bottom + 18), width: 48, height: 12);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(2)), Paint()..color = const Color(0xEE0F172A));
    final tp = TextPainter(
      text: const TextSpan(
        text: 'KP15 DUAL',
        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 6.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(badgeRect.center.dx - tp.width / 2, badgeRect.center.dy - tp.height / 2));
  }

  /// Píldora de pinza amperimétrica / vatímetro
  static void _drawElectricalSensorPill({
    required Canvas canvas,
    required Offset pos,
    required double amps,
    required double kw,
    required bool isSelected,
  }) {
    final pillRect = Rect.fromCenter(center: pos, width: 84, height: 20);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(4)), Paint()..color = const Color(0xEE0F172A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(4)),
      Paint()
        ..color = isSelected ? ScadaColors.cyanAccent : ScadaColors.warningAmber
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.8 : 1.0,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '${amps.toStringAsFixed(1)} A | ${kw.toStringAsFixed(2)} kW',
        style: const TextStyle(
          color: ScadaColors.warningAmber,
          fontSize: 8.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pillRect.center.dx - tp.width / 2, pillRect.center.dy - tp.height / 2));
  }

  static void _drawInstrumentTag(Canvas canvas, Offset pos, String text, Color color, bool isSelected) {
    final badgeRect = Rect.fromCenter(center: pos, width: 68, height: 12);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(2)), Paint()..color = const Color(0xEE0F172A));
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 6.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(badgeRect.center.dx - tp.width / 2, badgeRect.center.dy - tp.height / 2));
  }

  static void _drawSelectionHalo(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius * 1.35,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }
}
