import '../components/compressor_component.dart';
import '../components/condenser_component.dart';
import '../components/expansion_device_component.dart';
import '../components/evaporator_component.dart';
import 'connection_port.dart';
import 'circuit.dart';
import 'pipe.dart';
import 'thermodynamic_state.dart';

/// Generador de la instalación frigorífica básica estándar (Ciclo de compresión de vapor de 1 etapa).
class BasicCyclePreset {
  static Circuit create() {
    const compId = 'comp_1';
    const condId = 'cond_1';
    const expId = 'exp_1';
    const evapId = 'evap_1';

    final comp = const CompressorComponent(
      id: compId,
      name: 'Compresor Alternativo Hermético',
      displacementCm3: 34.5,
      rpm: 2900.0,
      volumetricEfficiency: 0.78,
      isentropicEfficiency: 0.72,
      posX: 120.0,
      posY: 340.0,
    );

    final cond = const CondenserComponent(
      id: condId,
      name: 'Condensador por Aire Forzado',
      ambientTemperatureKelvin: 298.15, // 25.0 °C
      targetSubcoolingKelvin: 5.0,
      overallHeatTransferCoefficientUA: 230.0,
      posX: 480.0,
      posY: 80.0,
    );

    final exp = const ExpansionDeviceComponent(
      id: expId,
      name: 'Válvula de Expansión Termostática (TXV)',
      openingPercent: 45.0,
      targetSuperheatKelvin: 7.0,
      posX: 520.0,
      posY: 340.0,
    );

    final evap = const EvaporatorComponent(
      id: evapId,
      name: 'Evaporador Cúbico de Aire Forzado',
      roomTemperatureKelvin: 277.15, // 4.0 °C
      targetSuperheatKelvin: 7.0,
      overallHeatTransferCoefficientUA: 190.0,
      posX: 120.0,
      posY: 80.0,
    );

    // Tuberías de interconexión con sus respectivos nodos físicos
    final zeroState = ThermodynamicState.zero();

    final dischargePipe = Pipe(
      id: 'pipe_discharge',
      name: 'Línea de Descarga (Gas caliente alta presión)',
      fromComponentId: compId,
      fromPortId: 'discharge',
      toComponentId: condId,
      toPortId: 'inlet',
      lengthMeters: 2.5,
      innerDiameterMm: 12.0,
      fluidNode: FluidNode(
        id: 'node_discharge',
        name: 'Nodo Descarga',
        state: zeroState,
      ),
    );

    final liquidPipe = Pipe(
      id: 'pipe_liquid',
      name: 'Línea de Líquido (Alta presión)',
      fromComponentId: condId,
      fromPortId: 'outlet',
      toComponentId: expId,
      toPortId: 'inlet',
      lengthMeters: 3.0,
      innerDiameterMm: 10.0,
      fluidNode: FluidNode(
        id: 'node_liquid',
        name: 'Nodo Líquido',
        state: zeroState,
      ),
    );

    final expansionPipe = Pipe(
      id: 'pipe_expansion',
      name: 'Línea de Inyección Bifásica (Baja presión)',
      fromComponentId: expId,
      fromPortId: 'outlet',
      toComponentId: evapId,
      toPortId: 'inlet',
      lengthMeters: 1.0,
      innerDiameterMm: 12.0,
      fluidNode: FluidNode(
        id: 'node_evap_in',
        name: 'Nodo Entrada Evaporador',
        state: zeroState,
      ),
    );

    final suctionPipe = Pipe(
      id: 'pipe_suction',
      name: 'Línea de Aspiración (Gas frío baja presión)',
      fromComponentId: evapId,
      fromPortId: 'outlet',
      toComponentId: compId,
      toPortId: 'suction',
      lengthMeters: 3.5,
      innerDiameterMm: 16.0,
      fluidNode: FluidNode(
        id: 'node_suction',
        name: 'Nodo Aspiración',
        state: zeroState,
      ),
    );

    return Circuit(
      id: 'preset_basic_cycle',
      name: 'Instalación Básica de 1 Etapa (R-134a)',
      components: {
        compId: comp,
        condId: cond,
        expId: exp,
        evapId: evap,
      },
      pipes: [
        dischargePipe,
        liquidPipe,
        expansionPipe,
        suctionPipe,
      ],
      refrigerantName: 'R-134a',
      refrigerantChargeKg: 1.25,
    );
  }
}
