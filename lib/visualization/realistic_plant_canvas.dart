import 'package:flutter/material.dart';
import '../../domain/components/base_component.dart';
import '../../domain/models/simulation_level.dart';
import '../../simulation/engine/simulation_state.dart';
import 'installation_plant_view.dart';

export 'installation_plant_view.dart';

/// Lienzo interactivo en perspectiva física 2.5D de la planta frigorífica completa.
///
/// Delega en [InstallationPlantView] para ofrecer la experiencia inmersiva industrial
/// con cámara frigorífica, unidad exterior en bancada, InteractiveViewer, instrumentación in situ
/// y control de capas físicas SCADA.
class RealisticPlantCanvas extends StatelessWidget {
  final SimulationState state;
  final BaseComponent? selectedComponent;
  final ValueChanged<BaseComponent>? onComponentSelected;
  final PlantViewMode viewMode;
  final VisualLayerToggles layerToggles;
  final SimulationInformationLevel informationLevel;
  final ValueChanged<String>? onInspectWhy;

  const RealisticPlantCanvas({
    super.key,
    required this.state,
    this.selectedComponent,
    this.onComponentSelected,
    this.viewMode = PlantViewMode.realistic25D,
    this.layerToggles = const VisualLayerToggles(),
    this.informationLevel = SimulationInformationLevel.level3Technical,
    this.onInspectWhy,
  });

  @override
  Widget build(BuildContext context) {
    return InstallationPlantView(
      state: state,
      selectedComponent: selectedComponent,
      onComponentSelected: onComponentSelected,
      layerToggles: layerToggles,
      informationLevel: informationLevel,
      onInspectWhy: onInspectWhy,
    );
  }
}
