import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/components/base_component.dart';
import '../../domain/models/simulation_level.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';
import 'components/compressor_visualizer.dart';
import 'components/condenser_visualizer.dart';
import 'components/evaporator_visualizer.dart';
import 'components/txv_visualizer.dart';
import 'flow/refrigerant_particle_system.dart';
import 'models/installation_instrument.dart';
import 'renderers/cold_room_3d_renderer.dart';
import 'renderers/compressor_3d_renderer.dart';
import 'renderers/condenser_3d_renderer.dart';
import 'renderers/evaporator_3d_renderer.dart';
import 'renderers/instruments_3d_renderer.dart';
import 'renderers/liquid_receiver_3d_renderer.dart';
import 'renderers/pipe_system_3d_renderer.dart';
import 'renderers/txv_3d_renderer.dart';
import 'widgets/instrument_inspection_panel.dart';

/// Vista física inmersiva 3D/volumétrica de la instalación frigorífica industrial completa.
///
/// Modela con separación espacial amplia, perspectiva técnica y volumen:
/// 1. Zona Fría (Izquierda): Gran cámara frigorífica aislada de paneles sándwich con puerta semiabierta,
///    termostato digital LED y evaporador cúbico comercial 3D con doble ventilador axial y bandeja con sifón.
/// 2. Zona Central: Bancada metálica con silentblocks y compresor hermético 3D con domo ovoide,
///    caja bornes, mirilla de aceite en cárter, válvulas de servicio Rotalock y vibración RPM.
/// 3. Zona Alta / Condensación (Derecha): Condensador de tiro forzado 3D con paquete de aletas y ventilador axial.
/// 4. Zona Líquido: Recipiente de líquido vertical (calderín) con visor de nivel, filtro deshidratador,
///    visor de líquido con corona indicadora y burbujeo dinámico (SC < 2K), y caudalímetro digital.
/// 5. Zona Expansión: Válvula de expansión termostática (TXV) 3D de latón forjado en 90° con cabezal de membrana
///    y capilar en espiral hacia el bulbo palpador en la línea de aspiración.
/// 6. Trazado continuo de tuberías con volumen cilíndrico sombreado y coquilla Armaflex en aspiración.
/// 7. Red de 14 instrumentos físicos interactivos in situ.
/// 8. Controlador de interacción web y táctil sin conflictos:
///    - Clic/Tap: Selecciona componente o instrumento.
///    - Arrastre sobre componente: Mueve el componente libremente en coordenadas internas.
///    - Arrastre sobre lienzo vacío: Desplaza (Pan) la cámara suavemente.
///    - Rueda de ratón: Zoom con anclaje al cursor (focal point).
///    - Botonera flotante con presets de escala (50%, 100%, 200%, 400%).
class InstallationPlantView extends StatefulWidget {
  final SimulationState state;
  final BaseComponent? selectedComponent;
  final ValueChanged<BaseComponent>? onComponentSelected;
  final ValueChanged<InstallationInstrument?>? onInstrumentSelected;
  final VisualLayerToggles layerToggles;
  final SimulationInformationLevel informationLevel;
  final ValueChanged<String>? onInspectWhy;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final VoidCallback? onFullscreen;

  const InstallationPlantView({
    super.key,
    required this.state,
    this.selectedComponent,
    this.onComponentSelected,
    this.onInstrumentSelected,
    this.layerToggles = const VisualLayerToggles(),
    this.informationLevel = SimulationInformationLevel.level3Technical,
    this.onInspectWhy,
    this.pressureUnit = PressureUnit.bar,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.onFullscreen,
  });

  @override
  State<InstallationPlantView> createState() => _InstallationPlantViewState();
}

