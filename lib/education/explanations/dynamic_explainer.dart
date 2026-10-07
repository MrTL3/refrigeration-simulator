import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../domain/components/base_component.dart';
import '../../domain/components/compressor_component.dart';
import '../../domain/components/condenser_component.dart';
import '../../domain/components/expansion_device_component.dart';
import '../../domain/components/evaporator_component.dart';
import '../../domain/models/transient_metrics.dart';
import '../../simulation/engine/simulation_state.dart';

/// Niveles pedagógicos de profundidad de explicación.
enum ExplanationLevel {
  basic('Básico'),
  intermediate('Intermedio'),
  technical('Técnico'),
  advanced('Avanzado');

  final String label;
  const ExplanationLevel(this.label);
}

/// Contenedor de la explicación contextual dinámica generada para un componente.
class ComponentExplanation {
  final String title;
  final String phaseSummary;
  final String telemetrySummary;
  final String explanation;
  final String causeEffectText;
  final String transientStatusText;
  final List<String> keyVariables;

  const ComponentExplanation({
    required this.title,
    required this.phaseSummary,
    required this.telemetrySummary,
    required this.explanation,
    required this.causeEffectText,
    required this.transientStatusText,
    required this.keyVariables,
  });
}

/// Generador de explicaciones en tiempo real basadas en la telemetría viva de la simulación.
class DynamicExplainer {
  static ComponentExplanation explain({
    required BaseComponent component,
    required SimulationState state,
    required ExplanationLevel level,
    PressureUnit pressureUnit = PressureUnit.bar,
    TemperatureUnit tempUnit = TemperatureUnit.celsius,
  }) {
    if (component is CompressorComponent) {
      return _explainCompressor(component, state, level, pressureUnit, tempUnit);
    } else if (component is CondenserComponent) {
      return _explainCondenser(component, state, level, pressureUnit, tempUnit);
    } else if (component is ExpansionDeviceComponent) {
      return _explainExpansion(component, state, level, pressureUnit, tempUnit);
    } else if (component is EvaporatorComponent) {
      return _explainEvaporator(component, state, level, pressureUnit, tempUnit);
    }

    return ComponentExplanation(
      title: component.name,
      phaseSummary: 'Estado de operación',
      telemetrySummary: 'Operativo: ${component.isOperational}',
      explanation: 'Componente auxiliar del circuito.',
      causeEffectText: '',
      transientStatusText: state.operationalMode.label,
      keyVariables: [],
    );
  }

  static String _formatTransientHeader(SimulationState state) {
    switch (state.operationalMode) {
      case SystemOperationalMode.off:
        return 'Estado: DETENIDO (Presiones ecualizadas con el ambiente).';
      case SystemOperationalMode.starting:
        return 'Estado: ARRANQUE RÁPIDO (Aceleración del motor y despresurización de baja).';
      case SystemOperationalMode.transient:
        final dpk = (state.trendPCond.derivativePerSec / 1000.0).toStringAsFixed(1);
        final dp0 = (state.trendPEvap.derivativePerSec / 1000.0).toStringAsFixed(1);
        return 'Estado: TRANSITORIO TÉRMICO EN CURSO (dP_alta/dt: $dpk kPa/s | dP_baja/dt: $dp0 kPa/s).';
      case SystemOperationalMode.steadyState:
        return 'Estado: RÉGIMEN PERMANENTE ESTABLE (Derivadas < tolerancia; equilibrio térmico alcanzado).';
      case SystemOperationalMode.stopping:
        return 'Estado: PARADA EN PROCESO (Ecualización gradual a través de la TXV).';
    }
  }

