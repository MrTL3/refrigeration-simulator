import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../domain/components/base_component.dart';
import '../../domain/models/simulation_level.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';
import 'components/compressor_visualizer.dart';
import 'components/condenser_visualizer.dart';
import 'components/evaporator_visualizer.dart';
import 'components/txv_visualizer.dart';
import 'flow/refrigerant_particle_system.dart';

/// Lienzo interactivo en perspectiva física 2.5D de la planta frigorífica completa.
/// Desacopla el bucle de renderizado (60 FPS) del solver físico (20 Hz), interpolando
/// cinemáticas de biela-manivela, aspas de ventiladores y partículas de flujo gobernadas por v = m_dot / (rho * A).
class RealisticPlantCanvas extends StatefulWidget {
  final SimulationState state;
  final BaseComponent? selectedComponent;
  final ValueChanged<BaseComponent>? onComponentSelected;
  final PlantViewMode viewMode;
  final VisualLayerToggles layerToggles;
  final SimulationInformationLevel informationLevel;
  final ValueChanged<String>? onInspectWhy;

  const RealisticPlantCanvas({
    super.key,
    required this.state,
    this.selectedComponent,
    this.onComponentSelected,
    this.viewMode = PlantViewMode.realistic25D,
    this.layerToggles = const VisualLayerToggles(),
    this.informationLevel = SimulationInformationLevel.level3Technical,
    this.onInspectWhy,
  });

  @override
  State<RealisticPlantCanvas> createState() => _RealisticPlantCanvasState();
}

class _RealisticPlantCanvasState extends State<RealisticPlantCanvas> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  double _crankAngleRad = 0.0;
  double _condFanAngleRad = 0.0;
  double _evapFanAngleRad = 0.0;

  final _compressorVisualizer = CompressorVisualizer();
  final _condenserVisualizer = CondenserVisualizer();
  final _evaporatorVisualizer = EvaporatorVisualizer();
  final _txvVisualizer = TxvVisualizer();
  final _particleSystem = RefrigerantParticleSystem();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    final dtSec = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.001, 0.05);
    _lastTick = elapsed;

    final state = widget.state;

    // Actualización de contratos de visualización
    _compressorVisualizer.updateFromState(state);
    _condenserVisualizer.updateFromState(state);
    _evaporatorVisualizer.updateFromState(state);
    _txvVisualizer.updateFromState(state);

    // Cinemática angular gobernada estrictamente por las variables físicas
    final rpm = state.dynamicRpm;
    if (rpm > 5.0) {
      _crankAngleRad = (_crankAngleRad + (2.0 * math.pi * (rpm / 60.0) * dtSec)) % (2.0 * math.pi);
    }

    final condFanRpm = state.condenserAirFlow.fanRpm;
    if (condFanRpm > 5.0) {
      _condFanAngleRad = (_condFanAngleRad + (2.0 * math.pi * (condFanRpm / 60.0) * dtSec)) % (2.0 * math.pi);
    }

    final evapFanRpm = state.evaporatorAirFlow.fanRpm;
    if (evapFanRpm > 5.0) {
      _evapFanAngleRad = (_evapFanAngleRad + (2.0 * math.pi * (evapFanRpm / 60.0) * dtSec)) % (2.0 * math.pi);
    }

    // Actualización de partículas físicas de refrigerante con v = m_dot / (rho * A)
    _particleSystem.update(state, dtSec);

    if (mounted) {
      setState(() {});
    }
  }

  void _handleTapUp(TapUpDetails details, Size canvasSize) {
    if (widget.onComponentSelected == null) return;

    final pos = details.localPosition;
    final w = canvasSize.width;
    final h = canvasSize.height;

    // Zonas interactivas de los 4 componentes en el lienzo 2.5D
    final compRect = Rect.fromCenter(center: Offset(w * 0.22, h * 0.72), width: 140, height: 160);
    final condRect = Rect.fromCenter(center: Offset(w * 0.76, h * 0.26), width: 150, height: 140);
    final txvRect = Rect.fromCenter(center: Offset(w * 0.76, h * 0.72), width: 130, height: 130);
    final evapRect = Rect.fromCenter(center: Offset(w * 0.22, h * 0.26), width: 160, height: 150);

    final circuit = widget.state.circuit;
    if (compRect.contains(pos) && circuit.compressor != null) {
      widget.onComponentSelected!(circuit.compressor!);
    } else if (condRect.contains(pos) && circuit.condenser != null) {
      widget.onComponentSelected!(circuit.condenser!);
    } else if (txvRect.contains(pos) && circuit.expansionDevice != null) {
      widget.onComponentSelected!(circuit.expansionDevice!);
    } else if (evapRect.contains(pos) && circuit.evaporator != null) {
      widget.onComponentSelected!(circuit.evaporator!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 600,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 480,
        );

        return GestureDetector(
          onTapUp: (details) => _handleTapUp(details, canvasSize),
          child: CustomPaint(
            size: canvasSize,
            painter: _RealisticPlantPainter(
              state: widget.state,
              selectedComponent: widget.selectedComponent,
              viewMode: widget.viewMode,
              layerToggles: widget.layerToggles,
              crankAngleRad: _crankAngleRad,
              condFanAngleRad: _condFanAngleRad,
              evapFanAngleRad: _evapFanAngleRad,
              compressorVis: _compressorVisualizer,
              condenserVis: _condenserVisualizer,
              evaporatorVis: _evaporatorVisualizer,
              txvVis: _txvVisualizer,
              particleSystem: _particleSystem,
            ),
          ),
        );
      },
    );
  }
}

