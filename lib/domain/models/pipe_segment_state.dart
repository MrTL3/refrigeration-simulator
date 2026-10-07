import 'dart:math' as math;
import 'thermodynamic_state.dart';

/// Estado físico completo e instantáneo de un tramo de tubería de la instalación.
class PipeSegmentState {
  final String id;
  final String name;
  final ThermodynamicState state;
  final double massFlowKgPerSec;
  final double innerDiameterMm;
  final double lengthMeters;
  final double velocityMetersPerSec;
  final double pressureDropPascals;

  const PipeSegmentState({
    required this.id,
    required this.name,
    required this.state,
    required this.massFlowKgPerSec,
    required this.innerDiameterMm,
    required this.lengthMeters,
    required this.velocityMetersPerSec,
    required this.pressureDropPascals,
  });

  /// Crea un estado de tubería calculando rigurosamente su velocidad física y pérdida de carga
  factory PipeSegmentState.calculate({
    required String id,
    required String name,
    required ThermodynamicState state,
    required double massFlowKgPerSec,
    required double innerDiameterMm,
    required double lengthMeters,
  }) {
    final dMeters = innerDiameterMm / 1000.0;
    final area = math.pi * math.pow(dMeters / 2.0, 2);
    final rho = state.density;

    final velocity = (rho > 0 && area > 0)
        ? (massFlowKgPerSec / (rho * area)).clamp(0.0, 35.0)
        : 0.0;

    // Darcy-Weisbach para pérdida de carga
    const double frictionFactor = 0.024;
    final deltaP = (dMeters > 0 && rho > 0 && velocity > 0)
        ? (frictionFactor * (lengthMeters / dMeters) * (rho * math.pow(velocity, 2) / 2.0))
        : 0.0;

    return PipeSegmentState(
      id: id,
      name: name,
      state: state,
      massFlowKgPerSec: massFlowKgPerSec,
      innerDiameterMm: innerDiameterMm,
      lengthMeters: lengthMeters,
      velocityMetersPerSec: velocity,
      pressureDropPascals: deltaP,
    );
  }

  /// Área transversal en m²
  double get crossSectionAreaM2 => math.pi * math.pow((innerDiameterMm / 1000.0) / 2.0, 2);

  bool get isLiquid => state.phaseState == PhaseState.subcooledLiquid || state.phaseState == PhaseState.saturatedLiquid;
  bool get isTwoPhase => state.phaseState == PhaseState.twoPhase;
  bool get isVapor => state.phaseState == PhaseState.saturatedVapor || state.phaseState == PhaseState.superheatedVapor;
}
