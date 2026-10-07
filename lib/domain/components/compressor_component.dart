import '../models/connection_port.dart';
import 'base_component.dart';

/// Tipos constructivos de compresor frigorífico.
enum CompressorTechnology {
  reciprocating('Alternativo/Pistón'),
  scroll('Scroll/Espiral'),
  semiHermetic('Semihermético'),
  screw('Tornillo');

  final String label;
  const CompressorTechnology(this.label);
}

/// Modelo físico y descriptivo de un compresor frigorífico industrial.
class CompressorComponent extends BaseComponent {
  final CompressorTechnology technology;

  /// Cilindrada o desplazamiento geométrico por revolución (cm³)
  final double displacementCm3;

  /// Velocidad de giro actual (RPM)
  final double rpm;

  /// Eficiencia volumétrica estimada (0.0 a 1.0)
  final double volumetricEfficiency;

  /// Eficiencia isentrópica del proceso de compresión (0.0 a 1.0)
  final double isentropicEfficiency;

  /// Eficiencia electromecánica del motor eléctrico (0.0 a 1.0)
  final double motorEfficiency;

  /// Consumo eléctrico activo actual (Watts)
  final double electricalPowerWatts;

  /// Trabajo mecánico de compresión entregado al refrigerante (Watts)
  final double indicatedPowerWatts;

  const CompressorComponent({
    required super.id,
    required super.name,
    this.technology = CompressorTechnology.reciprocating,
    this.displacementCm3 = 34.5, // ~34.5 cm³
    this.rpm = 2900.0,
    this.volumetricEfficiency = 0.78,
    this.isentropicEfficiency = 0.72,
    this.motorEfficiency = 0.88,
    this.electricalPowerWatts = 0.0,
    this.indicatedPowerWatts = 0.0,
    super.posX = 150.0,
    super.posY = 350.0,
    super.rotationDeg = 0.0,
    super.isOperational = true,
    super.activeAlarms = const [],
    List<ConnectionPort>? customPorts,
  }) : super(
          type: ComponentType.compressor,
          ports: customPorts ??
              const [
                ConnectionPort(
                  id: 'suction',
                  name: 'Aspiración (Baja)',
                  type: PortType.inlet,
                  relativeX: 0.1,
                  relativeY: 0.5,
                  nominalDiameterMm: 16.0,
                ),
                ConnectionPort(
                  id: 'discharge',
                  name: 'Descarga (Alta)',
                  type: PortType.outlet,
                  relativeX: 0.9,
                  relativeY: 0.2,
                  nominalDiameterMm: 12.0,
                ),
              ],
        );

  /// Caudal volumétrico desplazado teórico en m³/s
  double get theoreticalVolumeFlowM3PerSec {
    final displacementM3 = displacementCm3 * 1e-6;
    final rps = rpm / 60.0;
    return displacementM3 * rps;
  }

  /// Caudal másico bombeado (kg/s) a partir de la densidad del vapor de aspiración (kg/m³)
  double calculateMassFlowKgPerSec(double suctionDensityKgPerM3) {
    if (!isOperational || rpm <= 0) return 0.0;
    return theoreticalVolumeFlowM3PerSec * volumetricEfficiency * suctionDensityKgPerM3;
  }

  /// Relación de compresión (P_alta / P_baja)
  double calculateCompressionRatio(double dischargePressurePa, double suctionPressurePa) {
    if (suctionPressurePa <= 0) return 1.0;
    return (dischargePressurePa / suctionPressurePa).clamp(1.0, 50.0);
  }

  CompressorComponent copyWith({
    String? id,
    String? name,
    CompressorTechnology? technology,
    double? displacementCm3,
    double? rpm,
    double? volumetricEfficiency,
    double? isentropicEfficiency,
    double? motorEfficiency,
    double? electricalPowerWatts,
    double? indicatedPowerWatts,
    double? posX,
    double? posY,
    double? rotationDeg,
    bool? isOperational,
    List<String>? activeAlarms,
    List<ConnectionPort>? ports,
  }) {
    return CompressorComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      technology: technology ?? this.technology,
      displacementCm3: displacementCm3 ?? this.displacementCm3,
      rpm: rpm ?? this.rpm,
      volumetricEfficiency: volumetricEfficiency ?? this.volumetricEfficiency,
      isentropicEfficiency: isentropicEfficiency ?? this.isentropicEfficiency,
      motorEfficiency: motorEfficiency ?? this.motorEfficiency,
      electricalPowerWatts: electricalPowerWatts ?? this.electricalPowerWatts,
      indicatedPowerWatts: indicatedPowerWatts ?? this.indicatedPowerWatts,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      isOperational: isOperational ?? this.isOperational,
      activeAlarms: activeAlarms ?? this.activeAlarms,
      customPorts: ports ?? this.ports,
    );
  }
}
