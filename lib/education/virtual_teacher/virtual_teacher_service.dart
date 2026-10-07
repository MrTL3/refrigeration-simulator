import '../../domain/models/transient_metrics.dart';
import '../../simulation/engine/simulation_state.dart';

/// Notificación pedagógica contextual generada por el profesor virtual
class ContextualAlert {
  final String title;
  final String description;
  final String whyExplanation;
  final String associatedComponentId;

  const ContextualAlert({
    required this.title,
    required this.description,
    required this.whyExplanation,
    required this.associatedComponentId,
  });
}

/// Pregunta diagnóstica generada por el profesor virtual a partir del estado vivo
class TeacherQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String pedagogicalFeedback;

  const TeacherQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.pedagogicalFeedback,
  });
}

/// Servicio del Profesor Virtual y Detección de Eventos Contextuales en Tiempo Real
class VirtualTeacherService {
  /// Detecta eventos relevantes comparando el estado actual con las derivadas y modos
  static ContextualAlert? detectEvent(SimulationState state) {
    if (!state.isRunning) {
      if (state.operationalMode == SystemOperationalMode.stopping) {
        return const ContextualAlert(
          title: 'El ciclo se ha detenido: ecualización en curso',
          description: 'Las presiones de alta y baja están convergiendo a través del orificio de la válvula.',
          whyExplanation: 'Al cesar la compresión, el refrigerante de alta presión continúa pasando por la TXV hacia el evaporador hasta que ambos lados alcanzan la misma presión de equilibrio saturada con el ambiente.',
          associatedComponentId: 'exp_1',
        );
      }
      return null;
    }

    if (state.operationalMode == SystemOperationalMode.starting) {
      return const ContextualAlert(
        title: 'El compresor acaba de arrancar',
        description: 'Aceleración inercial del motor y bifurcación inicial de presiones.',
        whyExplanation: 'El motor eléctrico acelera progresivamente hasta vencer el par resistente. Los pistones empiezan a aspirar vapor del evaporador (bajando P₀) y descargarlo en el condensador (subiendo Pₖ).',
        associatedComponentId: 'comp_1',
      );
    }

    if (state.trendPCond.direction == TrendDirection.rising && state.trendPCond.derivativePerSec > 1500.0) {
      return ContextualAlert(
        title: 'La presión de condensación está aumentando',
        description: 'La tasa de descarga supera la evacuación térmica hacia el aire exterior.',
        whyExplanation: 'El compresor bombea gas caliente a alta velocidad. Hasta que el salto térmico (T_cond - T_amb) no sea suficientemente grande, el calor no se disipa al ritmo necesario, obligando a elevar la presión de saturación Pₖ.',
        associatedComponentId: 'cond_1',
      );
    }

    if (state.trendTRoom.direction == TrendDirection.falling && state.trendTRoom.derivativePerSec.abs() > 0.005) {
      return const ContextualAlert(
        title: 'Abatimiento térmico activo (Pull-down)',
        description: 'La potencia frigorífica neta supera la transmisión exterior del recinto.',
        whyExplanation: 'La potencia extraída en el evaporador Q̇_e es superior a la carga térmica global de la cámara, reduciendo la entalpía del aire del recinto progresivamente hacia la consigna del termostato.',
        associatedComponentId: 'evap_1',
      );
    }

    return null;
  }

  /// Genera preguntas del profesor virtual evaluando la comprensión de la instalación viva
  static List<TeacherQuestion> generateCurrentQuestions(SimulationState state) {
    final s1 = state.state1Suction;
    final pBar = state.condensingPressurePa / 1e5;

    return [
      TeacherQuestion(
        question: 'Observa el Punto 1 (Aspiración del compresor). ¿En qué estado físico se encuentra el refrigerante?',
        options: [
          'A) Líquido subenfriado.',
          'B) Mezcla bifásica líquido-vapor.',
          'C) Vapor sobrecalentado a baja presión.',
          'D) Gas licuado a alta temperatura.',
        ],
        correctIndex: 2,
        pedagogicalFeedback: '¡Exacto! El refrigerante sale del evaporador como vapor sobrecalentado (${s1.phaseState.displayName}) con ${state.superheatKelvin.toStringAsFixed(1)} K de superheat para proteger al compresor.',
      ),
      TeacherQuestion(
        question: 'La presión de condensación actual es de ${pBar.toStringAsFixed(1)} bar. ¿Qué función cumple esta alta presión?',
        options: [
          'A) Elevar la temperatura de saturación para que sea superior al aire exterior y poder ceder calor.',
          'B) Comprimir el aceite hacia los pistones para enfriarlo.',
          'C) Impedir que el refrigerante hierva en el evaporador.',
        ],
        correctIndex: 0,
        pedagogicalFeedback: '¡Correcto! En refrigeración necesitamos elevar la presión para que el fluido condense a una temperatura superior a los 25-35 °C del aire ambiente.',
      ),
      TeacherQuestion(
        question: '¿Qué le ocurriría a la potencia frigorífica útil si cerramos la TXV reduciendo su apertura?',
        options: [
          'A) Aumentaría porque el frío sale con más fuerza.',
          'B) Disminuiría porque el caudal másico que alimenta al evaporador cae drásticamente.',
          'C) Permanecería exactamente igual.',
        ],
        correctIndex: 1,
        pedagogicalFeedback: '¡Muy bien! Q_e = ṁ · (h₁ - h₄). Al estrangular la válvula, ṁ disminuye y la potencia frigorífica se desploma.',
      ),
    ];
  }
}
