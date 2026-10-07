import 'package:flutter/material.dart';
import '../../core/units/temperature_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../domain/models/thermodynamic_state.dart';
import '../../simulation/engine/simulation_state.dart';
import '../../simulation/thermodynamics/diagram_data_generator.dart';
import '../theme/scada_colors.dart';

/// Widget del Diagrama Temperatura - Entropía (T-s) con comparativa de Ciclo Real vs Ciclo Ideal.
class TsDiagramWidget extends StatefulWidget {
  final SimulationState state;
  final TemperatureUnit temperatureUnit;
  final ValueChanged<String>? onHighlightComponent;

  const TsDiagramWidget({
    super.key,
    required this.state,
    required this.temperatureUnit,
    this.onHighlightComponent,
  });

  @override
  State<TsDiagramWidget> createState() => _TsDiagramWidgetState();
}

class _TsDiagramWidgetState extends State<TsDiagramWidget> {
  bool _showIdealCycle = true;
  int _selectedPointIndex = 1; // 1, 2, 3, 4
  late final DiagramDataGenerator _generator;
  late final List<DiagramPoint> _liquidDome;
  late final List<DiagramPoint> _vaporDome;
  late final List<DiagramCurve> _qualityLines;

  @override
  void initState() {
    super.initState();
    _generator = DiagramDataGenerator(widget.state.refrigerant);
    _liquidDome = _generator.generateTsLiquidDome();
    _vaporDome = _generator.generateTsVaporDome();
    _qualityLines = _generator.generateTsQualityLines();
  }

  ThermodynamicState _getPointState(int idx) {
    switch (idx) {
      case 1:
        return widget.state.state1Suction;
      case 2:
        return widget.state.state2Discharge;
      case 3:
        return widget.state.state3Liquid;
      case 4:
      default:
        return widget.state.state4EvapInlet;
    }
  }

