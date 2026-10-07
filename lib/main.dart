import 'package:flutter/material.dart';
import 'presentation/screens/main_layout_screen.dart';
import 'presentation/theme/scada_colors.dart';
import 'simulation/engine/simulation_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final engine = SimulationEngine();

  runApp(FrigoLabApp(engine: engine));
}

class FrigoLabApp extends StatelessWidget {
  final SimulationEngine engine;

  const FrigoLabApp({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrigoLab - Simulador de Refrigeración Industrial',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainLayoutScreen(engine: engine),
    );
  }
}
