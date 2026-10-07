import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../domain/components/base_component.dart';
import '../../domain/components/compressor_component.dart';
import '../../domain/components/condenser_component.dart';
import '../../domain/components/expansion_device_component.dart';
import '../../domain/components/evaporator_component.dart';
import '../../domain/models/thermodynamic_state.dart';
import '../../education/components/component_knowledge_base.dart';
import '../../education/explanations/dynamic_explainer.dart';
import '../../simulation/engine/simulation_state.dart';
import '../theme/scada_colors.dart';

enum InspectorViewMode {
  learning('MODO APRENDIZAJE'),
  technical('MODO TÉCNICO');

  final String label;
  const InspectorViewMode(this.label);
}

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
  InspectorViewMode _viewMode = InspectorViewMode.learning;
  ExplanationLevel _selectedLevel = ExplanationLevel.intermediate;

  @override
  void initState() {
    super.initState();
    _currentComponent = widget.initialComponent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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

          // Selector de componente activo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

          // Selector principal de modo: [MODO APRENDIZAJE] vs [MODO TÉCNICO]
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: ScadaColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ScadaColors.border),
            ),
            child: Row(
              children: InspectorViewMode.values.map((mode) {
                final isSelected = mode == _viewMode;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _viewMode = mode),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? ScadaColors.infoBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mode.label,
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
          const SizedBox(height: 8),

          // Cuerpo de la pantalla según el modo seleccionado
          Expanded(
            child: _viewMode == InspectorViewMode.learning
                ? _buildLearningView()
                : _buildTechnicalView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningView() {
    final explanation = DynamicExplainer.explain(
      component: _currentComponent,
      state: widget.state,
      level: _selectedLevel,
      pressureUnit: widget.pressureUnit,
      tempUnit: widget.temperatureUnit,
    );
    final card = ComponentKnowledgeBase.getCard(_currentComponent.id);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        // Selector de 4 niveles de explicación
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ScadaColors.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Row(
            children: ExplanationLevel.values.map((lvl) {
              final isSel = lvl == _selectedLevel;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedLevel = lvl),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? ScadaColors.infoBlue.withValues(alpha: 0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isSel ? Border.all(color: ScadaColors.infoBlue) : null,
                    ),
                    child: Text(
                      lvl.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSel ? ScadaColors.infoBlue : ScadaColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Explicación dinámica del estado en vivo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ScadaColors.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                explanation.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                explanation.explanation,
                style: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary, height: 1.3),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.psychology, size: 14, color: ScadaColors.runningGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Causa y efecto: ${explanation.causeEffectText}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: ScadaColors.runningGreen),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ficha estructurada de aprendizaje para el técnico
        _sectionHeader('FICHA PEDAGÓGICA Y PRINCIPIOS DE OPERACIÓN', Icons.menu_book),
        const SizedBox(height: 6),
        _infoCard('¿Qué es y para qué sirve?', card.function),
        _infoCard('¿Dónde se ubica en el circuito?', card.location),
        _flowCard('¿Qué refrigerante entra?', card.whatEnters, isInput: true),
        _flowCard('¿Qué refrigerante sale?', card.whatLeaves, isInput: false),
        _infoCard('¿Qué variable física modifica?', card.variableModified),
        _infoCard('Valores de trabajo habituales', card.typicalValues),
        _infoCard('¿Cómo se mide y comprueba?', card.howToMeasure),
        _infoCard('Modos de fallo habituales', card.failureModes, isWarning: true),
        _infoCard('Síntomas observables de avería', card.failureSymptoms, isWarning: true),
        _infoCard('Procedimiento de diagnóstico', card.diagnosisProcedure, isHighlight: true),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTechnicalView() {
    final c = _currentComponent;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        _sectionHeader('TELEMETRÍA Y VARIABLES ACTIVAS', Icons.speed),
        const SizedBox(height: 6),

        if (c is CompressorComponent) ...[
          _techGrid([
            {'label': 'Velocidad Giro (RPM)', 'val': '${widget.state.dynamicRpm.toStringAsFixed(0)} RPM'},
            {'label': 'Cilindrada', 'val': '${c.displacementCm3.toStringAsFixed(1)} cm³'},
            {'label': 'Consumo Eléctrico', 'val': '${(widget.state.electricalPowerWatts / 1000.0).toStringAsFixed(2)} kW'},
            {'label': 'Potencia Indicada', 'val': '${(widget.state.compressorPowerWatts / 1000.0).toStringAsFixed(2)} kW'},
            {'label': 'Eficiencia Volumétrica', 'val': '${(c.volumetricEfficiency * 100).toStringAsFixed(1)}%'},
            {'label': 'Eficiencia Isentrópica', 'val': '${(c.isentropicEfficiency * 100).toStringAsFixed(1)}%'},
          ]),
          const SizedBox(height: 10),
          _equationCard(
            'Ecuación Cinemática de Caudal Másico:',
            'ṁ = V_disp · (RPM / 60) · ρ_aspiración · η_vol',
            'ṁ actual = ${(widget.state.massFlowKgPerSec * 1000.0).toStringAsFixed(2)} g/s',
          ),
          _equationCard(
            'Trabajo Isentrópico Específico:',
            'w_is = [k / (k - 1)] · (P₁ / ρ₁) · [(P₂ / P₁)^((k-1)/k) - 1]',
            'Potencia compresión = ${widget.state.compressorPowerWatts.toStringAsFixed(0)} W',
          ),
        ] else if (c is CondenserComponent) ...[
          _techGrid([
            {'label': 'Presión Condensación (Pₖ)', 'val': UnitFormatter.formatPressure(widget.state.condensingPressurePa, widget.pressureUnit)},
            {'label': 'T_sat Condensación', 'val': UnitFormatter.formatTemperature(widget.state.condensingTemperatureK, widget.temperatureUnit)},
            {'label': 'Subenfriamiento (SC)', 'val': '${widget.state.subcoolingKelvin.toStringAsFixed(1)} K'},
            {'label': 'Calor Rechazado (Q_c)', 'val': '${(widget.state.heatingCapacityWatts / 1000.0).toStringAsFixed(2)} kW'},
            {'label': 'T_ambiente Exterior', 'val': UnitFormatter.formatTemperature(c.ambientTemperatureKelvin, widget.temperatureUnit)},
            {'label': 'Coeficiente UA', 'val': '${c.overallHeatTransferCoefficientUA.toStringAsFixed(0)} W/K'},
          ]),
          const SizedBox(height: 10),
          _equationCard(
            'Balance Térmico en Condensador:',
            'Q̇_c = ṁ · (h₂ - h₃) = UA_cond · (T_cond - T_amb)',
            'Q̇_c = ${(widget.state.heatingCapacityWatts).toStringAsFixed(0)} W',
          ),
        ] else if (c is ExpansionDeviceComponent) ...[
          _techGrid([
            {'label': 'Apertura Orificio', 'val': '${c.openingPercent.toStringAsFixed(1)}%'},
            {'label': 'Salto de Presión (ΔP)', 'val': UnitFormatter.formatPressure(widget.state.condensingPressurePa - widget.state.evaporatingPressurePa, widget.pressureUnit)},
            {'label': 'Modo Válvula', 'val': c.isAutomatic ? 'Automático (Bulbo)' : 'Manual Fijo'},
            {'label': 'Recalentamiento Objetivo', 'val': '${c.targetSuperheatKelvin.toStringAsFixed(1)} K'},
          ]),
          const SizedBox(height: 10),
          _equationCard(
            'Expansión Isentálpica (Estrangulamiento):',
            'h₄ ≡ h₃ (sin trabajo ni calor intercambiado)',
            'h₃ = ${(widget.state.state3Liquid.enthalpy / 1000.0).toStringAsFixed(1)} kJ/kg -> h₄ = ${(widget.state.state4EvapInlet.enthalpy / 1000.0).toStringAsFixed(1)} kJ/kg',
          ),
        ] else if (c is EvaporatorComponent) ...[
          _techGrid([
            {'label': 'Presión Evaporación (P₀)', 'val': UnitFormatter.formatPressure(widget.state.evaporatingPressurePa, widget.pressureUnit)},
            {'label': 'T_sat Evaporación', 'val': UnitFormatter.formatTemperature(widget.state.evaporatingTemperatureK, widget.temperatureUnit)},
            {'label': 'Recalentamiento (SH)', 'val': '${widget.state.superheatKelvin.toStringAsFixed(1)} K'},
            {'label': 'Potencia Frigorífica (Q_e)', 'val': '${(widget.state.coolingCapacityWatts / 1000.0).toStringAsFixed(2)} kW'},
            {'label': 'T_cámara Recinto', 'val': UnitFormatter.formatTemperature(widget.state.coldRoom.temperatureKelvin, widget.temperatureUnit)},
            {'label': 'Coeficiente UA', 'val': '${c.overallHeatTransferCoefficientUA.toStringAsFixed(0)} W/K'},
          ]),
          const SizedBox(height: 10),
          _equationCard(
            'Potencia Frigorífica Absorbida:',
            'Q̇_e = ṁ · (h₁ - h₄) = UA_evap · (T_cám - T_evap)',
            'Q̇_e = ${(widget.state.coolingCapacityWatts).toStringAsFixed(0)} W',
          ),
        ],

        const SizedBox(height: 12),
        _sectionHeader('ESTADO TERMODINÁMICO DE LOS PUERTOS', Icons.schema),
        const SizedBox(height: 6),
        _portStateCard('Puerto de Entrada', _getInletStateForComponent(c)),
        const SizedBox(height: 6),
        _portStateCard('Puerto de Salida', _getOutletStateForComponent(c)),
        const SizedBox(height: 20),
      ],
    );
  }

  ThermodynamicState _getInletStateForComponent(BaseComponent c) {
    if (c is CompressorComponent) return widget.state.state1Suction;
    if (c is CondenserComponent) return widget.state.state2Discharge;
    if (c is ExpansionDeviceComponent) return widget.state.state3Liquid;
    if (c is EvaporatorComponent) return widget.state.state4EvapInlet;
    return widget.state.state1Suction;
  }

  ThermodynamicState _getOutletStateForComponent(BaseComponent c) {
    if (c is CompressorComponent) return widget.state.state2Discharge;
    if (c is CondenserComponent) return widget.state.state3Liquid;
    if (c is ExpansionDeviceComponent) return widget.state.state4EvapInlet;
    if (c is EvaporatorComponent) return widget.state.state1Suction;
    return widget.state.state2Discharge;
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ScadaColors.infoBlue),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: ScadaColors.infoBlue,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, String content, {bool isWarning = false, bool isHighlight = false}) {
    Color borderColor = ScadaColors.border;
    Color bgColor = ScadaColors.surfaceCard;
    if (isWarning) {
      borderColor = ScadaColors.warningAmber.withValues(alpha: 0.5);
      bgColor = ScadaColors.warningAmber.withValues(alpha: 0.05);
    } else if (isHighlight) {
      borderColor = ScadaColors.runningGreen.withValues(alpha: 0.5);
      bgColor = ScadaColors.runningGreen.withValues(alpha: 0.05);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textSecondary)),
          const SizedBox(height: 3),
          Text(content, style: const TextStyle(fontSize: 11, color: ScadaColors.textPrimary, height: 1.3)),
        ],
      ),
    );
  }

  Widget _flowCard(String title, String content, {required bool isInput}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInput ? ScadaColors.infoBlue.withValues(alpha: 0.4) : ScadaColors.runningGreen.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isInput ? Icons.login : Icons.logout,
            size: 16,
            color: isInput ? ScadaColors.infoBlue : ScadaColors.runningGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isInput ? ScadaColors.infoBlue : ScadaColors.runningGreen)),
                const SizedBox(height: 2),
                Text(content, style: const TextStyle(fontSize: 11, color: ScadaColors.textPrimary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _techGrid(List<Map<String, String>> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((it) {
        return Container(
          width: 165,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ScadaColors.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it['label']!, style: const TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                it['val']!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.infoBlue, fontFamily: 'monospace'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _equationCard(String title, String formula, String result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ScadaColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textSecondary)),
          const SizedBox(height: 3),
          Text(formula, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: ScadaColors.warningAmber)),
          const SizedBox(height: 2),
          Text(result, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: ScadaColors.runningGreen)),
        ],
      ),
    );
  }

  Widget _portStateCard(String label, ThermodynamicState s) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary)),
          Text(
            '${UnitFormatter.formatPressure(s.pressure, widget.pressureUnit)} | ${UnitFormatter.formatTemperature(s.temperature, widget.temperatureUnit)} | ${s.phaseState.displayName}',
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: ScadaColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
