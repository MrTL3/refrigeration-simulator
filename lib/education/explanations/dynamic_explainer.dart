import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../domain/components/base_component.dart';
import '../../domain/components/compressor_component.dart';
import '../../domain/components/condenser_component.dart';
import '../../domain/components/expansion_device_component.dart';
import '../../domain/components/evaporator_component.dart';
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
  final List<String> keyVariables;

  const ComponentExplanation({
    required this.title,
    required this.phaseSummary,
    required this.telemetrySummary,
    required this.explanation,
    required this.causeEffectText,
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
      keyVariables: [],
    );
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

    final telemetry =
        'P_asp: $pIn | T_asp: $tIn\nP_desc: $pOut | T_desc: $tOut\nRelación de compresión: $pRatio | Consumo: $pElectKw kW';

    switch (level) {
      case ExplanationLevel.basic:
        return ComponentExplanation(
          title: 'Compresor (El corazón de la instalación)',
          phaseSummary: 'Aspira vapor frío y expulsa vapor caliente a alta presión.',
          telemetrySummary: telemetry,
          explanation:
              'El compresor bombea el refrigerante por todo el circuito. Eleva la presión del gas desde $pIn hasta $pOut para que después pueda ceder su calor al ambiente.',
          causeEffectText: 'Trabajo eléctrico aplicado ➔ Aumento de presión (P ↑) y temperatura (T ↑).',
          keyVariables: ['RPM: ${comp.rpm.toInt()}', 'Potencia: $pElectKw kW'],
        );

      case ExplanationLevel.intermediate:
        return ComponentExplanation(
          title: 'Compresor Frigorífico',
          phaseSummary: 'Fase de aspiración: Vapor recalentado ➔ Fase de descarga: Vapor recalentado de alta presión.',
          telemetrySummary: telemetry,
          explanation:
              'Aspira vapor sobrecalentado a baja presión ($pIn) evitando la entrada de líquido que rompería los pistones. Al comprimirlo mecánicamente a $pOut, la energía suministrada eleva bruscamente su entalpía y temperatura hasta $tOut.',
          causeEffectText: 'Compresión mecánica ➔ Presión sube de $pIn a $pOut (Relación: $pRatio).',
          keyVariables: ['Relación compresión: $pRatio', 'Desplazamiento: ${comp.displacementCm3} cm³'],
        );

      case ExplanationLevel.technical:
        return ComponentExplanation(
          title: 'Compresor Alternativo Hermético',
          phaseSummary: 'Proceso de compresión politrópica con generación de calor por fricción y pérdidas internas.',
          telemetrySummary: telemetry,
          explanation:
              'El caudal másico aspirado es de ${(state.massFlowKgPerSec * 3600.0).toStringAsFixed(1)} kg/h con un rendimiento volumétrico estimado de ${(comp.volumetricEfficiency * 100).toInt()}%. La potencia indicada entregada al fluido es de ${(state.compressorPowerWatts / 1000.0).toStringAsFixed(2)} kW, resultando en un consumo eléctrico de $pElectKw kW tras considerar la eficiencia del motor.',
          causeEffectText: 'w_c = (h2 - h1) / η_is ➔ h2 = ${(state.state2Discharge.enthalpy / 1000).toStringAsFixed(1)} kJ/kg.',
          keyVariables: [
            'η_vol: ${(comp.volumetricEfficiency * 100).toInt()}%',
            'η_is: ${(comp.isentropicEfficiency * 100).toInt()}%',
            'Caudal: ${(state.massFlowKgPerSec * 1000).toStringAsFixed(1)} g/s'
          ],
        );

      case ExplanationLevel.advanced:
        return ComponentExplanation(
          title: 'Análisis Termodinámico de la Compresión',
          phaseSummary: 'Evolución no isentrópica entre P1 = $pIn y P2 = $pOut con aumento neto de entropía.',
          telemetrySummary: telemetry,
          explanation:
              'Entalpía de aspiración h1 = ${(state.state1Suction.enthalpy / 1000).toStringAsFixed(1)} kJ/kg, entropía s1 = ${(state.state1Suction.entropy).toStringAsFixed(1)} J/(kg·K). Debido a la irreversibilidad (η_is = ${comp.isentropicEfficiency}), la entropía de descarga crece a s2 = ${(state.state2Discharge.entropy).toStringAsFixed(1)} J/(kg·K). Temperatura de descarga alcanzada: $tOut.',
          causeEffectText: 's2 > s1 (Generación de entropía por irreversibilidad térmica y mecánica).',
          keyVariables: [
            's1: ${state.state1Suction.entropy.toStringAsFixed(1)} J/(kg·K)',
            's2: ${state.state2Discharge.entropy.toStringAsFixed(1)} J/(kg·K)',
            'Δh_comp: ${((state.state2Discharge.enthalpy - state.state1Suction.enthalpy) / 1000).toStringAsFixed(1)} kJ/kg'
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
    final tOut = UnitFormatter.formatTemperature(state.state3Liquid.temperature, tUnit);
    final subcooling = '${state.subcoolingKelvin.toStringAsFixed(1)} K';
    final qCondKw = (state.heatingCapacityWatts / 1000.0).toStringAsFixed(2);

    final telemetry =
        'P_cond: $pCond | T_sat: $tCond\nT_ambiente: $tAmb | T_salida líquido: $tOut\nSubcooling (Subenfriamiento): $subcooling | Rechazo térmico: $qCondKw kW';

    switch (level) {
      case ExplanationLevel.basic:
        return ComponentExplanation(
          title: 'Condensador (Evacuador de calor)',
          phaseSummary: 'Transforma el gas caliente en líquido.',
          telemetrySummary: telemetry,
          explanation:
              'El condensador expulsa al exterior el calor extraído de la cámara más el calor del compresor. El refrigerante entra como gas caliente y sale como líquido a $tOut.',
          causeEffectText: 'Cede calor al aire ambiente ➔ El gas se condensa y pasa a estado líquido.',
          keyVariables: ['T_ambiente: $tAmb', 'Potencia rechazo: $qCondKw kW'],
        );

      case ExplanationLevel.intermediate:
        return ComponentExplanation(
          title: 'Condensador por Aire',
          phaseSummary: '3 zonas: Desrecalentamiento ➔ Condensación isóbara ➔ Subenfriamiento.',
          telemetrySummary: telemetry,
          explanation:
              'A una presión de $pCond, el vapor condensa exactamente a $tCond. Una vez licuado por completo, el condensador enfría el líquido $subcooling adicionales (subcooling) para evitar que se formen burbujas antes de la válvula.',
          causeEffectText: 'P_cond = f(T_ambiente, caudal aire, transferencia UA).',
          keyVariables: ['Subcooling: $subcooling', 'T_condensación: $tCond'],
        );

      case ExplanationLevel.technical:
        return ComponentExplanation(
          title: 'Condensador Frigorífico de Tiro Forzado',
          phaseSummary: 'Intercambio térmico sensible y latente con aire a contracorriente.',
          telemetrySummary: telemetry,
          explanation:
              'Calor total cedido: Qc = $qCondKw kW. Coeficiente global efectivo UA = ${(cond.effectiveUA).toStringAsFixed(0)} W/K. El salto térmico aire-condensación es de ${(state.condensingTemperatureK - cond.ambientTemperatureKelvin).toStringAsFixed(1)} K. Un subcooling de $subcooling garantiza líquido 100% denso en la línea de líquido.',
          causeEffectText: 'Qc = m_dot · (h_descarga - h_liquido) = UA · ΔT_ml.',
          keyVariables: [
            'Qc: $qCondKw kW',
            'UA efectivo: ${(cond.effectiveUA).toStringAsFixed(0)} W/K',
            'Ventilador: ${cond.fanOperational ? 'ACTIVO' : 'PARADO'}'
          ],
        );

      case ExplanationLevel.advanced:
        return ComponentExplanation(
          title: 'Termodinámica de la Condensación',
          phaseSummary: 'Evolución cuasi-isobárica desde vapor recalentado hasta líquido subenfriado.',
          telemetrySummary: telemetry,
          explanation:
              'Entalpía de entrada: ${(state.state2Discharge.enthalpy / 1000).toStringAsFixed(1)} kJ/kg. Entalpía de salida: ${(state.state3Liquid.enthalpy / 1000).toStringAsFixed(1)} kJ/kg. Pérdida de entalpía específica: ${((state.state2Discharge.enthalpy - state.state3Liquid.enthalpy) / 1000).toStringAsFixed(1)} kJ/kg transferida a la atmósfera.',
          causeEffectText: 'Δh_cond = Δh_desrec + h_fg + Δh_subcool.',
          keyVariables: [
            'h_descarga: ${(state.state2Discharge.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
            'h_salida: ${(state.state3Liquid.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
            'Calor latente h_fg: ${(state.refrigerant.saturatedVaporEnthalpy(state.condensingPressurePa) - state.refrigerant.saturatedLiquidEnthalpy(state.condensingPressurePa)) / 1000} kJ/kg'
          ],
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
    final tIn = UnitFormatter.formatTemperature(state.state3Liquid.temperature, tUnit);
    final tOut = UnitFormatter.formatTemperature(state.state4EvapInlet.temperature, tUnit);
    final vaporQuality = (state.state4EvapInlet.vaporQuality * 100).toStringAsFixed(1);

    final telemetry =
        'P_alta: $pIn | T_alta: $tIn\nP_baja: $pOut | T_baja: $tOut\nApertura: ${exp.openingPercent.toStringAsFixed(0)}% | Título de vapor generado (flash gas): $vaporQuality%';

    switch (level) {
      case ExplanationLevel.basic:
        return ComponentExplanation(
          title: 'Válvula de Expansión (El dosificador de frío)',
          phaseSummary: 'Convierte el líquido a alta presión en una mezcla fría a baja presión.',
          telemetrySummary: telemetry,
          explanation:
              'Funciona como el difusor de un aerosol. Al estrangular el paso del líquido, su presión cae repentinamente de $pIn a $pOut, provocando una caída drástica de su temperatura hasta $tOut.',
          causeEffectText: 'Estrangulamiento ➔ Caída brusca de presión (P ↓) y temperatura (T ↓).',
          keyVariables: ['Apertura: ${exp.openingPercent.toStringAsFixed(0)}%', 'T_fría: $tOut'],
        );

      case ExplanationLevel.intermediate:
        return ComponentExplanation(
          title: 'Dispositivo de Expansión Termostático',
          phaseSummary: 'Líquido subenfriado ➔ Mezcla bifásica líquido + vapor instantáneo (flash gas).',
          telemetrySummary: telemetry,
          explanation:
              'Durante la caída de presión, una parte del refrigerante ($vaporQuality%) se evapora instantáneamente (vapor flash). Este vapor absorbe energía del propio líquido remanente, enfriándolo hasta la temperatura de saturación de baja ($tOut).',
          causeEffectText: 'Apertura regula el caudal de inyección para mantener superheat constante.',
          keyVariables: ['Vapor flash: $vaporQuality%', 'ΔP válvula: ${UnitFormatter.formatPressure(state.condensingPressurePa - state.evaporatingPressurePa, pUnit)}'],
        );

      case ExplanationLevel.technical:
        return ComponentExplanation(
          title: 'Expansión Isoentálpica (Efecto Joule-Thomson)',
          phaseSummary: 'Proceso adiabático sin trabajo externo (h_entrada = h_salida).',
          telemetrySummary: telemetry,
          explanation:
              'No hay intercambio de calor ni trabajo mecánico (w = 0, q = 0), por lo que h3 = h4 = ${(state.state3Liquid.enthalpy / 1000).toStringAsFixed(1)} kJ/kg. El título de vapor resultante a la salida es x = ${(state.state4EvapInlet.vaporQuality).toStringAsFixed(3)}, iniciando la evaporación a $tOut.',
          causeEffectText: 'h_constante ➔ x = (h3 - hf) / hfg.',
          keyVariables: [
            'h_constante: ${(state.state3Liquid.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
            'Título x: ${(state.state4EvapInlet.vaporQuality).toStringAsFixed(3)}',
            'Superheat consigna: ${exp.targetSuperheatKelvin} K'
          ],
        );

      case ExplanationLevel.advanced:
        return ComponentExplanation(
          title: 'Termodinámica de la Expansión Irreversible',
          phaseSummary: 'Proceso de estrangulamiento irreversible con salto de entropía.',
          telemetrySummary: telemetry,
          explanation:
              'A pesar de ser isoentálpico, el estrangulamiento genera una gran destrucción de exergía por fricción interna y despresurización turbulenta: la entropía salta de ${(state.state3Liquid.entropy).toStringAsFixed(1)} a ${(state.state4EvapInlet.entropy).toStringAsFixed(1)} J/(kg·K).',
          causeEffectText: 'Δs_irrev = s4 - s3 > 0 (Pérdida de capacidad de trabajo útil).',
          keyVariables: [
            's_entrada: ${state.state3Liquid.entropy.toStringAsFixed(1)} J/(kg·K)',
            's_salida: ${state.state4EvapInlet.entropy.toStringAsFixed(1)} J/(kg·K)',
            'Δs generado: ${(state.state4EvapInlet.entropy - state.state3Liquid.entropy).toStringAsFixed(1)} J/(kg·K)'
          ],
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
    final tRoom = UnitFormatter.formatTemperature(evap.roomTemperatureKelvin, tUnit);
    final tOut = UnitFormatter.formatTemperature(state.state1Suction.temperature, tUnit);
    final superheat = '${state.superheatKelvin.toStringAsFixed(1)} K';
    final qEvapKw = (state.coolingCapacityWatts / 1000.0).toStringAsFixed(2);

    final telemetry =
        'P_evap: $pEvap | T_sat: $tEvap\nT_recinto: $tRoom | T_salida evaporador: $tOut\nSuperheat (Recalentamiento): $superheat | Potencia frigorífica: $qEvapKw kW';

    switch (level) {
      case ExplanationLevel.basic:
        return ComponentExplanation(
          title: 'Evaporador (El generador de frío)',
          phaseSummary: 'Absorbe calor del recinto y hierve el refrigerante.',
          telemetrySummary: telemetry,
          explanation:
              'Aquí es donde se produce el enfriamiento útil. El refrigerante entra muy frío ($tEvap) y absorbe el calor del aire de la cámara ($tRoom), evaporándose por completo hasta salir como gas a $tOut.',
          causeEffectText: 'Absorbe calor de la cámara ➔ El aire se enfría y el líquido hierve a gas.',
          keyVariables: ['T_cámara: $tRoom', 'Potencia útil: $qEvapKw kW'],
        );

      case ExplanationLevel.intermediate:
        return ComponentExplanation(
          title: 'Evaporador de Expansión Directa',
          phaseSummary: 'Mezcla bifásica ➔ Vaporización a temperatura constante ➔ Recalentamiento de seguridad.',
          telemetrySummary: telemetry,
          explanation:
              'A una presión de $pEvap, el refrigerante hierve a $tEvap. En el tramo final de la batería, todo el líquido se ha evaporado y el gas se calienta $superheat adicionales (superheat) para garantizar que jamás llegue una gota líquida al compresor.',
          causeEffectText: 'Superheat = T_salida - T_saturación = $tOut - $tEvap = $superheat.',
          keyVariables: ['Superheat: $superheat', 'Potencia frigorífica: $qEvapKw kW'],
        );

      case ExplanationLevel.technical:
        return ComponentExplanation(
          title: 'Evaporador Cúbico de Tiro Forzado',
          phaseSummary: 'Ebullición convectiva en el interior de tubos aletados con forzador axial.',
          telemetrySummary: telemetry,
          explanation:
              'Capacidad frigorífica neta: Qe = $qEvapKw kW con coeficiente UA efectivo de ${(evap.effectiveUA).toStringAsFixed(0)} W/K. El salto térmico DT1 (recinto - evaporación) es de ${(evap.roomTemperatureKelvin - state.evaporatingTemperatureK).toStringAsFixed(1)} K. El COP actual de la instalación es de ${state.cop.toStringAsFixed(2)}.',
          causeEffectText: 'Qe = m_dot · (h_salida - h_entrada) = ${(state.coolingCapacityWatts / 1000).toStringAsFixed(2)} kW.',
          keyVariables: [
            'COP: ${state.cop.toStringAsFixed(2)}',
            'Superheat: $superheat',
            'UA efectivo: ${(evap.effectiveUA).toStringAsFixed(0)} W/K'
          ],
        );

      case ExplanationLevel.advanced:
        return ComponentExplanation(
          title: 'Termodinámica de la Evaporación',
          phaseSummary: 'Proceso isobárico e isotérmico en zona bifásica seguido de recalentamiento sensible.',
          telemetrySummary: telemetry,
          explanation:
              'Entalpía de entrada: ${(state.state4EvapInlet.enthalpy / 1000).toStringAsFixed(1)} kJ/kg (x = ${(state.state4EvapInlet.vaporQuality).toStringAsFixed(2)}). Entalpía de salida: ${(state.state1Suction.enthalpy / 1000).toStringAsFixed(1)} kJ/kg. Salto entálpico útil: ${((state.state1Suction.enthalpy - state.state4EvapInlet.enthalpy) / 1000).toStringAsFixed(1)} kJ/kg.',
          causeEffectText: 'Efecto frigorífico q_o = h1 - h4 = ${((state.state1Suction.enthalpy - state.state4EvapInlet.enthalpy) / 1000).toStringAsFixed(1)} kJ/kg.',
          keyVariables: [
            'h_entrada: ${(state.state4EvapInlet.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
            'h_salida: ${(state.state1Suction.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
            'COP Carnot equivalente: ${(state.evaporatingTemperatureK / (state.condensingTemperatureK - state.evaporatingTemperatureK)).toStringAsFixed(2)}'
          ],
        );
    }
  }
}
