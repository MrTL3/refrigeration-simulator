import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/components/base_component.dart';
import '../../education/explanations/dynamic_explainer.dart';
import '../../simulation/engine/simulation_state.dart';
import '../theme/scada_colors.dart';

/// Modal interactivo de explicación e inspección contextual ("¿QUÉ ESTÁ PASANDO?").
class ComponentInspectorModal extends StatefulWidget {
  final BaseComponent initialComponent;
  final SimulationState state;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;

  const ComponentInspectorModal({
    super.key,
    required this.initialComponent,
    required this.state,
    required this.pressureUnit,
    required this.temperatureUnit,
  });

  static Future<void> show(
    BuildContext context, {
    required BaseComponent component,
    required SimulationState state,
    required PressureUnit pressureUnit,
    required TemperatureUnit temperatureUnit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ComponentInspectorModal(
        initialComponent: component,
        state: state,
        pressureUnit: pressureUnit,
        temperatureUnit: temperatureUnit,
      ),
    );
  }

  @override
  State<ComponentInspectorModal> createState() => _ComponentInspectorModalState();
}

class _ComponentInspectorModalState extends State<ComponentInspectorModal> {
  late BaseComponent _currentComponent;
  ExplanationLevel _selectedLevel = ExplanationLevel.intermediate;

  @override
  void initState() {
    super.initState();
    _currentComponent = widget.initialComponent;
  }

  @override
  Widget build(BuildContext context) {
    final explanation = DynamicExplainer.explain(
      component: _currentComponent,
      state: widget.state,
      level: _selectedLevel,
      pressureUnit: widget.pressureUnit,
      tempUnit: widget.temperatureUnit,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: ScadaColors.infoBlue, width: 2)),
      ),
      child: Column(
        children: [
          // Barra de agarre
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ScadaColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Selector de componentes rápido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.state.circuit.components.values.map((c) {
                  final isSelected = c.id == _currentComponent.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected: isSelected,
                      selectedColor: ScadaColors.infoBlue.withValues(alpha: 0.25),
                      backgroundColor: ScadaColors.surfaceCard,
                      side: BorderSide(
                        color: isSelected ? ScadaColors.infoBlue : ScadaColors.border,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSelected ? ScadaColors.infoBlue : ScadaColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _currentComponent = c);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Selector de 4 niveles de explicación
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ScadaColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ScadaColors.border),
            ),
            child: Row(
              children: ExplanationLevel.values.map((lvl) {
                final isSelected = lvl == _selectedLevel;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedLevel = lvl),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? ScadaColors.infoBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lvl.label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : ScadaColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Contenido principal de la explicación
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                // Título y estado de fase
                Text(
                  explanation.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ScadaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ScadaColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    explanation.phaseSummary,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ScadaColors.infoBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Caja de Telemetría Viva Real
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ScadaColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ScadaColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monitor_heart, size: 16, color: ScadaColors.runningGreen),
                          SizedBox(width: 6),
                          Text(
                            'VALORES REALES EN LA MÁQUINA AHORA:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ScadaColors.runningGreen,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        explanation.telemetrySummary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ScadaColors.textPrimary,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Explicación didáctica
                const Text(
                  'EXPLICACIÓN FÍSICA:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ScadaColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  explanation.explanation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ScadaColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Relación Causa - Efecto
                if (explanation.causeEffectText.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ScadaColors.surfaceCardHighlight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScadaColors.infoBlue.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_tree, size: 16, color: ScadaColors.infoBlue),
                            SizedBox(width: 6),
                            Text(
                              'RELACIÓN CAUSA ➔ EFECTO:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ScadaColors.infoBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          explanation.causeEffectText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: ScadaColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Variables clave
                if (explanation.keyVariables.isNotEmpty) ...[
                  const Text(
                    'VARIABLES IMPLICADAS:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ScadaColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: explanation.keyVariables.map((v) {
                      return Chip(
                        label: Text(v),
                        backgroundColor: ScadaColors.surfaceCard,
                        side: const BorderSide(color: ScadaColors.border),
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          color: ScadaColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
