import '../components/base_component.dart';
import '../components/compressor_component.dart';
import '../components/condenser_component.dart';
import '../components/expansion_device_component.dart';
import '../components/evaporator_component.dart';
import 'pipe.dart';

/// Representa una instalación o circuito frigorífico completo, incluyendo
/// componentes, tuberías de interconexión y especificación de carga de fluido.
class Circuit {
  final String id;
  final String name;
  final Map<String, BaseComponent> components;
  final List<Pipe> pipes;
  final String refrigerantName;

  /// Carga de refrigerante presente en el circuito en kilogramos (kg)
  final double refrigerantChargeKg;

  const Circuit({
    required this.id,
    required this.name,
    required this.components,
    required this.pipes,
    this.refrigerantName = 'R-134a',
    this.refrigerantChargeKg = 1.25,
  });

  CompressorComponent? get compressor {
    for (final c in components.values) {
      if (c is CompressorComponent) return c;
    }
    return null;
  }

  CondenserComponent? get condenser {
    for (final c in components.values) {
      if (c is CondenserComponent) return c;
    }
    return null;
  }

  ExpansionDeviceComponent? get expansionDevice {
    for (final c in components.values) {
      if (c is ExpansionDeviceComponent) return c;
    }
    return null;
  }

  EvaporatorComponent? get evaporator {
    for (final c in components.values) {
      if (c is EvaporatorComponent) return c;
    }
    return null;
  }

  Circuit copyWith({
    String? id,
    String? name,
    Map<String, BaseComponent>? components,
    List<Pipe>? pipes,
    String? refrigerantName,
    double? refrigerantChargeKg,
  }) {
    return Circuit(
      id: id ?? this.id,
      name: name ?? this.name,
      components: components ?? this.components,
      pipes: pipes ?? this.pipes,
      refrigerantName: refrigerantName ?? this.refrigerantName,
      refrigerantChargeKg: refrigerantChargeKg ?? this.refrigerantChargeKg,
    );
  }
}
