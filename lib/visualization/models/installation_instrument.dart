import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';

/// Tipo de instrumento físico montado en la instalación frigorífica industrial.
enum InstrumentType {
  lowPressureGauge('Manómetro de Baja Presión (Po)', Icons.speed, ScadaColors.lowPressureSuction),
  highPressureGauge('Manómetro de Alta Presión (Pk)', Icons.speed, ScadaColors.highPressureDischarge),
  dischargeThermometer('Termómetro de Descarga de Culata', Icons.thermostat, ScadaColors.highPressureDischarge),
  liquidThermometer('Termómetro de Línea de Líquido', Icons.thermostat, ScadaColors.highPressureLiquid),
  evaporatorInletThermometer('Termómetro de Entrada a Evaporador', Icons.thermostat, ScadaColors.cyanAccent),
  suctionThermometer('Termómetro de Aspiración / Bulbo TXV', Icons.thermostat, ScadaColors.infoBlue),
  coldRoomThermometer('Sonda Ambiente Cámara Frigorífica', Icons.kitchen, ScadaColors.runningGreen),
  ambientThermometer('Sonda Ambiente Sala de Máquinas', Icons.wb_sunny_outlined, ScadaColors.warningAmber),
  dualPressureSwitch('Presostato Combinado Alta/Baja (KP15)', Icons.toggle_on, ScadaColors.textPrimary),
  massFlowMeter('Caudalímetro Másico de Refrigerante', Icons.waves, ScadaColors.cyanAccent),
  sightGlass('Visor de Líquido con Indicador de Humedad', Icons.remove_red_eye_outlined, ScadaColors.highPressureLiquid),
  oilSightGlass('Mirilla de Nivel de Aceite en Cárter', Icons.opacity, ScadaColors.warningAmber),
  electricalClamp('Pinza Amperimétrica / Vatímetro', Icons.electrical_services, ScadaColors.warningAmber),
  vacuumGauge('Vacuómetro Electrónico Pirani', Icons.compress, ScadaColors.infoBlue);

  final String label;
  final IconData icon;
  final Color primaryColor;
  const InstrumentType(this.label, this.icon, this.primaryColor);
}

/// Representa un instrumento o punto de medición físico ubicado en la planta 3D.
class InstallationInstrument {
  final String id;
  final InstrumentType type;
  final String tag;
  final Offset worldPosition;
  final double hitRadius;
  final String physicalLocation;
  final String technicalPurpose;

  const InstallationInstrument({
    required this.id,
    required this.type,
    required this.tag,
    required this.worldPosition,
    this.hitRadius = 24.0,
    required this.physicalLocation,
    required this.technicalPurpose,
  });

  /// Crea una copia del instrumento desplazado por un delta espacial
  InstallationInstrument withOffset(Offset delta) {
    if (delta == Offset.zero) return this;
    return InstallationInstrument(
      id: id,
      type: type,
      tag: tag,
      worldPosition: worldPosition + delta,
      hitRadius: hitRadius,
      physicalLocation: physicalLocation,
      technicalPurpose: technicalPurpose,
    );
  }

