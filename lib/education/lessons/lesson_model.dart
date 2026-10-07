/// Etapas del método pedagógico interactivo de FrigoLab
enum LessonStage {
  observe('1. OBSERVA', 'Visualización guiada'),
  interact('2. INTERACTÚA', 'Manipulación directa'),
  explain('3. EXPLICA', 'Fundamento termodinámico'),
  experiment('4. EXPERIMENTA', 'Inyección de cambios'),
  quiz('5. PREGUNTA', 'Comprobación conceptual'),
  practice('6. PRACTICA', 'Reto en la máquina'),
  verify('7. COMPRUEBA', 'Evaluación de resultados'),
  summary('8. RESUMEN', 'Regla de oro del frigorista');

  final String label;
  final String description;
  const LessonStage(this.label, this.description);
}

/// Modelo de datos de una Lección Interactiva de FrigoLab
class LessonModel {
  final int index;
  final String id;
  final String title;
  final String subtitle;
  final String targetComponentId;

  // Los 8 pasos interactivos
  final String observeText;
  final String interactPrompt;
  final String explainTheory;
  final String experimentTask;
  final String quizQuestion;
  final List<String> quizOptions;
  final int correctQuizIndex;
  final String practiceGoal;
  final String verifyFeedback;
  final String summaryGoldenRule;

  const LessonModel({
    required this.index,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetComponentId,
    required this.observeText,
    required this.interactPrompt,
    required this.explainTheory,
    required this.experimentTask,
    required this.quizQuestion,
    required this.quizOptions,
    required this.correctQuizIndex,
    required this.practiceGoal,
    required this.verifyFeedback,
    required this.summaryGoldenRule,
  });

