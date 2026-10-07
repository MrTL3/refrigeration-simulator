import 'package:flutter/material.dart';
import '../../domain/models/cold_room_model.dart';
import '../../domain/models/thermostat_model.dart';
import '../theme/scada_colors.dart';

/// Panel interactivo de control termostático de la cámara frigorífica.
class ThermostatWidget extends StatelessWidget {
  final ThermostatModel thermostat;
  final ColdRoomModel coldRoom;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<double> onSetpointChanged;
  final ValueChanged<double> onHysteresisChanged;

  const ThermostatWidget({
    super.key,
    required this.thermostat,
    required this.coldRoom,
    required this.onToggleEnabled,
    required this.onSetpointChanged,
    required this.onHysteresisChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roomC = (coldRoom.temperatureKelvin - 273.15).toStringAsFixed(1);
    final setpointC = thermostat.setpointCelsius.toStringAsFixed(1);
    final hystK = thermostat.hysteresisKelvin.toStringAsFixed(1);
    final cutInC = (thermostat.setpointCelsius + thermostat.hysteresisKelvin).toStringAsFixed(1);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.thermostat_auto, size: 18, color: ScadaColors.infoBlue),
                  const SizedBox(width: 8),
                  const Text(
                    'TERMOSTATO DE CÁMARA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: ScadaColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: thermostat.isEnabled,
                activeThumbColor: ScadaColors.runningGreen,
                activeTrackColor: ScadaColors.runningGreen.withValues(alpha: 0.4),
                onChanged: onToggleEnabled,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Estado del relé de frío
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: ScadaColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: thermostat.isEnabled
                    ? (thermostat.isCallForCooling ? ScadaColors.runningGreen : ScadaColors.border)
                    : ScadaColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: thermostat.isEnabled
                        ? (thermostat.isCallForCooling ? ScadaColors.runningGreen : ScadaColors.textMuted)
                        : ScadaColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thermostat.isEnabled
                        ? (thermostat.isCallForCooling
                            ? 'DEMANDA DE FRÍO ACTIVA (Compresor en marcha)'
                            : 'CONSIGNA ALCANZADA (Compresor en reposo)')
                        : 'CONTROL MANUAL (Termostato Desactivado)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: thermostat.isEnabled
                          ? (thermostat.isCallForCooling ? ScadaColors.runningGreen : ScadaColors.textSecondary)
                          : ScadaColors.textMuted,
                    ),
                  ),
                ),
                Text(
                  'T_cám: $roomC °C',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: ScadaColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Sliders de consigna e histéresis adaptativos
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final setpointCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Consigna (Parada):',
                          style: TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('$setpointC °C', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.infoBlue)),
                    ],
                  ),
                  Slider(
                    value: thermostat.setpointCelsius,
                    min: -25.0,
                    max: 12.0,
                    divisions: 37,
                    activeColor: ScadaColors.infoBlue,
                    onChanged: thermostat.isEnabled ? onSetpointChanged : null,
                  ),
                ],
              );

              final hystCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Histéresis (Arranca $cutInC°C):',
                          style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('$hystK K', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.warningAmber)),
                    ],
                  ),
                  Slider(
                    value: thermostat.hysteresisKelvin,
                    min: 1.0,
                    max: 6.0,
                    divisions: 10,
                    activeColor: ScadaColors.warningAmber,
                    onChanged: thermostat.isEnabled ? onHysteresisChanged : null,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    setpointCol,
                    const SizedBox(height: 6),
                    hystCol,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: setpointCol),
                  const SizedBox(width: 16),
                  Expanded(child: hystCol),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
