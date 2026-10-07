/// Tipo y rol de puerto de conexión física en un componente
enum WorkshopPortType {
  inlet('Entrada'),
  outlet('Salida');

  final String label;
  const WorkshopPortType(this.label);
}

/// Nivel de presión admisible en el puerto
enum PortPressureLevel {
  high('Alta Presión (Pₖ)'),
  low('Baja Presión (P₀)');

  final String label;
  const PortPressureLevel(this.label);
}

/// Puerto de conexión para el montaje en taller
class WorkshopPort {
  final String id;
  final String componentId;
  final String label;
  final WorkshopPortType type;
  final PortPressureLevel pressureLevel;

  const WorkshopPort({
    required this.id,
    required this.componentId,
    required this.label,
    required this.type,
    required this.pressureLevel,
  });
}

/// Conexión de tubería trazada entre dos puertos
class WorkshopPipeConnection {
  final String fromPortId;
  final String toPortId;
  final String label;

  const WorkshopPipeConnection({
    required this.fromPortId,
    required this.toPortId,
    required this.label,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkshopPipeConnection &&
          runtimeType == other.runtimeType &&
          fromPortId == other.fromPortId &&
          toPortId == other.toPortId;

  @override
  int get hashCode => fromPortId.hashCode ^ toPortId.hashCode;
}

/// Estado del procedimiento de puesta en servicio guiada
enum CommissioningStep {
  assembly('1. Montaje Tuberías', 'Conectar los 4 componentes del ciclo'),
  leakTest('2. Prueba de Estanqueidad', 'Presurizar con N₂ para verificar fugas'),
  vacuum('3. Proceso de Vacío', 'Evacuar humedad e incondensables (<500 micras)'),
  charging('4. Carga de Refrigerante', 'Carga controlada en peso (báscula digital)'),
  startup('5. Puesta en Marcha', 'Arranque del ciclo y control de transitorios');

  final String title;
  final String description;
  const CommissioningStep(this.title, this.description);
}

/// Validador pedagógico de conexiones de taller frigorífico
class WorkshopValidator {
  static const Map<String, String> correctSuccessors = {
    'comp_out': 'cond_in',
    'cond_out': 'exp_in',
    'exp_out': 'evap_in',
    'evap_out': 'comp_in',
  };

  /// Valida un intento de conexión física entre dos puertos y devuelve el resultado con razonamiento
  static ({bool isValid, String feedback, String? rule}) validateConnectionAttempt({
    required WorkshopPort fromPort,
    required WorkshopPort toPort,
  }) {
    // 1. Conexión de entrada con entrada
    if (fromPort.type == WorkshopPortType.inlet && toPort.type == WorkshopPortType.inlet) {
      return (
        isValid: false,
        feedback: 'No se pueden unir dos puertos de entrada. El refrigerante debe fluir desde una salida impulsora hacia una entrada receptora.',
        rule: 'REGLA: Salida -> Entrada.',
      );
    }

    // 2. Conexión de salida con salida
    if (fromPort.type == WorkshopPortType.outlet && toPort.type == WorkshopPortType.outlet) {
      return (
        isValid: false,
        feedback: 'No se pueden unir dos puertos de salida. Ambas bombas/baterías intentarían empujar refrigerante en sentidos opuestos generando un bloqueo hidráulico.',
        rule: 'REGLA: Salida -> Entrada.',
      );
    }

    // Normalizamos para comprobar sentido Salida -> Entrada
    final outPort = fromPort.type == WorkshopPortType.outlet ? fromPort : toPort;
    final inPort = fromPort.type == WorkshopPortType.inlet ? fromPort : toPort;

    // 3. Conexión sobre el mismo componente
    if (outPort.componentId == inPort.componentId) {
      return (
        isValid: false,
        feedback: 'No puedes recircular la salida de un componente directamente a su propia entrada. Se crearía un cortocircuito que anula el resto de la instalación.',
        rule: 'REGLA: Conexión entre componentes distintos.',
      );
    }

    // 4. Conexión en sentido termodinámico incorrecto
    final expectedInlet = correctSuccessors[outPort.id];
    if (expectedInlet != inPort.id) {
      String reason = '';
      if (outPort.id == 'comp_out') {
        reason = 'La descarga del compresor entrega vapor a alta presión y muy caliente. Debe conducirse hacia el condensador para disipar calor, no al evaporador ni a la válvula de expansión.';
      } else if (outPort.id == 'cond_out') {
        reason = 'La salida del condensador entrega líquido subenfriado a alta presión. Debe conducirse hacia la válvula de expansión para estrangularlo, no al compresor ni al evaporador.';
      } else if (outPort.id == 'exp_out') {
        reason = 'La salida de la válvula TXV entrega líquido-vapor frío a baja presión. Debe conducirse hacia el evaporador para absorber calor, no al compresor.';
      } else if (outPort.id == 'evap_out') {
        reason = 'La salida del evaporador entrega vapor sobrecalentado a baja presión. Debe conducirse hacia la aspiración del compresor para reiniciar el ciclo.';
      }
      return (
        isValid: false,
        feedback: reason,
        rule: 'REGLA DE SECUENCIA: Compresor -> Condensador -> Expansión -> Evaporador.',
      );
    }

    return (
      isValid: true,
      feedback: '¡Conexión correcta y estanca! Sentido termodinámico adecuado.',
      rule: null,
    );
  }
}
