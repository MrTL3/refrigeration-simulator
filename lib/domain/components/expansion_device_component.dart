import '../models/connection_port.dart';
import 'base_component.dart';

/// Tipos de dispositivos de expansión.
enum ExpansionDeviceType {
  thermostaticExpansionValve('Válvula de expansión termostática (TXV)'),
  electronicExpansionValve('Válvula de expansión electrónica (EEV)'),
  capillaryTube('Tubo capilar');

  final String label;
  const ExpansionDeviceType(this.label);
}

/// Modelo de dispositivo de expansión isentálpico (h_entrada = h_salida).
class ExpansionDeviceComponent extends BaseComponent {
  final ExpansionDeviceType deviceType;

  /// Porcentaje de apertura efectiva (0.0% = totalmente cerrada, 100.0% = totalmente abierta)
  final double openingPercent;

  /// Recalentamiento objetivo para control termostático automático (K)
  final double targetSuperheatKelvin;

  /// Coeficiente de caudal de referencia Kv nominal (m³/h a ΔP = 1 bar de agua)
  final double nominalKv;

  /// Si está activo el control automático modulante de recalentamiento
  final bool isAutomatic;

  const ExpansionDeviceComponent({
    required super.id,
    required super.name,
    this.deviceType = ExpansionDeviceType.thermostaticExpansionValve,
    this.openingPercent = 45.0, // 45% nominal
    this.targetSuperheatKelvin = 7.0, // 7 K de superheat estándar
    this.nominalKv = 0.25,
    this.isAutomatic = true,
    super.posX = 500.0,
    super.posY = 350.0,
    super.rotationDeg = 0.0,
    super.isOperational = true,
    super.activeAlarms = const [],
    List<ConnectionPort>? customPorts,
  }) : super(
          type: ComponentType.expansionDevice,
          ports: customPorts ??
              const [
                ConnectionPort(
                  id: 'inlet',
                  name: 'Entrada líquido alta presión',
                  type: PortType.inlet,
                  relativeX: 0.1,
                  relativeY: 0.5,
                  nominalDiameterMm: 10.0,
                ),
                ConnectionPort(
                  id: 'outlet',
                  name: 'Salida mezcla baja presión',
                  type: PortType.outlet,
                  relativeX: 0.9,
                  relativeY: 0.5,
                  nominalDiameterMm: 12.0,
                ),
              ],
        );

  ExpansionDeviceComponent copyWith({
    String? id,
    String? name,
    ExpansionDeviceType? deviceType,
    double? openingPercent,
    double? targetSuperheatKelvin,
    double? nominalKv,
    bool? isAutomatic,
    double? posX,
    double? posY,
    double? rotationDeg,
    bool? isOperational,
    List<String>? activeAlarms,
    List<ConnectionPort>? ports,
  }) {
    return ExpansionDeviceComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      openingPercent: openingPercent ?? this.openingPercent,
      targetSuperheatKelvin: targetSuperheatKelvin ?? this.targetSuperheatKelvin,
      nominalKv: nominalKv ?? this.nominalKv,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      rotationDeg: rotationDeg ?? this.rotationDeg,
      isOperational: isOperational ?? this.isOperational,
      activeAlarms: activeAlarms ?? this.activeAlarms,
      customPorts: ports ?? this.ports,
    );
  }
}
