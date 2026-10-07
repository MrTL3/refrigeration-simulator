import 'dart:math' as math;
import 'connection_port.dart';

/// Modelo físico de una tubería de refrigeración industrial.
/// Calcula la velocidad del fluido y la pérdida de carga por fricción (Darcy-Weisbach).
class Pipe {
  final String id;
  final String name;

  final String fromComponentId;
  final String fromPortId;
  final String toComponentId;
  final String toPortId;

  /// Longitud de la tubería en metros (m)
  final double lengthMeters;

  /// Diámetro interior en milímetros (mm)
  final double innerDiameterMm;

  /// Rugosidad absoluta del material en milímetros (cobre comercial: ~0.0015 mm)
  final double roughnessMm;

  /// Indica si la tubería cuenta con aislamiento térmico (coquilla elastomérica)
  final bool insulated;

  /// Nodo de fluido asociado a la línea
  final FluidNode fluidNode;

  const Pipe({
    required this.id,
    required this.name,
    required this.fromComponentId,
    required this.fromPortId,
    required this.toComponentId,
    required this.toPortId,
    this.lengthMeters = 2.0,
    this.innerDiameterMm = 12.0,
    this.roughnessMm = 0.0015,
    this.insulated = true,
    required this.fluidNode,
  });

  /// Área de paso transversal en m²
  double get crossSectionalAreaSquareMeters {
    final dMeters = innerDiameterMm / 1000.0;
    return math.pi * math.pow(dMeters / 2.0, 2);
  }

  /// Velocidad del refrigerante en la tubería en m/s
  double get velocityMetersPerSec {
    final rho = fluidNode.state.density;
    final mDot = fluidNode.massFlowKgPerSec;
    final area = crossSectionalAreaSquareMeters;
    if (rho <= 0 || area <= 0) return 0.0;
    return mDot / (rho * area);
  }

  /// Estimación de pérdida de carga continua (Pascal) mediante Darcy-Weisbach:
  /// ΔP = f · (L / D) · (ρ · v² / 2)
  double get pressureDropPascals {
    final rho = fluidNode.state.density;
    final v = velocityMetersPerSec;
    final dMeters = innerDiameterMm / 1000.0;
    if (dMeters <= 0 || rho <= 0 || v <= 0) return 0.0;

    // Factor de fricción de Blasius/Haaland simplificado para cobre frigorífico
    const double frictionFactor = 0.024;
    final deltaP = frictionFactor * (lengthMeters / dMeters) * (rho * math.pow(v, 2) / 2.0);
    return deltaP;
  }

  Pipe copyWith({
    String? id,
    String? name,
    String? fromComponentId,
    String? fromPortId,
    String? toComponentId,
    String? toPortId,
    double? lengthMeters,
    double? innerDiameterMm,
    double? roughnessMm,
    bool? insulated,
    FluidNode? fluidNode,
  }) {
    return Pipe(
      id: id ?? this.id,
      name: name ?? this.name,
      fromComponentId: fromComponentId ?? this.fromComponentId,
      fromPortId: fromPortId ?? this.fromPortId,
      toComponentId: toComponentId ?? this.toComponentId,
      toPortId: toPortId ?? this.toPortId,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      innerDiameterMm: innerDiameterMm ?? this.innerDiameterMm,
      roughnessMm: roughnessMm ?? this.roughnessMm,
      insulated: insulated ?? this.insulated,
      fluidNode: fluidNode ?? this.fluidNode,
    );
  }
}
