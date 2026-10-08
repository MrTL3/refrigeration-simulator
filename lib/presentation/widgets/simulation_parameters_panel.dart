import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../../simulation/engine/simulation_state.dart';
import '../theme/scada_colors.dart';

/// Panel de control y supervisión en tiempo real de actuadores físicos y parámetros.
/// Permite modificar variables existentes en tiempo real y observar la respuesta del solver.
class SimulationParametersPanel extends StatefulWidget {
  final SimulationEngine engine;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final VoidCallback? onClose;
  final bool isSidebar;

  const SimulationParametersPanel({
    super.key,
    required this.engine,
    required this.pressureUnit,
    required this.temperatureUnit,
    this.onClose,
    this.isSidebar = false,
  });

  @override
  State<SimulationParametersPanel> createState() => _SimulationParametersPanelState();
}

class _SimulationParametersPanelState extends State<SimulationParametersPanel> {
  int _activeTab = 0; // 0: Actuadores / Parámetros, 1: Mediciones en Tiempo Real

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;

        return Container(
          width: widget.isSidebar ? 340.0 : double.infinity,
          decoration: BoxDecoration(
            color: ScadaColors.surface.withValues(alpha: widget.isSidebar ? 0.94 : 1.0),
            borderRadius: widget.isSidebar
                ? const BorderRadius.horizontal(left: Radius.circular(16))
                : const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: ScadaColors.infoBlue.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: widget.isSidebar ? const Offset(-4, 0) : const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior del panel
              _buildPanelHeader(state),

              // Selector de pestaña: Actuadores vs Mediciones
              _buildTabSelector(),

              // Contenido con scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: _activeTab == 0
                      ? _buildActuatorsSection(state)
                      : _buildLiveMeasurementsSection(state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanelHeader(SimulationState state) {
    final isRunning = state.isRunning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: widget.isSidebar
            ? const BorderRadius.only(topLeft: Radius.circular(15))
            : const BorderRadius.vertical(top: Radius.circular(19)),
        border: const Border(bottom: BorderSide(color: ScadaColors.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ScadaColors.infoBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.tune, color: ScadaColors.infoBlue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PUESTO DE CONTROL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: ScadaColors.textPrimary,
                  ),
                ),
                Text(
                  isRunning ? '● EN MARCHA (60 Hz)' : '● DETENIDO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isRunning ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: ScadaColors.textMuted, size: 18),
              onPressed: widget.onClose,
              tooltip: 'Cerrar panel de parámetros',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = 0),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? ScadaColors.infoBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'ACTUADORES (CONTROL)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _activeTab == 0 ? Colors.white : ScadaColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = 1),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? ScadaColors.cyanAccent.withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: _activeTab == 1 ? Border.all(color: ScadaColors.cyanAccent) : null,
                ),
                child: Text(
                  'MEDICIONES EN VIVO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _activeTab == 1 ? ScadaColors.cyanAccent : ScadaColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorsSection(SimulationState state) {
    final comp = state.circuit.compressor;
    final exp = state.circuit.expansionDevice;
    final cond = state.circuit.condenser;
    final thermo = state.thermostat;
    final coldRoom = state.coldRoom;

    final currentRpm = comp?.rpm ?? 2900.0;
    final isTxvAuto = exp?.isAutomatic ?? true;
    final txvOpening = exp?.openingPercent ?? 45.0;
    final condFanOn = state.condenserFanSpeedOverride > 0.0 && (cond?.fanOperational ?? true);
    final ambientTC = (cond?.ambientTemperatureKelvin ?? 298.15) - 273.15;
    final internalLoadW = coldRoom.internalHeatLoadWatts;
    final bulbPressurePa = state.refrigerant.saturationPressure(state.dynamicBulbTempK);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. COMPRESOR
        _buildSectionCard(
          title: 'COMPRESOR HERMÉTICO',
          icon: Icons.compress,
          color: ScadaColors.infoBlue,
          children: [
            _buildControlHeader(
              name: 'Velocidad de Giro (RPM)',
              valueText: '${currentRpm.toInt()} RPM',
              subtext: 'CONTROL ACTUADOR · Rango: 500 a 4500 RPM',
            ),
            Slider(
              value: currentRpm.clamp(500.0, 4500.0),
              min: 500.0,
              max: 4500.0,
              divisions: 80,
              activeColor: ScadaColors.infoBlue,
              inactiveColor: ScadaColors.border,
              label: '${currentRpm.toInt()} RPM',
              onChanged: (val) => widget.engine.setCompressorRpm(val),
            ),
            _buildLiveReadoutRow([
              _readoutItem('Frecuencia', '${(state.dynamicRpm / 60.0).toStringAsFixed(1)} Hz'),
              _readoutItem('Potencia', '${(state.electricalPowerWatts / 1000.0).toStringAsFixed(2)} kW'),
              _readoutItem('Corriente', '${state.electricalState.currentAmps.toStringAsFixed(1)} A'),
            ]),
          ],
        ),
        const SizedBox(height: 10),

        // 2. VÁLVULA DE EXPANSIÓN (TXV)
        _buildSectionCard(
          title: 'VÁLVULA DE EXPANSIÓN (TXV)',
          icon: Icons.call_split,
          color: ScadaColors.lowPressureTwoPhase,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modo de Regulación',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                ),
                ChoiceChip(
                  label: Text(isTxvAuto ? 'AUTOMÁTICO' : 'MANUAL'),
                  selected: !isTxvAuto,
                  visualDensity: VisualDensity.compact,
                  selectedColor: ScadaColors.warningAmber.withValues(alpha: 0.25),
                  backgroundColor: ScadaColors.surface,
                  side: BorderSide(color: isTxvAuto ? ScadaColors.runningGreen : ScadaColors.warningAmber),
                  labelStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isTxvAuto ? ScadaColors.runningGreen : ScadaColors.warningAmber,
                  ),
                  onSelected: (val) => widget.engine.setTxvAutomatic(!val),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildControlHeader(
              name: 'Apertura de Válvula',
              valueText: '${txvOpening.toStringAsFixed(0)} %',
              subtext: isTxvAuto ? 'Apertura gobernada por recalentamiento' : 'CONTROL MANUAL DE APERTURA',
            ),
            Slider(
              value: txvOpening.clamp(5.0, 100.0),
              min: 5.0,
              max: 100.0,
              divisions: 95,
              activeColor: isTxvAuto ? ScadaColors.borderLight : ScadaColors.lowPressureTwoPhase,
              inactiveColor: ScadaColors.border,
              label: '${txvOpening.toInt()}%',
              onChanged: (val) => widget.engine.setValveOpening(val),
            ),
            _buildLiveReadoutRow([
              _readoutItem('Superheat', '${state.superheatKelvin.toStringAsFixed(1)} K'),
              _readoutItem('P_bulbo', '${(bulbPressurePa / 1e5).toStringAsFixed(2)} bar'),
              _readoutItem('Caudal ṁ', '${(state.massFlowKgPerSec * 1000).toStringAsFixed(1)} g/s'),
            ]),
          ],
        ),
        const SizedBox(height: 10),

        // 3. TERMOSTATO Y CÁMARA
        _buildSectionCard(
          title: 'CÁMARA FRIGORÍFICA Y TERMOSTATO',
          icon: Icons.kitchen,
          color: ScadaColors.runningGreen,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Control Termostático',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                ),
                Switch(
                  value: thermo.isEnabled,
                  activeThumbColor: ScadaColors.runningGreen,
                  onChanged: (val) => widget.engine.setThermostatEnabled(val),
                ),
              ],
            ),
            _buildControlHeader(
              name: 'Consigna de Temperatura',
              valueText: '${thermo.setpointCelsius.toStringAsFixed(1)} °C',
              subtext: 'Parada por frío en consigna · Histéresis: ${thermo.hysteresisKelvin.toStringAsFixed(1)} K',
            ),
            Slider(
              value: thermo.setpointCelsius.clamp(-25.0, 15.0),
              min: -25.0,
              max: 15.0,
              divisions: 80,
              activeColor: ScadaColors.runningGreen,
              inactiveColor: ScadaColors.border,
              label: '${thermo.setpointCelsius.toStringAsFixed(1)} °C',
              onChanged: thermo.isEnabled ? (val) => widget.engine.setThermostatSetpoint(val) : null,
            ),
            _buildControlHeader(
              name: 'Carga Térmica Interna (Género)',
              valueText: '${internalLoadW.toInt()} W',
              subtext: 'CONTROL · Aporte de calor de productos y personas',
            ),
            Slider(
              value: internalLoadW.clamp(0.0, 5000.0),
              min: 0.0,
              max: 5000.0,
              divisions: 50,
              activeColor: ScadaColors.warningAmber,
              inactiveColor: ScadaColors.border,
              label: '${internalLoadW.toInt()} W',
              onChanged: (val) => widget.engine.setInternalHeatLoad(val),
            ),
            _buildLiveReadoutRow([
              _readoutItem('T_cámara', '${(coldRoom.temperatureKelvin - 273.15).toStringAsFixed(1)} °C'),
              _readoutItem('Potencia Qe', '${(state.coolingCapacityWatts / 1000.0).toStringAsFixed(2)} kW'),
              _readoutItem('COP', state.cop.toStringAsFixed(2)),
            ]),
          ],
        ),
        const SizedBox(height: 10),

