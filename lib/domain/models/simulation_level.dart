/// Niveles pedagógicos de profundidad de información para el técnico/alumno
enum SimulationInformationLevel {
  level1Visual(
    'NIVEL 1 — VISUAL',
    'Componentes, calor/frío intuitivo, flujo y estado de marcha',
  ),
  level2Basic(
    'NIVEL 2 — BÁSICO',
    'Presión, temperatura, sentido de circulación, RPM y estado operativo',
  ),
  level3Technical(
    'NIVEL 3 — TÉCNICO',
    'P, T, h, s, ρ, x, caudal másico, superheat, subcooling, potencia y COP',
  ),
  level4Engineering(
    'NIVEL 4 — INGENIERÍA',
    'Balances térmicos detallados, caídas de presión, flujo de aire, corrientes eléctricas y derivadas',
  );

  final String title;
  final String description;
  const SimulationInformationLevel(this.title, this.description);

  /// Alias pedagógico para nivel 3
  static const SimulationInformationLevel level3Technician = SimulationInformationLevel.level3Technical;
}

/// Modo de visualización de la planta frigorífica
enum PlantViewMode {
  realistic25D('REALISTA (2.5D)', 'Mecanismos cinemáticos, tuberías con flujo físico y aletas industriales'),
  technicalPid('TÉCNICA (P&ID)', 'Esquema SCADA industrial normalizado con instrumentación y puertos de prueba'),
  educational('EDUCATIVA', 'Mapas de calor/frío, flechas directrices y explicaciones contextuales');

  final String label;
  final String description;
  const PlantViewMode(this.label, this.description);
}

/// Opciones de capas físicas superpuestas en tiempo real
class VisualLayerToggles {
  final bool showRefrigerantFlow;
  final bool showHeatTransfer;
  final bool showPressureMap;
  final bool showTemperatureMap;
  final bool showElectricalVectors;

  const VisualLayerToggles({
    this.showRefrigerantFlow = true,
    this.showHeatTransfer = true,
    this.showPressureMap = false,
    this.showTemperatureMap = false,
    this.showElectricalVectors = false,
  });

  bool get showFlow => showRefrigerantFlow;
  bool get showHeatExchange => showHeatTransfer;
  bool get showPressureZones => showPressureMap;
  bool get showTemperatures => showTemperatureMap;

  VisualLayerToggles copyWith({
    bool? showRefrigerantFlow,
    bool? showHeatTransfer,
    bool? showPressureMap,
    bool? showTemperatureMap,
    bool? showElectricalVectors,
    bool? showFlow,
    bool? showHeatExchange,
    bool? showPressureZones,
    bool? showTemperatures,
  }) {
    return VisualLayerToggles(
      showRefrigerantFlow: showFlow ?? showRefrigerantFlow ?? this.showRefrigerantFlow,
      showHeatTransfer: showHeatExchange ?? showHeatTransfer ?? this.showHeatTransfer,
      showPressureMap: showPressureZones ?? showPressureMap ?? this.showPressureMap,
      showTemperatureMap: showTemperatures ?? showTemperatureMap ?? this.showTemperatureMap,
      showElectricalVectors: showElectricalVectors ?? this.showElectricalVectors,
    );
  }
}
