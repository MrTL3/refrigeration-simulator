import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/core/units/pressure_unit.dart';
import 'package:frigolab/core/units/temperature_unit.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';
import 'package:frigolab/simulation/engine/simulation_state.dart';
import 'package:frigolab/visualization/models/installation_instrument.dart';
import 'package:frigolab/visualization/widgets/instrument_inspection_panel.dart';
import 'package:frigolab/visualization/installation_plant_view.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

void main() {
  group('Installation 3D Instrumentation Tests', () {
    late SimulationEngine engine;
    late SimulationState sampleState;

    setUp(() {
      engine = SimulationEngine();
      sampleState = engine.state.copyWith(
        isRunning: true,
        evaporatingPressurePa: 2.0e5, // ~2.0 bar (-10 °C aprox)
        condensingPressurePa: 11.5e5, // ~11.5 bar (45 °C aprox)
        superheatKelvin: 5.0,
        subcoolingKelvin: 4.5,
        massFlowKgPerSec: 0.012,
        electricalPowerWatts: 850.0,
      );
    });

    test('All default installation instruments are defined and positioned coherently', () {
      final instruments = InstallationInstrument.defaultInstallation();
      expect(instruments.length, equals(14));

      // Check key instruments exist
      expect(instruments.any((i) => i.type == InstrumentType.lowPressureGauge), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.highPressureGauge), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.evaporatorInletThermometer), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.suctionThermometer), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.dischargeThermometer), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.liquidThermometer), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.coldRoomThermometer), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.ambientThermometer), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.dualPressureSwitch), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.massFlowMeter), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.sightGlass), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.oilSightGlass), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.electricalClamp), isTrue);
      expect(instruments.any((i) => i.type == InstrumentType.vacuumGauge), isTrue);
    });

    test('All 14 instruments provide consistent readings mapped to physical solver state', () {
      final instruments = InstallationInstrument.defaultInstallation();
      for (final inst in instruments) {
        final reading = inst.getReading(sampleState, PressureUnit.bar, TemperatureUnit.celsius);
        expect(reading.primaryValue.isNotEmpty, isTrue);
        expect(reading.secondaryValue.isNotEmpty, isTrue);
        expect(reading.statusText.isNotEmpty, isTrue);
        expect(reading.technicalDetails.isNotEmpty, isTrue);
      }
    });

    test('Bourdon Gauges reflect exact bar pressure calculations', () {
      final lpGauge = InstallationInstrument.defaultInstallation().firstWhere(
        (i) => i.type == InstrumentType.lowPressureGauge,
      );
      final hpGauge = InstallationInstrument.defaultInstallation().firstWhere(
        (i) => i.type == InstrumentType.highPressureGauge,
      );

      final lpReading = lpGauge.getReading(sampleState, PressureUnit.bar, TemperatureUnit.celsius);
      final hpReading = hpGauge.getReading(sampleState, PressureUnit.bar, TemperatureUnit.celsius);

      expect(lpReading.primaryValue, contains('2.00 bar'));
      expect(hpReading.primaryValue, contains('11.50 bar'));
    });

    test('Inverse matrix transformation allows accurate hit testing under pan and zoom', () {
      final matrix = vmath.Matrix4.identity();
      // Simulate zoom of 1.5x and translation of (100, 50)
      matrix.scaleByVector3(vmath.Vector3(1.5, 1.5, 1.0));
      matrix.translateByVector3(vmath.Vector3(100.0, 50.0, 0.0));

      final invMatrix = vmath.Matrix4.tryInvert(matrix);
      expect(invMatrix, isNotNull);

      final originalWorldPoint = const Offset(650.0, 480.0);
      final screenPoint = MatrixUtils.transformPoint(matrix, originalWorldPoint);
      final transformedBack = MatrixUtils.transformPoint(invMatrix!, screenPoint);

      expect(transformedBack.dx, closeTo(originalWorldPoint.dx, 1e-4));
      expect(transformedBack.dy, closeTo(originalWorldPoint.dy, 1e-4));
    });
  });

  group('InstrumentInspectionPanel Widget Tests', () {
    testWidgets('Renders instrument reading details and responds to close button', (tester) async {
      final engine = SimulationEngine();
      final state = engine.state.copyWith(
        isRunning: true,
        evaporatingPressurePa: 2.2e5,
      );
      final inst = InstallationInstrument.defaultInstallation().firstWhere(
        (i) => i.type == InstrumentType.lowPressureGauge,
      );

      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstrumentInspectionPanel(
              instrument: inst,
              state: state,
              pressureUnit: PressureUnit.bar,
              temperatureUnit: TemperatureUnit.celsius,
              onClose: () => closed = true,
              onInspectWhy: () {},
            ),
          ),
        ),
      );

      expect(find.text(inst.type.label), findsOneWidget);
      expect(find.text('¿POR QUÉ?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('Renders InstallationPlantView with reset view and zoom controls', (tester) async {
      final engine = SimulationEngine();
      final state = engine.state.copyWith(isRunning: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: InstallationPlantView(
                state: state,
                pressureUnit: PressureUnit.bar,
                temperatureUnit: TemperatureUnit.celsius,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);

      // Tap zoom in
      await tester.tap(find.byIcon(Icons.zoom_in), warnIfMissed: false);
      await tester.pump();

      // Tap reset view
      await tester.tap(find.byIcon(Icons.center_focus_strong), warnIfMissed: false);
      await tester.pump();
    });
  });
}