  /// Colección completa de las 11 lecciones de la ruta educativa oficial
  static List<LessonModel> get allLessons => [
    const LessonModel(
      index: 0,
      id: 'lesson_0',
      title: 'Lección 0: ¿Qué es el frío?',
      subtitle: 'La ausencia de calor y la termodinámica del calor sensible y latente',
      targetComponentId: 'evap_1',
      observeText: 'Observa la cámara frigorífica. El frío no es una energía que se inyecta desde fuera, sino la extracción física de calor del aire y de los alimentos.',
      interactPrompt: 'Toca el evaporador. Observa cómo el refrigerante hierve a baja temperatura para "robar" calorías al recinto.',
      explainTheory: 'La Primera y Segunda Ley de la Termodinámica dictan que el calor siempre fluye espontáneamente de lo caliente a lo frío. Para enfriar una cámara a 4 °C, necesitamos un fluido todavía más frío (a -5 °C) circulando por los tubos.',
      experimentTask: 'Pausa y arranca el ciclo. Comprueba cómo al detener el flujo, el recinto vuelve a calentarse por la transmisión del ambiente exterior.',
      quizQuestion: '¿Cómo consigue una máquina frigorífica enfriar un recinto?',
      quizOptions: [
        'A) Inyectando partículas de frío procedentes de un depósito a presión.',
        'B) Extrayendo calor del recinto mediante un refrigerante que evapora a menor temperatura.',
        'C) Destruyendo la energía térmica del aire mediante un campo magnético.',
      ],
      correctQuizIndex: 1,
      practiceGoal: 'Mantén la instalación encendida hasta observar que la temperatura del recinto empieza a descender.',
      verifyFeedback: '¡Correcto! En refrigeración no creamos frío: trasladamos el calor indeseado del recinto hacia el exterior.',
      summaryGoldenRule: 'REGLA DE ORO: El frío no existe físicamente; es simplemente la ausencia de calor. Enfriar es extraer calor.',
    ),
    const LessonModel(
      index: 1,
      id: 'lesson_1',
      title: 'Lección 1: El ciclo frigorífico básico',
      subtitle: 'Los 4 procesos fundamentales: Compresión, Condensación, Expansión y Evaporación',
      targetComponentId: 'comp_1',
      observeText: 'Observa las 4 tuberías y el circuito cerrado. El refrigerante circula en un bucle continuo cambiando de estado líquido a vapor y viceversa.',
      interactPrompt: 'Recorre el ciclo con el dedo en el sentido de las flechas: Compresor -> Condensador -> TXV -> Evaporador -> Compresor.',
      explainTheory: 'El ciclo tiene dos niveles de presión: ALTA PRESIÓN (rojo/naranja: descarga y líquido) y BAJA PRESIÓN (azul claro/oscuro: evaporación y aspiración). La TXV y el compresor son las dos fronteras que separan ambas zonas.',
      experimentTask: 'Observa las diferencias de presión entre el manómetro de alta (Pₖ) y el manómetro de baja (P₀).',
      quizQuestion: '¿Qué dos componentes separan el lado de alta presión del lado de baja presión?',
      quizOptions: [
        'A) El condensador y el evaporador.',
        'B) El compresor y la válvula de expansión.',
        'C) El filtro deshidratador y el termostato.',
      ],
      correctQuizIndex: 1,
      practiceGoal: 'Identifica los 4 componentes tocando cada uno en el esquema sinóptico.',
      verifyFeedback: '¡Excelente! El compresor eleva la presión de baja a alta, y la válvula de expansión reduce la presión de alta a baja.',
      summaryGoldenRule: 'REGLA DE ORO: Un ciclo frigorífico es una bomba de calor que extrae calor a baja presión y lo expulsa a alta presión.',
    ),
    const LessonModel(
      index: 2,
      id: 'lesson_2',
      title: 'Lección 2: El compresor',
      subtitle: 'El corazón del circuito: aspiración, trabajo mecánico y descarga caliente',
      targetComponentId: 'comp_1',
      observeText: 'Observa el compresor alternativo en marcha. Escucha mentalmente el motor de 2900 RPM y fíjate en el tubo de descarga al rojo térmico.',
      interactPrompt: 'Abre el inspector del compresor. Comprueba la cilindrada geométrica y la potencia eléctrica consumida.',
      explainTheory: 'El compresor aspira vapor sobrecalentado y reduce su volumen en los cilindros. El trabajo mecánico entregado se transforma en presión y en una gran elevación de temperatura.',
      experimentTask: 'Modifica las RPM del compresor de 1450 a 2900 RPM y observa el incremento del caudal másico bombeado.',
      quizQuestion: '¿Por qué está terminantemente prohibido que entre líquido al compresor?',
      quizOptions: [
        'A) Porque los líquidos son prácticamente incompresibles y romperían las válvulas y bielas mecánicas (golpe de líquido).',
        'B) Porque el líquido congelaría el aceite lubricante al instante.',
        'C) Porque el motor eléctrico se pararía por falta de resistencia eléctrica.',
      ],
      correctQuizIndex: 0,
      practiceGoal: 'Configura las RPM a 2500 y comprueba que el caudal másico supere los 10 g/s.',
      verifyFeedback: '¡Perfecto! El compresor es una bomba de vapor; el líquido es incompresible y destruye las láminas.',
      summaryGoldenRule: 'REGLA DE ORO: Al compresor solo debe entrar vapor. El líquido destruye el mecanismo de compresión.',
    ),
    const LessonModel(
      index: 3,
      id: 'lesson_3',
      title: 'Lección 3: El condensador',
      subtitle: 'Disipación de calor: desrecalentamiento, condensación y subenfriamiento',
      targetComponentId: 'cond_1',
      observeText: 'Observa la batería de tubos con aletas del condensador. El aire exterior impulsado por el ventilador absorbe el calor del refrigerante.',
      interactPrompt: 'Toca el condensador. Comprueba cómo la temperatura de condensación es siempre superior a la temperatura ambiente exterior.',
      explainTheory: 'En el condensador ocurren 3 fenómenos sucesivos: 1. El gas caliente se desrecalienta hasta saturación. 2. El vapor condensa a temperatura constante liberando calor latente. 3. El líquido resultante se subenfría unos grados.',
      experimentTask: 'Desactiva el ventilador del condensador o añade suciedad en los mandos. Mira cómo se dispara la presión de descarga.',
      quizQuestion: 'Si la temperatura exterior es de 25 °C, ¿a qué temperatura debe condensar aproximadamente el refrigerante?',
      quizOptions: [
        'A) A 10 °C, para estar más frío que el ambiente.',
        'B) A unos 38 °C a 42 °C (salto de 13 a 17 K superior al ambiente para poder expulsar el calor).',
        'C) Exactamente a 0 °C.',
      ],
      correctQuizIndex: 1,
      practiceGoal: 'Verifica en la telemetría que la potencia de rechazo (Q_c) sea igual a Q_e + W_comp.',
      verifyFeedback: '¡Exacto! Para que el calor fluya hacia el aire exterior de 25 °C, el refrigerante debe condensar a unos 40 °C.',
      summaryGoldenRule: 'REGLA DE ORO: La condensación ocurre siempre por encima de la temperatura ambiente exterior.',
    ),
    const LessonModel(
      index: 4,
      id: 'lesson_4',
      title: 'Lección 4: La expansión y la TXV',
      subtitle: 'Estrangulamiento isentálpico, generación de flash gas y dosificación',
      targetComponentId: 'exp_1',
      observeText: 'Observa la pequeña válvula con su bulbo sensor. Es el orificio restrictor donde la presión cae en picado.',
      interactPrompt: 'Modifica la apertura de la válvula TXV del 50% al 20% en el panel de mandos.',
      explainTheory: 'La expansión es un proceso isentálpico (h₄ = h₃). Al reducirse la presión de golpe, una parte del refrigerante hierve al instante generando "flash gas", enfriando el resto del líquido a la temperatura de evaporación.',
      experimentTask: 'Cierra la válvula al 15% y observa cómo el recalentamiento (superheat) se dispara por falta de líquido en la batería.',
      quizQuestion: '¿Qué ocurre con la entalpía del refrigerante al pasar por una válvula de expansión termostática ideal?',
      quizOptions: [
        'A) Se multiplica por dos.',
        'B) Permanece prácticamente constante (h_salida ≈ h_entrada), ya que no hay trabajo ni calor intercambiado.',
        'C) Cae a cero.',
      ],
      correctQuizIndex: 1,
      practiceGoal: 'Establece la apertura de la TXV en 45% y comprueba que el recalentamiento se estabilice entre 6 y 8 K.',
      verifyFeedback: '¡Muy bien! La expansión es isentálpica: no produce trabajo exterior ni intercambia calor con el aire.',
      summaryGoldenRule: 'REGLA DE ORO: La TXV no enfría porque absorba calor, sino porque reduce la presión obligando al fluido a enfriarse a sí mismo.',
    ),
    const LessonModel(
      index: 5,
      id: 'lesson_5',
      title: 'Lección 5: El evaporador',
      subtitle: 'Absorción de calor útil: ebullición latente y sobrecalentamiento de seguridad',
      targetComponentId: 'evap_1',
      observeText: 'Observa el evaporador situado dentro de la cámara. Las gotas de refrigerante entran frías y hierven al absorber el calor del aire del recinto.',
      interactPrompt: 'Abre el inspector del evaporador y comprueba la potencia frigorífica útil Q_e (kW).',
      explainTheory: 'La ebullición del refrigerante ocurre a temperatura y presión constantes mientras absorbe una enorme cantidad de calor latente de vaporización. Al final del tubo, el vapor seco se calienta unos grados más (recalentamiento útil).',
      experimentTask: 'Varía la temperatura del recinto de 4 °C a 12 °C y observa cómo aumenta el calor absorbido por mayor salto térmico.',
      quizQuestion: '¿En qué estado físico entra el refrigerante en el evaporador tras salir de la TXV?',
      quizOptions: [
        'A) Vapor 100% recalentado.',
        'B) Líquido 100% puro sin burbujas.',
        'C) Mezcla bifásica de líquido frío con una fracción de vapor (título x ≈ 0.2 a 0.3).',
      ],
      correctQuizIndex: 2,
      practiceGoal: 'Observa en el diagrama P-h cómo el Punto 4 se sitúa dentro de la campana bifásica.',
      verifyFeedback: '¡Correcto! Entra como una niebla fría bifásica que termina de evaporarse por completo a lo largo del serpentín.',
      summaryGoldenRule: 'REGLA DE ORO: El evaporador aprovecha el calor latente de cambio de fase: hervir un líquido absorbe muchísimo más calor que calentarlo.',
    ),
    const LessonModel(
      index: 6,
      id: 'lesson_6',
      title: 'Lección 6: Presión y temperatura',
      subtitle: 'La relación indisoluble en los cambios de fase: la regla de refrigerantes',
      targetComponentId: 'comp_1',
      observeText: 'Observa los manómetros. Cada presión tiene debajo una temperatura equivalente marcada en la escala del fluido.',
      interactPrompt: 'Cambia las unidades de presión de bar a PSI y comprueba cómo la relación física se mantiene inalterable.',
      explainTheory: 'Para un fluido puro como el R-134a, en la zona de cambio de fase existe una relación biunívoca estricta: fijada la presión, la temperatura de ebullición queda automáticamente fijada.',
      experimentTask: 'Consulta en la telemetría la presión de baja (ej. 2.0 bar) y comprueba que su temperatura de saturación es de aprox. -10 °C.',
      quizQuestion: 'Si aumentamos la presión en el interior de una botella de refrigerante, ¿qué ocurre con su temperatura de ebullición?',
      quizOptions: [
        'A) Disminuye.',
        'B) Permanece exactamente igual.',
        'C) Aumenta.',
      ],
      correctQuizIndex: 2,
      practiceGoal: 'Comprueba con el manómetro de alta la presión de descarga y su temperatura de saturación asociada.',
      verifyFeedback: '¡Exacto! A mayor presión, mayor temperatura de ebullición/condensación. Es el principio de la olla a presión.',
      summaryGoldenRule: 'REGLA DE ORO: En cambio de fase, controlar la presión es controlar exactamente la temperatura.',
    ),
    const LessonModel(
      index: 7,
      id: 'lesson_7',
      title: 'Lección 7: Temperatura de saturación',
      subtitle: 'Comprender la campana de Mollier: líquido saturado, vapor saturado y flash gas',
      targetComponentId: 'cond_1',
      observeText: 'Abre el diagrama P-h. Observa la gran campana verde que divide el plano en tres mundos termodinámicos.',
      interactPrompt: 'Toca la línea izquierda de la campana (líquido saturado, x=0) y la línea derecha (vapor saturado, x=1).',
      explainTheory: 'Dentro de la campana coexisten líquido y vapor a la misma temperatura (T_sat). A la izquierda todo es líquido subenfriado; a la derecha todo es gas sobrecalentado.',
      experimentTask: 'Toca el Punto 2 en el diagrama P-h y observa que se sitúa claramente a la derecha de la campana.',
      quizQuestion: '¿Qué significa que el refrigerante esté en "estado saturado"?',
      quizOptions: [
        'A) Que está a punto de cambiar de fase a la presión y temperatura dadas (ebullición o condensación).',
        'B) Que el circuito contiene demasiado refrigerante y se va a romper.',
        'C) Que el aceite está completamente mezclado.',
      ],
      correctQuizIndex: 0,
      practiceGoal: 'Localiza en el diagrama P-h los 4 puntos del ciclo y comprueba cuáles están dentro y cuáles fuera de la campana.',
      verifyFeedback: '¡Perfecto! El estado saturado representa el equilibrio exacto de coexistencia entre fases.',
      summaryGoldenRule: 'REGLA DE ORO: La campana de saturación es el mapa de carreteras del frigorista. Fuera de ella no hay cambio de fase.',
    ),
    const LessonModel(
      index: 8,
      id: 'lesson_8',
      title: 'Lección 8: Superheat (Recalentamiento)',
      subtitle: 'El guardián del compresor: medición, cálculo y ajuste térmico',
      targetComponentId: 'exp_1',
      observeText: 'Observa la tarjeta de telemetría SUPERHEAT (SH). Indica cuántos Kelvin por encima de la saturación está el gas en la aspiración.',
      interactPrompt: 'Toca el Punto 1 en el diagrama P-h. Observa la distancia horizontal entre la curva de vapor saturado y el punto.',
      explainTheory: 'Superheat = T_aspiración - T_sat(P_aspiración). Si SH = 0, el gas arrastra gotas de líquido que destruirán el compresor. Si SH > 15 K, la batería está seca y el compresor se sobrecalienta.',
      experimentTask: 'Cierra la TXV al 20% y observa cómo el Superheat sube de 7 K a más de 18 K.',
      quizQuestion: '¿Cuál es el valor típico recomendado de recalentamiento útil en una instalación comercial estándar?',
      quizOptions: [
        'A) Exactamente 0 K.',
        'B) Entre 5 K y 8 K (suficiente para proteger de líquido sin perder rendimiento).',
        'C) Más de 40 K.',
      ],
      correctQuizIndex: 1,
      practiceGoal: 'Regula la válvula de expansión para situar el superheat en la zona verde (entre 5.0 y 8.0 K).',
      verifyFeedback: '¡Excelente! Un superheat de 6 a 8 K es el equilibrio perfecto entre seguridad mecánica y eficiencia frigorífica.',
      summaryGoldenRule: 'REGLA DE ORO: Superheat protege al compresor. Poco superheat = líquido peligroso; mucho superheat = batería desnutrida y calentón.',
    ),
    const LessonModel(
      index: 9,
      id: 'lesson_9',
      title: 'Lección 9: Subcooling (Subenfriamiento)',
      subtitle: 'Garantía de líquido 100% y alimentación perfecta de la válvula de expansión',
      targetComponentId: 'cond_1',
      observeText: 'Observa la tarjeta de telemetría de alta presión. El subcooling mide cuántos grados por debajo de la condensación sale el líquido.',
      interactPrompt: 'Toca el Punto 3 en el diagrama P-h. Observa que está a la izquierda de la campana (en la región de líquido subenfriado).',
      explainTheory: 'Subcooling = T_sat(P_condensación) - T_líquido. Garantiza que no se forme vapor antes de llegar a la TXV. Si hay poco subenfriamiento, se forman burbujas en la tubería y la válvula pierde hasta un 40% de capacidad.',
      experimentTask: 'Comprueba el valor de subcooling en régimen permanente estable.',
      quizQuestion: '¿Por qué es imprescindible que el líquido llegue subenfriado a la válvula de expansión?',
      quizOptions: [
        'A) Para evitar que se formen burbujas de vapor en la línea de líquido (flash gas prematuro) que descontrolarían la válvula.',
        'B) Para que la tubería no vibre.',
        'C) Para enfriar el aire exterior.',
      ],
      correctQuizIndex: 0,
      practiceGoal: 'Comprueba que el subcooling del ciclo simulado se encuentre entre 3 y 6 K.',
      verifyFeedback: '¡Muy bien! El subcooling asegura columna de líquido 100% puro en la entrada del orificio de expansión.',
      summaryGoldenRule: 'REGLA DE ORO: Subcooling garantiza líquido 100%. Sin subenfriamiento, la TXV traga burbujas y la instalación no rinde.',
    ),
    const LessonModel(
      index: 10,
      id: 'lesson_10',
      title: 'Lección 10: Cómo leer una instalación',
      subtitle: 'Diagnóstico visual y correlación de manómetros, termómetros y tacto',
      targetComponentId: 'comp_1',
      observeText: 'Observa la instalación completa funcionando en conjunto: manómetros, temperaturas, consumos y diagrama P-h.',
      interactPrompt: 'Pulsa el botón permanente "¿QUÉ ESTÁ PASANDO?" en la barra de telemetría para ver el análisis completo.',
      explainTheory: 'Un técnico frigorista profesional nunca mira una sola variable. Cruza mentalmente: Presión de alta + Presión de baja + Salto térmico en condensador + Superheat + Subcooling + Amperaje del compresor.',
      experimentTask: 'Provoca un cambio (RPM o temperatura ambiente) y observa cómo todas las magnitudes se reajustan en cadena.',
      quizQuestion: 'Si observas: Presión de baja muy baja + Superheat muy alto + Presión de alta ligeramente baja, ¿cuál es la causa probable?',
      quizOptions: [
        'A) Batería de condensador sucia.',
        'B) Falta de alimentación de refrigerante al evaporador (TXV cerrada, filtro obstruido o falta de carga).',
        'C) Compresor con láminas rotas.',
      ],
      correctQuizIndex: 1,
      practiceGoal: 'Ejecuta una inspección completa revisando los 4 puntos del diagrama P-h en tiempo real.',
      verifyFeedback: '¡Enhorabuena! Has completado las lecciones teóricas fundamentales. Estás listo para el banco de montaje y taller.',
      summaryGoldenRule: 'REGLA DE ORO: Nunca diagnostiques con una sola medida. El ciclo frigorífico es un sistema interconectado y vivo.',
    ),
  ];
}
