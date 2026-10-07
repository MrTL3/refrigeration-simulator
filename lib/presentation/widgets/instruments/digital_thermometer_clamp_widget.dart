import 'package:flutter/material.dart';
import '../../../simulation/engine/simulation_state.dart';
import '../../theme/scada_colors.dart';

enum ProbeLocation {
  suction('Aspiración (Punto 1)', 'comp_1'),
  discharge('Descarga (Punto 2)', 'comp_1'),
  liquid('Línea Líquido (Punto 3)', 'cond_1'),
  evapInlet('Entrada Evaporador (Punto 4)', 'exp_1'),
  coldRoom('Interior Cámara Frigorífica', 'evap_1'),
  ambient('Ambiente Exterior', 'cond_1');

  final String label;
  final String componentId;
  const ProbeLocation(this.label, this.componentId);
}

/// Termómetro de pinza digital para medición simultánea en tuberías y cálculo de Superheat/Subcooling.
class DigitalThermometerClampWidget extends StatefulWidget {
  final SimulationState state;

  const DigitalThermometerClampWidget({
    super.key,
    required this.state,
  });

  @override
  State<DigitalThermometerClampWidget> createState() => _DigitalThermometerClampWidgetState();
}

class _DigitalThermometerClampWidgetState extends State<DigitalThermometerClampWidget> {
  ProbeLocation _selectedProbe = ProbeLocation.suction;

  double _getTemperatureC(ProbeLocation probe) {
    final s = widget.state;
    switch (probe) {
      case ProbeLocation.suction:
        return s.state1Suction.temperature - 273.15;
      case ProbeLocation.discharge:
        return s.state2Discharge.temperature - 273.15;
      case ProbeLocation.liquid:
        return s.state3Liquid.temperature - 273.15;
      case ProbeLocation.evapInlet:
        return s.state4EvapInlet.temperature - 273.15;
      case ProbeLocation.coldRoom:
        return s.coldRoom.temperatureKelvin - 273.15;
      case ProbeLocation.ambient:
        return (s.circuit.condenser?.ambientTemperatureKelvin ?? 298.15) - 273.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempC = _getTemperatureC(_selectedProbe);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.thermostat_outlined, color: ScadaColors.warningAmber, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'TERMÓMETRO DE CONTACTO / PINZA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ScadaColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('CALIBRADO', style: TextStyle(fontSize: 9, color: ScadaColors.runningGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pantalla LCD estilo display de campo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProbe.label,
                      style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                    ),
                    Text(
                      '${tempC.toStringAsFixed(1)} °C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: ScadaColors.warningAmber,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SH: ${widget.state.superheatKelvin.toStringAsFixed(1)} K',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.cyanAccent, fontFamily: 'monospace'),
                    ),
                    Text(
                      'SC: ${widget.state.subcoolingKelvin.toStringAsFixed(1)} K',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.highPressureLiquid, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Selector de ubicación de la sonda
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ProbeLocation.values.map((probe) {
              final isSelected = _selectedProbe == probe;
              return ChoiceChip(
                label: Text(probe.label, style: const TextStyle(fontSize: 10)),
                selected: isSelected,
                selectedColor: ScadaColors.warningAmber.withValues(alpha: 0.3),
                onSelected: (_) => setState(() => _selectedProbe = probe),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
