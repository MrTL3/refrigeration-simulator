import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/core/services/platform_service.dart';
import 'package:frigolab/core/units/pressure_unit.dart';
import 'package:frigolab/core/units/temperature_unit.dart';
import 'package:frigolab/domain/components/compressor_component.dart';
import 'package:frigolab/domain/components/expansion_device_component.dart';
import 'package:frigolab/presentation/screens/simulator_screen.dart';
import 'package:frigolab/presentation/widgets/desktop_inspector_panel.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';
import 'package:frigolab/simulation/engine/simulation_state.dart';
import 'package:frigolab/visualization/installation_plant_view.dart';
import 'package:frigolab/visualization/models/installation_instrument.dart';

void main() {
  group('PlatformService Tests', () {
    test('PlatformService exposes expected properties without exception', () {
      expect(PlatformService.isDesktop, isA<bool>());
      expect(PlatformService.isWeb, isA<bool>());
      expect(PlatformService.isMobile, isA<bool>());
    });

    test('Fullscreen helpers execute cleanly without throw', () async {
      await PlatformService.enterFullscreenLandscape();
      await PlatformService.exitFullscreenLandscape();
    });
  });

  group('InstallationInstrument Multiplatform Positioning Tests', () {
    test('withOffset creates translated instrument with new coordinates', () {
      final base = InstallationInstrument(
        id: 'gauge_hp',
        tag: 'PI-01',
        type: InstrumentType.highPressureGauge,
        worldPosition: const Offset(100.0, 200.0),
        physicalLocation: 'Línea de descarga',
        technicalPurpose: 'Presión de alta',
      );

      final moved = base.withOffset(const Offset(35.0, -15.0));
      expect(moved.worldPosition.dx, 135.0);
      expect(moved.worldPosition.dy, 185.0);
      expect(moved.tag, 'PI-01');
      expect(moved.type, InstrumentType.highPressureGauge);
    });
  });

  group('DesktopInspectorPanel Widget Tests', () {
    late SimulationEngine engine;
    late SimulationState sampleState;

    setUp(() {
      engine = SimulationEngine();
      sampleState = engine.state.copyWith(
        isRunning: true,
        evaporatingPressurePa: 2.0e5, // ~2.0 bar
        condensingPressurePa: 11.5e5, // ~11.5 bar
        superheatKelvin: 5.0,
        subcoolingKelvin: 4.5,
        massFlowKgPerSec: 0.012,
        electricalPowerWatts: 850.0,
      );
    });

    tearDown(() {
      engine.dispose();
    });

    testWidgets('Renders instrument telemetry correctly in DesktopInspectorPanel',
        (WidgetTester tester) async {
      bool closed = false;
      final instrument = InstallationInstrument(
        id: 'gauge_hp',
        tag: 'PI-01',
        type: InstrumentType.highPressureGauge,
        worldPosition: const Offset(650.0, 195.0),
        physicalLocation: 'Salida de descarga del compresor',
        technicalPurpose: 'Presión manométrica de descarga y condensación.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 700,
              child: DesktopInspectorPanel(
                state: sampleState,
                engine: engine,
                instrument: instrument,
                component: null,
                pressureUnit: PressureUnit.bar,
                temperatureUnit: TemperatureUnit.celsius,
                onClose: () => closed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('PI-01'), findsOneWidget);
      expect(find.textContaining('INSTRUMENTO: PI-01'), findsOneWidget);
      expect(find.textContaining('bar'), findsWidgets);
      expect(find.text('Ubicación Física'), findsOneWidget);
      expect(find.text('Función Técnica'), findsOneWidget);

      // Tap close button
      final closeButton = find.byTooltip('Cerrar panel lateral');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      expect(closed, isTrue);
    });

    testWidgets('Renders compressor component telemetry and dynamic explanation',
        (WidgetTester tester) async {
      const compressorComp = CompressorComponent(
        id: 'comp-1',
        name: 'Compresor Alternativo Semihermético',
        rpm: 2900.0,
        displacementCm3: 34.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 800,
              child: DesktopInspectorPanel(
                state: sampleState,
                engine: engine,
                instrument: null,
                component: compressorComp,
                pressureUnit: PressureUnit.bar,
                temperatureUnit: TemperatureUnit.celsius,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Compresor'), findsWidgets);
      expect(find.text('COMPORTAMIENTO FÍSICO ACTUAL'), findsOneWidget);
      expect(find.text('MÉTRICAS ESPECÍFICAS DE OPERACIÓN:'), findsOneWidget);
      expect(find.textContaining('RPM'), findsWidgets);
    });

    testWidgets('Renders expansion valve details and telemetry',
        (WidgetTester tester) async {
      const txvComp = ExpansionDeviceComponent(
        id: 'txv-1',
        name: 'Válvula de Expansión Termostática TXV',
        openingPercent: 45.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 800,
              child: DesktopInspectorPanel(
                state: sampleState,
                engine: engine,
                instrument: null,
                component: txvComp,
                pressureUnit: PressureUnit.bar,
                temperatureUnit: TemperatureUnit.celsius,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Expansión'), findsWidgets);
      expect(find.text('MÉTRICAS ESPECÍFICAS DE OPERACIÓN:'), findsOneWidget);
      expect(find.textContaining('Apertura de Válvula:'), findsOneWidget);
    });
  });

  group('InstallationPlantView Web Scale and Presets Tests', () {
    late SimulationEngine engine;
    late SimulationState sampleState;

    setUp(() {
      engine = SimulationEngine();
      sampleState = engine.state;
    });

    tearDown(() {
      engine.dispose();
    });

    testWidgets('InstallationPlantView renders scale preset buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 700,
              child: InstallationPlantView(
                state: sampleState,
                pressureUnit: PressureUnit.bar,
                temperatureUnit: TemperatureUnit.celsius,
              ),
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('200%'), findsOneWidget);
      expect(find.text('400%'), findsOneWidget);

      final centerBtn = find.byTooltip('Centrar instalación (Vista Inicial)');
      expect(centerBtn, findsOneWidget);

      final resetBtn = find.byTooltip('Restablecer posiciones de componentes');
      expect(resetBtn, findsOneWidget);

      // Tap preset buttons to ensure smooth operation without throws
      await tester.tap(find.text('200%'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('100%'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(centerBtn, warnIfMissed: false);
      await tester.pump();
      await tester.tap(resetBtn, warnIfMissed: false);
      await tester.pump();
    });
  });

  group('Responsive Layout Tests in SimulatorScreen', () {
    late SimulationEngine engine;

    setUp(() {
      engine = SimulationEngine();
    });

    tearDown(() {
      engine.dispose();
    });

    testWidgets('SimulatorScreen initializes cleanly in desktop widescreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SimulatorScreen(
            engine: engine,
            pressureUnit: PressureUnit.bar,
            temperatureUnit: TemperatureUnit.celsius,
            onPressureUnitChanged: (_) {},
            onTemperatureUnitChanged: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SimulatorScreen), findsOneWidget);
      expect(find.byType(InstallationPlantView), findsOneWidget);
    });
  });
}
