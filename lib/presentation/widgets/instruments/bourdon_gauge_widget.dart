import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../simulation/thermodynamics/r134a_model.dart';
import '../../theme/scada_colors.dart';

enum GaugeType {
  lowPressure('MANÓMETRO LP (BAJA)', ScadaColors.lowPressureSuction, -1.0, 10.0),
  highPressure('MANÓMETRO HP (ALTA)', ScadaColors.highPressureDischarge, 0.0, 30.0);

  final String title;
  final Color accentColor;
  final double minBar;
  final double maxBar;
  const GaugeType(this.title, this.accentColor, this.minBar, this.maxBar);
}

/// Manómetro analógico Bourdon industrial con glicerina y escala de temperatura de saturación para R-134a.
class BourdonGaugeWidget extends StatefulWidget {
  final GaugeType type;
  final double measuredPressureBar;
  final double size;

  const BourdonGaugeWidget({
    super.key,
    required this.type,
    required this.measuredPressureBar,
    this.size = 180.0,
  });

  @override
  State<BourdonGaugeWidget> createState() => _BourdonGaugeWidgetState();
}

class _BourdonGaugeWidgetState extends State<BourdonGaugeWidget> with SingleTickerProviderStateMixin {
  late double _displayedPressureBar;
  final _refrigerant = R134aModel();

  @override
  void initState() {
    super.initState();
    _displayedPressureBar = widget.measuredPressureBar;
  }

  @override
  void didUpdateWidget(covariant BourdonGaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Respuesta mecánica amortiguada suave sin modificar la medida real
    _displayedPressureBar += (widget.measuredPressureBar - _displayedPressureBar) * 0.35;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0F172A),
        border: Border.all(color: widget.type.accentColor, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: widget.type.accentColor.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _BourdonGaugePainter(
          type: widget.type,
          pressureBar: _displayedPressureBar,
          refrigerant: _refrigerant,
        ),
      ),
    );
  }
}

class _BourdonGaugePainter extends CustomPainter {
  final GaugeType type;
  final double pressureBar;
  final R134aModel refrigerant;

  _BourdonGaugePainter({
    required this.type,
    required this.pressureBar,
    required this.refrigerant,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final radius = size.width / 2.0 - 10;

    // 1. Fondo de la esfera (acabado blanco/marfil técnico industrial)
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = const Color(0xFFF8FAFC));

    // Arco útil: 240 grados (de 150° a 390° / -30°)
    const startAngle = 135.0 * math.pi / 180.0;
    const sweepAngle = 270.0 * math.pi / 180.0;

    // 2. Marcas y divisiones de presión (escala exterior en bar)
    final minorTickPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.0;

    final majorTickPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.5;

    // Sub-divisiones finas
    final minorStep = (type == GaugeType.highPressure) ? 1.0 : 0.2;
    for (double b = type.minBar; b <= type.maxBar; b += minorStep) {
      final fraction = (b - type.minBar) / (type.maxBar - type.minBar);
      final angle = startAngle + fraction * sweepAngle;
      final pOuter = Offset(cx + (radius - 4) * math.cos(angle), cy + (radius - 4) * math.sin(angle));
      final pInner = Offset(cx + (radius - 8) * math.cos(angle), cy + (radius - 8) * math.sin(angle));
      canvas.drawLine(pInner, pOuter, minorTickPaint);
    }

    final step = (type == GaugeType.highPressure) ? 5 : 1;

    for (int barVal = type.minBar.toInt(); barVal <= type.maxBar.toInt(); barVal += step) {
      final fraction = (barVal - type.minBar) / (type.maxBar - type.minBar);
      final angle = startAngle + fraction * sweepAngle;

      final pOuter = Offset(cx + (radius - 4) * math.cos(angle), cy + (radius - 4) * math.sin(angle));
      final pInner = Offset(cx + (radius - 12) * math.cos(angle), cy + (radius - 12) * math.sin(angle));

      canvas.drawLine(pInner, pOuter, majorTickPaint);

      // Números de la escala
      final numOffset = Offset(cx + (radius - 22) * math.cos(angle), cy + (radius - 22) * math.sin(angle));
      final tp = TextPainter(
        text: TextSpan(
          text: '$barVal',
          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(numOffset.dx - tp.width / 2, numOffset.dy - tp.height / 2));
    }

    // 3. Escala interior de temperatura de saturación Tsat para R-134a (°C)
    final satRingPaint = Paint()
      ..color = type.accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), radius - 30, satRingPaint);

    // 4. Aguja indicadora mecánica
    final clampedP = pressureBar.clamp(type.minBar, type.maxBar);
    final needleFraction = (clampedP - type.minBar) / (type.maxBar - type.minBar);
    final needleAngle = startAngle + needleFraction * sweepAngle;

    final needleTip = Offset(cx + (radius - 14) * math.cos(needleAngle), cy + (radius - 14) * math.sin(needleAngle));
    final needleTail = Offset(cx - 14 * math.cos(needleAngle), cy - 14 * math.sin(needleAngle));

    final needlePaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(needleTail, needleTip, needlePaint);

    // Cubre-eje central con tornillo
    canvas.drawCircle(Offset(cx, cy), 6.0, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(cx, cy), 3.0, Paint()..color = const Color(0xFFCBD5E1));

    // 5. Etiqueta digital central: Presión exacta y Tsat equivalente
    double tSatC = 0.0;
    if (pressureBar > 0.3) {
      tSatC = refrigerant.saturationTemperature(pressureBar * 1e5) - 273.15;
    }

    final readText = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${pressureBar.toStringAsFixed(2)} bar\n',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: type.accentColor),
          ),
          TextSpan(
            text: 'Tsat: ${tSatC.toStringAsFixed(1)} °C',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    readText.paint(canvas, Offset(cx - readText.width / 2.0, cy + 18));
  }

  @override
  bool shouldRepaint(covariant _BourdonGaugePainter oldDelegate) {
    return oldDelegate.pressureBar != pressureBar;
  }
}