class _InstallationPlantViewState extends State<InstallationPlantView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  // Controlador de matriz de transformación de cámara
  final TransformationController _transformController = TransformationController();

  double _crankAngleRad = 0.0;
  double _condFanAngleRad = 0.0;
  double _evapFanAngleRad = 0.0;
  double _bubblePhase = 0.0;

  final _compressorVisualizer = CompressorVisualizer();
  final _condenserVisualizer = CondenserVisualizer();
  final _evaporatorVisualizer = EvaporatorVisualizer();
  final _txvVisualizer = TxvVisualizer();
  final _particleSystem = RefrigerantParticleSystem();

  // Dimensiones del espacio virtual del mundo de la instalación (coordenadas internas fijas)
  static const double _worldWidth = 1380.0;
  static const double _worldHeight = 780.0;

  Size _lastConstraintsSize = Size.zero;
  Matrix4 _defaultMatrix = Matrix4.identity();

  // Desplazamientos libres de componentes en coordenadas internas
  final Map<String, Offset> _componentOffsets = {
    'comp': Offset.zero,
    'cond': Offset.zero,
    'txv': Offset.zero,
    'evap': Offset.zero,
    'receiver': Offset.zero,
  };

  // Gestión de gestos sin interferencias
  Offset _startFocalPoint = Offset.zero;
  Matrix4 _startMatrix = Matrix4.identity();
  bool _pointerMoved = false;

  // Estado de arrastre de componentes
  String? _draggingComponentId;
  Offset _dragStartComponentOffset = Offset.zero;
  Offset _dragStartWorldPos = Offset.zero;
  bool _isPanningCanvas = false;

  // Estado de cursor de ratón sobre lienzo
  String? _hoveredComponentId;
  InstallationInstrument? _hoveredInstrument;

  // Instrumento actualmente seleccionado para inspección
  InstallationInstrument? _selectedInstrument;

  // Registro de instrumentos físicos colocados en la instalación 3D
  late final List<InstallationInstrument> _instruments;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _initInstrumentRegistry();
  }

  void _initInstrumentRegistry() {
    _instruments = InstallationInstrument.defaultInstallation();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformController.dispose();
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

    _compressorVisualizer.updateFromState(state);
    _condenserVisualizer.updateFromState(state);
    _evaporatorVisualizer.updateFromState(state);
    _txvVisualizer.updateFromState(state);

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

    _bubblePhase = (_bubblePhase + dtSec * 1.5) % 1.0;

    _particleSystem.update(state, dtSec);

    if (mounted) {
      setState(() {});
    }
  }

  /// Lista de instrumentos dinámica con posiciones ajustadas según el desplazamiento de componentes
  List<InstallationInstrument> get _dynamicInstruments {
    final compOffset = _componentOffsets['comp'] ?? Offset.zero;
    final condOffset = _componentOffsets['cond'] ?? Offset.zero;
    final txvOffset = _componentOffsets['txv'] ?? Offset.zero;
    final evapOffset = _componentOffsets['evap'] ?? Offset.zero;
    final receiverOffset = _componentOffsets['receiver'] ?? Offset.zero;

    return _instruments.map((inst) {
      switch (inst.id) {
        case 'gauge_po':
        case 'gauge_pk':
        case 'thermo_discharge':
        case 'oil_sight_glass':
        case 'electrical_clamp':
        case 'vacuum_gauge':
          return inst.withOffset(compOffset);
        case 'thermo_liquid':
        case 'mass_flow_meter':
        case 'moisture_sight_glass':
          return inst.withOffset(receiverOffset);
        case 'thermo_ambient':
          return inst.withOffset(condOffset);
        case 'thermo_evap':
          return inst.withOffset(txvOffset);
        case 'thermo_suction':
          return inst.withOffset(evapOffset);
        default:
          return inst;
      }
    }).toList();
  }

  void _resetZoom() {
    _transformController.value = _defaultMatrix.clone();
    setState(() {
      _selectedInstrument = null;
    });
    widget.onInstrumentSelected?.call(null);
  }

  void _resetComponentPositions() {
    setState(() {
      _componentOffsets.updateAll((key, value) => Offset.zero);
    });
  }

  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale < 4.5) {
      final matrix = _transformController.value.clone();
      matrix.setEntry(0, 0, matrix.entry(0, 0) * 1.25);
      matrix.setEntry(1, 1, matrix.entry(1, 1) * 1.25);
      _transformController.value = matrix;
    }
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 0.25) {
      final matrix = _transformController.value.clone();
      matrix.setEntry(0, 0, matrix.entry(0, 0) * 0.8);
      matrix.setEntry(1, 1, matrix.entry(1, 1) * 0.8);
      _transformController.value = matrix;
    }
  }

  void _setPresetScale(double targetScale) {
    if (_lastConstraintsSize == Size.zero) return;
    final viewportCenter = Offset(_lastConstraintsSize.width / 2, _lastConstraintsSize.height / 2);
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale <= 0) return;
    final ratio = targetScale / currentScale;

    final newMatrix = _transformController.value.clone();
    newMatrix.translateByVector3(vmath.Vector3(viewportCenter.dx, viewportCenter.dy, 0.0));
    newMatrix.scaleByVector3(vmath.Vector3(ratio, ratio, 1.0));
    newMatrix.translateByVector3(vmath.Vector3(-viewportCenter.dx, -viewportCenter.dy, 0.0));

    setState(() {
      _transformController.value = newMatrix;
    });
  }

  /// Manejo de zoom suave mediante rueda de ratón (Mouse Scroll Wheel)
  void _handlePointerScroll(PointerScrollEvent event) {
    final dy = event.scrollDelta.dy;
    if (dy == 0) return;

    final zoomFactor = dy < 0 ? 1.15 : 0.85;
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * zoomFactor).clamp(0.20, 5.0);
    final effectiveFactor = targetScale / currentScale;

    final localPoint = event.localPosition;
    final newMatrix = _transformController.value.clone();

    // Pivotar exactamente sobre el punto donde está situado el puntero del ratón
    newMatrix.translateByVector3(vmath.Vector3(localPoint.dx, localPoint.dy, 0.0));
    newMatrix.scaleByVector3(vmath.Vector3(effectiveFactor, effectiveFactor, 1.0));
    newMatrix.translateByVector3(vmath.Vector3(-localPoint.dx, -localPoint.dy, 0.0));

    setState(() {
      _transformController.value = newMatrix;
    });
  }

  /// Hit testing para identificar si se tocó o arrastró un componente móvil
  String? _hitTestComponentId(Offset worldPos) {
    final compOffset = _componentOffsets['comp'] ?? Offset.zero;
    final condOffset = _componentOffsets['cond'] ?? Offset.zero;
    final txvOffset = _componentOffsets['txv'] ?? Offset.zero;
    final evapOffset = _componentOffsets['evap'] ?? Offset.zero;
    final receiverOffset = _componentOffsets['receiver'] ?? Offset.zero;

    final compRect = Rect.fromCenter(center: Offset(725 + compOffset.dx, 580 + compOffset.dy), width: 220, height: 270);
    final condRect = Rect.fromCenter(center: Offset(1120 + condOffset.dx, 235 + condOffset.dy), width: 330, height: 300);
    final txvRect = Rect.fromCenter(center: Offset(545 + txvOffset.dx, 350 + txvOffset.dy), width: 140, height: 140);
    final evapRect = Rect.fromCenter(center: Offset(265 + evapOffset.dx, 220 + evapOffset.dy), width: 260, height: 200);
    final receiverRect = Rect.fromLTWH(1120 + receiverOffset.dx, 450 + receiverOffset.dy, 90, 260);

    if (compRect.contains(worldPos)) return 'comp';
    if (condRect.contains(worldPos)) return 'cond';
    if (txvRect.contains(worldPos)) return 'txv';
    if (evapRect.contains(worldPos)) return 'evap';
    if (receiverRect.contains(worldPos)) return 'receiver';
    return null;
  }

  /// Procesa un tap genuino en el espacio del mundo de la instalación
  void _handleWorldTap(Offset worldPos) {
    final dynInsts = _dynamicInstruments;

    // 1. Comprobar primero si se tocó un INSTRUMENTO (radio de tolerancia)
    for (final inst in dynInsts) {
      final dist = (inst.worldPosition - worldPos).distance;
      if (dist <= inst.hitRadius + 16.0) {
        setState(() {
          _selectedInstrument = inst;
        });
        widget.onInstrumentSelected?.call(inst);
        return;
      }
    }

    // 2. Si no es un instrumento, comprobar los COMPONENTES PRINCIPALES
    final circuit = widget.state.circuit;
    final compOffset = _componentOffsets['comp'] ?? Offset.zero;
    final condOffset = _componentOffsets['cond'] ?? Offset.zero;
    final txvOffset = _componentOffsets['txv'] ?? Offset.zero;
    final evapOffset = _componentOffsets['evap'] ?? Offset.zero;

    final compRect = Rect.fromCenter(center: Offset(725 + compOffset.dx, 580 + compOffset.dy), width: 220, height: 270);
    final condRect = Rect.fromCenter(center: Offset(1120 + condOffset.dx, 235 + condOffset.dy), width: 330, height: 300);
    final txvRect = Rect.fromCenter(center: Offset(545 + txvOffset.dx, 350 + txvOffset.dy), width: 140, height: 140);
    final evapRect = Rect.fromCenter(center: Offset(265 + evapOffset.dx, 220 + evapOffset.dy), width: 260, height: 200);
    final coldRoomRect = const Rect.fromLTWH(50, 80, 420, 620);

    if (compRect.contains(worldPos) && circuit.compressor != null) {
      setState(() => _selectedInstrument = null);
      widget.onInstrumentSelected?.call(null);
      widget.onComponentSelected?.call(circuit.compressor!);
      return;
    } else if (condRect.contains(worldPos) && circuit.condenser != null) {
      setState(() => _selectedInstrument = null);
      widget.onInstrumentSelected?.call(null);
      widget.onComponentSelected?.call(circuit.condenser!);
      return;
    } else if (txvRect.contains(worldPos) && circuit.expansionDevice != null) {
      setState(() => _selectedInstrument = null);
      widget.onInstrumentSelected?.call(null);
      widget.onComponentSelected?.call(circuit.expansionDevice!);
      return;
    } else if (evapRect.contains(worldPos) && circuit.evaporator != null) {
      setState(() => _selectedInstrument = null);
      widget.onInstrumentSelected?.call(null);
      widget.onComponentSelected?.call(circuit.evaporator!);
      return;
    } else if (coldRoomRect.contains(worldPos) && circuit.evaporator != null) {
      setState(() => _selectedInstrument = null);
      widget.onInstrumentSelected?.call(null);
      widget.onComponentSelected?.call(circuit.evaporator!);
      return;
    }

    // Si tocó en zona vacía, deseleccionar
    if (_selectedInstrument != null) {
      setState(() {
        _selectedInstrument = null;
      });
      widget.onInstrumentSelected?.call(null);
    }
  }

  MouseCursor get _currentCursor {
    if (_draggingComponentId != null) return SystemMouseCursors.move;
    if (_isPanningCanvas) return SystemMouseCursors.grabbing;
    if (_hoveredComponentId != null || _hoveredInstrument != null) return SystemMouseCursors.click;
    return SystemMouseCursors.grab;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 0 &&
            constraints.maxHeight > 0 &&
            (constraints.biggest != _lastConstraintsSize)) {
          _lastConstraintsSize = constraints.biggest;
          final scaleX = constraints.maxWidth / _worldWidth;
          final scaleY = constraints.maxHeight / _worldHeight;
          final fitScale = math.min(scaleX, scaleY).clamp(0.28, 1.4);
          final tx = (constraints.maxWidth - _worldWidth * fitScale) / 2.0;
          final ty = (constraints.maxHeight - _worldHeight * fitScale) / 2.0;
          final m = Matrix4.identity();
          m.setEntry(0, 0, fitScale);
          m.setEntry(1, 1, fitScale);
          m.setEntry(0, 3, tx);
          m.setEntry(1, 3, ty);
          _defaultMatrix = m;
          _transformController.value = m;
        }

        final dynInstruments = _dynamicInstruments;

        return Stack(
          children: [
            // Escucha de eventos de rueda de ratón para Zoom inmediato en Web
            Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  _handlePointerScroll(pointerSignal);
                }
              },
              onPointerHover: (event) {
                final invMatrix = Matrix4.tryInvert(_transformController.value);
                if (invMatrix != null) {
                  final worldPos = MatrixUtils.transformPoint(invMatrix, event.localPosition);
                  final hitComp = _hitTestComponentId(worldPos);
                  InstallationInstrument? hitInst;
                  for (final inst in dynInstruments) {
                    if ((inst.worldPosition - worldPos).distance <= inst.hitRadius + 14.0) {
                      hitInst = inst;
                      break;
                    }
                  }
                  if (hitComp != _hoveredComponentId || hitInst != _hoveredInstrument) {
                    setState(() {
                      _hoveredComponentId = hitComp;
                      _hoveredInstrument = hitInst;
                    });
                  }
                }
              },
              child: MouseRegion(
                cursor: _currentCursor,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final invMatrix = Matrix4.tryInvert(_transformController.value);
                    if (invMatrix != null) {
                      final worldPos = MatrixUtils.transformPoint(invMatrix, details.localPosition);
                      _handleWorldTap(worldPos);
                    }
                  },
                  onScaleStart: (details) {
                    _startFocalPoint = details.localFocalPoint;
                    _startMatrix = _transformController.value.clone();
                    _pointerMoved = false;

                    // Comprobar si el inicio del arrastre fue sobre un componente
                    final invMatrix = Matrix4.tryInvert(_transformController.value);
                    if (invMatrix != null) {
                      final worldPos = MatrixUtils.transformPoint(invMatrix, details.localFocalPoint);
                      final hitComp = _hitTestComponentId(worldPos);
                      if (hitComp != null) {
                        _draggingComponentId = hitComp;
                        _dragStartComponentOffset = _componentOffsets[hitComp] ?? Offset.zero;
                        _dragStartWorldPos = worldPos;
                        _isPanningCanvas = false;
                      } else {
                        _draggingComponentId = null;
                        _isPanningCanvas = true;
                      }
                    }
                  },
                  onScaleUpdate: (details) {
                    final delta = details.localFocalPoint - _startFocalPoint;
                    if (delta.distanceSquared > 16.0 || (details.scale - 1.0).abs() > 0.05) {
                      _pointerMoved = true;
                    }

                    final invMatrix = Matrix4.tryInvert(_transformController.value);
                    if (_draggingComponentId != null && invMatrix != null) {
                      // 1. ARRASTRE DE COMPONENTE LIBRE EN EL LIENZO
                      final currentWorldPos = MatrixUtils.transformPoint(invMatrix, details.localFocalPoint);
                      final deltaWorld = currentWorldPos - _dragStartWorldPos;
                      setState(() {
                        _componentOffsets[_draggingComponentId!] = _dragStartComponentOffset + deltaWorld;
                      });
                    } else {
                      // 2. DESPLAZAMIENTO DEL LIENZO (PAN) Y PELLIZCO (PINCH ZOOM)
                      final newMatrix = _startMatrix.clone();
                      final currentScale = _startMatrix.getMaxScaleOnAxis();
                      final targetScale = (currentScale * details.scale).clamp(0.25, 4.5);
                      final scaleRatio = targetScale / currentScale;

                      newMatrix.translateByVector3(vmath.Vector3(details.localFocalPoint.dx, details.localFocalPoint.dy, 0.0));
                      newMatrix.scaleByVector3(vmath.Vector3(scaleRatio, scaleRatio, 1.0));
                      newMatrix.translateByVector3(vmath.Vector3(-details.localFocalPoint.dx, -details.localFocalPoint.dy, 0.0));
                      newMatrix.translateByVector3(vmath.Vector3(delta.dx, delta.dy, 0.0));

                      _transformController.value = newMatrix;
                    }
                  },
                  onScaleEnd: (details) {
                    if (!_pointerMoved) {
                      final invMatrix = Matrix4.tryInvert(_transformController.value);
                      if (invMatrix != null) {
                        final worldPos = MatrixUtils.transformPoint(invMatrix, _startFocalPoint);
                        _handleWorldTap(worldPos);
                      }
                    }
                    setState(() {
                      _draggingComponentId = null;
                      _isPanningCanvas = false;
                    });
                  },
                  child: AnimatedBuilder(
                    animation: _transformController,
                    builder: (context, _) {
                      return Transform(
                        transform: _transformController.value,
                        child: OverflowBox(
                          minWidth: _worldWidth,
                          maxWidth: _worldWidth,
                          minHeight: _worldHeight,
                          maxHeight: _worldHeight,
                          alignment: Alignment.topLeft,
                          child: CustomPaint(
                            size: const Size(_worldWidth, _worldHeight),
                            painter: _Volumetric3DPlantPainter(
                              state: widget.state,
                              selectedComponent: widget.selectedComponent,
                              selectedInstrument: _selectedInstrument,
                              instruments: dynInstruments,
                              layerToggles: widget.layerToggles,
                              informationLevel: widget.informationLevel,
                              crankAngleRad: _crankAngleRad,
                              condFanAngleRad: _condFanAngleRad,
                              evapFanAngleRad: _evapFanAngleRad,
                              bubblePhase: _bubblePhase,
                              compressorVis: _compressorVisualizer,
                              condenserVis: _condenserVisualizer,
                              evaporatorVis: _evaporatorVisualizer,
                              txvVis: _txvVisualizer,
                              particleSystem: _particleSystem,
                              pressureUnit: widget.pressureUnit,
                              temperatureUnit: widget.temperatureUnit,
                              componentOffsets: _componentOffsets,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Panel contextual de inspección de instrumento (aparece al tocar cualquier instrumento)
            if (_selectedInstrument != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 54,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: InstrumentInspectionPanel(
                      instrument: _selectedInstrument!,
                      state: widget.state,
                      pressureUnit: widget.pressureUnit,
                      temperatureUnit: widget.temperatureUnit,
                      onClose: () {
                        setState(() => _selectedInstrument = null);
                        widget.onInstrumentSelected?.call(null);
                      },
                      onInspectWhy: () {
                        widget.onInspectWhy?.call(_selectedInstrument!.tag);
                      },
                    ),
                  ),
                ),
              ),

            // Botonera flotante completa de zoom, presets de escala y centrado
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: ScadaColors.surfaceCard.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ScadaColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Presets de escala directa (Fase 5)
                    _buildZoomPresetButton('50%', 0.5),
                    _buildZoomPresetButton('100%', 1.0),
                    _buildZoomPresetButton('200%', 2.0),
                    _buildZoomPresetButton('400%', 4.0),
                    Container(height: 18, width: 1, color: ScadaColors.border, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, size: 18),
                      color: ScadaColors.textPrimary,
                      tooltip: 'Acercar zoom',
                      onPressed: _zoomIn,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out, size: 18),
                      color: ScadaColors.textPrimary,
                      tooltip: 'Alejar zoom',
                      onPressed: _zoomOut,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.center_focus_strong, size: 18),
                      color: ScadaColors.infoBlue,
                      tooltip: 'Centrar instalación (Vista Inicial)',
                      onPressed: _resetZoom,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.restart_alt, size: 18),
                      color: ScadaColors.warningAmber,
                      tooltip: 'Restablecer posiciones de componentes',
                      onPressed: _resetComponentPositions,
                      visualDensity: VisualDensity.compact,
                    ),
                    if (widget.onFullscreen != null)
                      IconButton(
                        icon: const Icon(Icons.fullscreen, size: 18),
                        color: ScadaColors.primary,
                        tooltip: 'Pantalla completa',
                        onPressed: widget.onFullscreen,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),

            // Leyenda de controles interactivos inferior izquierda
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ScadaColors.surfaceCard.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mouse, size: 14, color: ScadaColors.cyanAccent),
                    SizedBox(width: 6),
                    Text(
                      'Arrastra componente para mover · Arrastra fondo para desplazar · Rueda para zoom',
                      style: TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZoomPresetButton(String label, double scale) {
    return InkWell(
      onTap: () => _setPresetScale(scale),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.cyanAccent),
        ),
      ),
    );
  }
}

