import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/core/units/pressure_unit.dart';
import 'package:frigolab/core/units/temperature_unit.dart';
import 'package:frigolab/main.dart';
import 'package:frigolab/presentation/screens/fullscreen_simulator_screen.dart';
import 'package:frigolab/presentation/widgets/simulation_parameters_panel.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';

void main() {
  testWidgets('FrigoLab UI smoke test', (WidgetTester tester) async {
    final engine = SimulationEngine();
    await tester.pumpWidget(FrigoLabApp(engine: engine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Comprobamos que el título y la barra de estado se renderizan
    expect(find.text('FRIGOLAB'), findsOneWidget);
    expect(find.text('TELEMETRÍA DE CICLO'), findsOneWidget);
    expect(find.text('¿QUÉ ESTÁ PASANDO?'), findsOneWidget);
  });

  testWidgets('InstallationPlantView y selector de modos funcionan sin overflow', (WidgetTester tester) async {
    final engine = SimulationEngine();
    await tester.pumpWidget(FrigoLabApp(engine: engine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verificamos los modos en la barra de pestañas scrollable
    expect(find.text('Instalación'), findsOneWidget);
    expect(find.text('P&ID Técnico'), findsOneWidget);
    expect(find.text('Instrumentos'), findsOneWidget);
    expect(find.text('Diagrama P-h'), findsOneWidget);
    expect(find.text('Diagrama T-s'), findsOneWidget);

    // Cambiamos a P&ID Técnico
    await tester.tap(find.text('P&ID Técnico'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('P&ID Técnico'), findsOneWidget);

    // Volvemos a Instalación
    await tester.tap(find.text('Instalación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Instalación'), findsOneWidget);
  });

  testWidgets('SimulationParametersPanel renderiza actuadores y mediciones en tiempo real', (WidgetTester tester) async {
    final engine = SimulationEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimulationParametersPanel(
            engine: engine,
            pressureUnit: PressureUnit.bar,
            temperatureUnit: TemperatureUnit.celsius,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verificamos presencia de actuadores y etiquetas
    expect(find.text('PUESTO DE CONTROL'), findsOneWidget);
    expect(find.text('ACTUADORES (CONTROL)'), findsOneWidget);
    expect(find.text('COMPRESOR HERMÉTICO'), findsOneWidget);
    expect(find.text('VÁLVULA DE EXPANSIÓN (TXV)'), findsOneWidget);
    expect(find.text('CÁMARA FRIGORÍFICA Y TERMOSTATO'), findsOneWidget);
    expect(find.text('CONDENSADOR Y ENTORNO EXTERIOR'), findsOneWidget);

    // Verificamos botones de simulación
    expect(find.text('ARRANCAR'), findsOneWidget);
    expect(find.text('PASO dt (0.05s)'), findsOneWidget);
    expect(find.text('REINICIAR'), findsOneWidget);
  });

  testWidgets('FullscreenSimulatorScreen inicializa HUD de telemetría y barra SCADA panorámica', (WidgetTester tester) async {
    final engine = SimulationEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenSimulatorScreen(
          engine: engine,
          pressureUnit: PressureUnit.bar,
          temperatureUnit: TemperatureUnit.celsius,
          onPressureUnitChanged: (_) {},
          onTemperatureUnitChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verificamos HUD y barra superior SCADA
    expect(find.text('PARÁMETROS'), findsOneWidget);
    expect(find.text('SALIR'), findsOneWidget);

    // Verificamos telemetría HUD inferior
    expect(find.textContaining('Po:'), findsOneWidget);
    expect(find.textContaining('Pk:'), findsOneWidget);
    expect(find.textContaining('T_cám:'), findsOneWidget);
    expect(find.textContaining('SH:'), findsOneWidget);
    expect(find.textContaining('SC:'), findsOneWidget);
  });
}
