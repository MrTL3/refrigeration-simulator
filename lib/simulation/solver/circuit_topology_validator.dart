import '../../domain/models/circuit.dart';
import '../../domain/models/connection_port.dart';

/// Resultado detallado de la validación topológica de un circuito frigorífico.
class TopologyValidationResult {
  final bool isValid;
  final bool isClosedLoop;
  final List<String> errors;
  final List<String> warnings;

  const TopologyValidationResult({
    required this.isValid,
    required this.isClosedLoop,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Validador topológico de circuitos frigoríficos.
/// Comprueba continuidad de lazo, coherencia de puertos y componentes elementales.
class CircuitTopologyValidator {
  static TopologyValidationResult validate(Circuit circuit) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Verificación de componentes mínimos
    final comp = circuit.compressor;
    final cond = circuit.condenser;
    final exp = circuit.expansionDevice;
    final evap = circuit.evaporator;

    if (comp == null) errors.add('Falta el compresor en el circuito.');
    if (cond == null) errors.add('Falta el condensador en el circuito.');
    if (exp == null) errors.add('Falta el dispositivo de expansión en el circuito.');
    if (evap == null) errors.add('Falta el evaporador en el circuito.');

    // 2. Verificación de conexiones de tuberías
    final componentMap = circuit.components;
    final outgoingMap = <String, List<String>>{}; // fromCompId -> toCompId

    for (final pipe in circuit.pipes) {
      final source = componentMap[pipe.fromComponentId];
      final target = componentMap[pipe.toComponentId];

      if (source == null) {
        errors.add('La tubería "${pipe.name}" tiene un componente de origen inexistente (${pipe.fromComponentId}).');
        continue;
      }
      if (target == null) {
        errors.add('La tubería "${pipe.name}" tiene un componente de destino inexistente (${pipe.toComponentId}).');
        continue;
      }

      final sourcePort = source.getPortById(pipe.fromPortId);
      final targetPort = target.getPortById(pipe.toPortId);

      if (sourcePort == null) {
        errors.add('El puerto de origen "${pipe.fromPortId}" no existe en "${source.name}".');
      } else if (sourcePort.type == PortType.inlet) {
        errors.add('Conexión invertida: el puerto de origen "${sourcePort.name}" en "${source.name}" es de entrada.');
      }

      if (targetPort == null) {
        errors.add('El puerto de destino "${pipe.toPortId}" no existe en "${target.name}".');
      } else if (targetPort.type == PortType.outlet) {
        errors.add('Conexión incompatible: el puerto de destino "${targetPort.name}" en "${target.name}" es una salida.');
      }

      outgoingMap.putIfAbsent(pipe.fromComponentId, () => []).add(pipe.toComponentId);
    }

    // 3. Verificación de lazo cerrado (Closed Loop)
    bool closedLoop = false;
    if (comp != null && cond != null && exp != null && evap != null) {
      // Verificamos la ruta clásica: Compresor -> Condensador -> Expansión -> Evaporador -> Compresor
      final hasCompToCond = outgoingMap[comp.id]?.contains(cond.id) ?? false;
      final hasCondToExp = outgoingMap[cond.id]?.contains(exp.id) ?? false;
      final hasExpToEvap = outgoingMap[exp.id]?.contains(evap.id) ?? false;
      final hasEvapToComp = outgoingMap[evap.id]?.contains(comp.id) ?? false;

      if (hasCompToCond && hasCondToExp && hasExpToEvap && hasEvapToComp) {
        closedLoop = true;
      } else {
        if (!hasCompToCond) warnings.add('La descarga del compresor no está conectada al condensador.');
        if (!hasCondToExp) warnings.add('La salida del condensador no está conectada a la válvula de expansión.');
        if (!hasExpToEvap) warnings.add('La salida de la válvula de expansión no está conectada al evaporador.');
        if (!hasEvapToComp) warnings.add('La salida del evaporador no retorna a la aspiración del compresor.');
      }
    }

    if (!closedLoop && errors.isEmpty) {
      errors.add('El circuito no forma un ciclo cerrado continuo.');
    }

    return TopologyValidationResult(
      isValid: errors.isEmpty,
      isClosedLoop: closedLoop,
      errors: errors,
      warnings: warnings,
    );
  }
}