/// CustomPainter maestro que renderiza la instalación frigorífica 3D volumétrica en el espacio de 1380x780.
class _Volumetric3DPlantPainter extends CustomPainter {
  final SimulationState state;
  final BaseComponent? selectedComponent;
  final InstallationInstrument? selectedInstrument;
  final List<InstallationInstrument> instruments;
  final VisualLayerToggles layerToggles;
  final SimulationInformationLevel informationLevel;
  final double crankAngleRad;
  final double condFanAngleRad;
  final double evapFanAngleRad;
  final double bubblePhase;
  final CompressorVisualizer compressorVis;
  final CondenserVisualizer condenserVis;
  final EvaporatorVisualizer evaporatorVis;
  final TxvVisualizer txvVis;
  final RefrigerantParticleSystem particleSystem;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final Map<String, Offset> componentOffsets;

  _Volumetric3DPlantPainter({
    required this.state,
    required this.selectedComponent,
    required this.selectedInstrument,
    required this.instruments,
    required this.layerToggles,
    required this.informationLevel,
    required this.crankAngleRad,
    required this.condFanAngleRad,
    required this.evapFanAngleRad,
    required this.bubblePhase,
    required this.compressorVis,
    required this.condenserVis,
    required this.evaporatorVis,
    required this.txvVis,
    required this.particleSystem,
    required this.pressureUnit,
    required this.temperatureUnit,
    required this.componentOffsets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo de nave industrial / taller frigorífico
    final bgShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0B1120), Color(0xFF0F172A), Color(0xFF090D1A)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = bgShader);