  /// Lista oficial de los 14 instrumentos físicos integrados in situ en la instalación industrial.
  static List<InstallationInstrument> defaultInstallation() {
    return const [
      InstallationInstrument(
        id: 'gauge_po',
        type: InstrumentType.lowPressureGauge,
        tag: 'PI-01',
        worldPosition: Offset(615, 465),
        hitRadius: 28.0,
        physicalLocation: 'Línea de aspiración / Válvula de servicio del compresor',
        technicalPurpose: 'Mide la presión de evaporación del refrigerante y permite deducir la temperatura de saturación To.',
      ),
      InstallationInstrument(
        id: 'gauge_pk',
        type: InstrumentType.highPressureGauge,
        tag: 'PI-02',
        worldPosition: Offset(835, 465),
        hitRadius: 28.0,
        physicalLocation: 'Línea de descarga / Culata del compresor',
        technicalPurpose: 'Mide la presión de condensación y permite vigilar la temperatura de saturación Tk y sobrepresiones.',
      ),
      InstallationInstrument(
        id: 'thermo_discharge',
        type: InstrumentType.dischargeThermometer,
        tag: 'TI-01',
        worldPosition: Offset(765, 410),
        hitRadius: 22.0,
        physicalLocation: 'Tubería de cobre de descarga (salida de culata)',
        technicalPurpose: 'Vigila la temperatura máxima del ciclo. Si supera los 105-115 °C degrada el aceite lubricante.',
      ),
      InstallationInstrument(
        id: 'thermo_liquid',
        type: InstrumentType.liquidThermometer,
        tag: 'TI-02',
        worldPosition: Offset(1020, 570),
        hitRadius: 22.0,
        physicalLocation: 'Tubería de líquido a la salida del calderín y filtro',
        technicalPurpose: 'Permite calcular el Subenfriamiento (SC = Tk - T_liq). Garantiza que el fluido llegue 100% líquido a la TXV.',
      ),
      InstallationInstrument(
        id: 'thermo_evap',
        type: InstrumentType.evaporatorInletThermometer,
        tag: 'TI-03',
        worldPosition: Offset(430, 360),
        hitRadius: 22.0,
        physicalLocation: 'Distribuidor Venturi a la entrada del evaporador',
        technicalPurpose: 'Mide la temperatura de ebullición del refrigerante tras la despresurización isentálpica en la TXV.',
      ),
      InstallationInstrument(
        id: 'thermo_suction',
        type: InstrumentType.suctionThermometer,
        tag: 'TI-04',
        worldPosition: Offset(490, 210),
        hitRadius: 22.0,
        physicalLocation: 'Tubería de aspiración exterior en el punto del bulbo sensor',
        technicalPurpose: 'Permite calcular el Recalentamiento útil (SH = T_asp - To). Protege al compresor de aspirar gotas de líquido.',
      ),
      InstallationInstrument(
        id: 'thermo_cold_room',
        type: InstrumentType.coldRoomThermometer,
        tag: 'TT-01',
        worldPosition: Offset(260, 92),
        hitRadius: 26.0,
        physicalLocation: 'Dintel de la puerta de la cámara / Interior de la cámara',
        technicalPurpose: 'Mide la temperatura del aire dentro del recinto refrigerado gobernada por el termostato de control.',
      ),
      InstallationInstrument(
        id: 'thermo_ambient',
        type: InstrumentType.ambientThermometer,
        tag: 'TT-02',
        worldPosition: Offset(1120, 75),
        hitRadius: 24.0,
        physicalLocation: 'Aire exterior adyacente a la batería del condensador',
        technicalPurpose: 'Indica la temperatura del foco caliente disipador para evaluar la eficiencia térmica del ciclo.',
      ),
      InstallationInstrument(
        id: 'pressostat_kp15',
        type: InstrumentType.dualPressureSwitch,
        tag: 'PS-01',
        worldPosition: Offset(895, 560),
        hitRadius: 26.0,
        physicalLocation: 'Bancada central con tomas capilares a alta y baja',
        technicalPurpose: 'Dispositivo electromecánico de seguridad que corta la maniobra ante alta presión excesiva o fuga de gas.',
      ),
      InstallationInstrument(
        id: 'flowmeter',
        type: InstrumentType.massFlowMeter,
        tag: 'FI-01',
        worldPosition: Offset(930, 600),
        hitRadius: 24.0,
        physicalLocation: 'Línea de líquido entre visor y TXV',
        technicalPurpose: 'Mide la masa de refrigerante que circula por segundo en el circuito (g/s o kg/h).',
      ),
      InstallationInstrument(
        id: 'sight_glass',
        type: InstrumentType.sightGlass,
        tag: 'SG-01',
        worldPosition: Offset(830, 600),
        hitRadius: 22.0,
        physicalLocation: 'Línea de líquido antes de la válvula de expansión',
        technicalPurpose: 'Permite al frigorista verificar visualmente si hay burbujas de vapor flash (falta de carga) y humedad.',
      ),
      InstallationInstrument(
        id: 'oil_sight_glass',
        type: InstrumentType.oilSightGlass,
        tag: 'LG-01',
        worldPosition: Offset(675, 625),
        hitRadius: 22.0,
        physicalLocation: 'Tercio inferior del cárter del compresor',
        technicalPurpose: 'Permite comprobar la existencia del nivel óptimo de aceite lubricante para los cojinetes y el pistón.',
      ),
      InstallationInstrument(
        id: 'electrical_clamp',
        type: InstrumentType.electricalClamp,
        tag: 'EM-01',
        worldPosition: Offset(770, 670),
        hitRadius: 24.0,
        physicalLocation: 'Caja de bornes del motor del compresor',
        technicalPurpose: 'Mide la intensidad absorbida (A) y potencia activa (kW) para calcular el consumo y factor de potencia.',
      ),
      InstallationInstrument(
        id: 'vacuum_gauge',
        type: InstrumentType.vacuumGauge,
        tag: 'VG-01',
        worldPosition: Offset(580, 560),
        hitRadius: 22.0,
        physicalLocation: 'Toma de aspiración auxiliar para bomba de vacío',
        technicalPurpose: 'Mide presiones inferiores a 1 mbar durante procesos de deshidratación y prueba de vacío.',
      ),
    ];
  }

