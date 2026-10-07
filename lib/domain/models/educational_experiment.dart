/// Definición y estado de un experimento didáctico guiado en el laboratorio.
enum ExperimentType {
  rpmVariation,
  ambientTemperatureVariation,
  expansionValveThrottling,
  condenserAirflowReduction,
  thermalLoadIncrease,
  severeExpansionThrottling;
}

enum ExperimentPhase {
  notStarted,
  stabilizingBaseline,
  readyToPerturb,
  observingTransient,
  evaluatingResults,
  completed;
}

class EducationalExperiment {
  final ExperimentType type;
  final String title;
  final String hypothesisQuestion;
  final List<String> quizOptions;
  final int correctOptionIndex;
  final String physicalExplanation;
  final ExperimentPhase phase;

  // Variables de control de la perturbación
  final double baselineValue;
  final double perturbedValue;
  final String parameterName;
  final String unitSymbol;

  const EducationalExperiment({
    required this.type,
    required this.title,
    required this.hypothesisQuestion,
    required this.quizOptions,
    required this.correctOptionIndex,
    required this.physicalExplanation,
    this.phase = ExperimentPhase.notStarted,
    required this.baselineValue,
    required this.perturbedValue,
    required this.parameterName,
    required this.unitSymbol,
  });

  String get id => type.name;

  static List<EducationalExperiment> get builtInExperiments => availableExperiments;

