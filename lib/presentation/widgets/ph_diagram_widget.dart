import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../domain/models/thermodynamic_state.dart';
import '../../simulation/engine/simulation_state.dart';
import '../../simulation/thermodynamics/diagram_data_generator.dart';
import '../theme/scada_colors.dart';

/// Punto del ciclo frigorífico en el diagrama P-h
enum PhCyclePoint {
  point1('Punto 1: Aspiración', 'Salida del evaporador / Entrada del compresor', 'comp_1'),
  point2('Punto 2: Descarga', 'Salida del compresor / Entrada del condensador', 'comp_1'),
  point3('Punto 3: Líquido Subenfriado', 'Salida del condensador / Entrada de la TXV', 'cond_1'),
  point4('Punto 4: Mezcla Bifásica', 'Salida de la TXV / Entrada del evaporador', 'exp_1');

  final String label;
  final String location;
  final String componentId;
  const PhCyclePoint(this.label, this.location, this.componentId);
}

/// Widget del Diagrama Presión - Entalpía (P-h Mollier) dinámico e interactivo.
class PhDiagramWidget extends StatefulWidget {
  final SimulationState state;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final ValueChanged<String>? onHighlightComponent;

  const PhDiagramWidget({
    super.key,
    required this.state,
    required this.pressureUnit,
    required this.temperatureUnit,
    this.onHighlightComponent,
  });

  @override
  State<PhDiagramWidget> createState() => _PhDiagramWidgetState();
}

class _PhDiagramWidgetState extends State<PhDiagramWidget> {
  PhCyclePoint? _selectedPoint;
  late final DiagramDataGenerator _generator;
  late final List<DiagramPoint> _liquidDome;
  late final List<DiagramPoint> _vaporDome;
  late final List<DiagramCurve> _qualityLines;
  late final List<DiagramCurve> _isotherms;

  @override
  void initState() {
    super.initState();
    _generator = DiagramDataGenerator(widget.state.refrigerant);
    _liquidDome = _generator.generatePhLiquidDome();
    _vaporDome = _generator.generatePhVaporDome();
    _qualityLines = _generator.generatePhQualityLines();
    _isotherms = _generator.generatePhIsotherms();
  }

  void _selectPoint(PhCyclePoint point) {
    setState(() => _selectedPoint = point);
    _showPointDetailsSheet(point);
  }

  ThermodynamicState _getStateForPoint(PhCyclePoint pt) {
    switch (pt) {
      case PhCyclePoint.point1:
        return widget.state.state1Suction;
      case PhCyclePoint.point2:
        return widget.state.state2Discharge;
      case PhCyclePoint.point3:
        return widget.state.state3Liquid;
      case PhCyclePoint.point4:
        return widget.state.state4EvapInlet;
    }
  }