class _RealisticPlantPainter extends CustomPainter {
  final SimulationState state;
  final BaseComponent? selectedComponent;
  final PlantViewMode viewMode;
  final VisualLayerToggles layerToggles;
  final double crankAngleRad;
  final double condFanAngleRad;
  final double evapFanAngleRad;

  final CompressorVisualizer compressorVis;
  final CondenserVisualizer condenserVis;
  final EvaporatorVisualizer evaporatorVis;
  final TxvVisualizer txvVis;
  final RefrigerantParticleSystem particleSystem;

  _RealisticPlantPainter({
    required this.state,
    required this.selectedComponent,
    required this.viewMode,
    required this.layerToggles,
    required this.crankAngleRad,
    required this.condFanAngleRad,
    required this.evapFanAngleRad,
    required this.compressorVis,
    required this.condenserVis,
    required this.evaporatorVis,
    required this.txvVis,
    required this.particleSystem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Centros geométricos de los componentes
    final compPos = Offset(w * 0.22, h * 0.72);
    final condPos = Offset(w * 0.76, h * 0.26);
    final txvPos = Offset(w * 0.76, h * 0.72);
    final evapPos = Offset(w * 0.22, h * 0.26);

    // 1. Trazado de tuberías metálicas industriales
    // A) Línea de descarga: Compresor -> Condensador (rojo alta presión)
    final pathDischarge = [
      Offset(compPos.dx + 48, compPos.dy - 35),
      Offset(w * 0.48, compPos.dy - 35),
      Offset(w * 0.48, condPos.dy - 35),
      Offset(condPos.dx - 58, condPos.dy - 35),
    ];

    // B) Línea de líquido: Condensador -> TXV (rojo oscuro líquido)
    final pathLiquid = [
      Offset(condPos.dx + 58, condPos.dy + 35),
      Offset(w * 0.92, condPos.dy + 35),
      Offset(w * 0.92, txvPos.dy),
      Offset(txvPos.dx + 40, txvPos.dy),
    ];

    // C) Línea de inyección bifásica: TXV -> Evaporador (cian frío)
    final pathExpansion = [
      Offset(txvPos.dx - 38, txvPos.dy),
      Offset(w * 0.52, txvPos.dy),
      Offset(w * 0.52, evapPos.dy + 30),
      Offset(evapPos.dx + 55, evapPos.dy + 30),
    ];

    // D) Línea de aspiración: Evaporador -> Compresor (azul baja presión)
    final pathSuction = [
      Offset(evapPos.dx - 55, evapPos.dy - 25),
      Offset(w * 0.08, evapPos.dy - 25),
      Offset(w * 0.08, compPos.dy - 15),
      Offset(compPos.dx - 48, compPos.dy - 15),
    ];

    // Pintar tuberías físicas
    _drawMetallicPipe(canvas, pathDischarge, ScadaColors.highPressureDischarge, 8.0, 'pipe_discharge');
    _drawMetallicPipe(canvas, pathLiquid, ScadaColors.highPressureLiquid, 7.0, 'pipe_liquid');
    _drawMetallicPipe(canvas, pathExpansion, ScadaColors.lowPressureTwoPhase, 7.5, 'pipe_expansion');
    _drawMetallicPipe(canvas, pathSuction, ScadaColors.lowPressureSuction, 9.0, 'pipe_suction');

    // 2. Partículas físicas de refrigerante (si la capa 'showRefrigerantFlow' está activa)
    if (layerToggles.showRefrigerantFlow) {
      particleSystem.paintPipeParticles(canvas: canvas, pipeId: 'pipe_discharge', pathPoints: pathDischarge, pipeState: state.pipeDischarge);
      particleSystem.paintPipeParticles(canvas: canvas, pipeId: 'pipe_liquid', pathPoints: pathLiquid, pipeState: state.pipeLiquid);
      particleSystem.paintPipeParticles(canvas: canvas, pipeId: 'pipe_expansion', pathPoints: pathExpansion, pipeState: state.pipeExpansion);
      particleSystem.paintPipeParticles(canvas: canvas, pipeId: 'pipe_suction', pathPoints: pathSuction, pipeState: state.pipeSuction);
    }

    // 3. Renderizado de componentes visuales en sus coordenadas
    // A) Compresor
    canvas.save();
    canvas.translate(compPos.dx - 75, compPos.dy - 85);
    compressorVis.paint(canvas, const Size(150, 170), crankAngleRad);
    canvas.restore();

    // B) Condensador
    canvas.save();
    canvas.translate(condPos.dx - 85, condPos.dy - 70);
    condenserVis.paint(canvas, const Size(170, 140), condFanAngleRad);
    canvas.restore();

    // C) Válvula de Expansión TXV
    canvas.save();
    canvas.translate(txvPos.dx - 65, txvPos.dy - 65);
    txvVis.paint(canvas, const Size(130, 130));
    canvas.restore();

    // D) Evaporador y Cámara
    canvas.save();
    canvas.translate(evapPos.dx - 90, evapPos.dy - 80);
    evaporatorVis.paint(canvas, const Size(180, 160), evapFanAngleRad);
    canvas.restore();

    // 4. Capa de transferencia de calor 'showHeatTransfer'
    if (layerToggles.showHeatTransfer) {
      _drawHeatTransferArrows(canvas, condPos, evapPos);
    }

    // 5. Marco de resalte del componente seleccionado
    if (selectedComponent != null) {
      Offset targetCenter;
      Size targetSize;
      if (selectedComponent!.id == 'comp_1') {
        targetCenter = compPos;
        targetSize = const Size(160, 180);
      } else if (selectedComponent!.id == 'cond_1') {
        targetCenter = condPos;
        targetSize = const Size(180, 150);
      } else if (selectedComponent!.id == 'exp_1') {
        targetCenter = txvPos;
        targetSize = const Size(140, 140);
      } else {
        targetCenter = evapPos;
        targetSize = const Size(190, 170);
      }

      final selPaint = Paint()
        ..color = ScadaColors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: targetCenter, width: targetSize.width, height: targetSize.height), const Radius.circular(12)),
        selPaint,
      );
    }
  }

  void _drawMetallicPipe(Canvas canvas, List<Offset> points, Color fluidColor, double thickness, String pipeId) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Cuerpo metálico de cobre exterior
    final outerPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness + 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, outerPaint);

    // Núcleo del fluido interior
    final innerPaint = Paint()
      ..color = fluidColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, innerPaint);
  }

  void _drawHeatTransferArrows(Canvas canvas, Offset condPos, Offset evapPos) {
    // Flechas de calor saliendo del condensador hacia el ambiente
    if (state.heatingCapacityWatts > 10.0) {
      final heatOutPaint = Paint()
        ..color = ScadaColors.highPressureDischarge.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final arrowP1 = Offset(condPos.dx, condPos.dy - 75);
      final arrowP2 = Offset(condPos.dx, condPos.dy - 100);
      canvas.drawLine(arrowP1, arrowP2, heatOutPaint);
      canvas.drawLine(arrowP2, Offset(arrowP2.dx - 6, arrowP2.dy + 8), heatOutPaint);
      canvas.drawLine(arrowP2, Offset(arrowP2.dx + 6, arrowP2.dy + 8), heatOutPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: 'Q̇c = ${(state.heatingCapacityWatts / 1000).toStringAsFixed(2)} kW',
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: ScadaColors.highPressureDischarge),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(condPos.dx - tp.width / 2, condPos.dy - 114));
    }

    // Flechas de calor entrando al evaporador desde la cámara
    if (state.coolingCapacityWatts > 10.0) {
      final heatInPaint = Paint()
        ..color = ScadaColors.cyanAccent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final arrowP1 = Offset(evapPos.dx, evapPos.dy + 85);
      final arrowP2 = Offset(evapPos.dx, evapPos.dy + 60);
      canvas.drawLine(arrowP1, arrowP2, heatInPaint);
      canvas.drawLine(arrowP2, Offset(arrowP2.dx - 6, arrowP2.dy + 8), heatInPaint);
      canvas.drawLine(arrowP2, Offset(arrowP2.dx + 6, arrowP2.dy + 8), heatInPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: 'Q̇e = ${(state.coolingCapacityWatts / 1000).toStringAsFixed(2)} kW',
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: ScadaColors.cyanAccent),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(evapPos.dx - tp.width / 2, evapPos.dy + 88));
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticPlantPainter oldDelegate) {
    return true; // Siempre repinta en el bucle de ticker desacoplado a 60 FPS
  }
}
