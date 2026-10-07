import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/main.dart';
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
}
