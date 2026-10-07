import 'dart:math' as math;
import '../../simulation/thermodynamics/refrigerant_model.dart';
import '../../simulation/thermodynamics/r134a_model.dart';

/// Punto bidimensional en coordenadas físicas (X, Y)
class DiagramPoint {
  final double x;
  final double y;

  const DiagramPoint(this.x, this.y);
}

/// Curva continua generada en un diagrama termodinámico
class DiagramCurve {
  final String label;
  final List<DiagramPoint> points;

  const DiagramCurve({required this.label, required this.points});
}

/// Generador riguroso de curvas de campana y líneas características para diagramas P-h y T-s.
class DiagramDataGenerator {
  final RefrigerantModel refrigerant;

  DiagramDataGenerator([RefrigerantModel? ref]) : refrigerant = ref ?? R134aModel();

  /// Genera la curva de líquido saturado en el diagrama P-h: (h_f en kJ/kg, P en bar)
  List<DiagramPoint> generatePhLiquidDome({int steps = 60}) {
    final points = <DiagramPoint>[];
    const double minT = 233.15; // -40 °C
    final double maxT = refrigerant.criticalTemperature - 1.5; // ~99.5 °C

    for (int i = 0; i <= steps; i++) {
      final t = minT + (i / steps) * (maxT - minT);
      final pPa = refrigerant.saturationPressure(t);
      final pBar = pPa / 1e5;
      final hLiquidKj = refrigerant.saturatedLiquidEnthalpy(pPa) / 1000.0;
      points.add(DiagramPoint(hLiquidKj, pBar));
    }
    return points;
  }

  /// Genera la curva de vapor saturado en el diagrama P-h: (h_g en kJ/kg, P en bar)
  List<DiagramPoint> generatePhVaporDome({int steps = 60}) {
    final points = <DiagramPoint>[];
    const double minT = 233.15; // -40 °C
    final double maxT = refrigerant.criticalTemperature - 1.5;

    for (int i = 0; i <= steps; i++) {
      final t = minT + (i / steps) * (maxT - minT);
      final pPa = refrigerant.saturationPressure(t);
      final pBar = pPa / 1e5;
      final hVaporKj = refrigerant.saturatedVaporEnthalpy(pPa) / 1000.0;
      points.add(DiagramPoint(hVaporKj, pBar));
    }
    return points;
  }

  /// Genera curvas de título de vapor constante (x = 0.2, 0.4, 0.6, 0.8) en P-h
  List<DiagramCurve> generatePhQualityLines({List<double> qualities = const [0.2, 0.4, 0.6, 0.8], int steps = 40}) {
    final curves = <DiagramCurve>[];
    const double minT = 238.15; // -35 °C
    final double maxT = refrigerant.criticalTemperature - 2.5;

    for (final x in qualities) {
      final pts = <DiagramPoint>[];
      for (int i = 0; i <= steps; i++) {
        final t = minT + (i / steps) * (maxT - minT);
        final pPa = refrigerant.saturationPressure(t);
        final pBar = pPa / 1e5;
        final hf = refrigerant.saturatedLiquidEnthalpy(pPa);
        final hg = refrigerant.saturatedVaporEnthalpy(pPa);
        final hxKj = (hf + x * (hg - hf)) / 1000.0;
        pts.add(DiagramPoint(hxKj, pBar));
      }
      curves.add(DiagramCurve(label: 'x = ${(x * 100).toInt()}%', points: pts));
    }
    return curves;
  }

  /// Genera isotermas seleccionadas en el diagrama P-h (T = -10, 0, 20, 40, 60 °C)
  List<DiagramCurve> generatePhIsotherms({
    List<double> temperaturesCelsius = const [-10.0, 0.0, 20.0, 40.0, 60.0],
  }) {
    final curves = <DiagramCurve>[];

    for (final tC in temperaturesCelsius) {
      final tK = tC + 273.15;
      final pSatPa = refrigerant.saturationPressure(tK);
      final pSatBar = pSatPa / 1e5;
      final hfKj = refrigerant.saturatedLiquidEnthalpy(pSatPa) / 1000.0;
      final hgKj = refrigerant.saturatedVaporEnthalpy(pSatPa) / 1000.0;

      final pts = <DiagramPoint>[];
      // Tramo líquido subenfriado (vertical / ligeramente inclinado a la izquierda)
      pts.add(DiagramPoint(hfKj - 15.0, pSatBar * 2.2));
      pts.add(DiagramPoint(hfKj, pSatBar));
      // Tramo bifásico (horizontal a P = Psat)
      pts.add(DiagramPoint(hgKj, pSatBar));
      // Tramo vapor sobrecalentado (baja hacia presiones menores al ganar entalpía)
      pts.add(DiagramPoint(hgKj + 45.0, math.max(0.6, pSatBar * 0.45)));

      curves.add(DiagramCurve(label: '${tC.toInt()} °C', points: pts));
    }

    return curves;
  }

  // --- MÉTODOS PARA DIAGRAMA T-S ---

  /// Genera la curva de líquido saturado en el diagrama T-s: (s_f en kJ/(kg·K), T en °C)
  List<DiagramPoint> generateTsLiquidDome({int steps = 60}) {
    final points = <DiagramPoint>[];
    const double minT = 233.15; // -40 °C
    final double maxT = refrigerant.criticalTemperature - 1.5;

    for (int i = 0; i <= steps; i++) {
      final t = minT + (i / steps) * (maxT - minT);
      final pPa = refrigerant.saturationPressure(t);
      final sfKj = refrigerant.saturatedLiquidEntropy(pPa) / 1000.0;
      points.add(DiagramPoint(sfKj, t - 273.15));
    }
    return points;
  }

  /// Genera la curva de vapor saturado en el diagrama T-s: (s_g en kJ/(kg·K), T en °C)
  List<DiagramPoint> generateTsVaporDome({int steps = 60}) {
    final points = <DiagramPoint>[];
    const double minT = 233.15; // -40 °C
    final double maxT = refrigerant.criticalTemperature - 1.5;

    for (int i = 0; i <= steps; i++) {
      final t = minT + (i / steps) * (maxT - minT);
      final pPa = refrigerant.saturationPressure(t);
      final sgKj = refrigerant.saturatedVaporEntropy(pPa) / 1000.0;
      points.add(DiagramPoint(sgKj, t - 273.15));
    }
    return points;
  }

  /// Genera curvas de título en T-s (x = 0.2, 0.4, 0.6, 0.8)
  List<DiagramCurve> generateTsQualityLines({List<double> qualities = const [0.2, 0.4, 0.6, 0.8], int steps = 40}) {
    final curves = <DiagramCurve>[];
    const double minT = 238.15;
    final double maxT = refrigerant.criticalTemperature - 2.5;

    for (final x in qualities) {
      final pts = <DiagramPoint>[];
      for (int i = 0; i <= steps; i++) {
        final t = minT + (i / steps) * (maxT - minT);
        final pPa = refrigerant.saturationPressure(t);
        final sf = refrigerant.saturatedLiquidEntropy(pPa);
        final sg = refrigerant.saturatedVaporEntropy(pPa);
        final sxKj = (sf + x * (sg - sf)) / 1000.0;
        pts.add(DiagramPoint(sxKj, t - 273.15));
      }
      curves.add(DiagramCurve(label: 'x = ${(x * 100).toInt()}%', points: pts));
    }
    return curves;
  }
}
