/// Ficha didáctica estructurada de componentes frigoríficos para técnicos e iniciantes.
class ComponentKnowledgeCard {
  final String id;
  final String name;
  final String function;
  final String location;
  final String whatEnters;
  final String whatLeaves;
  final String variableModified;
  final String typicalValues;
  final String howToMeasure;
  final String failureModes;
  final String failureSymptoms;
  final String diagnosisProcedure;

  const ComponentKnowledgeCard({
    required this.id,
    required this.name,
    required this.function,
    required this.location,
    required this.whatEnters,
    required this.whatLeaves,
    required this.variableModified,
    required this.typicalValues,
    required this.howToMeasure,
    required this.failureModes,
    required this.failureSymptoms,
    required this.diagnosisProcedure,
  });
}

/// Base de conocimiento educativo contextual de componentes de refrigeración.
class ComponentKnowledgeBase {
  static const Map<String, ComponentKnowledgeCard> _cards = {
    'comp': ComponentKnowledgeCard(
      id: 'comp',
      name: 'Compresor Frigorífico',
      function: 'Aspirar el vapor de refrigerante que proviene del evaporador a baja presión y comprimirlo mecánicamente elevando su presión y temperatura para permitir que ceda calor al exterior.',
      location: 'Entre la línea de aspiración (lado de baja presión) y la línea de descarga (lado de alta presión). Corazón mecánico del circuito.',
      whatEnters: 'Vapor sobrecalentado a baja presión y baja temperatura (ej. -5 °C a +5 °C, ~2.5 bar con R-134a). ¡Bajo ningún concepto debe entrar líquido!',
      whatLeaves: 'Vapor muy caliente sobrecalentado a alta presión (ej. 60 °C a 85 °C, ~10 a 14 bar con R-134a).',
      variableModified: 'Eleva la Presión (P₀ → Pₖ) y la Entalpía específica (h₁ → h₂), aportando trabajo electromecánico (W_comp).',
      typicalValues: 'Relación de compresión r_p = 3.0 a 6.0 | Consumo eléctrico: 0.5 a 3.5 kW | Eficiencia isentrópica: 65% a 78%.',
      howToMeasure: 'Manómetros en tomas de servicio (aspiración y descarga), pinza amperimétrica en bornes eléctricos (R, S, C), termómetro de contacto en tubería de descarga a 15 cm.',
      failureModes: 'Golpe de líquido por inundación (rotura de láminas de válvulas), desgaste de pistones/aros con pérdida de compresión, agarrotamiento mecánico por falta de lubricación, bobinado quemado.',
      failureSymptoms: 'Presión de aspiración alta con presión de descarga baja (el compresor "no comprime"), sobrecorriente eléctrica con disparo térmico (clixon), ruido metálico severo, temperatura de descarga anormalmente alta.',
      diagnosisProcedure: '1. Comprobar compresión aislando el circuito (bombeo en vacío). 2. Medir resistencia de aislamiento de devanados con megóhmetro (mínimo 5 MΩ). 3. Comparar corriente absorbida contra placa de características (RLA / LRA).',
    ),
    'cond': ComponentKnowledgeCard(
      id: 'cond',
      name: 'Condensador por Aire Forzado',
      function: 'Evacuar al ambiente exterior todo el calor absorbido en el evaporador más el calor equivalente al trabajo de compresión mecánica, transformando el gas caliente en líquido.',
      location: 'En el lado de alta presión, entre la descarga del compresor y la línea de líquido / válvula de expansión.',
      whatEnters: 'Vapor sobrecalentado a alta presión y alta temperatura procedente del compresor.',
      whatLeaves: 'Líquido subenfriado a alta presión (3 a 5 K por debajo de la temperatura de saturación exterior).',
      variableModified: 'Reduce la Entalpía (h₂ → h₃) a Presión aproximadamente constante (P ≈ P_k). Realiza 3 etapas: desrecalentamiento, condensación y subenfriamiento.',
      typicalValues: 'Salto térmico respecto al aire exterior: ΔT_cond = 12 a 16 K | Subcooling normal: 3.0 a 6.0 K.',
      howToMeasure: 'Manómetro de alta presión (para deducir T_sat en regla de refrigerantes) y termómetro de contacto en tubo de salida de líquido.',
      failureModes: 'Ensuciamiento de aletas por polvo/grasa, ventilador quemado o aspas bloqueadas, incondensables (aire/nitrógeno) atrapados en la batería.',
      failureSymptoms: 'Presión de descarga (Pₖ) disparada por las nubes, corte recurrente por presostato de alta, calentamiento excesivo del compresor, pérdida de subenfriamiento y aumento del consumo eléctrico.',
      diagnosisProcedure: '1. Limpiar batería con cepillo y producto desengrasante. 2. Verificar sentido de giro y caudal de aire del ventilador. 3. Medir salto de temperatura del aire a través del serpentín (debe ser de 5 a 10 K).',
    ),
    'exp': ComponentKnowledgeCard(
      id: 'exp',
      name: 'Válvula de Expansión Termostática (TXV)',
      function: 'Dosificar el caudal exacto de refrigerante líquido hacia el evaporador para que se evapore por completo, reduciendo bruscamente la presión y manteniendo un recalentamiento constante.',
      location: 'En la línea de líquido, justo antes de la entrada del evaporador. Separa el lado de alta presión del lado de baja presión.',
      whatEnters: 'Líquido subenfriado 100% puro a alta presión (P_k).',
      whatLeaves: 'Mezcla bifásica líquido-vapor (flash gas, ~20-30% vapor y 70-80% líquido frío) a baja presión (P₀).',
      variableModified: 'Reduce la Presión (P_k → P₀) en un proceso isentálpico ideal (h₄ = h₃) sin intercambio de calor ni trabajo exterior.',
      typicalValues: 'Recalentamiento estático de consigna: 5.0 a 8.0 K | Caída de presión: ΔP = 6 a 12 bar.',
      howToMeasure: 'Diferencia entre la temperatura medida por el bulbo en el tubo de aspiración y la temperatura de saturación indicada por el manómetro de baja.',
      failureModes: 'Pérdida de carga del bulbo sensor (válvula cerrada fija), atascamiento por parafina o humedad congelada en el orificio, desajuste mecánico del tornillo de regulación.',
      failureSymptoms: 'Si se queda cerrada: evaporador con baja presión extrema, superheat disparado (> 20 K), vacío en aspiración. Si se queda abierta: retorno de líquido al compresor, superheat nulo (< 1 K), escarcha en cárter.',
      diagnosisProcedure: '1. Comprobar contacto térmico y aislamiento del bulbo en la tubería de aspiración (posición horaria a las 10:00 o 14:00). 2. Calentar el bulbo con la mano y observar si sube la presión de baja.',
    ),
    'evap': ComponentKnowledgeCard(
      id: 'evap',
      name: 'Evaporador Cúbico de Aire Forzado',
      function: 'Absorber calor del aire del recinto refrigerado (cámara, mueble, vitrina), hirviendo el refrigerante líquido a baja presión hasta convertirlo totalmente en vapor sobrecalentado.',
      location: 'En el interior de la cámara frigorífica, entre la salida de la TXV y la línea de aspiración del compresor.',
      whatEnters: 'Mezcla bifásica fría a baja presión (gotas de líquido dispersas en gas frío a temperatura inferior a la del recinto).',
      whatLeaves: 'Vapor sobrecalentado a baja presión y baja temperatura, listo para ser comprimido.',
      variableModified: 'Incrementa la Entalpía (h₄ → h₁) a Presión casi constante (P ≈ P₀) extrayendo potencia frigorífica útil (Q_e).',
      typicalValues: 'Salto térmico aire-refrigerante: DTM = 6 a 10 K | Caudal de aire: 800 a 2500 m³/h según potencia.',
      howToMeasure: 'Manómetro de baja presión (T_sat) y termómetro de contacto a la salida de la batería antes del compresor.',
      failureModes: 'Bloqueo de aletas por escarcha o hielo excesivo, ventiladores parados, suciedad en batería, resistencia de desescarche quemada.',
      failureSymptoms: 'La cámara deja de enfriar, la presión de evaporación cae continuamente, el compresor funciona sin parar sin abatir temperatura, formación de bloque de hielo compacto.',
      diagnosisProcedure: '1. Inspeccionar visualmente la distribución de escarcha. 2. Forzar un ciclo de desescarche manual para verificar resistencias eléctricas. 3. Comprobar que los ventiladores expulsan aire con caudal adecuado.',
    ),
  };

  static ComponentKnowledgeCard getCard(String componentId) {
    if (componentId.startsWith('comp')) return _cards['comp']!;
    if (componentId.startsWith('cond')) return _cards['cond']!;
    if (componentId.startsWith('exp')) return _cards['exp']!;
    if (componentId.startsWith('evap')) return _cards['evap']!;
    return _cards['comp']!;
  }
}