    // Rejilla de ingeniería milimetrada técnica de fondo
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ==========================================
    // DEFINICIÓN DE COORDENADAS ESPACIALES CON DESPLAZAMIENTO DINÁMICO
    // ==========================================
    final compOffset = componentOffsets['comp'] ?? Offset.zero;
    final condOffset = componentOffsets['cond'] ?? Offset.zero;
    final txvOffset = componentOffsets['txv'] ?? Offset.zero;
    final evapOffset = componentOffsets['evap'] ?? Offset.zero;
    final receiverOffset = componentOffsets['receiver'] ?? Offset.zero;

    // 1. Cámara Frigorífica (Izquierda amplia)
    final coldRoomRect = const Rect.fromLTWH(50, 80, 420, 620);
    // 2. Evaporador 3D (Dentro de la cámara, desplazable)
    final evapRect = Rect.fromLTWH(140 + evapOffset.dx, 130 + evapOffset.dy, 250, 180);
    // 3. Compresor 3D (Desplazable)
    final compRect = Rect.fromLTWH(620 + compOffset.dx, 450 + compOffset.dy, 210, 260);
    // 4. Condensador 3D (Desplazable)
    final condRect = Rect.fromLTWH(960 + condOffset.dx, 90 + condOffset.dy, 320, 290);
    // 5. Calderín de líquido y accesorios (Desplazable)
    final receiverRect = Rect.fromLTWH(1120 + receiverOffset.dx, 450 + receiverOffset.dy, 80, 250);
    final filterRect = Rect.fromLTWH(980 + receiverOffset.dx, 585 + receiverOffset.dy, 75, 30);
    final sightGlassRect = Rect.fromLTWH(850 + receiverOffset.dx, 585 + receiverOffset.dy, 32, 32);
    final flowmeterRect = Rect.fromLTWH(730 + receiverOffset.dx, 582 + receiverOffset.dy, 60, 36);
    // 6. Válvula TXV 3D (Desplazable)
    final txvRect = Rect.fromLTWH(510 + txvOffset.dx, 310 + txvOffset.dy, 80, 80);

