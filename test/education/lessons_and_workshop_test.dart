import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/education/lessons/lesson_model.dart';
import 'package:frigolab/education/lessons/progress_tracker.dart';
import 'package:frigolab/education/virtual_teacher/virtual_teacher_service.dart';
import 'package:frigolab/workshop/assembly_models.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';

void main() {
  group('Educational Syllabus & LessonModel Tests', () {
    test('All 11 official lessons (0 to 10) are present and complete', () {
      final lessons = LessonModel.allLessons;
      expect(lessons.length, equals(11));

      for (int i = 0; i < 11; i++) {
        final lesson = lessons[i];
        expect(lesson.index, equals(i));
        expect(lesson.id, equals('lesson_$i'));
        expect(lesson.title.isNotEmpty, isTrue);
        expect(lesson.subtitle.isNotEmpty, isTrue);
        expect(lesson.targetComponentId.isNotEmpty, isTrue);

        // Validar que cada lección contiene los 8 pasos pedagógicos
        expect(lesson.observeText.isNotEmpty, isTrue);
        expect(lesson.interactPrompt.isNotEmpty, isTrue);
        expect(lesson.explainTheory.isNotEmpty, isTrue);
        expect(lesson.experimentTask.isNotEmpty, isTrue);
        expect(lesson.quizQuestion.isNotEmpty, isTrue);
        expect(lesson.quizOptions.length, greaterThanOrEqualTo(3));
        expect(lesson.correctQuizIndex, inInclusiveRange(0, lesson.quizOptions.length - 1));
        expect(lesson.practiceGoal.isNotEmpty, isTrue);
        expect(lesson.verifyFeedback.isNotEmpty, isTrue);
        expect(lesson.summaryGoldenRule.isNotEmpty, isTrue);
      }
    });

    test('ProgressTracker accurately tracks student progression', () {
      final tracker = ProgressTracker();
      tracker.resetProgress();

      // Al inicio debe estar la lección 0 completada
      expect(tracker.completedLessonIds.contains('lesson_0'), isTrue);
      expect(tracker.syllabusCompletionPercent, closeTo(1.0 / 11.0, 1e-2));

      // Completar lección 1 y registrar conceptos
      tracker.markLessonCompleted('lesson_1', newMasteredConcepts: ['Ciclo Frigorífico']);
      expect(tracker.isLessonCompleted('lesson_1'), isTrue);
      expect(tracker.masteredConcepts.contains('Ciclo Frigorífico'), isTrue);
      expect(tracker.syllabusCompletionPercent, closeTo(2.0 / 11.0, 1e-2));

      // Registrar respuestas de quiz
      tracker.recordQuizAnswer(isCorrect: true);
      tracker.recordQuizAnswer(isCorrect: false);
      expect(tracker.totalQuizAttempts, equals(2));
      expect(tracker.correctQuizCount, equals(1));

      // Completar práctica de taller
      tracker.markWorkshopPracticeCompleted('practica_01');
      expect(tracker.completedWorkshopPractices.contains('practica_01'), isTrue);
    });
  });

  group('Assembly Workshop & Connection Validation Tests', () {
    const compOut = WorkshopPort(
      id: 'comp_out',
      componentId: 'comp_1',
      label: 'Descarga Compresor',
      type: WorkshopPortType.outlet,
      pressureLevel: PortPressureLevel.high,
    );
    const condIn = WorkshopPort(
      id: 'cond_in',
      componentId: 'cond_1',
      label: 'Entrada Condensador',
      type: WorkshopPortType.inlet,
      pressureLevel: PortPressureLevel.high,
    );
    const condOut = WorkshopPort(
      id: 'cond_out',
      componentId: 'cond_1',
      label: 'Salida Condensador',
      type: WorkshopPortType.outlet,
      pressureLevel: PortPressureLevel.high,
    );
    const expIn = WorkshopPort(
      id: 'exp_in',
      componentId: 'exp_1',
      label: 'Entrada Válvula Expansión',
      type: WorkshopPortType.inlet,
      pressureLevel: PortPressureLevel.high,
    );
    const expOut = WorkshopPort(
      id: 'exp_out',
      componentId: 'exp_1',
      label: 'Salida Válvula Expansión',
      type: WorkshopPortType.outlet,
      pressureLevel: PortPressureLevel.low,
    );
    const evapIn = WorkshopPort(
      id: 'evap_in',
      componentId: 'evap_1',
      label: 'Entrada Evaporador',
      type: WorkshopPortType.inlet,
      pressureLevel: PortPressureLevel.low,
    );
    const evapOut = WorkshopPort(
      id: 'evap_out',
      componentId: 'evap_1',
      label: 'Salida Evaporador',
      type: WorkshopPortType.outlet,
      pressureLevel: PortPressureLevel.low,
    );
    const compIn = WorkshopPort(
      id: 'comp_in',
      componentId: 'comp_1',
      label: 'Aspiración Compresor',
      type: WorkshopPortType.inlet,
      pressureLevel: PortPressureLevel.low,
    );

    test('Rejects invalid connection between two inlet ports', () {
      final res = WorkshopValidator.validateConnectionAttempt(
        fromPort: condIn,
        toPort: evapIn,
      );
      expect(res.isValid, isFalse);
      expect(res.feedback, contains('No se pueden unir dos puertos de entrada'));
      expect(res.rule, contains('Salida -> Entrada'));
    });

    test('Rejects invalid connection between two outlet ports', () {
      final res = WorkshopValidator.validateConnectionAttempt(
        fromPort: compOut,
        toPort: condOut,
      );
      expect(res.isValid, isFalse);
      expect(res.feedback, contains('No se pueden unir dos puertos de salida'));
      expect(res.rule, contains('Salida -> Entrada'));
    });

    test('Rejects short-circuit on the same component', () {
      final res = WorkshopValidator.validateConnectionAttempt(
        fromPort: compOut,
        toPort: compIn,
      );
      expect(res.isValid, isFalse);
      expect(res.feedback, contains('No puedes recircular la salida de un componente directamente a su propia entrada'));
    });

    test('Rejects thermodynamically reversed order with pedagogical explanation', () {
      // Intentar conectar Compresor Descarga a la TXV en lugar de al Condensador
      final res = WorkshopValidator.validateConnectionAttempt(
        fromPort: compOut,
        toPort: expIn,
      );
      expect(res.isValid, isFalse);
      expect(res.feedback, contains('La descarga del compresor entrega vapor a alta presión'));
      expect(res.feedback, contains('Debe conducirse hacia el condensador'));
      expect(res.rule, contains('REGLA DE SECUENCIA'));
    });

    test('Accepts all 4 valid connections forming a closed industrial cycle', () {
      // 1. Descarga Compresor -> Entrada Condensador
      final c1 = WorkshopValidator.validateConnectionAttempt(fromPort: compOut, toPort: condIn);
      expect(c1.isValid, isTrue);

      // 2. Salida Condensador -> Entrada TXV
      final c2 = WorkshopValidator.validateConnectionAttempt(fromPort: condOut, toPort: expIn);
      expect(c2.isValid, isTrue);

      // 3. Salida TXV -> Entrada Evaporador
      final c3 = WorkshopValidator.validateConnectionAttempt(fromPort: expOut, toPort: evapIn);
      expect(c3.isValid, isTrue);

      // 4. Salida Evaporador -> Aspiración Compresor
      final c4 = WorkshopValidator.validateConnectionAttempt(fromPort: evapOut, toPort: compIn);
      expect(c4.isValid, isTrue);
    });
  });

  group('Virtual Teacher Service Tests', () {
    late SimulationEngine engine;

    setUp(() {
      engine = SimulationEngine();
    });

    tearDown(() {
      engine.pause();
      engine.dispose();
    });

    test('Detects starting transient event and explains why', () {
      engine.start();
      // Un solo paso corto para estar en modo starting
      engine.step();

      final alert = VirtualTeacherService.detectEvent(engine.state);
      expect(alert, isNotNull);
      expect(alert!.title, contains('arrancar'));
      expect(alert.whyExplanation, contains('El motor eléctrico acelera'));
      expect(alert.associatedComponentId, equals('comp_1'));
    });

    test('Generates live questions based on current simulation values', () {
      engine.start();
      for (int i = 0; i < 20; i++) {
        engine.step();
      }

      final questions = VirtualTeacherService.generateCurrentQuestions(engine.state);
      expect(questions.isNotEmpty, isTrue);
      for (final q in questions) {
        expect(q.question.isNotEmpty, isTrue);
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
        expect(q.pedagogicalFeedback.isNotEmpty, isTrue);
      }
    });
  });
}
