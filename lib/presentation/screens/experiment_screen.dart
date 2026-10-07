import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/models/educational_experiment.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../theme/scada_colors.dart';
import '../widgets/transient_chart_widget.dart';

/// Pantalla del Laboratorio de Ensayos y Experimentos Educativos Guiados (Fase 2).
class ExperimentScreen extends StatefulWidget {
  final SimulationEngine engine;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;

  const ExperimentScreen({
    super.key,
    required this.engine,
    required this.pressureUnit,
    required this.temperatureUnit,
  });

  @override
  State<ExperimentScreen> createState() => _ExperimentScreenState();
}

class _ExperimentScreenState extends State<ExperimentScreen> {
  int _selectedQuizOption = -1;
  bool _quizAnswered = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;
        final activeExp = widget.engine.activeExperiment;

        return Scaffold(
          backgroundColor: ScadaColors.background,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cabecera del Laboratorio de Ensayos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ScadaColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ScadaColors.infoBlue.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: ScadaColors.infoBlue, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'LABORATORIO DE EXPERIMENTOS VIRTUALES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: ScadaColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'En este entorno podrás provocar perturbaciones controladas (RPM, T_ambiente, apertura de TXV), observar el transitorio en tiempo real y contrastar los resultados físicos con tu hipótesis.',
                      style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Si hay un experimento activo, mostramos su flujo guiado
              if (activeExp != null) ...[
                _buildActiveExperimentFlow(activeExp, state),
                const SizedBox(height: 16),
                // Gráfica de evolución transitoria viva durante la práctica
                TransientChartWidget(history: state.timeSeriesHistory),
                const SizedBox(height: 16),
              ] else ...[
                // Selector de prácticas disponibles
                const Text(
                  'PRÁCTICAS DISPONIBLES (FASE 2):',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: ScadaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),

                ...EducationalExperiment.availableExperiments.map((exp) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                exp.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: ScadaColors.textPrimary,
                                ),
                              ),
                              Chip(
                                label: Text('${exp.parameterName}: ${exp.baselineValue.toInt()} ➔ ${exp.perturbedValue.toInt()} ${exp.unitSymbol}'),
                                backgroundColor: ScadaColors.surface,
                                side: const BorderSide(color: ScadaColors.border),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            exp.hypothesisQuestion,
                            style: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedQuizOption = -1;
                                _quizAnswered = false;
                              });
                              widget.engine.startExperiment(exp);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ScadaColors.infoBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('COMENZAR ESTA PRÁCTICA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveExperimentFlow(EducationalExperiment exp, dynamic state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.infoBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exp.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.engine.cancelExperiment(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ScadaColors.dangerRed,
                  side: const BorderSide(color: ScadaColors.dangerRed),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.close, size: 14),
                label: const Text('CANCELAR', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const Divider(height: 20),

          // Paso 1: Hipótesis previa
          const Text(
            'PASO 1: PLANTEA TU HIPÓTESIS CIENTÍFICA:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.warningAmber, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(exp.hypothesisQuestion, style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary, height: 1.4)),
          const SizedBox(height: 10),

          ...List.generate(exp.quizOptions.length, (idx) {
            final isSelected = _selectedQuizOption == idx;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: exp.phase == ExperimentPhase.stabilizingBaseline
                    ? () => setState(() => _selectedQuizOption = idx)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? ScadaColors.infoBlue.withValues(alpha: 0.2) : ScadaColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? ScadaColors.infoBlue : ScadaColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: isSelected ? ScadaColors.infoBlue : ScadaColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(exp.quizOptions[idx], style: TextStyle(fontSize: 12, color: isSelected ? ScadaColors.textPrimary : ScadaColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          // Paso 2: Perturbación
          if (exp.phase == ExperimentPhase.stabilizingBaseline) ...[
            ElevatedButton.icon(
              onPressed: _selectedQuizOption >= 0
                  ? () => widget.engine.applyExperimentPerturbation()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.runningGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.bolt, size: 16),
              label: Text(
                'APLICAR PERTURBACIÓN (${exp.parameterName}: ${exp.perturbedValue.toInt()} ${exp.unitSymbol})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScadaColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ScadaColors.runningGreen),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.autorenew, size: 16, color: ScadaColors.runningGreen),
                      const SizedBox(width: 8),
                      Text(
                        'PERTURBACIÓN APLICADA: ${exp.parameterName} = ${exp.perturbedValue.toInt()} ${exp.unitSymbol}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.runningGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Observa en la gráfica inferior cómo evolucionan las curvas y espera a que el sistema alcance el régimen permanente.',
                    style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _quizAnswered = true);
                      widget.engine.evaluateExperimentResults();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScadaColors.infoBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('VER RESULTADOS Y EXPLICACIÓN'),
                  ),
                ],
              ),
            ),
          ],

          // Paso 3: Explicación y resolución pedagógica
          if (_quizAnswered) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedQuizOption == exp.correctOptionIndex
                    ? ScadaColors.runningGreen.withValues(alpha: 0.15)
                    : ScadaColors.dangerRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedQuizOption == exp.correctOptionIndex ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedQuizOption == exp.correctOptionIndex ? '✔ ¡HIPÓTESIS VERIFICADA!' : '❌ HIPÓTESIS INCORRECTA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedQuizOption == exp.correctOptionIndex ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exp.physicalExplanation,
                    style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