    // Puertos de tuberías dinámicos
    final compSuctionPort = Offset(compRect.left + 28, compRect.top + 35);
    final compDischargePort = Offset(compRect.right - 28, compRect.top + 35);
    final condInletPort = Offset(condRect.left + 16, condRect.top + 35);
    final condOutletPort = Offset(condRect.right - 20, condRect.bottom - 20);
    final receiverInletPort = Offset(receiverRect.center.dx, receiverRect.top);
    final receiverOutletPort = Offset(receiverRect.left, receiverRect.bottom - 30);
    final filterInletPort = Offset(filterRect.right, filterRect.center.dy);
    final filterOutletPort = Offset(filterRect.left, filterRect.center.dy);
    final txvInletPort = Offset(txvRect.center.dx, txvRect.bottom);
    final txvOutletPort = Offset(txvRect.left, txvRect.center.dy);
    final evapInletPort = Offset(evapRect.right - 20, evapRect.top + 28);
    final evapOutletPort = Offset(evapRect.left + 20, evapRect.top + 28);
    final bulbPosition = Offset(evapRect.left - 45, evapRect.top + 28);

    // ==========================================
    // RENDERIZADO POR CAPAS VOLUMÉTRICAS
    // ==========================================

    // 1. Cámara Frigorífica 3D
    final isColdRoomSelected = selectedComponent?.id == 'evap_1';
    ColdRoom3DRenderer.paint(
      canvas: canvas,
      roomRect: coldRoomRect,
      state: state,
      isSelected: isColdRoomSelected,
    );