  static ComponentExplanation _explainCompressor(
    CompressorComponent comp,
    SimulationState state,
    ExplanationLevel level,
    PressureUnit pUnit,
    TemperatureUnit tUnit,
  ) {
    final pIn = UnitFormatter.formatPressure(state.state1Suction.pressure, pUnit);
    final pOut = UnitFormatter.formatPressure(state.state2Discharge.pressure, pUnit);
    final tIn = UnitFormatter.formatTemperature(state.state1Suction.temperature, tUnit);
    final tOut = UnitFormatter.formatTemperature(state.state2Discharge.temperature, tUnit);
    final pRatio = (state.state2Discharge.pressure / state.state1Suction.pressure.clamp(1.0, 1e7))
        .toStringAsFixed(2);
    final pElectKw = (state.electricalPowerWatts / 1000.0).toStringAsFixed(2);
    final currentRpm = state.dynamicRpm.toInt();

    final telemetry =
        'Velocidad dinámica: $currentRpm RPM\nP_asp: $pIn (${state.trendPEvap.direction.symbol}) | T_asp: $tIn\nP_desc: $pOut (${state.trendPCond.direction.symbol}) | T_desc: $tOut\nRelación compresión: $pRatio | Consumo: $pElectKw kW';

    final transientHeader = _formatTransientHeader(state);

    switch (level) {
      case ExplanationLevel.basic:
        return ComponentExplanation(
          title: 'Compresor (El corazón de la instalación)',
          phaseSummary: 'Aspira vapor frío a baja presión y descarga vapor caliente a alta presión.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'El compresor gira actualmente a $currentRpm RPM. Aspira el refrigerante de la cámara frigorífica a $pIn y lo comprime mecánicamente hasta $pOut para que pueda calentarse y ceder su calor al exterior.',
          causeEffectText: 'Trabajo eléctrico aplicado ➔ Aumento de presión (P ↑) y temperatura (T ↑).',
          keyVariables: ['RPM: $currentRpm', 'Potencia: $pElectKw kW', 'Modo: ${state.operationalMode.label}'],
        );

      case ExplanationLevel.intermediate:
        return ComponentExplanation(
          title: 'Compresor Frigorífico Alternativo',
          phaseSummary: 'Compresión politrópica de vapor sobrecalentado.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'El compresor bombea actualmente ${(state.massFlowKgPerSec * 3600).toStringAsFixed(1)} kg/h de vapor. Al aumentar las RPM o en el arranque, la masa extraída del evaporador supera inicialmente la inyectada por la TXV, provocando la caída de presión de baja hasta alcanzar un nuevo equilibrio.',
          causeEffectText: 'Caudal m_dot = V_g · (RPM/60) · ρ_asp · η_vol ➔ P_descarga $pOut.',
          keyVariables: ['Relación: $pRatio', 'Desplazamiento: ${comp.displacementCm3} cm³'],
        );

      case ExplanationLevel.technical:
        return ComponentExplanation(
          title: 'Dinámica del Proceso de Compresión',
          phaseSummary: 'Rendimiento volumétrico con re-expansión en espacio nocivo.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'Con una relación de compresión de $pRatio, el rendimiento volumétrico se sitúa en torno a ${(comp.volumetricEfficiency * 100).toInt()}%. La potencia mecánica entregada al refrigerante es de ${(state.compressorPowerWatts / 1000).toStringAsFixed(2)} kW. La derivada de presión de alta es ${(state.trendPCond.derivativePerSec / 1000).toStringAsFixed(2)} kPa/s.',
          causeEffectText: 'w_c = (h2 - h1) / η_is ➔ h2 = ${(state.state2Discharge.enthalpy / 1000).toStringAsFixed(1)} kJ/kg.',
          keyVariables: [
            'Caudal: ${(state.massFlowKgPerSec * 1000).toStringAsFixed(1)} g/s',
            'Derivada Pk: ${(state.trendPCond.derivativePerSec / 1000).toStringAsFixed(1)} kPa/s',
            'Tendencia: ${state.trendPCond.direction.description}'
          ],
        );

      case ExplanationLevel.advanced:
        return ComponentExplanation(
          title: 'Análisis Termodinámico y Entrópico',
          phaseSummary: 'Evolución no isentrópica con generación de irreversibilidad.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'Entalpía de aspiración h1 = ${(state.state1Suction.enthalpy / 1000).toStringAsFixed(1)} kJ/kg, entropía s1 = ${(state.state1Suction.entropy).toStringAsFixed(1)} J/(kg·K). La compresión real genera un salto entrópico hasta s2 = ${(state.state2Discharge.entropy).toStringAsFixed(1)} J/(kg·K) con temperatura de descarga de $tOut.',
          causeEffectText: 'Δs_comp = s2 - s1 > 0 (Irreversibilidad térmica y mecánica).',
          keyVariables: [
            's1: ${state.state1Suction.entropy.toStringAsFixed(1)} J/(kg·K)',
            's2: ${state.state2Discharge.entropy.toStringAsFixed(1)} J/(kg·K)',
            'w_is: ${((state.state2Discharge.enthalpy - state.state1Suction.enthalpy) * comp.isentropicEfficiency / 1000).toStringAsFixed(1)} kJ/kg'
          ],
        );
    }
  }

