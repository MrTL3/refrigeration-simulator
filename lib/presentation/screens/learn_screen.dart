import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/components/base_component.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../theme/scada_colors.dart';
import '../widgets/component_inspector_modal.dart';

/// Pantalla didáctica del modo "APRENDER" (Lección 01: Fundamentos del Ciclo Frigorífico).
class LearnScreen extends StatefulWidget {
  final SimulationEngine engine;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;

  const LearnScreen({
    super.key,
    required this.engine,
    required this.pressureUnit,
    required this.temperatureUnit,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _selectedQuizOption = -1;
  bool _quizAnswered = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;
        final comp = state.circuit.compressor;
        final cond = state.circuit.condenser;
        final exp = state.circuit.expansionDevice;
        final evap = state.circuit.evaporator;

        return Scaffold(
          backgroundColor: ScadaColors.background,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner de Cabecera de Lección
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ScadaColors.infoBlue.withValues(alpha: 0.15),
                      ScadaColors.surfaceCard,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ScadaColors.infoBlue.withValues(alpha: 0.4)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text('NIVEL 0 — FUNDAMENTOS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: ScadaColors.surface,
                          side: BorderSide(color: ScadaColors.infoBlue),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'LECCIÓN 01',
                          style: TextStyle(
                            color: ScadaColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '¿Qué es una instalación frigorífica?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ScadaColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Una máquina frigorífica no "crea frío"; lo que hace es extraer calor de un lugar donde no se desea (como el interior de una cámara) y expulsarlo al exterior mediante un ciclo termodinámico cerrado.',
                      style: TextStyle(
                        fontSize: 13,
                        color: ScadaColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Los 4 componentes elementales interactivos
              const Text(
                'LOS 4 ÓRGANOS VITALES DEL CICLO:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ScadaColors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              if (comp != null)
                _buildComponentLessonCard(
                  number: '1',
                  name: 'COMPRESOR',
                  actionText: 'Aspira el vapor y lo comprime',
                  phaseText: 'Vapor baja presión ➔ Vapor alta presión',
                  color: ScadaColors.highPressureDischarge,
                  component: comp,
                ),
              const SizedBox(height: 8),

              if (cond != null)
                _buildComponentLessonCard(
                  number: '2',
                  name: 'CONDENSADOR',
                  actionText: 'Cede calor al ambiente y licúa el gas',
                  phaseText: 'Vapor caliente ➔ Líquido subenfriado',
                  color: ScadaColors.highPressureLiquid,
                  component: cond,
                ),
              const SizedBox(height: 8),

              if (exp != null)
                _buildComponentLessonCard(
                  number: '3',
                  name: 'VÁLVULA DE EXPANSIÓN',
                  actionText: 'Estrangula la presión y genera mezcla fría',
                  phaseText: 'Líquido alta presión ➔ Mezcla bifásica fría baja presión',
                  color: ScadaColors.lowPressureTwoPhase,
                  component: exp,
                ),
              const SizedBox(height: 8),

              if (evap != null)
                _buildComponentLessonCard(
                  number: '4',
                  name: 'EVAPORADOR',
                  actionText: 'Absorbe calor del recinto y produce el frío útil',
                  phaseText: 'Mezcla bifásica fría ➔ Vapor sobrecalentado',
                  color: ScadaColors.lowPressureSuction,
                  component: evap,
                ),
              const SizedBox(height: 20),

              // Reto del Profesor Virtual
              _buildTeacherQuizCard(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComponentLessonCard({
    required String number,
    required String name,
    required String actionText,
    required String phaseText,
    required Color color,
    required BaseComponent component,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ComponentInspectorModal.show(
            context,
            component: component,
            state: widget.engine.state,
            pressureUnit: widget.pressureUnit,
            temperatureUnit: widget.temperatureUnit,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ScadaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      actionText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ScadaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phaseText,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: ScadaColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherQuizCard(dynamic state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.warningAmber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: ScadaColors.warningAmber, size: 20),
              SizedBox(width: 8),
              Text(
                'PROFESOR VIRTUAL: ¿QUÉ CREES QUE OCURRIRÁ?',
                style: TextStyle(
                  color: ScadaColors.warningAmber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Si en pleno verano aumenta fuertemente la temperatura exterior ambiente, ¿qué le ocurrirá a la presión de condensación (alta presión)?',
            style: TextStyle(fontSize: 13, color: ScadaColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Opciones
          _buildQuizOption(0, 'A) La presión de condensación aumentará.'),
          _buildQuizOption(1, 'B) La presión de condensación disminuirá.'),
          _buildQuizOption(2, 'C) No cambiará en absoluto.'),
          const SizedBox(height: 12),

          if (_quizAnswered) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _selectedQuizOption == 0
                    ? ScadaColors.runningGreen.withValues(alpha: 0.15)
                    : ScadaColors.dangerRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedQuizOption == 0 ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedQuizOption == 0 ? '✔ ¡CORRECTO!' : '❌ INCORRECTO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _selectedQuizOption == 0 ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Al hacer más calor afuera, al condensador le cuesta más transferir calor al aire. Por equilibrio termodinámico, el refrigerante debe condensar a mayor temperatura, lo que eleva directamente la presión de alta (Pk = Psat(Tk)).',
                    style: TextStyle(fontSize: 12, color: ScadaColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizOption(int index, String text) {
    final isSelected = _selectedQuizOption == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          setState(() {
            _selectedQuizOption = index;
            _quizAnswered = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? ScadaColors.infoBlue.withValues(alpha: 0.2) : ScadaColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? ScadaColors.infoBlue : ScadaColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: isSelected ? ScadaColors.infoBlue : ScadaColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? ScadaColors.textPrimary : ScadaColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
