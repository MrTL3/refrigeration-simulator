import '../../simulation/engine/simulation_state.dart';

/// Contrato absoluto entre la simulación física y la visualización.
///
/// REGLA DE ORO DE FRIGOLAB:
/// 1. El solver físico es la ÚNICA FUENTE DE VERDAD.
/// 2. Los visualizadores NUNCA calculan presiones, temperaturas, caudales ni densidades.
/// 3. Los visualizadores NUNCA usan Random() ni inventan valores arbitrarios.
/// 4. Los visualizadores solo traducen el estado físico riguroso en posiciones,
///    ángulos, radios, colores y trazadores visuales.
abstract class PhysicalVisualizer {
  /// Actualiza las variables de renderizado a partir del estado físico del solver
  void updateFromState(SimulationState state);
}