  /// Obtiene los datos en tiempo real calculados por el solver físico para este instrumento.
  InstrumentReading getReading(SimulationState state, PressureUnit pUnit, TemperatureUnit tUnit) {
    switch (type) {
      case InstrumentType.lowPressureGauge:
        final pPa = state.evaporatingPressurePa;
        final pVal = pUnit.fromPascals(pPa);
        final tSatK = state.evaporatingTemperatureK;
        final tSatVal = tUnit.fromKelvin(tSatK);
        return InstrumentReading(
          instrument: this,
          primaryValue: '${pVal.toStringAsFixed(2)} ${pUnit.symbol}',
          secondaryValue: 'T_sat: ${tSatVal.toStringAsFixed(1)} ${tUnit.symbol}',
          statusText: state.isRunning ? 'PRESIÓN DE EVAPORACIÓN ESTABLE' : 'PRESIÓN IGUALADA (PARADA)',
          fluidState: 'Mezcla Saturada Líquido-Vapor en Evaporador',
          technicalDetails: [
            'Presión absoluta: ${(pPa / 1e5).toStringAsFixed(3)} bar',
            'T_saturación teórica: ${(tSatK - 273.15).toStringAsFixed(1)} °C',
            'Punto de toma: Válvula de servicio de aspiración del compresor',
          ],
        );

      case InstrumentType.highPressureGauge:
        final pPa = state.condensingPressurePa;
        final pVal = pUnit.fromPascals(pPa);
        final tSatK = state.condensingTemperatureK;
        final tSatVal = tUnit.fromKelvin(tSatK);
        final isAlarm = pPa > 16e5;
        return InstrumentReading(
          instrument: this,
          primaryValue: '${pVal.toStringAsFixed(2)} ${pUnit.symbol}',
          secondaryValue: 'T_sat: ${tSatVal.toStringAsFixed(1)} ${tUnit.symbol}',
          statusText: isAlarm ? 'ALERTA: SOBREPRESIÓN DE CONDENSACIÓN' : 'PRESIÓN DE CONDENSACIÓN NOMINAL',
          statusColor: isAlarm ? ScadaColors.dangerRed : ScadaColors.runningGreen,
          fluidState: 'Vapor en proceso de condensación a líquido',
          technicalDetails: [
            'Presión absoluta: ${(pPa / 1e5).toStringAsFixed(3)} bar',
            'T_condensación: ${(tSatK - 273.15).toStringAsFixed(1)} °C',
            'Punto de toma: Válvula de descarga de culata del compresor',
          ],
        );

      case InstrumentType.dischargeThermometer:
        final tK = state.state2Discharge.temperature;
        final tVal = tUnit.fromKelvin(tK);
        final tC = tK - 273.15;
        return InstrumentReading(
          instrument: this,
          primaryValue: '${tVal.toStringAsFixed(1)} ${tUnit.symbol}',
          secondaryValue: 'Sobrecalentamiento de descarga: ${(tC - (state.condensingTemperatureK - 273.15)).toStringAsFixed(1)} K',
          statusText: tC > 105.0 ? 'PELIGRO: DEGRADACIÓN TÉRMICA DE ACEITE' : 'TEMPERATURA DE DESCARGA NORMAL',
          statusColor: tC > 105.0 ? ScadaColors.dangerRed : ScadaColors.highPressureDischarge,
          fluidState: 'Vapor sobrecalentado a alta presión y alta temperatura',
          technicalDetails: [
            'Temperatura culata: ${tC.toStringAsFixed(1)} °C',
            'Entalpía descarga: ${(state.state2Discharge.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
            'Entropía descarga: ${(state.state2Discharge.entropy / 1000).toStringAsFixed(3)} kJ/(kg·K)',
          ],
        );

      case InstrumentType.liquidThermometer:
        final tK = state.state3Liquid.temperature;
        final tVal = tUnit.fromKelvin(tK);
        return InstrumentReading(
          instrument: this,
          primaryValue: '${tVal.toStringAsFixed(1)} ${tUnit.symbol}',
          secondaryValue: 'Subcooling (SC): ${state.subcoolingKelvin.toStringAsFixed(1)} K',
          statusText: state.subcoolingKelvin >= 3.0 ? 'LÍQUIDO 100% SUBENFRIADO' : 'SUBENFRIAMIENTO BAJO (< 3K)',
          statusColor: state.subcoolingKelvin >= 3.0 ? ScadaColors.runningGreen : ScadaColors.warningAmber,
          fluidState: 'Líquido comprimido subenfriado antes de la TXV',
          technicalDetails: [
            'Temperatura líquido: ${(tK - 273.15).toStringAsFixed(1)} °C',
            'Subcooling útil: ${state.subcoolingKelvin.toStringAsFixed(1)} K',
            'Previene formación prematura de vapor flash en tubería',
          ],
        );

      case InstrumentType.evaporatorInletThermometer:
        final tK = state.state4EvapInlet.temperature;
        final tVal = tUnit.fromKelvin(tK);
        return InstrumentReading(
          instrument: this,
          primaryValue: '${tVal.toStringAsFixed(1)} ${tUnit.symbol}',
          secondaryValue: 'Calidad vapor (x): ${(state.state4EvapInlet.vaporQuality * 100).toStringAsFixed(0)} %',
          statusText: 'EXPANSIÓN ISENTÁLPICA EFECTUADA',
          fluidState: 'Mezcla bifásica líquido-vapor a baja presión',
          technicalDetails: [
            'Temperatura mezcla: ${(tK - 273.15).toStringAsFixed(1)} °C',
            'Fracción de vapor flash: ${(state.state4EvapInlet.vaporQuality * 100).toStringAsFixed(1)} %',
            'Entalpía entrada: ${(state.state4EvapInlet.enthalpy / 1000).toStringAsFixed(1)} kJ/kg',
          ],
        );

      case InstrumentType.suctionThermometer:
        final tK = state.state1Suction.temperature;
        final tVal = tUnit.fromKelvin(tK);
        final sh = state.superheatKelvin;
        final isRisk = sh < 4.0 && state.isRunning;
        return InstrumentReading(
          instrument: this,
          primaryValue: '${tVal.toStringAsFixed(1)} ${tUnit.symbol}',
          secondaryValue: 'Superheat (SH): ${sh.toStringAsFixed(1)} K',
          statusText: isRisk ? '¡PELIGRO!: RIESGO DE GOLPE DE LÍQUIDO (SH < 4K)' : 'RECALENTAMIENTO ÚTIL CORRECTO',
          statusColor: isRisk ? ScadaColors.dangerRed : ScadaColors.runningGreen,
          fluidState: 'Vapor recalentado aspirado por el compresor',
          technicalDetails: [
            'Temperatura gas aspirado: ${(tK - 273.15).toStringAsFixed(1)} °C',
            'Superheat útil: ${sh.toStringAsFixed(1)} K',
            'Ubicación del bulbo palpador de la TXV',
          ],
        );

      case InstrumentType.coldRoomThermometer:
        final tK = state.coldRoom.temperatureKelvin;
        final tVal = tUnit.fromKelvin(tK);
        final setpointC = state.thermostat.setpointCelsius;
        final tC = tK - 273.15;
        return InstrumentReading(
          instrument: this,
          primaryValue: '${tVal.toStringAsFixed(1)} ${tUnit.symbol}',
          secondaryValue: 'Consigna termostato: ${setpointC.toStringAsFixed(1)} °C',
          statusText: (tC <= setpointC) ? 'CÁMARA EN TEMPERATURA DE RÉGIMEN' : 'CÁMARA DEMANDANDO FRÍO',
          statusColor: (tC <= setpointC) ? ScadaColors.runningGreen : ScadaColors.infoBlue,
          fluidState: 'Aire interior de cámara en convección forzada',
          technicalDetails: [
            'Temperatura aire cámara: ${tC.toStringAsFixed(1)} °C',
            'Carga térmica interna: ${state.coldRoom.internalHeatLoadWatts.toInt()} W',
            'Capacidad frigorífica Qe: ${(state.coolingCapacityWatts / 1000).toStringAsFixed(2)} kW',
          ],
        );

      case InstrumentType.ambientThermometer:
        final tK = state.circuit.condenser?.ambientTemperatureKelvin ?? 298.15;
        final tVal = tUnit.fromKelvin(tK);
        return InstrumentReading(
          instrument: this,
          primaryValue: '${tVal.toStringAsFixed(1)} ${tUnit.symbol}',
          secondaryValue: 'Diferencial aire condensador: ${state.condenserAirFlow.deltaTAirKelvin.toStringAsFixed(1)} K',
          statusText: 'AIRE EXTERIOR DISPONIBLE PARA ENFRIAMIENTO',
          fluidState: 'Aire ambiental sala de máquinas / exterior',
          technicalDetails: [
            'Temperatura exterior: ${(tK - 273.15).toStringAsFixed(1)} °C',
            'Caudal de aire condensador: ${(state.condenserAirFlow.massFlowKgPerSec).toStringAsFixed(2)} kg/s',
            'Calor disipado Qc: ${(state.heatingCapacityWatts / 1000).toStringAsFixed(2)} kW',
          ],
        );

      case InstrumentType.dualPressureSwitch:
        final poBar = state.evaporatingPressurePa / 1e5;
        final pkBar = state.condensingPressurePa / 1e5;
        final isHpTripped = pkBar > 18.0;
        final isLpTripped = poBar < 0.5 && state.isRunning;
        return InstrumentReading(
          instrument: this,
          primaryValue: 'LP: ${poBar.toStringAsFixed(1)} / HP: ${pkBar.toStringAsFixed(1)} bar',
          secondaryValue: isHpTripped ? 'DISPARADO POR ALTA' : isLpTripped ? 'DISPARADO POR BAJA' : 'CIRCUITO DE SEGURIDAD CERRADO (OK)',
          statusText: (isHpTripped || isLpTripped) ? 'CONTACTO ABIERTO (BLOQUEO)' : 'CONTACTO CERRADO (PERMISIVO ON)',
          statusColor: (isHpTripped || isLpTripped) ? ScadaColors.dangerRed : ScadaColors.runningGreen,
          fluidState: 'Monitoreo electromecánico de presiones extremas',
          technicalDetails: [
            'Fuelle de baja (LP): Corte a 1.2 bar / Diferencial 1.0 bar',
            'Fuelle de alta (HP): Corte a 16.5 bar / Rearme manual',
            'Protege el motor contra sobrepresión y congelación',
          ],
        );

      case InstrumentType.massFlowMeter:
        final mDotGs = state.massFlowKgPerSec * 1000.0;
        final mDotKgh = state.massFlowKgPerSec * 3600.0;
        return InstrumentReading(
          instrument: this,
          primaryValue: '${mDotGs.toStringAsFixed(1)} g/s',
          secondaryValue: '${mDotKgh.toStringAsFixed(1)} kg/h',
          statusText: state.isRunning ? 'CIRCULACIÓN CONTINUA DE R-134a' : 'CAUDAL NULO (PARADA)',
          statusColor: state.isRunning ? ScadaColors.cyanAccent : ScadaColors.textMuted,
          fluidState: 'Flujo másico estacionario en línea de líquido',
          technicalDetails: [
            'Caudal instantáneo: ${mDotGs.toStringAsFixed(2)} g/s',
            'Caudal horario: ${mDotKgh.toStringAsFixed(1)} kg/h',
            'Gobernado por RPM del compresor y apertura de TXV',
          ],
        );

      case InstrumentType.sightGlass:
        final sc = state.subcoolingKelvin;
        final hasFlashGas = sc < 1.5 && state.isRunning;
        return InstrumentReading(
          instrument: this,
          primaryValue: hasFlashGas ? 'BURBUJEO DETECTADO' : 'COLUMNA LLENA 100%',
          secondaryValue: 'Indicador corona: VERDE (CIRCUITO SECO)',
          statusText: hasFlashGas ? 'ADVERTENCIA: FALTA DE SUBENFRIAMIENTO / CARGA' : 'LÍQUIDO ÓPTIMO ANTES DE TXV',
          statusColor: hasFlashGas ? ScadaColors.warningAmber : ScadaColors.runningGreen,
          fluidState: hasFlashGas ? 'Presencia de burbujas de gas flash' : 'Líquido continuo sin cavitación',
          technicalDetails: [
            'Subcooling medido: ${sc.toStringAsFixed(1)} K',
            'Corona química indicadora de humedad en aceite/gas',
            'Inspección visual directa recomendada para técnico',
          ],
        );

      case InstrumentType.oilSightGlass:
        return InstrumentReading(
          instrument: this,
          primaryValue: 'NIVEL ACEITE: 1/2 VISOR',
          secondaryValue: 'Color: ÁMBAR TRANSPARENTE',
          statusText: 'NIVEL Y LUBRICACIÓN CORRECTOS',
          statusColor: ScadaColors.runningGreen,
          fluidState: 'Aceite polioléster (POE) mezclado con refrigerante',
          technicalDetails: [
            'Ubicación: Tercio inferior del cárter del compresor',
            'Garantiza lubricación del cigüeñal y pistón',
            'Un visor espumoso indica presencia excesiva de líquido',
          ],
        );

      case InstrumentType.electricalClamp:
        final amps = state.electricalState.currentAmps;
        final kw = state.electricalPowerWatts / 1000.0;
        final pf = state.electricalState.powerFactor;
        return InstrumentReading(
          instrument: this,
          primaryValue: '${amps.toStringAsFixed(1)} A',
          secondaryValue: '${kw.toStringAsFixed(2)} kW (cos φ: ${pf.toStringAsFixed(2)})',
          statusText: state.isRunning ? 'MOTOR ABSORBIENDO POTENCIA NOMINAL' : 'CONSUMO CERO (PARADA)',
          statusColor: ScadaColors.warningAmber,
          fluidState: 'Red trifásica 400V 50Hz / Inverter',
          technicalDetails: [
            'Corriente de línea: ${amps.toStringAsFixed(2)} A',
            'Potencia activa consumida: ${kw.toStringAsFixed(2)} kW',
            'Factor de potencia (cos φ): ${pf.toStringAsFixed(2)}',
          ],
        );

      case InstrumentType.vacuumGauge:
        final isVac = state.vacuumState.isPumpRunning || state.vacuumState.pressurePa < 95000.0;
        final pMbar = state.vacuumState.pressureMbar;
        final stageStr = state.vacuumState.pressurePa > 2300.0
            ? 'Evacuación de no condensables'
            : (state.vacuumState.residualWaterGrams > 0.005
                ? 'Ebullición de humedad'
                : (state.vacuumState.isDeepVacuumReached ? 'Vacío profundo' : 'Evacuación final'));
        return InstrumentReading(
          instrument: this,
          primaryValue: isVac ? '${pMbar.toStringAsFixed(1)} mbar' : 'ATMOSFÉRICA',
          secondaryValue: isVac ? 'Etapa: $stageStr' : 'No conectado a bomba de vacío',
          statusText: isVac ? 'PROCESO DE EVACUACIÓN EN CURSO' : 'CIRCUITO PRESURIZADO CON R-134a',
          statusColor: isVac ? ScadaColors.cyanAccent : ScadaColors.textMuted,
          fluidState: isVac ? 'Vapor residual de aire y humedad evaporando' : 'Carga completa de refrigerante',
          technicalDetails: [
            'Presión absoluta: ${pMbar.toStringAsFixed(2)} mbar (${state.vacuumState.pressureMicrons.toStringAsFixed(0)} µmHg)',
            'Evapora humedad si P < 23.4 mbar a 20 °C',
            'Toma en válvula de servicio de aspiración',
          ],
        );
    }
  }
}

/// DTO con los datos formateados de la lectura de un instrumento en un instante t.
class InstrumentReading {
  final InstallationInstrument instrument;
  final String primaryValue;
  final String secondaryValue;
  final String statusText;
  final Color statusColor;
  final String fluidState;
  final List<String> technicalDetails;

  const InstrumentReading({
    required this.instrument,
    required this.primaryValue,
    required this.secondaryValue,
    required this.statusText,
    this.statusColor = ScadaColors.runningGreen,
    required this.fluidState,
    required this.technicalDetails,
  });
}