  void _showPointDetailsSheet(PhCyclePoint pt) {
    final s = _getStateForPoint(pt);
    showModalBottomSheet(
      context: context,
      backgroundColor: ScadaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPointColor(pt).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getPointColor(pt)),
                        ),
                        child: Text(
                          pt.name.toUpperCase().replaceAll('POINT', 'PUNTO '),
                          style: TextStyle(
                            color: _getPointColor(pt),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        pt.label,
                        style: const TextStyle(
                          color: ScadaColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: ScadaColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                pt.location,
                style: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11),
              ),
              const Divider(color: ScadaColors.border, height: 20),

              // Rejilla de propiedades termodinámicas vivas
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _propBadge('Presión (P)', UnitFormatter.formatPressure(s.pressure, widget.pressureUnit)),
                  _propBadge('Temperatura (T)', UnitFormatter.formatTemperature(s.temperature, widget.temperatureUnit)),
                  _propBadge('Entalpía (h)', '${(s.enthalpy / 1000.0).toStringAsFixed(1)} kJ/kg'),
                  _propBadge('Entropía (s)', '${(s.entropy / 1000.0).toStringAsFixed(3)} kJ/(kg·K)'),
                  _propBadge('Densidad (ρ)', '${s.density.toStringAsFixed(1)} kg/m³'),
                  _propBadge('Título (x)', s.phaseState == PhaseState.twoPhase ? '${(s.vaporQuality * 100).toStringAsFixed(1)}%' : (s.phaseState == PhaseState.subcooledLiquid ? '0.0 (Líq)' : '1.0 (Vap)')),
                  _propBadge('Estado Físico', s.phaseState.displayName, highlight: true),
                ],
              ),
              const SizedBox(height: 14),

              // Explicación física contextual "¿POR QUÉ?"
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ScadaColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.help_outline, size: 14, color: ScadaColors.infoBlue),
                        SizedBox(width: 6),
                        Text(
                          '¿POR QUÉ SE ENCUENTRA EN ESTE ESTADO?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ScadaColors.infoBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getPointExplanation(pt, s),
                      style: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ScadaColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.functions, size: 14, color: ScadaColors.warningAmber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _getPointEquation(pt),
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: ScadaColors.warningAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botón de resaltar en el sinóptico
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onHighlightComponent?.call(pt.componentId);
                },
                icon: const Icon(Icons.location_searching, size: 16),
                label: const Text('VER COMPONENTE ASOCIADO EN LA MÁQUINA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScadaColors.infoBlue,
                  side: const BorderSide(color: ScadaColors.infoBlue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _propBadge(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: highlight ? ScadaColors.infoBlue.withValues(alpha: 0.15) : ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: highlight ? ScadaColors.infoBlue : ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: highlight ? ScadaColors.infoBlue : ScadaColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _getPointExplanation(PhCyclePoint pt, ThermodynamicState s) {
    switch (pt) {
      case PhCyclePoint.point1:
        return 'El refrigerante ha terminado de evaporarse absorbiendo calor del recinto y ha ganado ${widget.state.superheatKelvin.toStringAsFixed(1)} K de recalentamiento (superheat) para garantizar que no entre ninguna gota de líquido al compresor.';
      case PhCyclePoint.point2:
        return 'El compresor ha realizado un trabajo mecánico indicado sobre el gas, elevando su presión de ${(widget.state.evaporatingPressurePa / 1e5).toStringAsFixed(1)} bar a ${(widget.state.condensingPressurePa / 1e5).toStringAsFixed(1)} bar y su temperatura a ${(s.temperature - 273.15).toStringAsFixed(1)} °C por calor de compresión irreversibilidad.';
      case PhCyclePoint.point3:
        return 'El refrigerante ha cedido calor latente al aire exterior en el condensador pasando a líquido saturado, y posteriormente ha sido subenfriado ${widget.state.subcoolingKelvin.toStringAsFixed(1)} K para asegurar líquido 100% puro en la entrada de la válvula.';
      case PhCyclePoint.point4:
        return 'Al atravesar el orificio de la válvula TXV se produce una expansión estrangulada isentálpica (h₄ = h₃). Una fracción se evapora instantáneamente (flash gas, título x ≈ ${(s.vaporQuality * 100).toStringAsFixed(0)}%) enfriando el resto hasta la temperatura de evaporación.';
    }
  }

  String _getPointEquation(PhCyclePoint pt) {
    switch (pt) {
      case PhCyclePoint.point1:
        return 'T₁ = T_evap_sat(P₀) + Superheat | h₁ = h_sat_vap + c_p_vap · SH';
      case PhCyclePoint.point2:
        return 'h₂ = h₁ + (h₂_isen - h₁) / η_is | P₂ = P_k';
      case PhCyclePoint.point3:
        return 'T₃ = T_cond_sat(P_k) - Subcooling | h₃ = h_sat_liq - c_p_liq · SC';
      case PhCyclePoint.point4:
        return 'h₄ ≡ h₃ (Proceso Isentálpico) | x₄ = (h₄ - h_f) / (h_g - h_f)';
    }
  }

  Color _getPointColor(PhCyclePoint pt) {
    switch (pt) {
      case PhCyclePoint.point1:
        return ScadaColors.lowPressureGas;
      case PhCyclePoint.point2:
        return ScadaColors.highPressureDischarge;
      case PhCyclePoint.point3:
        return ScadaColors.highPressureLiquid;
      case PhCyclePoint.point4:
        return ScadaColors.lowPressureTwoPhase;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Barra superior con leyenda interactiva
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_graph, color: ScadaColors.infoBlue, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'DIAGRAMA P-h (MOLLIER) — R-134a',
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
                children: PhCyclePoint.values.map((pt) {
                  final isSel = _selectedPoint == pt;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => _selectPoint(pt),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSel ? _getPointColor(pt).withValues(alpha: 0.25) : ScadaColors.surfaceCard,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isSel ? _getPointColor(pt) : ScadaColors.border),
                        ),
                        child: Text(
                          'P${pt.index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getPointColor(pt),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Lienzo CustomPainter interactivo
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: const Color(0xFF0F1520),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapUp: (details) {
                        _handleCanvasTap(details.localPosition, constraints.biggest);
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _PhDiagramPainter(
                          state: widget.state,
                          liquidDome: _liquidDome,
                          vaporDome: _vaporDome,
                          qualityLines: _qualityLines,
                          isotherms: _isotherms,
                          selectedPoint: _selectedPoint,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Leyenda inferior de regiones
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              _RegionLegend(color: ScadaColors.highPressureLiquid, label: 'Líq. Subenfriado'),
              _RegionLegend(color: ScadaColors.lowPressureTwoPhase, label: 'Campana Bifásica (L+V)'),
              _RegionLegend(color: ScadaColors.highPressureDischarge, label: 'Vapor Sobrecalentado'),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCanvasTap(Offset tapPos, Size size) {
    // Detectamos si el toque está cerca de algún punto del ciclo
    final p1Pix = _worldToPixel(widget.state.state1Suction.enthalpy / 1000.0, widget.state.state1Suction.pressure / 1e5, size);
    final p2Pix = _worldToPixel(widget.state.state2Discharge.enthalpy / 1000.0, widget.state.state2Discharge.pressure / 1e5, size);
    final p3Pix = _worldToPixel(widget.state.state3Liquid.enthalpy / 1000.0, widget.state.state3Liquid.pressure / 1e5, size);
    final p4Pix = _worldToPixel(widget.state.state4EvapInlet.enthalpy / 1000.0, widget.state.state4EvapInlet.pressure / 1e5, size);

    const hitRadius = 24.0;
    if ((tapPos - p1Pix).distance <= hitRadius) {
      _selectPoint(PhCyclePoint.point1);
    } else if ((tapPos - p2Pix).distance <= hitRadius) {
      _selectPoint(PhCyclePoint.point2);
    } else if ((tapPos - p3Pix).distance <= hitRadius) {
      _selectPoint(PhCyclePoint.point3);
    } else if ((tapPos - p4Pix).distance <= hitRadius) {
      _selectPoint(PhCyclePoint.point4);
    }
  }

  Offset _worldToPixel(double hKj, double pBar, Size size) {
    const minH = 160.0;
    const maxH = 460.0;
    const minLogP = -0.301; // log10(0.5 bar)
    const maxLogP = 1.477;  // log10(30 bar)

    const padL = 38.0;
    const padR = 20.0;
    const padT = 20.0;
    const padB = 28.0;

    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    final xNorm = ((hKj - minH) / (maxH - minH)).clamp(0.0, 1.0);
    final logP = math.log(pBar.clamp(0.3, 35.0)) / math.ln10;
    final yNorm = ((logP - minLogP) / (maxLogP - minLogP)).clamp(0.0, 1.0);

    return Offset(padL + xNorm * w, padT + (1.0 - yNorm) * h);
  }
}

class _RegionLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _RegionLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
      ],
    );
  }
}

class _PhDiagramPainter extends CustomPainter {
  final SimulationState state;
  final List<DiagramPoint> liquidDome;
  final List<DiagramPoint> vaporDome;
  final List<DiagramCurve> qualityLines;
  final List<DiagramCurve> isotherms;
  final PhCyclePoint? selectedPoint;

  _PhDiagramPainter({
    required this.state,
    required this.liquidDome,
    required this.vaporDome,
    required this.qualityLines,
    required this.isotherms,
    required this.selectedPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 38.0;
    const padR = 20.0;
    const padT = 20.0;
    const padB = 28.0;

    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    const minH = 160.0;
    const maxH = 460.0;
    const minLogP = -0.301; // log10(0.5 bar)
    const maxLogP = 1.477;  // log10(30 bar)

    Offset toPixel(double hKj, double pBar) {
      final xNorm = ((hKj - minH) / (maxH - minH)).clamp(0.0, 1.0);
      final logP = math.log(pBar.clamp(0.3, 35.0)) / math.ln10;
      final yNorm = ((logP - minLogP) / (maxLogP - minLogP)).clamp(0.0, 1.0);
      return Offset(padL + xNorm * w, padT + (1.0 - yNorm) * h);
    }

    // 1. Rejilla y ejes logarítmicos
    final gridPaint = Paint()
      ..color = ScadaColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    final textStyle = const TextStyle(color: ScadaColors.textMuted, fontSize: 9, fontFamily: 'monospace');

    // Líneas de presión (eje vertical logarítmico: 1, 2, 5, 10, 20 bar)
    for (final pVal in [1.0, 2.0, 5.0, 10.0, 20.0]) {
      final yPos = toPixel(minH, pVal).dy;
      canvas.drawLine(Offset(padL, yPos), Offset(padL + w, yPos), gridPaint);
      _drawText(canvas, '${pVal.toInt()} bar', Offset(6, yPos - 5), textStyle);
    }

    // Líneas de entalpía (eje horizontal lineal: 200, 250, 300, 350, 400, 450 kJ/kg)
    for (final hVal in [200.0, 250.0, 300.0, 350.0, 400.0, 450.0]) {
      final xPos = toPixel(hVal, 1.0).dx;
      canvas.drawLine(Offset(xPos, padT), Offset(xPos, padT + h), gridPaint);
      _drawText(canvas, '${hVal.toInt()}', Offset(xPos - 10, padT + h + 6), textStyle);
    }
    _drawText(canvas, 'h (kJ/kg)', Offset(padL + w - 45, padT + h + 14), textStyle);

    // 2. Curvas de título (x = cte)
    final qualityPaint = Paint()
      ..color = ScadaColors.lowPressureTwoPhase.withValues(alpha: 0.25)
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

    // 3. Isotermas de referencia
    final isoPaint = Paint()
      ..color = ScadaColors.warningAmber.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final iso in isotherms) {
      final path = Path();
      for (int i = 0; i < iso.points.length; i++) {
        final pt = toPixel(iso.points[i].x, iso.points[i].y);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, isoPaint);
    }

    // 4. Campana de saturación principal (Líquido saturado x=0 y Vapor saturado x=1)
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

    // 5. Trazado del ciclo frigorífico real (1 -> 2 -> 3 -> 4 -> 1)
    final s1 = state.state1Suction;
    final s2 = state.state2Discharge;
    final s3 = state.state3Liquid;
    final s4 = state.state4EvapInlet;

    final p1 = toPixel(s1.enthalpy / 1000.0, s1.pressure / 1e5);
    final p2 = toPixel(s2.enthalpy / 1000.0, s2.pressure / 1e5);
    final p3 = toPixel(s3.enthalpy / 1000.0, s3.pressure / 1e5);
    final p4 = toPixel(s4.enthalpy / 1000.0, s4.pressure / 1e5);

    // Relleno suave del área encerrada por el ciclo
    final cycleFillPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final fillPaint = Paint()
      ..color = ScadaColors.infoBlue.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cycleFillPath, fillPaint);

    // Líneas del ciclo
    _drawProcessLine(canvas, p1, p2, ScadaColors.highPressureDischarge, 2.5); // Compresión 1 -> 2
    _drawProcessLine(canvas, p2, p3, ScadaColors.highPressureLiquid, 2.5);    // Condensación 2 -> 3
    _drawProcessLine(canvas, p3, p4, ScadaColors.warningAmber, 2.5);          // Expansión 3 -> 4
    _drawProcessLine(canvas, p4, p1, ScadaColors.lowPressureGas, 2.5);        // Evaporación 4 -> 1

    // 6. Dibujo de los 4 nodos interactivos
    _drawCycleNode(canvas, p1, '1', ScadaColors.lowPressureGas, selectedPoint == PhCyclePoint.point1);
    _drawCycleNode(canvas, p2, '2', ScadaColors.highPressureDischarge, selectedPoint == PhCyclePoint.point2);
    _drawCycleNode(canvas, p3, '3', ScadaColors.highPressureLiquid, selectedPoint == PhCyclePoint.point3);
    _drawCycleNode(canvas, p4, '4', ScadaColors.lowPressureTwoPhase, selectedPoint == PhCyclePoint.point4);
  }

  void _drawProcessLine(Canvas canvas, Offset from, Offset to, Color color, double width) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, linePaint);
  }

  void _drawCycleNode(Canvas canvas, Offset pos, String label, Color color, bool isSelected) {
    if (isSelected) {
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 14.0, pulsePaint);
    }

    final bgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 8.0, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
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
  bool shouldRepaint(covariant _PhDiagramPainter oldDelegate) {
    return true; // Se redibuja con cada tick dinámico de la simulación
  }
}