  static List<EducationalExperiment> get availableExperiments => [
        const EducationalExperiment(
          type: ExperimentType.rpmVariation,
          title: 'Práctica 1: Influencia de la velocidad del compresor (RPM)',
          parameterName: 'RPM Compresor',
          unitSymbol: 'RPM',
          baselineValue: 1450.0,
          perturbedValue: 2900.0,
          hypothesisQuestion:
              'Si duplicamos la velocidad de giro del compresor de 1450 a 2900 RPM, ¿qué ocurrirá con el caudal másico y las presiones del sistema?',
          quizOptions: [
            'A) El caudal másico aumenta, la presión de baja disminuye ligeramente y la de alta aumenta para evacuar más calor.',
            'B) El caudal disminuye debido a la fricción y ambas presiones caen a cero.',
            'C) El caudal aumenta pero las presiones permanecen inalterables en todo momento.',
          ],
          correctOptionIndex: 0,
          physicalExplanation:
              'Al aumentar las RPM, el compresor desplaza mayor volumen de gas por unidad de tiempo. Al aspirar más vapor del evaporador, la presión de baja tiende a disminuir, mientras que el condensador recibe más refrigerante y debe trabajar a mayor presión y temperatura para transferir el exceso de calor al aire exterior.',
        ),
        const EducationalExperiment(
          type: ExperimentType.ambientTemperatureVariation,
          title: 'Práctica 2: Influencia de una ola de calor exterior (T_amb)',
          parameterName: 'Temperatura Ambiente',
          unitSymbol: '°C',
          baselineValue: 22.0,
          perturbedValue: 38.0,
          hypothesisQuestion:
              'Si la temperatura exterior sube de 22 °C a 38 °C (verano intenso), ¿cómo responderá el condensador y la eficiencia global (COP)?',
          quizOptions: [
            'A) La presión de condensación se mantiene igual y el COP aumenta.',
            'B) La presión y temperatura de condensación aumentan obligadas por el salto térmico con el aire, provocando que el compresor consuma más energía y el COP disminuya.',
            'C) La presión de alta disminuye porque el calor exterior fluidifica el gas.',
          ],
          correctOptionIndex: 1,
          physicalExplanation:
              'El condensador necesita una diferencia de temperatura positiva (T_cond > T_amb) para ceder calor. Si el aire exterior está más caliente, la temperatura de condensación debe subir forzosamente, aumentando la presión de alta (Pk). Esto incrementa la relación de compresión, eleva el consumo eléctrico y deteriora el COP de la máquina.',
        ),
        const EducationalExperiment(
          type: ExperimentType.expansionValveThrottling,
          title: 'Práctica 3: Estrangulamiento de la Válvula de Expansión (TXV)',
          parameterName: 'Apertura TXV',
          unitSymbol: '%',
          baselineValue: 50.0,
          perturbedValue: 15.0,
          hypothesisQuestion:
              'Si cerramos la válvula de expansión del 50% al 15%, ¿qué sucederá con el recalentamiento (Superheat) a la salida del evaporador?',
          quizOptions: [
            'A) El recalentamiento disminuirá drásticamente, inundando el compresor de líquido.',
            'B) El recalentamiento no variará porque solo depende del forzador de la cámara.',
            'C) El recalentamiento aumentará fuertemente porque entra poco líquido y el gas se sobrecalienta en los tubos secos.',
          ],
          correctOptionIndex: 2,
          physicalExplanation:
              'Al estrangular la válvula entra muy poco caudal líquido al evaporador. Este líquido se evapora en los primeros metros de la batería, y todo el tramo restante de tubos solo transporta vapor que continúa absorbiendo calor del aire. El vapor se sobrecalienta excesivamente (alto superheat), reduciendo la potencia frigorífica.',
        ),
        const EducationalExperiment(
          type: ExperimentType.condenserAirflowReduction,
          title: 'Práctica 4: Reducción del Caudal de Aire en el Condensador',
          parameterName: 'Ensuciamiento Condensador',
          unitSymbol: '%',
          baselineValue: 0.0,
          perturbedValue: 80.0,
          hypothesisQuestion:
              'Si el condensador se ensucia severamente o el ventilador pierde caudal, ¿qué le ocurrirá a la presión de condensación y al trabajo del compresor?',
          quizOptions: [
            'A) La presión de condensación se disparará al perder capacidad de disipación, obligando al compresor a consumir más energía.',
            'B) El compresor se detendrá de inmediato porque el condensador genera vacío.',
            'C) La presión de alta bajará porque el aire ya no roba calor.',
          ],
          correctOptionIndex: 0,
          physicalExplanation:
              'Al reducir el coeficiente de transferencia UA o el flujo de aire, el salto térmico requerido para disipar el calor liberado se multiplica. La presión y temperatura de saturación de condensación aumentan bruscamente, elevando la relación de compresión y el riesgo de disparo por presostato de alta.',
        ),
        const EducationalExperiment(
          type: ExperimentType.thermalLoadIncrease,
          title: 'Práctica 5: Incremento de la Carga Térmica en el Recinto',
          parameterName: 'Carga Interna Recinto',
          unitSymbol: 'W',
          baselineValue: 250.0,
          perturbedValue: 2500.0,
          hypothesisQuestion:
              'Si se introducen de golpe 2500 W de producto caliente en la cámara, ¿cómo responderán la presión de evaporación y el abatimiento de temperatura?',
          quizOptions: [
            'A) La presión de baja aumentará inmediatamente por mayor transferencia de calor, y el tiempo de enfriamiento se alargará.',
            'B) La presión de baja caerá a cero porque el calor extra agota el gas.',
            'C) El compresor disminuirá sus RPM para proteger la cámara.',
          ],
          correctOptionIndex: 0,
          physicalExplanation:
              'El mayor flujo de calor desde el recinto hacia los tubos del evaporador intensifica la ebullición del refrigerante, elevando la presión de evaporación P₀ y la densidad del vapor aspirado. La instalación absorbe más potencia pero la cámara tarda más tiempo en alcanzar la consigna.',
        ),
        const EducationalExperiment(
          type: ExperimentType.severeExpansionThrottling,
          title: 'Práctica 6: Estrangulamiento Severo de la TXV (Falta de Alimentación)',
          parameterName: 'Apertura TXV',
          unitSymbol: '%',
          baselineValue: 45.0,
          perturbedValue: 10.0,
          hypothesisQuestion:
              'Si la válvula de expansión se estrangula al 10%, ¿qué ocurrirá con el caudal másico y el recalentamiento?',
          quizOptions: [
            'A) El caudal disminuye drásticamente, la presión de evaporación cae en picado y el recalentamiento se dispara.',
            'B) El evaporador se inunda de líquido y el recalentamiento cae a 0 K.',
            'C) La instalación genera el doble de potencia frigorífica.',
          ],
          correctOptionIndex: 0,
          physicalExplanation:
              'Un orificio fuertemente estrangulado restringe el caudal másico por debajo de la capacidad de aspiración del compresor. La presión de evaporación cae hacia el vacío, la batería se desnutre y el gas se recalienta excesivamente antes de llegar al compresor.',
        ),
      ];

  EducationalExperiment copyWith({
    ExperimentPhase? phase,
  }) {
    return EducationalExperiment(
      type: type,
      title: title,
      hypothesisQuestion: hypothesisQuestion,
      quizOptions: quizOptions,
      correctOptionIndex: correctOptionIndex,
      physicalExplanation: physicalExplanation,
      phase: phase ?? this.phase,
      baselineValue: baselineValue,
      perturbedValue: perturbedValue,
      parameterName: parameterName,
      unitSymbol: unitSymbol,
    );
  }
}
