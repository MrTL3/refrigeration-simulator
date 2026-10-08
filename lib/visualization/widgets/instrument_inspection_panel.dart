import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../presentation/theme/scada_colors.dart';
import '../../simulation/engine/simulation_state.dart';
import '../models/installation_instrument.dart';

/// Panel contextual de inspección técnica en tiempo real al tocar cualquier instrumento físico.
class InstrumentInspectionPanel extends StatelessWidget {
  final InstallationInstrument instrument;
  final SimulationState state;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final VoidCallback onClose;
  final VoidCallback? onInspectWhy;

  const InstrumentInspectionPanel({
    super.key,
    required this.instrument,
    required this.state,
    required this.pressureUnit,
    required this.temperatureUnit,
    required this.onClose,
    this.onInspectWhy,
  });

  @override
  Widget build(BuildContext context) {
    final reading = instrument.getReading(state, pressureUnit, temperatureUnit);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: instrument.type.primaryColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabecera del instrumento
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: instrument.type.primaryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: instrument.type.primaryColor.withValues(alpha: 0.5)),
                ),
                child: Icon(instrument.type.icon, color: instrument.type.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ScadaColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: ScadaColors.borderLight),
                          ),
                          child: Text(
                            instrument.tag,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: instrument.type.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            instrument.type.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ScadaColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ubicación: ${instrument.physicalLocation}',
                      style: const TextStyle(fontSize: 10, color: ScadaColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: ScadaColors.textMuted),
                onPressed: onClose,
                tooltip: 'Cerrar inspección',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: ScadaColors.border),
          const SizedBox(height: 10),

          // 2. Lecturas físicas en tiempo real
          Row(
            children: [
              // Valor principal
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ScadaColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ScadaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LECTURA ACTUAL (SOLVER)',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: ScadaColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reading.primaryValue,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: instrument.type.primaryColor,
                        ),
                      ),
                      if (reading.secondaryValue.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          reading.secondaryValue,
                          style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Estado operativo
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ScadaColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ScadaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTADO DEL FLUIDO',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: ScadaColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reading.statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: reading.statusColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reading.fluidState,
                        style: const TextStyle(fontSize: 9, color: ScadaColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Detalles técnicos para el técnico frigorista
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ScadaColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ScadaColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: reading.technicalDetails.map((detail) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 5, color: ScadaColors.infoBlue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // 4. Botón educativo: ¿Por qué ocurre esto?
          Row(
            children: [
              Expanded(
                child: Text(
                  instrument.technicalPurpose,
                  style: const TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: ScadaColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onInspectWhy != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onInspectWhy,
                  icon: const Icon(Icons.school, size: 14),
                  label: const Text('¿POR QUÉ?'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.warningAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