  static ComponentExplanation _explainCondenser(
    CondenserComponent cond,
    SimulationState state,
    ExplanationLevel level,
    PressureUnit pUnit,
    TemperatureUnit tUnit,
  ) {
    final pCond = UnitFormatter.formatPressure(state.condensingPressurePa, pUnit);
    final tCond = UnitFormatter.formatTemperature(state.condensingTemperatureK, tUnit);
    final tAmb = UnitFormatter.formatTemperature(cond.ambientTemperatureKelvin, tUnit);
    final subcooling = '${state.subcoolingKelvin.toStringAsFixed(1)} K';
    final qCondKw = (state.heatingCapacityWatts / 1000.0).toStringAsFixed(2);
    final transientHeader = _formatTransientHeader(state);

    final telemetry =
        'P_cond: $pCond (${state.trendPCond.direction.symbol}) | T_sat: $tCond\nT_ambiente: $tAmb | Rechazo térmico: $qCondKw kW\nSubcooling: $subcooling | Inercia térmica: 14 kJ/K';

    switch (level) {
      case ExplanationLevel.basic:
        return ComponentExplanation(
          title: 'Condensador (Evacuador de calor)',
          phaseSummary: 'Cede al exterior el calor de la cámara y del compresor.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'El condensador está evacuando $qCondKw kW hacia el aire exterior que está a $tAmb. Para lograrlo, el refrigerante condensa a $tCond (${state.trendPCond.direction.description}).',
          causeEffectText: 'Q_rechazo = UA · (T_cond - T_amb) ➔ Condensación a estado líquido.',
          keyVariables: ['T_ambiente: $tAmb', 'Q_rechazo: $qCondKw kW'],
        );

      case ExplanationLevel.intermediate:
        return ComponentExplanation(
          title: 'Condensador por Aire de Tiro Forzado',
          phaseSummary: 'Desrecalentamiento ➔ Condensación ➔ Subenfriamiento.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'Durante el transitorio, el calor aportado por la compresión eleva la temperatura del condensador a un ritmo dT_cond/dt gobernado por su capacitancia térmica de 14 kJ/K hasta que el calor cedido al aire iguala exactamente al calor generado.',
          causeEffectText: 'C_cond · (dT_cond/dt) = Q_ref_in - UA · (T_cond - T_amb).',
          keyVariables: ['Subcooling: $subcooling', 'T_condensación: $tCond'],
        );

      case ExplanationLevel.technical:
        return ComponentExplanation(
          title: 'Balance Térmico Diferencial del Condensador',
          phaseSummary: 'Ecuación diferencial de almacenamiento térmico de segundo orden.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'Capacidad de evacuación efectiva UA = ${(cond.effectiveUA).toStringAsFixed(0)} W/K. El salto térmico aire-condensación actual es de ${(state.condensingTemperatureK - cond.ambientTemperatureKelvin).toStringAsFixed(1)} K. Derivada de presión: ${(state.trendPCond.derivativePerSec / 1000).toStringAsFixed(2)} kPa/s.',
          causeEffectText: 'Qc = m_dot · (h_descarga - h_liquido).',
          keyVariables: ['UA efectivo: ${(cond.effectiveUA).toStringAsFixed(0)} W/K', 'Qc: $qCondKw kW'],
        );

      case ExplanationLevel.advanced:
        return ComponentExplanation(
          title: 'Termodinámica de la Condensación Transitoria',
          phaseSummary: 'Evolución cuasi-isobárica acoplada a la convección exterior.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'Entalpía de entrada: ${(state.state2Discharge.enthalpy / 1000).toStringAsFixed(1)} kJ/kg. Entalpía de líquido: ${(state.state3Liquid.enthalpy / 1000).toStringAsFixed(1)} kJ/kg. Pérdida neta de entalpía específica: ${((state.state2Discharge.enthalpy - state.state3Liquid.enthalpy) / 1000).toStringAsFixed(1)} kJ/kg.',
          causeEffectText: 'Δh_cond = Δh_sensible_gas + h_fg + Δh_subcool.',
          keyVariables: ['h_descarga: ${(state.state2Discharge.enthalpy / 1000).toStringAsFixed(1)} kJ/kg'],
        );
    }
  }

