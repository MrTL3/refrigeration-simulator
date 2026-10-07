import '../models/connection_port.dart';
import 'base_component.dart';

/// Tipos de evaporador.
enum EvaporatorType {
  directExpansionAir('Evaporador de expansión directa por aire forzado'),
  flooded('Evaporador inundado con separador de líquido');

  final String label;
  const EvaporatorType(this.label);
}

/// Modelo físico y descriptivo de un evaporador frigorífico.
class EvaporatorComponent extends BaseComponent {
  final EvaporatorType evaporatorType;

  /// Potencia frigorífica neta absorbida de la cámara (Watts)
  final double coolingCapacityWatts;

  /// Temperatura del aire de la cámara o recinto a enfriar (Kelvin)
  final double roomTemperatureKelvin;

  /// Recalentamiento útil a la salida del evaporador (Kelvin)
  final double targetSuperheatKelvin;

  /// Coeficiente global de transferencia de calor y área efectiva (W/K)
  final double overallHeatTransferCoefficientUA;

  /// Estado del forzador/ventilador del evaporador
  final bool fanOperational;

  /// Espesor de escarcha en batería en mm (aumenta resistencia térmica)
  final double frostThicknessMm;

  const EvaporatorComponent({
    required super.id,
    required super.name,
    this.evaporatorType = EvaporatorType.directExpansionAir,
    this.coolingCapacityWatts = 0.0,
    this.roomTemperatureKelvin = 277.15, // 4.0 °C (cámara de conservación)
    this.targetSuperheatKelvin = 7.0, // 7.0 K
    this.overallHeatTransferCoefficientUA = 180.0, // W/K
    this.fanOperational = true,
    this.frostThicknessMm = 0.0,
    super.posX = 150.0,
    super.posY = 100.0,
    super.rotationDeg = 0.0,
    super.isOperational = true,
    super.activeAlarms = const [],
    List<ConnectionPort>? customPorts,
  }) : super(
          type: ComponentType.evaporator,
          ports: customPorts ??
              const [
                ConnectionPort(
                  id: 'inlet',
                  name: 'Entrada mezcla bifásica fría',
                  type: PortType.inlet,
                  relativeX: 0.1,
                  relativeY: 0.8,
                  nominalDiameterMm: 12.0,
                ),
                ConnectionPort(
                  id: 'outlet',
                  name: 'Salida vapor recalentado',
                  type: PortType.outlet,
                  relativeX: 0.9,
                  relativeY: 0.2,
                  nominalDiameterMm: 16.0,
                ),
              ],
        );

  /// Coeficiente efectivo considerando escarcha y ventilador
  double get effectiveUA {
    if (!fanOperational) return overallHeatTransferCoefficientUA * 0.15;
    // La escarcha actúa como aislante térmico
    final frostResistance = 1.0 + (frostThicknessMm * 0.25);
    return overallHeatTransferCoefficientUA / frostResistance;
  }

  EvaporatorComponent copyWith({
    String? id,
    String? name,
    EvaporatorType? evaporatorType,
    double? coolingCapacityWatts,
    double? roomTemperatureKelvin,
    double? targetSuperheatKelvin,
    double? overallHeatTransferCoefficientUA,
    bool? fanOperational,
    double? frostThicknessMm,
    double? posX,
    double? posY,
    double? rotationDeg,
    bool? isOperational,
    List<String>? activeAlarms,
    List<ConnectionPort>? ports,
  }) {
    return EvaporatorComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      evaporatorType: evaporatorType ?? this.evaporatorType,
      coolingCapacityWatts: coolingCapacityWatts ?? this.coolingCapacityWatts,
      roomTemperatureKelvin: roomTemperatureKelvin ?? this.roomTemperatureKelvin,
      targetSuperheatKelvin: targetSuperheatKelvin ?? this.targetSuperheatKelvin,
      overallHeatTransferCoefficientUA: overallHeatTransferCoefficientUA ?? this.overallHeatTransferCoefficientUA,
      fanOperational: fanOperational ?? this.fanOperational,
      frostThicknessMm: frostThicknessMm ?? this.frostThicknessMm,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      isOperational: isOperational ?? this.isOperational,
      activeAlarms: activeAlarms ?? this.activeAlarms,
      customPorts: ports ?? this.ports,
    );
  }
}
