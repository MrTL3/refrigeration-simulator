import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../domain/components/base_component.dart';
import '../../domain/components/compressor_component.dart';
import '../../domain/components/condenser_component.dart';
import '../../domain/components/expansion_device_component.dart';
import '../../domain/components/evaporator_component.dart';
import '../../education/explanations/dynamic_explainer.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../../simulation/engine/simulation_state.dart';
import '../../visualization/models/installation_instrument.dart';
import '../theme/scada_colors.dart';

/// Panel lateral de información técnica, didáctica y de control para Desktop Web y pantallas grandes.
/// Permite examinar en detalle tanto instrumentos de medición como componentes frigoríficos
/// sin tapar el lienzo del circuito principal.
class DesktopInspectorPanel extends StatelessWidget {
  final BaseComponent? component;
  final InstallationInstrument? instrument;
  final SimulationState state;
  final SimulationEngine? engine;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final VoidCallback onClose;
  final ValueChanged<String>? onInspectWhy;

  const DesktopInspectorPanel({
    super.key,
    this.component,
    this.instrument,
    required this.state,
    this.engine,
    required this.pressureUnit,
    required this.temperatureUnit,
    required this.onClose,
    this.onInspectWhy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de título del panel
          _buildPanelHeader(),
          const Divider(height: 1, color: ScadaColors.border),

          // Contenido principal scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: instrument != null
                  ? _buildInstrumentDetails(instrument!)
                  : (component != null
                      ? _buildComponentDetails(component!)
                      : _buildDefaultOverview()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    final title = instrument != null
        ? 'INSTRUMENTO: ${instrument!.tag}'
        : (component != null ? 'COMPONENTE: ${component!.name}' : 'SUPERVISIÓN TÉCNICA');

    final icon = instrument != null
        ? Icons.speed
        : (component != null ? Icons.precision_manufacturing : Icons.analytics_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ScadaColors.infoBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: ScadaColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: ScadaColors.textMuted),
            tooltip: 'Cerrar panel lateral',
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VISTA DE INSTRUMENTO SELECCIONADO
  // ==========================================
  Widget _buildInstrumentDetails(InstallationInstrument inst) {
    final reading = inst.getReading(state, pressureUnit, temperatureUnit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta de lectura principal
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ScadaColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: reading.statusColor.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    inst.tag,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ScadaColors.cyanAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: reading.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: reading.statusColor),
                      ),
                      child: Text(
                        reading.statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: reading.statusColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reading.primaryValue,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: ScadaColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (reading.secondaryValue.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reading.secondaryValue,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: ScadaColors.infoBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Información de ubicación y función
        _buildInfoTile('Ubicación Física', inst.physicalLocation, Icons.place_outlined),
        const SizedBox(height: 8),
        _buildInfoTile('Función Técnica', inst.technicalPurpose, Icons.engineering_outlined),
        const SizedBox(height: 8),
        _buildInfoTile('Estado del Refrigerante', reading.fluidState, Icons.water_drop_outlined),
        const SizedBox(height: 12),

        // Detalles cuantitativos
        const Text(
          'PARÁMETROS ANALÍTICOS (SOLVER):',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textSecondary),
        ),
        const SizedBox(height: 6),
        ...reading.technicalDetails.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 12, color: ScadaColors.runningGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      detail,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: ScadaColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),

        const SizedBox(height: 16),
        // Botón explicador pedagógico
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onInspectWhy?.call(inst.tag),
            icon: const Icon(Icons.school, size: 16),
            label: const Text('¿POR QUÉ MARCA ESTE VALOR?'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.infoBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VISTA DE COMPONENTE SELECCIONADO
  // ==========================================
  Widget _buildComponentDetails(BaseComponent comp) {
    final circuit = state.circuit;
    final isRunning = state.isRunning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado y Refrigerante
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ScadaColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      comp.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? ScadaColors.runningGreen.withValues(alpha: 0.15)
                          : ScadaColors.textMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isRunning ? ScadaColors.runningGreen : ScadaColors.textMuted,
                      ),
                    ),
                    child: Text(
                      isRunning ? 'EN SERVICIO' : 'PARADO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isRunning ? ScadaColors.runningGreen : ScadaColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Refrigerante de trabajo:', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  const Text('R-134a (HFC)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.cyanAccent)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Valores de Puertos (Entrada y Salida)
        const Text('CONDICIONES DE FLUIDO EN PUERTOS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textSecondary)),
        const SizedBox(height: 6),
        if (comp is CompressorComponent) ...[
          _buildPortRow('Aspiración (Entrada):', state.state1Suction.pressure, state.state1Suction.temperature, 'Vapor Sobrecalentado'),
          const SizedBox(height: 4),
          _buildPortRow('Descarga (Salida):', state.state2Discharge.pressure, state.state2Discharge.temperature, 'Gas Caliente'),
        ] else if (comp is CondenserComponent) ...[
          _buildPortRow('Entrada Culata:', state.state2Discharge.pressure, state.state2Discharge.temperature, 'Vapor Caliente'),
          const SizedBox(height: 4),
          _buildPortRow('Salida Calderín:', state.state3Liquid.pressure, state.state3Liquid.temperature, 'Líquido Subenfriado'),
        ] else if (comp is ExpansionDeviceComponent) ...[
          _buildPortRow('Entrada Líquido:', state.state3Liquid.pressure, state.state3Liquid.temperature, 'Líquido Alta'),
          const SizedBox(height: 4),
          _buildPortRow('Salida Inyección:', state.state4EvapInlet.pressure, state.state4EvapInlet.temperature, 'Mezcla Bifásica (x=${(state.state4EvapInlet.vaporQuality * 100).toStringAsFixed(0)}%)'),
        ] else if (comp is EvaporatorComponent) ...[
          _buildPortRow('Entrada Inyección:', state.state4EvapInlet.pressure, state.state4EvapInlet.temperature, 'Bifásico en Ebullición'),
          const SizedBox(height: 4),
          _buildPortRow('Salida Aspiración:', state.state1Suction.pressure, state.state1Suction.temperature, 'Vapor Sobrecalentado'),
        ],

        const SizedBox(height: 12),
        // Variables Termodinámicas y Eléctricas Específicas
        const Text('MÉTRICAS ESPECÍFICAS DE OPERACIÓN:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textSecondary)),
        const SizedBox(height: 6),
        if (comp is CompressorComponent) ...[
          _buildMetricRow('Régimen de Giro:', '${state.dynamicRpm.toStringAsFixed(0)} RPM'),
          _buildMetricRow('Potencia Eléctrica:', '${(state.electricalPowerWatts / 1000).toStringAsFixed(2)} kW'),
          _buildMetricRow('Intensidad Motor:', '${state.electricalState.currentAmps.toStringAsFixed(1)} A'),
          _buildMetricRow('Caudal Másico:', '${(state.massFlowKgPerSec * 3600).toStringAsFixed(1)} kg/h'),
          _buildMetricRow('Rendimiento Volumétrico:', '${((circuit.compressor?.volumetricEfficiency ?? 0.75) * 100).toStringAsFixed(1)} %'),
          if (engine != null) ...[
            const SizedBox(height: 8),
            Text('Control de Velocidad: ${state.dynamicRpm.toInt()} RPM', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
            Slider(
              value: state.dynamicRpm.clamp(500.0, 4500.0),
              min: 500.0,
              max: 4500.0,
              divisions: 20,
              onChanged: (val) => engine!.setCompressorRpm(val),
            ),
          ],
        ] else if (comp is CondenserComponent) ...[
          _buildMetricRow('Calor Disipado (Q_c):', '${(state.heatingCapacityWatts / 1000).toStringAsFixed(2)} kW'),
          _buildMetricRow('Subenfriamiento (SC):', '${state.subcoolingKelvin.toStringAsFixed(1)} K'),
          _buildMetricRow('T_condensación Sat:', '${(state.condensingTemperatureK - 273.15).toStringAsFixed(1)} °C'),
          _buildMetricRow('Temperatura Exterior:', '${((state.circuit.condenser?.ambientTemperatureKelvin ?? 298.15) - 273.15).toStringAsFixed(1)} °C'),
        ] else if (comp is ExpansionDeviceComponent) ...[
          _buildMetricRow('Recalentamiento Útil (SH):', '${state.superheatKelvin.toStringAsFixed(1)} K'),
          _buildMetricRow('Modo de Control:', comp.isAutomatic ? 'AUTOMÁTICA (Bulbo)' : 'MANUAL'),
          _buildMetricRow('Apertura de Válvula:', '${comp.openingPercent.toStringAsFixed(0)} %'),
          if (engine != null && !comp.isAutomatic) ...[
            const SizedBox(height: 8),
            Text('Apertura Manual: ${comp.openingPercent.toInt()}%', style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary)),
            Slider(
              value: comp.openingPercent.clamp(5.0, 100.0),
              min: 5.0,
              max: 100.0,
              divisions: 19,
              onChanged: (val) => engine!.setValveOpening(val),
            ),
          ],
        ] else if (comp is EvaporatorComponent) ...[
          _buildMetricRow('Potencia Frigorífica (Q_e):', '${(state.coolingCapacityWatts / 1000).toStringAsFixed(2)} kW'),
          _buildMetricRow('Temperatura de Cámara:', '${(state.coldRoom.temperatureKelvin - 273.15).toStringAsFixed(1)} °C'),
          _buildMetricRow('T_evaporación Sat:', '${(state.evaporatingTemperatureK - 273.15).toStringAsFixed(1)} °C'),
          _buildMetricRow('COP de Instalación:', state.cop.toStringAsFixed(2)),
        ],

        const SizedBox(height: 14),
        // Explicación didáctica causal
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ScadaColors.infoBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ScadaColors.infoBlue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: ScadaColors.warningAmber),
                  SizedBox(width: 6),
                  Text('COMPORTAMIENTO FÍSICO ACTUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.infoBlue)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DynamicExplainer.explain(
                  component: comp,
                  state: state,
                  level: ExplanationLevel.intermediate,
                ).explanation,
                style: const TextStyle(fontSize: 11, color: ScadaColors.textPrimary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VISTA RESUMEN GENERAL (SIN SELECCIÓN)
  // ==========================================
  Widget _buildDefaultOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INSTALACIÓN FRIGORÍFICA R-134a',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.cyanAccent),
        ),
        const SizedBox(height: 4),
        const Text(
          'Haz clic sobre cualquier componente o instrumento de la instalación para inspeccionar sus variables en tiempo real.',
          style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary),
        ),
        const SizedBox(height: 14),
        _buildMetricRow('Estado General:', state.isRunning ? 'EN FUNCIONAMIENTO' : 'DETENIDA'),
        _buildMetricRow('P_baja (Evaporación):', UnitFormatter.formatPressure(state.evaporatingPressurePa, pressureUnit)),
        _buildMetricRow('P_alta (Condensación):', UnitFormatter.formatPressure(state.condensingPressurePa, pressureUnit)),
        _buildMetricRow('Recalentamiento (SH):', '${state.superheatKelvin.toStringAsFixed(1)} K'),
        _buildMetricRow('Subenfriamiento (SC):', '${state.subcoolingKelvin.toStringAsFixed(1)} K'),
        _buildMetricRow('Potencia Frigorífica:', '${(state.coolingCapacityWatts / 1000).toStringAsFixed(2)} kW'),
        _buildMetricRow('Potencia Eléctrica:', '${(state.electricalPowerWatts / 1000).toStringAsFixed(2)} kW'),
        _buildMetricRow('Eficiencia (COP):', state.cop.toStringAsFixed(2)),
        _buildMetricRow('Temp. Cámara Frigorífica:', '${(state.coldRoom.temperatureKelvin - 273.15).toStringAsFixed(1)} °C'),
      ],
    );
  }

  Widget _buildInfoTile(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ScadaColors.infoBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textSecondary)),
                const SizedBox(height: 2),
                Text(content, style: const TextStyle(fontSize: 11, color: ScadaColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortRow(String label, double pPa, double tK, String phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 3,
            child: Text(
              '${UnitFormatter.formatPressure(pPa, pressureUnit)} | ${UnitFormatter.formatTemperature(tK, temperatureUnit)} ($phase)',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: ScadaColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: ScadaColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