    // 2. Evaporador 3D (dentro de la cámara)
    final isEvapSelected = selectedComponent?.id == 'evap_1';
    Evaporator3DRenderer.paint(
      canvas: canvas,
      evapRect: evapRect,
      state: state,
      fanAngleRad: evapFanAngleRad,
      isSelected: isEvapSelected,
      showHeatVectors: layerToggles.showHeatExchange,
    );

    // 3. Tuberías 3D volumétricas continuas
    PipeSystem3DRenderer.paint(
      canvas: canvas,
      state: state,
      compSuctionPort: compSuctionPort,
      compDischargePort: compDischargePort,
      condInletPort: condInletPort,
      condOutletPort: condOutletPort,
      receiverInletPort: receiverInletPort,
      receiverOutletPort: receiverOutletPort,
      filterInletPort: filterInletPort,
      filterOutletPort: filterOutletPort,
      txvInletPort: txvInletPort,
      txvOutletPort: txvOutletPort,
      evapInletPort: evapInletPort,
      evapOutletPort: evapOutletPort,
      wallX: coldRoomRect.right - 12,
      showTemperatures: layerToggles.showTemperatures,
    );

    // 4. Elementos auxiliares de línea de líquido (Calderín, Filtro, Visor, Caudalímetro)
    LiquidReceiver3DRenderer.paint(
      canvas: canvas,
      receiverRect: receiverRect,
      filterRect: filterRect,
      sightGlassRect: sightGlassRect,
      flowmeterRect: flowmeterRect,
      state: state,
      bubblePhase: bubblePhase,
    );