  static ComponentExplanation _explainExpansion(
    ExpansionDeviceComponent exp,
    SimulationState state,
    ExplanationLevel level,
    PressureUnit pUnit,
    TemperatureUnit tUnit,
  ) {
    final pIn = UnitFormatter.formatPressure(state.condensingPressurePa, pUnit);
    final pOut = UnitFormatter.formatPressure(state.evaporatingPressurePa, pUnit);
    final opening = exp.openingPercent.toStringAsFixed(1);
    final flashGas = (state.state4EvapInlet.vaporQuality * 100).toStringAsFixed(1);
    final transientHeader = _formatTransientHeader(state);

    final telemetry =
        'Apertura TXV: $opening% (${exp.isAutomatic ? "Modulación automática" : "Manual"})\nP_alta: $pIn | P_baja: $pOut\nVapor flash generado: $flashGas% | Superheat objetivo: ${exp.targetSuperheatKelvin} K';

    switch (level) {
      case ExplanationLevel.basic:
        return ComponentExplanation(
          title: 'Válvula de Expansión Termostática (TXV)',
          phaseSummary: 'Dosifica el flujo de refrigerante y reduce la presión.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'La válvula está abierta actualmente al $opening%. Al estrangular el paso, la presión cae bruscamente de $pIn a $pOut, provocando que el líquido se enfríe instantáneamente y genere un $flashGas% de vapor flash frío.',
          causeEffectText: 'Estrangulamiento ➔ Caída de presión (P ↓) y generación de frío.',
          keyVariables: ['Apertura: $opening%', 'Vapor flash: $flashGas%'],
        );

      case ExplanationLevel.intermediate:
        return ComponentExplanation(
          title: 'Válvula Termostática con Bulbo Sensor',
          phaseSummary: 'Lazo de control mecánico proporcional de recalentamiento.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'El bulbo sensor colocado en la tubería de aspiración detecta la temperatura del gas. Si el recalentamiento aumenta, la presión del bulbo sube y empuja la membrana para abrir la aguja. El caudal de inyección es gobernado por la ley de orificio: m_dot = C_v · apertura · √(2 · ρ · ΔP).',
          causeEffectText: 'F_apertura = P_bulbo - P_evap - P_resorte.',
          keyVariables: ['Modulación: ${exp.isAutomatic ? "Auto" : "Fija"}', 'Apertura: $opening%'],
        );

      case ExplanationLevel.technical:
        return ComponentExplanation(
          title: 'Ecuación de Flujo y Estrangulamiento Isentálpico',
          phaseSummary: 'Proceso adiabático sin trabajo externo (h3 = h4).',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'Entalpía constante h3 = h4 = ${(state.state3Liquid.enthalpy / 1000).toStringAsFixed(1)} kJ/kg. Caudal orificio calculado mediante ecuación ISA de control de fluidos para líquidos en estrangulamiento con caída de presión ΔP = ${UnitFormatter.formatPressure(state.condensingPressurePa - state.evaporatingPressurePa, pUnit)}.',
          causeEffectText: 'm_dot_txv = C_v · √(2 · ρ · ΔP).',
          keyVariables: ['h_constante: ${(state.state3Liquid.enthalpy / 1000).toStringAsFixed(1)} kJ/kg'],
        );

      case ExplanationLevel.advanced:
        return ComponentExplanation(
          title: 'Termodinámica de la Expansión Irreversible',
          phaseSummary: 'Salto irreversible de entropía y destrucción de exergía.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'El estrangulamiento genera una pérdida exergética irrecuperable: la entropía salta de ${(state.state3Liquid.entropy).toStringAsFixed(1)} a ${(state.state4EvapInlet.entropy).toStringAsFixed(1)} J/(kg·K). Título de vapor x = ${(state.state4EvapInlet.vaporQuality).toStringAsFixed(3)}.',
          causeEffectText: 'Δs = s4 - s3 > 0 (Generación interna de entropía).',
          keyVariables: ['Título x: ${(state.state4EvapInlet.vaporQuality).toStringAsFixed(3)}'],
        );
    }
  }