        // 4. CONDENSADOR Y AMBIENTE
        _buildSectionCard(
          title: 'CONDENSADOR Y ENTORNO EXTERIOR',
          icon: Icons.wb_sunny_outlined,
          color: ScadaColors.highPressureDischarge,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ventilador Condensador',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                ),
                Switch(
                  value: condFanOn,
                  activeThumbColor: ScadaColors.runningGreen,
                  inactiveThumbColor: ScadaColors.dangerRed,
                  onChanged: (val) => widget.engine.toggleCondenserFan(val),
                ),
              ],
            ),
            _buildControlHeader(
              name: 'Temperatura Exterior (T_amb)',
              valueText: '${ambientTC.toStringAsFixed(0)} °C',
              subtext: 'CONTROL · Perturbación climática de verano/invierno',
            ),
            Slider(
              value: ambientTC.clamp(10.0, 45.0),
              min: 10.0,
              max: 45.0,
              divisions: 35,
              activeColor: ScadaColors.highPressureDischarge,
              inactiveColor: ScadaColors.border,
              label: '${ambientTC.toInt()} °C',
              onChanged: (val) => widget.engine.setAmbientTemperature(val + 273.15),
            ),
            _buildLiveReadoutRow([
              _readoutItem('P_cond (Pk)', '${(state.condensingPressurePa / 1e5).toStringAsFixed(2)} bar'),
              _readoutItem('T_cond (Tk)', '${(state.condensingTemperatureK - 273.15).toStringAsFixed(1)} °C'),
              _readoutItem('Subcooling', '${state.subcoolingKelvin.toStringAsFixed(1)} K'),
            ]),
          ],
        ),
        const SizedBox(height: 10),

        // 5. ACCIONES DE SIMULACIÓN Y RESTAURACIÓN
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ScadaColors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8,
            runSpacing: 6,
            children: [
              ElevatedButton.icon(
                onPressed: () => state.isRunning ? widget.engine.pause() : widget.engine.start(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isRunning ? ScadaColors.warningAmber : ScadaColors.runningGreen,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow, size: 16),
                label: Text(state.isRunning ? 'PAUSAR' : 'ARRANCAR', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.engine.step(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScadaColors.infoBlue,
                  side: const BorderSide(color: ScadaColors.infoBlue),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.skip_next, size: 16),
                label: const Text('PASO dt (0.05s)', style: TextStyle(fontSize: 11)),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.engine.reset(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScadaColors.dangerRed,
                  side: const BorderSide(color: ScadaColors.dangerRed),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('REINICIAR', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMeasurementsSection(SimulationState state) {
    final poBar = state.evaporatingPressurePa / 1e5;
    final pkBar = state.condensingPressurePa / 1e5;
    final toC = state.evaporatingTemperatureK - 273.15;
    final tkC = state.condensingTemperatureK - 273.15;
    final tDisC = state.state2Discharge.temperature - 273.15;
    final tLiqC = state.state3Liquid.temperature - 273.15;
    final tSucC = state.state1Suction.temperature - 273.15;
    final tCamC = state.coldRoom.temperatureKelvin - 273.15;
    final qeKw = state.coolingCapacityWatts / 1000.0;
    final qcKw = state.heatingCapacityWatts / 1000.0;
    final wCompKw = state.compressorPowerWatts / 1000.0;
    final mDotGs = state.massFlowKgPerSec * 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMeasurementBanner(),
        const SizedBox(height: 8),

        // Grilla de mediciones SCADA
        _buildMetricGrid([
          _metricTile('P_BAJA (Po)', '${poBar.toStringAsFixed(2)} bar', 'Evaporación', ScadaColors.lowPressureSuction),
          _metricTile('P_ALTA (Pk)', '${pkBar.toStringAsFixed(2)} bar', 'Condensación', ScadaColors.highPressureDischarge),
          _metricTile('T_EVAP (To)', '${toC.toStringAsFixed(1)} °C', 'Saturación baja', ScadaColors.cyanAccent),
          _metricTile('T_COND (Tk)', '${tkC.toStringAsFixed(1)} °C', 'Saturación alta', ScadaColors.highPressureLiquid),
          _metricTile('T_DESCARGA', '${tDisC.toStringAsFixed(1)} °C', 'Salida culata', ScadaColors.highPressureDischarge),
          _metricTile('T_LÍQUIDO', '${tLiqC.toStringAsFixed(1)} °C', 'Salida condensador', ScadaColors.highPressureLiquid),
          _metricTile('T_ASPIRACIÓN', '${tSucC.toStringAsFixed(1)} °C', 'Entrada compresor', ScadaColors.infoBlue),
          _metricTile('SUPERHEAT (SH)', '${state.superheatKelvin.toStringAsFixed(1)} K', 'Recalentamiento útil', state.superheatKelvin < 4.0 ? ScadaColors.dangerRed : ScadaColors.runningGreen),
          _metricTile('SUBCOOLING (SC)', '${state.subcoolingKelvin.toStringAsFixed(1)} K', 'Subenfriamiento líquido', ScadaColors.highPressureLiquid),
          _metricTile('T_CÁMARA', '${tCamC.toStringAsFixed(1)} °C', 'Recinto refrigerado', ScadaColors.runningGreen),
          _metricTile('CAUDAL MÁSICO', '${mDotGs.toStringAsFixed(1)} g/s', 'Circulación R-134a', ScadaColors.textPrimary),
          _metricTile('POTENCIA FRÍO (Qe)', '${qeKw.toStringAsFixed(2)} kW', 'Calor absorbido', ScadaColors.cyanAccent),
          _metricTile('CALOR DISIPADO (Qc)', '${qcKw.toStringAsFixed(2)} kW', 'Calor condensador', ScadaColors.highPressureDischarge),
          _metricTile('CONSUMO (Wcomp)', '${wCompKw.toStringAsFixed(2)} kW', 'Potencia compresión', ScadaColors.warningAmber),
          _metricTile('EFICIENCIA (COP)', state.cop.toStringAsFixed(2), 'Qe / Wcomp', ScadaColors.runningGreen),
        ]),
      ],
    );
  }

  Widget _buildMeasurementBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ScadaColors.cyanAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ScadaColors.cyanAccent.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.insights, size: 16, color: ScadaColors.cyanAccent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'VALORES CALCULADOS EN TIEMPO REAL POR EL SOLVER (ÚNICA FUENTE DE VERDAD)',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: ScadaColors.cyanAccent, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(List<Widget> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 300 ? 2 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: tiles,
        );
      },
    );
  }

  Widget _metricTile(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: ScadaColors.textMuted, letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace'),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 8.5, color: ScadaColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const Divider(height: 14, color: ScadaColors.border),
          ...children,
        ],
      ),
    );
  }

  Widget _buildControlHeader({
    required String name,
    required String valueText,
    required String subtext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ScadaColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ScadaColors.infoBlue),
              ),
              child: Text(
                valueText,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.infoBlue, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: const TextStyle(fontSize: 8.5, color: ScadaColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildLiveReadoutRow(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items,
      ),
    );
  }

  Widget _readoutItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 8.5, color: ScadaColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary, fontFamily: 'monospace')),
      ],
    );
  }
}
