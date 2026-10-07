import '../models/connection_port.dart';
import 'base_component.dart';

/// Tipos de condensador.
enum CondenserType {
  airCooled('Condensador por aire de tiro forzado'),
  waterCooled('Condensador por agua (multitubular/placas)');

  final String label;
  const CondenserType(this.label);
}

/// Modelo físico y descriptivo de un condensador frigorífico.
class CondenserComponent extends BaseComponent {
  final CondenserType condenserType;

  /// Potencia térmica de rechazo de calor actual (Watts)
  final double heatRejectionWatts;

  /// Temperatura ambiente del aire de refrigeración (Kelvin)
  final double ambientTemperatureKelvin;

  /// Subenfriamiento de salida previsto / ajustado (Kelvin)
  final double targetSubcoolingKelvin;

  /// Coeficiente global de transferencia de calor y área efectiva (W/K)
  final double overallHeatTransferCoefficientUA;

  /// Estado del ventilador de tiro forzado
  final bool fanOperational;

  /// Factor de suciedad / atascamiento de aletas (0.0 = limpio, 1.0 = bloqueado)
  final double foulingFactor;

  const CondenserComponent({
    required super.id,
    required super.name,
    this.condenserType = CondenserType.airCooled,
    this.heatRejectionWatts = 0.0,
    this.ambientTemperatureKelvin = 298.15, // 25 °C
    this.targetSubcoolingKelvin = 5.0, // 5 K de subcooling
    this.overallHeatTransferCoefficientUA = 220.0, // W/K
    this.fanOperational = true,
    this.foulingFactor = 0.0,
    super.posX = 450.0,
    super.posY = 100.0,
    super.rotationDeg = 0.0,
    super.isOperational = true,
    super.activeAlarms = const [],
    List<ConnectionPort>? customPorts,
  }) : super(
          type: ComponentType.condenser,
          ports: customPorts ??
              const [
                ConnectionPort(
                  id: 'inlet',
                  name: 'Entrada vapor caliente',
                  type: PortType.inlet,
                  relativeX: 0.1,
                  relativeY: 0.2,
                  nominalDiameterMm: 12.0,
                ),
                ConnectionPort(
                  id: 'outlet',
                  name: 'Salida líquido subenfriado',
                  type: PortType.outlet,
                  relativeX: 0.9,
                  relativeY: 0.8,
                  nominalDiameterMm: 10.0,
                ),
              ],
        );

  /// Coeficiente de transferencia efectivo considerando ventilador y suciedad
  double get effectiveUA {
    if (!fanOperational) return overallHeatTransferCoefficientUA * 0.12; // Solo convección natural
    final cleanlinessFactor = (1.0 - (foulingFactor * 0.7)).clamp(0.1, 1.0);
    return overallHeatTransferCoefficientUA * cleanlinessFactor;
  }

  CondenserComponent copyWith({
    String? id,
    String? name,
    CondenserType? condenserType,
    double? heatRejectionWatts,
    double? ambientTemperatureKelvin,
    double? targetSubcoolingKelvin,
    double? overallHeatTransferCoefficientUA,
    bool? fanOperational,
    double? foulingFactor,
    double? posX,
    double? posY,
    double? rotationDeg,
    bool? isOperational,
    List<String>? activeAlarms,
    List<ConnectionPort>? ports,
  }) {
    return CondenserComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      condenserType: condenserType ?? this.condenserType,
      heatRejectionWatts: heatRejectionWatts ?? this.heatRejectionWatts,
      ambientTemperatureKelvin: ambientTemperatureKelvin ?? this.ambientTemperatureKelvin,
      targetSubcoolingKelvin: targetSubcoolingKelvin ?? this.targetSubcoolingKelvin,
      overallHeatTransferCoefficientUA: overallHeatTransferCoefficientUA ?? this.overallHeatTransferCoefficientUA,
      fanOperational: fanOperational ?? this.fanOperational,
      foulingFactor: foulingFactor ?? this.foulingFactor,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      isOperational: isOperational ?? this.isOperational,
      activeAlarms: activeAlarms ?? this.activeAlarms,
      customPorts: ports ?? this.ports,
    );
  }
}
