import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/components/base_component.dart';
import '../../education/lessons/lesson_model.dart';
import '../../education/lessons/progress_tracker.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../theme/scada_colors.dart';
import '../widgets/component_inspector_modal.dart';

/// Pantalla didáctica del modo "APRENDER" (Ruta completa de 11 lecciones interactivas paso a paso).
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
  int _currentLessonIndex = 0;
  LessonStage _currentStage = LessonStage.observe;
  int _selectedQuizOption = -1;
  bool _quizAnswered = false;
  final ProgressTracker _tracker = ProgressTracker();

  LessonModel get _currentLesson => LessonModel.allLessons[_currentLessonIndex];

  void _openComponentModal(BaseComponent comp) {
    ComponentInspectorModal.show(
      context,
      component: comp,
      state: widget.engine.state,
      pressureUnit: widget.pressureUnit,
      temperatureUnit: widget.temperatureUnit,
    );
  }

  void _onAnswerQuiz(int optionIndex) {
    if (_quizAnswered) return;
    setState(() {
      _selectedQuizOption = optionIndex;
      _quizAnswered = true;
    });
    final isCorrect = optionIndex == _currentLesson.correctQuizIndex;
    _tracker.recordQuizAnswer(isCorrect: isCorrect);
  }

  void _nextLesson() {
    _tracker.markLessonCompleted(_currentLesson.id);
    if (_currentLessonIndex < LessonModel.allLessons.length - 1) {
      setState(() {
        _currentLessonIndex++;
        _currentStage = LessonStage.observe;
        _selectedQuizOption = -1;
        _quizAnswered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.engine, _tracker]),
      builder: (context, _) {
        final comp = widget.engine.state.circuit.compressor;
        final cond = widget.engine.state.circuit.condenser;
        final exp = widget.engine.state.circuit.expansionDevice;
        final evap = widget.engine.state.circuit.evaporator;

        return Scaffold(
          backgroundColor: ScadaColors.background,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;

              if (isWide) {
                return Row(
                  children: [
                    // Columna izquierda: Índice del temario
                    SizedBox(
                      width: 280,
                      child: _buildSyllabusList(),
                    ),
                    const VerticalDivider(width: 1, color: ScadaColors.border),
                    // Columna derecha: Visor interactivo de la lección
                    Expanded(
                      child: _buildLessonPlayer(comp, cond, exp, evap),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    // Selector rápido de lección en cabecera móvil
                    _buildMobileLessonSelector(),
                    Expanded(
                      child: _buildLessonPlayer(comp, cond, exp, evap),
                    ),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSyllabusList() {
    return Container(
      color: ScadaColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ScadaColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school, size: 16, color: ScadaColors.infoBlue),
                    SizedBox(width: 8),
                    Text(
                      'TEMARIO FORMATIVO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: ScadaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _tracker.syllabusCompletionPercent,
                    backgroundColor: ScadaColors.surfaceCard,
                    valueColor: const AlwaysStoppedAnimation(ScadaColors.runningGreen),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progreso: ${(_tracker.syllabusCompletionPercent * 100).toInt()}% completado',
                  style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: LessonModel.allLessons.length,
              itemBuilder: (context, idx) {
                final les = LessonModel.allLessons[idx];
                final isSelected = idx == _currentLessonIndex;
                final isDone = _tracker.isLessonCompleted(les.id);

                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: ScadaColors.infoBlue.withValues(alpha: 0.12),
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: isDone
                        ? ScadaColors.runningGreen.withValues(alpha: 0.2)
                        : (isSelected ? ScadaColors.infoBlue.withValues(alpha: 0.2) : ScadaColors.surfaceCard),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: ScadaColors.runningGreen)
                        : Text(
                            '$idx',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? ScadaColors.infoBlue : ScadaColors.textSecondary,
                            ),
                          ),
                  ),
                  title: Text(
                    les.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? ScadaColors.infoBlue : ScadaColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    les.subtitle,
                    style: const TextStyle(fontSize: 9, color: ScadaColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _currentLessonIndex = idx;
                      _currentStage = LessonStage.observe;
                      _selectedQuizOption = -1;
                      _quizAnswered = false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLessonSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: ScadaColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: DropdownButton<int>(
              value: _currentLessonIndex,
              isExpanded: true,
              dropdownColor: ScadaColors.surfaceCard,
              underline: const SizedBox(),
              items: LessonModel.allLessons.map((l) {
                return DropdownMenuItem(
                  value: l.index,
                  child: Text(
                    l.title,
                    style: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _currentLessonIndex = val;
                    _currentStage = LessonStage.observe;
                    _selectedQuizOption = -1;
                    _quizAnswered = false;
                  });
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 18, color: ScadaColors.infoBlue),
            onPressed: _currentLessonIndex < LessonModel.allLessons.length - 1
                ? () {
                    setState(() {
                      _currentLessonIndex++;
                      _currentStage = LessonStage.observe;
                      _selectedQuizOption = -1;
                      _quizAnswered = false;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPlayer(BaseComponent? comp, BaseComponent? cond, BaseComponent? exp, BaseComponent? evap) {
    final les = _currentLesson;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cabecera de la lección
        Container(
          padding: const EdgeInsets.all(14),
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
            border: Border.all(color: ScadaColors.infoBlue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LECCIÓN ${_currentLessonIndex.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: ScadaColors.infoBlue,
                    ),
                  ),
                  if (_tracker.isLessonCompleted(les.id))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ScadaColors.runningGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ScadaColors.runningGreen),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: ScadaColors.runningGreen),
                          SizedBox(width: 4),
                          Text('COMPLETADA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.runningGreen)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                les.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                les.subtitle,
                style: const TextStyle(fontSize: 12, color: ScadaColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Barra de 8 pasos del método pedagógico
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: LessonStage.values.map((stg) {
              final isSel = stg == _currentStage;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _currentStage = stg),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? ScadaColors.infoBlue : ScadaColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? ScadaColors.infoBlue : ScadaColors.border),
                    ),
                    child: Text(
                      stg.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : ScadaColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Contenido dinámico del paso activo
        _buildStageContent(les, comp, cond, exp, evap),
        const SizedBox(height: 14),

        // Barra de acciones inferiores
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                BaseComponent? target;
                if (les.targetComponentId.startsWith('comp')) target = comp;
                if (les.targetComponentId.startsWith('cond')) target = cond;
                if (les.targetComponentId.startsWith('exp')) target = exp;
                if (les.targetComponentId.startsWith('evap')) target = evap;
                if (target != null) _openComponentModal(target);
              },
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('¿QUÉ ESTÁ PASANDO?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ScadaColors.infoBlue,
                side: const BorderSide(color: ScadaColors.infoBlue),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _nextLesson,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('SIGUIENTE LECCIÓN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ScadaColors.runningGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStageContent(LessonModel les, BaseComponent? comp, BaseComponent? cond, BaseComponent? exp, BaseComponent? evap) {
    switch (_currentStage) {
      case LessonStage.observe:
        return _card(
          icon: Icons.visibility,
          title: 'PASO 1: OBSERVA LA MÁQUINA',
          content: les.observeText,
          badgeColor: ScadaColors.infoBlue,
        );
      case LessonStage.interact:
        return _card(
          icon: Icons.touch_app,
          title: 'PASO 2: INTERACTÚA CON LOS COMPONENTES',
          content: les.interactPrompt,
          badgeColor: ScadaColors.warningAmber,
          actionWidget: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.engine.isRunning) {
                    widget.engine.pause();
                  } else {
                    widget.engine.start();
                  }
                },
                icon: Icon(widget.engine.isRunning ? Icons.pause : Icons.play_arrow, size: 16),
                label: Text(widget.engine.isRunning ? 'PAUSAR CICLO' : 'ARRANCAR CICLO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.engine.isRunning ? ScadaColors.warningAmber : ScadaColors.runningGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      case LessonStage.explain:
        return _card(
          icon: Icons.lightbulb_outline,
          title: 'PASO 3: EXPLICACIÓN TERMODINÁMICA',
          content: les.explainTheory,
          badgeColor: ScadaColors.infoBlue,
        );
      case LessonStage.experiment:
        return _card(
          icon: Icons.science,
          title: 'PASO 4: EXPERIMENTA Y COMPRUEBA EL EFECTO',
          content: les.experimentTask,
          badgeColor: ScadaColors.warningAmber,
        );
      case LessonStage.quiz:
        return _buildQuizCard(les);
      case LessonStage.practice:
        return _card(
          icon: Icons.fitness_center,
          title: 'PASO 6: PRACTICA EN LA INSTALACIÓN',
          content: les.practiceGoal,
          badgeColor: ScadaColors.infoBlue,
        );
      case LessonStage.verify:
        return _card(
          icon: Icons.task_alt,
          title: 'PASO 7: COMPRUEBA EL RESULTADO',
          content: les.verifyFeedback,
          badgeColor: ScadaColors.runningGreen,
        );
      case LessonStage.summary:
        return _card(
          icon: Icons.star,
          title: 'PASO 8: RESUMEN Y REGLA DE ORO DEL FRIGORISTA',
          content: les.summaryGoldenRule,
          badgeColor: ScadaColors.runningGreen,
          isHighlight: true,
        );
    }
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String content,
    required Color badgeColor,
    Widget? actionWidget,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? ScadaColors.runningGreen.withValues(alpha: 0.1) : ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighlight ? ScadaColors.runningGreen : ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: badgeColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: badgeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary, height: 1.4),
          ),
          if (actionWidget != null) ...[
            const SizedBox(height: 12),
            actionWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildQuizCard(LessonModel les) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.quiz, size: 18, color: ScadaColors.infoBlue),
              SizedBox(width: 8),
              Text(
                'PASO 5: PREGUNTA DE COMPROBACIÓN CONCEPTUAL',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.infoBlue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            les.quizQuestion,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...List.generate(les.quizOptions.length, (idx) {
            final isChosen = _selectedQuizOption == idx;
            final isCorrect = idx == les.correctQuizIndex;

            Color borderColor = ScadaColors.border;
            Color bgColor = ScadaColors.background;
            if (_quizAnswered) {
              if (isCorrect) {
                borderColor = ScadaColors.runningGreen;
                bgColor = ScadaColors.runningGreen.withValues(alpha: 0.15);
              } else if (isChosen) {
                borderColor = ScadaColors.dangerRed;
                bgColor = ScadaColors.dangerRed.withValues(alpha: 0.15);
              }
            } else if (isChosen) {
              borderColor = ScadaColors.infoBlue;
              bgColor = ScadaColors.infoBlue.withValues(alpha: 0.1);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _onAnswerQuiz(idx),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: isChosen ? 1.5 : 1.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _quizAnswered
                            ? (isCorrect ? Icons.check_circle : (isChosen ? Icons.cancel : Icons.radio_button_unchecked))
                            : (isChosen ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                        size: 16,
                        color: _quizAnswered
                            ? (isCorrect ? ScadaColors.runningGreen : (isChosen ? ScadaColors.dangerRed : ScadaColors.textMuted))
                            : (isChosen ? ScadaColors.infoBlue : ScadaColors.textMuted),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          les.quizOptions[idx],
                          style: TextStyle(
                            fontSize: 12,
                            color: _quizAnswered && isCorrect ? ScadaColors.runningGreen : ScadaColors.textPrimary,
                            fontWeight: _quizAnswered && isCorrect ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_quizAnswered) ...[
            const SizedBox(height: 8),
            Text(
              _selectedQuizOption == les.correctQuizIndex
                  ? '¡RESPUESTA CORRECTA! ${les.verifyFeedback}'
                  : 'INCORRECTO. Revisa la explicación del paso 3 y vuelve a intentarlo.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _selectedQuizOption == les.correctQuizIndex ? ScadaColors.runningGreen : ScadaColors.dangerRed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
