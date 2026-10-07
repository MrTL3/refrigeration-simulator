import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../theme/scada_colors.dart';
import 'experiment_screen.dart';
import 'learn_screen.dart';
import 'roadmap_phase_screen.dart';
import 'simulator_screen.dart';
import 'workshop_screen.dart';

/// Estructura de navegación principal y contenedor adaptativo de FrigoLab.
class MainLayoutScreen extends StatefulWidget {
  final SimulationEngine engine;

  const MainLayoutScreen({super.key, required this.engine});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  PressureUnit _pressureUnit = PressureUnit.bar;
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: ScadaColors.background,
          appBar: _buildTopAppBar(),
          body: Row(
            children: [
              if (isWide) _buildNavigationRail(),
              Expanded(child: _buildCurrentScreen()),
            ],
          ),
          bottomNavigationBar: isWide ? null : _buildBottomNavigationBar(),
        );
      },
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ScadaColors.infoBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ScadaColors.infoBlue),
            ),
            child: const Icon(Icons.severe_cold, color: ScadaColors.infoBlue, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FRIGOLAB',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
                  color: ScadaColors.textPrimary,
                ),
              ),
              Text(
                'Laboratorio Virtual de Refrigeración Industrial',
                style: TextStyle(fontSize: 10, color: ScadaColors.textMuted),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Chip(
          label: const Text('FASE 1: FUNDAMENTOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: ScadaColors.surfaceCard,
          side: const BorderSide(color: ScadaColors.runningGreen),
          labelStyle: const TextStyle(color: ScadaColors.runningGreen),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      backgroundColor: ScadaColors.surface,
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: const TextStyle(color: ScadaColors.infoBlue, fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: const TextStyle(color: ScadaColors.textSecondary, fontSize: 11),
      selectedIconTheme: const IconThemeData(color: ScadaColors.infoBlue),
      unselectedIconTheme: const IconThemeData(color: ScadaColors.textMuted),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.schema_outlined),
          selectedIcon: Icon(Icons.schema),
          label: Text('Simulador'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: Text('Aprender'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build),
          label: Text('Taller'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.science_outlined),
          selectedIcon: Icon(Icons.science),
          label: Text('Ensayos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.troubleshoot_outlined),
          selectedIcon: Icon(Icons.troubleshoot),
          label: Text('Diagnóstico'),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      backgroundColor: ScadaColors.surface,
      indicatorColor: ScadaColors.infoBlue.withValues(alpha: 0.2),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.schema_outlined),
          selectedIcon: Icon(Icons.schema, color: ScadaColors.infoBlue),
          label: 'Simulador',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book, color: ScadaColors.infoBlue),
          label: 'Aprender',
        ),
        NavigationDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build, color: ScadaColors.infoBlue),
          label: 'Taller',
        ),
        NavigationDestination(
          icon: Icon(Icons.science_outlined),
          selectedIcon: Icon(Icons.science, color: ScadaColors.infoBlue),
          label: 'Ensayos',
        ),
        NavigationDestination(
          icon: Icon(Icons.troubleshoot_outlined),
          selectedIcon: Icon(Icons.troubleshoot, color: ScadaColors.infoBlue),
          label: 'Diagnóstico',
        ),
      ],
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return SimulatorScreen(
          engine: widget.engine,
          pressureUnit: _pressureUnit,
          temperatureUnit: _temperatureUnit,
          onPressureUnitChanged: (u) => setState(() => _pressureUnit = u),
          onTemperatureUnitChanged: (u) => setState(() => _temperatureUnit = u),
        );
      case 1:
        return LearnScreen(
          engine: widget.engine,
          pressureUnit: _pressureUnit,
          temperatureUnit: _temperatureUnit,
        );
      case 2:
        return WorkshopScreen(
          engine: widget.engine,
          pressureUnit: _pressureUnit,
        );
      case 3:
        return ExperimentScreen(
          engine: widget.engine,
          pressureUnit: _pressureUnit,
          temperatureUnit: _temperatureUnit,
        );
      case 4:
        return const RoadmapPhaseScreen(
          title: 'Módulo de Diagnóstico y Averías a Ciegas',
          phaseBadge: 'FASE 8 (ROADMAP)',
          description:
              'Entorno de entrenamiento técnico en el que la aplicación genera anomalías físicas sin revelar la causa, obligando al usuario a utilizar su instrumental para diagnosticar.',
          icon: Icons.troubleshoot,
          plannedFeatures: [
            'Simulación física de fugas de refrigerante y falta de carga.',
            'Atascamiento de filtro deshidratador y caída de presión localizada.',
            'Incondensables en el circuito y sobrepresión de alta.',
            'Ventiladores agarrotados y suciedad progresiva de condensador.',
            'Informe técnico final con puntuación y retroalimentación pedagógica.',
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
