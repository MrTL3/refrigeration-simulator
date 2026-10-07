import '../models/connection_port.dart';

/// Tipos de componentes del sistema frigorífico.
enum ComponentType {
  compressor('Compresor'),
  condenser('Condensador'),
  expansionDevice('Dispositivo de expansión'),
  evaporator('Evaporador'),
  liquidReceiver('Recipiente de líquido'),
  filterDrier('Filtro deshidratador'),
  sightGlass('Visor de líquido'),
  solenoidValve('Electroválvula');

  final String label;
  const ComponentType(this.label);
}

/// Clase base abstracta para todos los componentes del sistema frigorífico.
abstract class BaseComponent {
  final String id;
  final String name;
  final ComponentType type;

  /// Posición en el plano 2D de diseño/taller (coordenadas de lienzo)
  final double posX;
  final double posY;

  /// Rotación en grados (0, 90, 180, 270)
  final double rotationDeg;

  /// Puertos de conexión físicos
  final List<ConnectionPort> ports;

  /// Indica si el componente está energizado y en servicio
  final bool isOperational;

  /// Lista de alarmas activas del componente
  final List<String> activeAlarms;

  const BaseComponent({
    required this.id,
    required this.name,
    required this.type,
    this.posX = 0.0,
    this.posY = 0.0,
    this.rotationDeg = 0.0,
    required this.ports,
    this.isOperational = true,
    this.activeAlarms = const [],
  });

  /// Busca un puerto por su ID
  ConnectionPort? getPortById(String portId) {
    for (final p in ports) {
      if (p.id == portId) return p;
    }
    return null;
  }

  /// Busca el primer puerto de entrada
  ConnectionPort? get inletPort {
    for (final p in ports) {
      if (p.type == PortType.inlet) return p;
    }
    return null;
  }

  /// Busca el primer puerto de salida
  ConnectionPort? get outletPort {
    for (final p in ports) {
      if (p.type == PortType.outlet) return p;
    }
    return null;
  }
}
