import 'package:flutter/material.dart';
import '../../../simulation/engine/simulation_engine.dart';
import '../../theme/scada_colors.dart';

/// Vacuómetro digital industrial de alta precisión en micras de mercurio (µmHg).
class VacuumGaugeWidget extends StatelessWidget {
  final SimulationEngine engine;

  const VacuumGaugeWidget({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final state = engine.state;
    final vac = state.vacuumState;
    final microns = vac.pressureMicrons;
    final isPumpOn = vac.isPumpRunning;

    Color statusColor;
    String statusLabel;
    if (microns < 500.0) {
      statusColor = ScadaColors.runningGreen;
      statusLabel = 'VACÍO PROFUNDO OK (< 500 µmHg)';
    } else if (microns < 1500.0) {
      statusColor = ScadaColors.warningAmber;
      statusLabel = 'DESGASIFICACIÓN FINAL';
    } else if (microns < 25000.0) {
      statusColor = const Color(0xFF38BDF8);
      statusLabel = 'EBULLICIÓN DE HUMEDAD';
    } else {
      statusColor = ScadaColors.dangerRed;
      statusLabel = 'PRESIÓN ATMOSFÉRICA / AIRE';
    }

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
                  Icon(Icons.speed, color: ScadaColors.cyanAccent, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'VACUÓMETRO ELECTRÓNICO (PIRANI)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pantalla digital de gran formato en micras
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VACÍO ABSOLUTO', style: TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
                    Text(
                      microns > 99999 ? '> 99.999 µm' : '${microns.toStringAsFixed(0)} µmHg',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: statusColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${vac.pressureMbar.toStringAsFixed(2)} mbar',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary, fontFamily: 'monospace'),
                    ),
                    Text(
                      'Humedad: ${(vac.residualWaterGrams * 1000).toStringAsFixed(0)} mg',
                      style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Control de la bomba de vacío (conectar/desconectar para prueba de retención)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPumpOn ? 'Bomba conectada y aspirando' : 'Bomba aislada (Prueba de estanqueidad)',
                style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  engine.stepVacuum(0.5, pumpOn: !isPumpOn);
                },
                icon: Icon(isPumpOn ? Icons.power_settings_new : Icons.play_arrow, size: 14),
                label: Text(isPumpOn ? 'PARAR BOMBA' : 'ARRANCAR BOMBA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPumpOn ? ScadaColors.dangerRed : ScadaColors.runningGreen,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