    // 5. Válvula de Expansión Termostática TXV 3D
    final isTxvSelected = selectedComponent?.id == 'exp_1';
    Txv3DRenderer.paint(
      canvas: canvas,
      txvRect: txvRect,
      state: state,
      bulbPosition: bulbPosition,
      isSelected: isTxvSelected,
    );

    // 6. Condensador 3D de Tiro Forzado
    final isCondSelected = selectedComponent?.id == 'cond_1';
    Condenser3DRenderer.paint(
      canvas: canvas,
      condRect: condRect,
      state: state,
      fanAngleRad: condFanAngleRad,
      isSelected: isCondSelected,
      showHeatVectors: layerToggles.showHeatExchange,
    );

    // 7. Compresor Hermético 3D
    final isCompSelected = selectedComponent?.id == 'comp_1';
    Compressor3DRenderer.paint(
      canvas: canvas,
      compRect: compRect,
      state: state,
      crankAngleRad: crankAngleRad,
      isSelected: isCompSelected,
    );

    // 8. Flujo cinemático de partículas si la capa FLUJO está activa
    if (layerToggles.showFlow && state.isRunning) {
      particleSystem.paintPipeParticles(
        canvas: canvas,
        pipeId: 'pipe_discharge',
        pathPoints: [
          compDischargePort,
          Offset(compDischargePort.dx + 25, compDischargePort.dy - 10),
          Offset(condInletPort.dx - 30, compDischargePort.dy - 10),
          Offset(condInletPort.dx - 30, condInletPort.dy),
          condInletPort,
        ],
        pipeState: state.pipeStates['pipe_discharge'],
      );
      particleSystem.paintPipeParticles(
        canvas: canvas,
        pipeId: 'pipe_liquid',
        pathPoints: [
          condOutletPort,
          Offset(condOutletPort.dx, receiverInletPort.dy - 20),
          Offset(receiverInletPort.dx, receiverInletPort.dy - 20),
          receiverInletPort,
          receiverOutletPort,
          filterInletPort,
          filterOutletPort,
          txvInletPort,
        ],
        pipeState: state.pipeStates['pipe_liquid'],
      );
      particleSystem.paintPipeParticles(
        canvas: canvas,
        pipeId: 'pipe_expansion',
        pathPoints: [
          txvOutletPort,
          Offset(evapInletPort.dx, txvOutletPort.dy),
          evapInletPort,
        ],
        pipeState: state.pipeStates['pipe_expansion'],
      );
      particleSystem.paintPipeParticles(
        canvas: canvas,
        pipeId: 'pipe_suction',
        pathPoints: [
          evapOutletPort,
          Offset(evapOutletPort.dx - 35, evapOutletPort.dy),
          Offset(evapOutletPort.dx - 35, compSuctionPort.dy - 35),
          Offset(compSuctionPort.dx, compSuctionPort.dy - 35),
          compSuctionPort,
        ],
        pipeState: state.pipeStates['pipe_suction'],
      );
    }

    // 9. Instrumentación física in situ (Manómetros Bourdon, Termómetros, KP15)
    Instruments3DRenderer.paint(
      canvas: canvas,
      state: state,
      pUnit: pressureUnit,
      tUnit: temperatureUnit,
      instruments: instruments,
      selectedInstrumentId: selectedInstrument?.id,
      highlightInstrumentsLayer: layerToggles.showInstruments,
    );
  }

  @override
  bool shouldRepaint(covariant _Volumetric3DPlantPainter oldDelegate) {
    return true; // Animación viva a 60fps
  }
}
