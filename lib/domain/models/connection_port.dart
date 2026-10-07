import 'package:flutter/foundation.dart';
import 'thermodynamic_state.dart';

/// Tipo de puerto de conexión de un componente frigorífico.
enum PortType {
  inlet('Entrada'),
  outlet('Salida'),
  service('Servicio/Manómetro');

  final String label;
  const PortType(this.label);
}

/// Representa un puerto de conexión físico de un componente.
class ConnectionPort {
  final String id;
  final String name;
  final PortType type;

  /// Posición relativa (0..1 o píxeles relativos) respecto al centro o esquina del componente
  final double relativeX;
  final double relativeY;

  /// Diámetro nominal en milímetros (mm)
  final double nominalDiameterMm;

  /// ID de la tubería conectada actualmente, o null si está libre
  final String? connectedPipeId;

  const ConnectionPort({
    required this.id,
    required this.name,
    required this.type,
    required this.relativeX,
    required this.relativeY,
    this.nominalDiameterMm = 12.0,
    this.connectedPipeId,
  });

  bool get isConnected => connectedPipeId != null;

  ConnectionPort copyWith({
    String? id,
    String? name,
    PortType? type,
    double? relativeX,
    double? relativeY,
    double? nominalDiameterMm,
    ValueGetter<String?>? connectedPipeId,
  }) {
    return ConnectionPort(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      relativeX: relativeX ?? this.relativeX,
      relativeY: relativeY ?? this.relativeY,
      nominalDiameterMm: nominalDiameterMm ?? this.nominalDiameterMm,
      connectedPipeId: connectedPipeId != null ? connectedPipeId() : this.connectedPipeId,
    );
  }
}

/// Nodo de fluido que encapsula el estado termodinámico y flujo en una unión o punto de medición.
class FluidNode {
  final String id;
  final String name;
  final ThermodynamicState state;
  final double massFlowKgPerSec;

  const FluidNode({
    required this.id,
    required this.name,
    required this.state,
    this.massFlowKgPerSec = 0.0,
  });

  FluidNode copyWith({
    String? id,
    String? name,
    ThermodynamicState? state,
    double? massFlowKgPerSec,
  }) {
    return FluidNode(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      massFlowKgPerSec: massFlowKgPerSec ?? this.massFlowKgPerSec,
    );
  }
}
