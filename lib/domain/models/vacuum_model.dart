import 'dart:math' as math;

/// Estado y modelo físico del procedimiento de evacuación y secado por vacío.
class VacuumState {
  /// Presión absoluta actual en el circuito (Pascal, Pa)
  final double pressurePa;

  /// Presión en micras de mercurio (µmHg o microns, 1 Pa ≈ 7.5006 µmHg)
  double get pressureMicrons => pressurePa * 7.5006168;

  /// Presión en milibares (mbar)
  double get pressureMbar => pressurePa / 100.0;

  /// Indica si la bomba de vacío de doble efecto está encendida
  final bool isPumpRunning;

  /// Caudal volumétrico de la bomba de vacío en litros por minuto (L/min o CFM)
  final double pumpCapacityLitersPerMin;

  /// Volumen interno del circuito frigorífico en litros
  final double circuitVolumeLiters;

  /// Nivel de humedad residual líquida estimada en el circuito (gramos de agua)
  final double residualWaterGrams;

  /// Tasa de desgasificación / evaporación de agua actual (Pa/s)
  final double outgassingRatePaPerSec;

  /// Indica si se ha alcanzado el vacío reglamentario profundo (< 500 µmHg)
  bool get isDeepVacuumReached => pressureMicrons < 500.0;

  const VacuumState({
    required this.pressurePa,
    required this.isPumpRunning,
    this.pumpCapacityLitersPerMin = 70.0, // Bomba típica 2.5 CFM (~70 L/min)
    this.circuitVolumeLiters = 4.5,
    required this.residualWaterGrams,
    required this.outgassingRatePaPerSec,
  });

  /// Estado inicial atmosférico a 1 bar (760.000 micras)
  factory VacuumState.initial() {
    return const VacuumState(
      pressurePa: 101325.0,
      isPumpRunning: false,
      residualWaterGrams: 0.15, // Pequeña traza de humedad ambiental
      outgassingRatePaPerSec: 0.0,
    );
  }

  /// Integra un paso temporal del proceso de vacío
  VacuumState integrateStep(double dt, {bool pumpOn = true}) {
    if (!pumpOn && !isPumpRunning) {
      return this;
    }

    if (!pumpOn) {
      // Bomba apagada (prueba de retención de vacío / test de subida)
      // Si hay humedad residual, la presión sube hacia la presión de vapor del agua (~23 mbar)
      double dP = 0.0;
      if (residualWaterGrams > 0.001) {
        final pWaterSat = 2300.0; // ~23 mbar a 20 °C
        if (pressurePa < pWaterSat) {
          dP = 45.0 * dt; // Subida por evaporación de agua
        }
      }
      final newP = math.min(101325.0, pressurePa + dP);
      return copyWith(
        pressurePa: newP,
        isPumpRunning: false,
        outgassingRatePaPerSec: dP / math.max(0.001, dt),
      );
    }

    // Bomba encendida
    final speed = (pumpCapacityLitersPerMin / 60.0) / circuitVolumeLiters; // 1/s
    double currentP = pressurePa;
    double water = residualWaterGrams;

    // Presión de saturación del agua a 20 °C (~2300 Pa = 17.250 micras)
    const pWaterSat = 2300.0;

    if (currentP > pWaterSat) {
      // Fase 1: Evacuación de gases no condensables (aire seco y nitrógeno)
      currentP = currentP * math.exp(-speed * dt * 0.4);
    } else if (water > 0.005) {
      // Fase 2: Meseta de ebullición y desgasificación de humedad (el agua hierve a temperatura ambiente)
      // La presión se mantiene estabilizada en ~23 mbar hasta que toda el agua se evapora
      final evaporationRate = 0.008 * dt; // gramos evaporados por segundo
      water = math.max(0.0, water - evaporationRate);
      currentP = (currentP + (pWaterSat - currentP) * 0.1 * dt).clamp(1800.0, pWaterSat + 200.0);
    } else {
      // Fase 3: Vacío profundo (< 1.000 micras hacia el límite de la bomba de 15-20 micras)
      const pPumpLimit = 2.5; // ~18 micras límite de paletas rotativas
      currentP = pPumpLimit + (currentP - pPumpLimit) * math.exp(-speed * dt * 0.3);
    }

    return VacuumState(
      pressurePa: currentP.clamp(2.5, 101325.0),
      isPumpRunning: true,
      pumpCapacityLitersPerMin: pumpCapacityLitersPerMin,
      circuitVolumeLiters: circuitVolumeLiters,
      residualWaterGrams: water,
      outgassingRatePaPerSec: (pressurePa - currentP) / math.max(0.001, dt),
    );
  }

  VacuumState copyWith({
    double? pressurePa,
    bool? isPumpRunning,
    double? pumpCapacityLitersPerMin,
    double? circuitVolumeLiters,
    double? residualWaterGrams,
    double? outgassingRatePaPerSec,
  }) {
    return VacuumState(
      pressurePa: pressurePa ?? this.pressurePa,
      isPumpRunning: isPumpRunning ?? this.isPumpRunning,
      pumpCapacityLitersPerMin: pumpCapacityLitersPerMin ?? this.pumpCapacityLitersPerMin,
      circuitVolumeLiters: circuitVolumeLiters ?? this.circuitVolumeLiters,
      residualWaterGrams: residualWaterGrams ?? this.residualWaterGrams,
      outgassingRatePaPerSec: outgassingRatePaPerSec ?? this.outgassingRatePaPerSec,
    );
  }
}