  static ComponentExplanation _explainEvaporator(
    EvaporatorComponent evap,
    SimulationState state,
    ExplanationLevel level,
    PressureUnit pUnit,
    TemperatureUnit tUnit,
  ) {
    final pEvap = UnitFormatter.formatPressure(state.evaporatingPressurePa, pUnit);
    final tEvap = UnitFormatter.formatTemperature(state.evaporatingTemperatureK, tUnit);
    final tRoom = UnitFormatter.formatTemperature(state.coldRoom.temperatureKelvin, tUnit);
    final superheat = '${state.superheatKelvin.toStringAsFixed(1)} K';
    final qEvapKw = (state.coolingCapacityWatts / 1000.0).toStringAsFixed(2);
    final transientHeader = _formatTransientHeader(state);

    final telemetry =
        'P_evap: $pEvap (${state.trendPEvap.direction.symbol}) | T_sat: $tEvap\nT_cámara: $tRoom (${state.trendTRoom.direction.symbol}) | Potencia frío: $qEvapKw kW\nSuperheat: $superheat | Inercia cámara: 85 kJ/K';

    switch (level) {
      case ExplanationLevel.basic:
        return ComponentExplanation(
          title: 'Evaporador (El generador de frío)',
          phaseSummary: 'Absorbe calor del aire de la cámara y enfría el producto.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'El evaporador está extrayendo $qEvapKw kW de calor de la cámara frigorífica. Como consecuencia, la temperatura de la cámara se sitúa en $tRoom (${state.trendTRoom.direction.description}).',
          causeEffectText: 'Q_frío extrae calor del recinto ➔ El aire se enfría.',
          keyVariables: ['T_cámara: $tRoom', 'Potencia útil: $qEvapKw kW'],
        );

      case ExplanationLevel.intermediate:
        return ComponentExplanation(
          title: 'Evaporador de Tiro Forzado y Cámara Frigorífica',
          phaseSummary: 'Ebullición convectiva y balance dinámico del recinto.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'La temperatura de la cámara evoluciona según la ecuación de conservación: C_cámara · (dT_cámara/dt) = Q_carga - Q_evap. Si la potencia del evaporador supera la carga térmica, la cámara se enfriará progresivamente hasta alcanzar la consigna.',
          causeEffectText: 'dT_cámara/dt = (Q_carga - Q_evap) / C_cámara.',
          keyVariables: ['Superheat: $superheat', 'Potencia útil: $qEvapKw kW'],
        );

      case ExplanationLevel.technical:
        return ComponentExplanation(
          title: 'Dinámica de Transferencia Térmica en Evaporador',
          phaseSummary: 'Evolución acoplada refrigerante-batería-aire de cámara.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'UA efectivo del evaporador: ${(evap.effectiveUA).toStringAsFixed(0)} W/K. Salto térmico cámara-evaporación: ${(state.coldRoom.temperatureKelvin - state.evaporatingTemperatureK).toStringAsFixed(1)} K. Inercia de batería: 8.5 kJ/K. COP actual del ciclo: ${state.cop.toStringAsFixed(2)}.',
          causeEffectText: 'Qe = m_dot · (h_aspiración - h_entrada).',
          keyVariables: [
            'COP: ${state.cop.toStringAsFixed(2)}',
            'dT_cámara/dt: ${(state.trendTRoom.derivativePerSec * 60).toStringAsFixed(2)} K/min',
          ],
        );

      case ExplanationLevel.advanced:
        return ComponentExplanation(
          title: 'Termodinámica de la Evaporación y Pull-Down',
          phaseSummary: 'Evolución transitoria de entalpía y curvas de enfriamiento.',
          telemetrySummary: telemetry,
          transientStatusText: transientHeader,
          explanation:
              'Efecto frigorífico específico: ${((state.state1Suction.enthalpy - state.state4EvapInlet.enthalpy) / 1000).toStringAsFixed(1)} kJ/kg. COP de Carnot de referencia: ${(state.evaporatingTemperatureK / (state.condensingTemperatureK - state.evaporatingTemperatureK)).toStringAsFixed(2)}. Eficiencia exergética del ciclo: ${(state.cop / (state.evaporatingTemperatureK / (state.condensingTemperatureK - state.evaporatingTemperatureK)).clamp(0.01, 100.0) * 100).toStringAsFixed(1)}%.',
          causeEffectText: 'q_o = h1 - h4 = Δh_útil.',
          keyVariables: [
            'h_entrada: ${(state.state4EvapInlet.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
            'h_salida: ${(state.state1Suction.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
          ],
        );
    }
  }
}
