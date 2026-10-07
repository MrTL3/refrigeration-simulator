import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../theme/scada_colors.dart';

/// Panel de mandos y control de variables de ensayo del simulador.
class SimulationControlPanel extends StatelessWidget {
  final SimulationEngine engine;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final ValueChanged<PressureUnit> onPressureUnitChanged;
  final ValueChanged<TemperatureUnit> onTemperatureUnitChanged;

  const SimulationControlPanel({
    super.key,
    required this.engine,
    required this.pressureUnit,
    required this.temperatureUnit,
    required this.onPressureUnitChanged,
    required this.onTemperatureUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final state = engine.state;
    final comp = state.circuit.compressor;
    final cond = state.circuit.condenser;
    final exp = state.circuit.expansionDevice;
    final evap = state.circuit.evaporator;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila de Controles de Ejecución
          Row(
            children: [
              // Botón Start / Stop
              ElevatedButton.icon(
                onPressed: () {
                  if (engine.isRunning) {
                    engine.pause();
                  } else {
                    engine.start();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: engine.isRunning ? ScadaColors.dangerRed : ScadaColors.runningGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: Icon(engine.isRunning ? Icons.pause : Icons.play_arrow, size: 18),
                label: Text(
                  engine.isRunning ? 'PARAR' : 'MARCHA',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),

              // Botón Paso a Paso (Step)
              OutlinedButton.icon(
                onPressed: engine.isRunning ? null : () => engine.step(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScadaColors.infoBlue,
                  side: const BorderSide(color: ScadaColors.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                icon: const Icon(Icons.skip_next, size: 16),
                label: const Text('PASO', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),

              // Botón Reset
              OutlinedButton.icon(
                onPressed: () => engine.reset(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScadaColors.textSecondary,
                  side: const BorderSide(color: ScadaColors.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('RESET', style: TextStyle(fontSize: 11)),
              ),

              const Spacer(),

              // Contador de tiempo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ScadaColors.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: Text(
                  't = ${state.timeSeconds.toStringAsFixed(1)} s',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: ScadaColors.infoBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Controles de Parámetros Físicos
          Row(
            children: [
              // Selector de Unidades
              Row(
                children: [
                  const Text('Presión:', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                  const SizedBox(width: 4),
                  DropdownButton<PressureUnit>(
                    value: pressureUnit,
                    dropdownColor: ScadaColors.surfaceCard,
                    style: const TextStyle(fontSize: 11, color: ScadaColors.infoBlue),
                    isDense: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: PressureUnit.bar, child: Text('bar')),
                      DropdownMenuItem(value: PressureUnit.psi, child: Text('PSI')),
                      DropdownMenuItem(value: PressureUnit.kilopascal, child: Text('kPa')),
                    ],
                    onChanged: (val) {
                      if (val != null) onPressureUnitChanged(val);
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text('Temp:', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                  const SizedBox(width: 4),
                  DropdownButton<TemperatureUnit>(
                    value: temperatureUnit,
                    dropdownColor: ScadaColors.surfaceCard,
                    style: const TextStyle(fontSize: 11, color: ScadaColors.infoBlue),
                    isDense: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: TemperatureUnit.celsius, child: Text('°C')),
                      DropdownMenuItem(value: TemperatureUnit.fahrenheit, child: Text('°F')),
                      DropdownMenuItem(value: TemperatureUnit.kelvin, child: Text('K')),
                    ],
                    onChanged: (val) {
                      if (val != null) onTemperatureUnitChanged(val);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sliders de variables operativas
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              // RPM Compresor
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Compresor RPM', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                        Text('${comp?.rpm.toInt() ?? 0} RPM',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary)),
                      ],
                    ),
                    Slider(
                      value: comp?.rpm ?? 2900.0,
                      min: 1000.0,
                      max: 3600.0,
                      divisions: 26,
                      activeColor: ScadaColors.infoBlue,
                      onChanged: (v) => engine.setCompressorRpm(v),
                    ),
                  ],
                ),
              ),

              // Apertura Válvula TXV
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Apertura TXV (%)', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                        Text('${exp?.openingPercent.toStringAsFixed(0) ?? 45}%',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary)),
                      ],
                    ),
                    Slider(
                      value: exp?.openingPercent ?? 45.0,
                      min: 10.0,
                      max: 90.0,
                      divisions: 16,
                      activeColor: ScadaColors.lowPressureTwoPhase,
                      onChanged: (v) => engine.setValveOpening(v),
                    ),
                  ],
                ),
              ),

              // Temperatura Ambiente
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Temp. Ambiente', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                        Text('${((cond?.ambientTemperatureKelvin ?? 298.15) - 273.15).toStringAsFixed(0)} °C',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary)),
                      ],
                    ),
                    Slider(
                      value: ((cond?.ambientTemperatureKelvin ?? 298.15) - 273.15),
                      min: 10.0,
                      max: 45.0,
                      divisions: 35,
                      activeColor: ScadaColors.highPressureDischarge,
                      onChanged: (v) => engine.setAmbientTemperature(v + 273.15),
                    ),
                  ],
                ),
              ),

              // Switches de ventiladores
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilterChip(
                      label: const Text('Vent. Condensador', style: TextStyle(fontSize: 11)),
                      selected: cond?.fanOperational ?? true,
                      selectedColor: ScadaColors.runningGreen.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: (cond?.fanOperational ?? true) ? ScadaColors.runningGreen : ScadaColors.border,
                      ),
                      onSelected: (val) => engine.toggleCondenserFan(val),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Vent. Evaporador', style: TextStyle(fontSize: 11)),
                      selected: evap?.fanOperational ?? true,
                      selectedColor: ScadaColors.runningGreen.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: (evap?.fanOperational ?? true) ? ScadaColors.runningGreen : ScadaColors.border,
                      ),
                      onSelected: (val) => engine.toggleEvaporatorFan(val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
