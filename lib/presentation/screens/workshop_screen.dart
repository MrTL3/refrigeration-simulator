import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../theme/scada_colors.dart';

/// Pantalla del modo "TALLER" (Banco de montaje y análisis de conexiones físicas).
class WorkshopScreen extends StatelessWidget {
  final SimulationEngine engine;
  final PressureUnit pressureUnit;

  const WorkshopScreen({
    super.key,
    required this.engine,
    required this.pressureUnit,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final state = engine.state;
        final circuit = state.circuit;
        final validation = state.topologyResult;

        return Scaffold(
          backgroundColor: ScadaColors.background,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Panel de Estado de Topología y Estanqueidad
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: validation.isValid ? ScadaColors.surfaceCard : ScadaColors.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: validation.isValid ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      validation.isValid ? Icons.verified : Icons.error_outline,
                      color: validation.isValid ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            validation.isValid
                                ? 'CIRCUITO FÍSICAMENTE CERRADO Y ESTANCO'
                                : 'ANOMALÍA TOPOLÓGICA EN LA INSTALACIÓN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: validation.isValid ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            validation.isValid
                                ? 'Todos los puertos están correctamente interconectados respetando el sentido del flujo.'
                                : validation.errors.join(' | '),
                            style: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista de Componentes Montados en el Banco
              const Text(
                'COMPONENTES INSTALADOS EN EL BANCO:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ScadaColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              ...circuit.components.values.map((c) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: ScadaColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ScadaColors.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: ScadaColors.border),
                              ),
                              child: Text(
                                c.type.label,
                                style: const TextStyle(fontSize: 10, color: ScadaColors.infoBlue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Puertos físicos:', style: TextStyle(fontSize: 11, color: ScadaColors.textMuted)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: c.ports.map((p) {
                            return Chip(
                              label: Text('${p.name} (${p.nominalDiameterMm}mm)'),
                              backgroundColor: ScadaColors.surface,
                              side: const BorderSide(color: ScadaColors.border),
                              labelStyle: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Lista de Tuberías Físicas y Pérdidas de Carga Darcy-Weisbach
              const Text(
                'LÍNEAS DE TUBERÍA Y PÉRDIDA DE CARGA (DARCY-WEISBACH):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ScadaColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              ...circuit.pipes.map((pipe) {
                final vel = pipe.velocityMetersPerSec.toStringAsFixed(2);
                final dP = UnitFormatter.formatPressure(pipe.pressureDropPascals, pressureUnit, decimals: 3);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ScadaColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ScadaColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.linear_scale, color: ScadaColors.infoBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pipe.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Longitud: ${pipe.lengthMeters} m | Diámetro interior: ${pipe.innerDiameterMm} mm',
                              style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('v = $vel m/s', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: ScadaColors.infoBlue)),
                          Text('ΔP = $dP', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: ScadaColors.warningAmber)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Aviso didáctico del taller
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ScadaColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: ScadaColors.infoBlue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'En la Fase 6 del roadmap se activará la mesa de taller libre con rejilla magnética, corte de tuberías y abocardado virtual.',
                        style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