  String _getPointName(int idx) {
    switch (idx) {
      case 1:
        return 'Punto 1: Aspiración (Vapor Sobrecalentado)';
      case 2:
        return 'Punto 2: Descarga (Gas Caliente Comprimido)';
      case 3:
        return 'Punto 3: Salida Condensador (Líquido Subenfriado)';
      case 4:
      default:
        return 'Punto 4: Entrada Evaporador (Mezcla Flash Bifásica)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final curState = _getPointState(_selectedPointIndex);

    return Container(
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de título y controles
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thermostat, color: ScadaColors.infoBlue, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'DIAGRAMA T-s (TEMPERATURA - ENTROPÍA)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: ScadaColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilterChip(
                    label: const Text('Ciclo Ideal (s=cte)'),
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _showIdealCycle ? ScadaColors.runningGreen : ScadaColors.textSecondary,
                    ),
                    selected: _showIdealCycle,
                    onSelected: (val) => setState(() => _showIdealCycle = val),
                    backgroundColor: ScadaColors.surfaceCard,
                    selectedColor: ScadaColors.runningGreen.withValues(alpha: 0.2),
                    side: BorderSide(color: _showIdealCycle ? ScadaColors.runningGreen : ScadaColors.border),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Lienzo CustomPaint para T-s
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: const Color(0xFF0F1520),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapUp: (details) {
                        _handleTap(details.localPosition, constraints.biggest);
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _TsDiagramPainter(
                          state: widget.state,
                          liquidDome: _liquidDome,
                          vaporDome: _vaporDome,
                          qualityLines: _qualityLines,
                          showIdealCycle: _showIdealCycle,
                          selectedPoint: _selectedPointIndex,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tarjeta inferior educativa de análisis del ciclo real vs ideal
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ScadaColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ScadaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getPointName(_selectedPointIndex),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ScadaColors.textPrimary,
                      ),
                    ),
                    Text(
                      'T: ${UnitFormatter.formatTemperature(curState.temperature, widget.temperatureUnit)} | s: ${(curState.entropy / 1000.0).toStringAsFixed(3)} kJ/(kg·K)',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: ScadaColors.infoBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getEntropyComparisonExplanation(),
                  style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(Offset tapPos, Size size) {
    const padL = 40.0;
    const padR = 20.0;
    const padT = 20.0;
    const padB = 28.0;

    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    const minS = 0.8;
    const maxS = 2.0;
    const minT = -35.0;
    const maxT = 90.0;

    Offset toPixel(double sKj, double tC) {
      final xNorm = ((sKj - minS) / (maxS - minS)).clamp(0.0, 1.0);
      final yNorm = ((tC - minT) / (maxT - minT)).clamp(0.0, 1.0);
      return Offset(padL + xNorm * w, padT + (1.0 - yNorm) * h);
    }

    final p1 = toPixel(widget.state.state1Suction.entropy / 1000.0, widget.state.state1Suction.temperature - 273.15);
    final p2 = toPixel(widget.state.state2Discharge.entropy / 1000.0, widget.state.state2Discharge.temperature - 273.15);
    final p3 = toPixel(widget.state.state3Liquid.entropy / 1000.0, widget.state.state3Liquid.temperature - 273.15);
    final p4 = toPixel(widget.state.state4EvapInlet.entropy / 1000.0, widget.state.state4EvapInlet.temperature - 273.15);

    const hitRadius = 24.0;
    if ((tapPos - p1).distance <= hitRadius) {
      setState(() => _selectedPointIndex = 1);
    } else if ((tapPos - p2).distance <= hitRadius) {
      setState(() => _selectedPointIndex = 2);
    } else if ((tapPos - p3).distance <= hitRadius) {
      setState(() => _selectedPointIndex = 3);
    } else if ((tapPos - p4).distance <= hitRadius) {
      setState(() => _selectedPointIndex = 4);
    }
  }

  String _getEntropyComparisonExplanation() {
    final s1 = widget.state.state1Suction.entropy / 1000.0;
    final s2 = widget.state.state2Discharge.entropy / 1000.0;
    final deltaSComp = s2 - s1;
    final s3 = widget.state.state3Liquid.entropy / 1000.0;
    final s4 = widget.state.state4EvapInlet.entropy / 1000.0;
    final deltaSExp = s4 - s3;

    return 'Diferencia Real vs Ideal: La compresión genera Δs = ${deltaSComp.toStringAsFixed(3)} kJ/(kg·K) de entropía por fricción y calor interno (línea 1->2 inclinada a la derecha). La expansión por estrangulamiento en la TXV es isentálpica pero irreversible, generando Δs = ${deltaSExp.toStringAsFixed(3)} kJ/(kg·K) (línea 3->4 inclinada).';
  }
}

class _TsDiagramPainter extends CustomPainter {
  final SimulationState state;
  final List<DiagramPoint> liquidDome;
  final List<DiagramPoint> vaporDome;
  final List<DiagramCurve> qualityLines;
  final bool showIdealCycle;
  final int selectedPoint;

  _TsDiagramPainter({
    required this.state,
    required this.liquidDome,
    required this.vaporDome,
    required this.qualityLines,
    required this.showIdealCycle,
    required this.selectedPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 40.0;
    const padR = 20.0;
    const padT = 20.0;
    const padB = 28.0;

    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    const minS = 0.8;
    const maxS = 2.0;
    const minT = -35.0;
    const maxT = 90.0;

    Offset toPixel(double sKj, double tC) {
      final xNorm = ((sKj - minS) / (maxS - minS)).clamp(0.0, 1.0);
      final yNorm = ((tC - minT) / (maxT - minT)).clamp(0.0, 1.0);
      return Offset(padL + xNorm * w, padT + (1.0 - yNorm) * h);
    }

    // 1. Ejes y rejilla
    final gridPaint = Paint()
      ..color = ScadaColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    final textStyle = const TextStyle(color: ScadaColors.textMuted, fontSize: 9, fontFamily: 'monospace');

    // Eje vertical (Temperatura en °C: -20, 0, 20, 40, 60, 80)
    for (final tVal in [-20.0, 0.0, 20.0, 40.0, 60.0, 80.0]) {
      final yPos = toPixel(minS, tVal).dy;
      canvas.drawLine(Offset(padL, yPos), Offset(padL + w, yPos), gridPaint);
      _drawText(canvas, '${tVal.toInt()}°C', Offset(6, yPos - 5), textStyle);
    }

    // Eje horizontal (Entropía en kJ/kg·K: 1.0, 1.2, 1.4, 1.6, 1.8)
    for (final sVal in [1.0, 1.2, 1.4, 1.6, 1.8]) {
      final xPos = toPixel(sVal, minT).dx;
      canvas.drawLine(Offset(xPos, padT), Offset(xPos, padT + h), gridPaint);
      _drawText(canvas, sVal.toStringAsFixed(1), Offset(xPos - 8, padT + h + 6), textStyle);
    }
    _drawText(canvas, 's (kJ/kg·K)', Offset(padL + w - 55, padT + h + 14), textStyle);

    // 2. Líneas de calidad x constante
    final qualityPaint = Paint()
      ..color = ScadaColors.lowPressureTwoPhase.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final qCurve in qualityLines) {
      final path = Path();
      for (int i = 0; i < qCurve.points.length; i++) {
        final pt = toPixel(qCurve.points[i].x, qCurve.points[i].y);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, qualityPaint);
    }

    // 3. Campana de saturación en T-s
    final domePaint = Paint()
      ..color = ScadaColors.runningGreen
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final domePath = Path();
    for (int i = 0; i < liquidDome.length; i++) {
      final pt = toPixel(liquidDome[i].x, liquidDome[i].y);
      if (i == 0) {
        domePath.moveTo(pt.dx, pt.dy);
      } else {
        domePath.lineTo(pt.dx, pt.dy);
      }
    }
    for (int i = vaporDome.length - 1; i >= 0; i--) {
      final pt = toPixel(vaporDome[i].x, vaporDome[i].y);
      domePath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(domePath, domePaint);

    // 4. Puntos del ciclo real
    final s1 = state.state1Suction;
    final s2 = state.state2Discharge;
    final s3 = state.state3Liquid;
    final s4 = state.state4EvapInlet;

    final p1 = toPixel(s1.entropy / 1000.0, s1.temperature - 273.15);
    final p2 = toPixel(s2.entropy / 1000.0, s2.temperature - 273.15);
    final p3 = toPixel(s3.entropy / 1000.0, s3.temperature - 273.15);
    final p4 = toPixel(s4.entropy / 1000.0, s4.temperature - 273.15);

    // 5. Ciclo Ideal (s=cte) si está activado
    if (showIdealCycle) {
      // Punto 2 isentrópico: misma entropía que punto 1, pero a temperatura de condensación
      final p2Isen = toPixel(s1.entropy / 1000.0, s2.temperature - 273.15);
      final p4Isen = toPixel(s3.entropy / 1000.0, s4.temperature - 273.15);

      final idealPaint = Paint()
        ..color = ScadaColors.infoBlue.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final idealPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2Isen.dx, p2Isen.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4Isen.dx, p4Isen.dy)
        ..close();
      canvas.drawPath(idealPath, idealPaint);
    }

    // 6. Ciclo Real (sólido y coloreado)
    final realFill = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();
    final fillPaint = Paint()
      ..color = ScadaColors.warningAmber.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(realFill, fillPaint);

    _drawProcessLine(canvas, p1, p2, ScadaColors.highPressureDischarge, 2.5);
    _drawProcessLine(canvas, p2, p3, ScadaColors.highPressureLiquid, 2.5);
    _drawProcessLine(canvas, p3, p4, ScadaColors.warningAmber, 2.5);
    _drawProcessLine(canvas, p4, p1, ScadaColors.lowPressureGas, 2.5);

    // Nodos 1, 2, 3, 4
    _drawNode(canvas, p1, '1', ScadaColors.lowPressureGas, selectedPoint == 1);
    _drawNode(canvas, p2, '2', ScadaColors.highPressureDischarge, selectedPoint == 2);
    _drawNode(canvas, p3, '3', ScadaColors.highPressureLiquid, selectedPoint == 3);
    _drawNode(canvas, p4, '4', ScadaColors.lowPressureTwoPhase, selectedPoint == 4);
  }

  void _drawProcessLine(Canvas canvas, Offset from, Offset to, Color color, double width) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, linePaint);
  }

  void _drawNode(Canvas canvas, Offset pos, String label, Color color, bool isSelected) {
    if (isSelected) {
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 14.0, pulsePaint);
    }

    final bgPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 8.0, bgPaint);

    final borderPaint = Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawCircle(pos, 8.0, borderPaint);

    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _TsDiagramPainter oldDelegate) => true;
}
