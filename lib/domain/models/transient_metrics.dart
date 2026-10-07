/// Estados operacionales del ciclo frigorífico durante su evolución dinámica.
enum SystemOperationalMode {
  off('DETENIDO'),
  starting('ARRANQUE (TRANSITORIO RÁPIDO)'),
  transient('TRANSITORIO TÉRMICO EN CURSO'),
  steadyState('RÉGIMEN PERMANENTE ESTABLE'),
  stopping('PARADA Y ECUALIZACIÓN');

  final String label;
  const SystemOperationalMode(this.label);
}

/// Dirección de la tendencia temporal de una magnitud física.
enum TrendDirection {
  rising('↑', 'Subiendo'),
  falling('↓', 'Bajando'),
  steady('→', 'Estable');

  final String symbol;
  final String description;
  const TrendDirection(this.symbol, this.description);
}

/// Representa el valor actual, el histórico y la derivada de una magnitud termodinámica.
class MetricTrend {
  final double currentValue;
  final double previousValue;
  final double delta;
  final double derivativePerSec;
  final TrendDirection direction;

  const MetricTrend({
    required this.currentValue,
    required this.previousValue,
    required this.delta,
    required this.derivativePerSec,
    required this.direction,
  });

  factory MetricTrend.initial(double val) {
    return MetricTrend(
      currentValue: val,
      previousValue: val,
      delta: 0.0,
      derivativePerSec: 0.0,
      direction: TrendDirection.steady,
    );
  }

  factory MetricTrend.calculate({
    required double current,
    required double previous,
    required double dt,
    double steadyTolerance = 0.01,
  }) {
    final delta = current - previous;
    final rate = dt > 0 ? (delta / dt) : 0.0;
    TrendDirection dir;
    if (rate.abs() <= steadyTolerance) {
      dir = TrendDirection.steady;
    } else if (rate > 0) {
      dir = TrendDirection.rising;
    } else {
      dir = TrendDirection.falling;
    }

    return MetricTrend(
      currentValue: current,
      previousValue: previous,
      delta: delta,
      derivativePerSec: rate,
      direction: dir,
    );
  }
}

/// Punto de muestra temporal para gráficas $y(t)$.
class TimeSeriesSample {
  final double timeSeconds;
  final double evaporatingPressureBar;
  final double condensingPressureBar;
  final double suctionTemperatureCelsius;
  final double dischargeTemperatureCelsius;
  final double roomTemperatureCelsius;
  final double massFlowGramsPerSec;
  final double coolingCapacityKw;
  final double cop;

  const TimeSeriesSample({
    required this.timeSeconds,
    required this.evaporatingPressureBar,
    required this.condensingPressureBar,
    required this.suctionTemperatureCelsius,
    required this.dischargeTemperatureCelsius,
    required this.roomTemperatureCelsius,
    required this.massFlowGramsPerSec,
    required this.coolingCapacityKw,
    required this.cop,
  });
}
