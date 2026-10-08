import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/education/lessons/progress_tracker.dart';
import 'package:frigolab/domain/models/basic_cycle_preset.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';
import 'package:frigolab/simulation/engine/simulation_state.dart';
import 'package:frigolab/state/history_manager.dart';
import 'package:frigolab/state/session_coordinator.dart';
import 'package:frigolab/state/workshop_state.dart';
import 'package:frigolab/workshop/assembly_models.dart';

void main() {
  group('FrigoLab State Management & Determinism Tests', () {
    late SimulationEngine engine;
    late HistoryManager history;
    late SessionCoordinator coordinator;

    setUp(() {
      engine = SimulationEngine();
      history = HistoryManager(maxHistoryLength: 50);
      coordinator = SessionCoordinator(engine: engine, historyManager: history);
    });

    tearDown(() {
      engine.pause();
      engine.dispose();
      coordinator.dispose();
    });

    test('TEST CRÍTICO DE DETERMINISMO (Sección 22): A -> X -> B -> UNDO => A\' == A', () {
      // Estado A de referencia (máquina parada, 2900 RPM nominales, 45% TXV)
      final snapA = coordinator.captureCurrentSnapshot('Estado A inicial');

      // Acción X: Modificar RPM del compresor a 3500 y apertura TXV a 75%
      engine.setCompressorRpm(3500.0);
      engine.setValveOpening(75.0);

      // Estado B modificado
      expect(engine.state.circuit.compressor?.rpm, equals(3500.0));
      expect(engine.state.circuit.expansionDevice?.openingPercent, equals(75.0));
      expect(coordinator.canUndo, isTrue);

      // UNDO de la última acción (TXV)
      final undo1Success = coordinator.undo();
      expect(undo1Success, isTrue);
      expect(engine.state.circuit.expansionDevice?.openingPercent, equals(45.0));

      // UNDO de la primera acción (RPM)
      final undo2Success = coordinator.undo();
      expect(undo2Success, isTrue);

      // Comprobación de determinismo estricto: A' == A
      final snapAPrime = coordinator.captureCurrentSnapshot('Estado A restaurado');
      expect(
        snapAPrime.isPhysicallyIdenticalTo(snapA),
        isTrue,
        reason: 'El estado A\' restaurado tras UNDO debe ser físicamente idéntico a A',
      );
      expect(engine.state.circuit.compressor?.rpm, equals(snapA.simulationState.circuit.compressor?.rpm));
      expect(engine.state.circuit.expansionDevice?.openingPercent, equals(snapA.simulationState.circuit.expansionDevice?.openingPercent));
    });

    test('TEST DE REDO (Sección 23): A -> B -> C -> UNDO -> REDO => C_restaurado == C_original', () {
      // Estado A: Compresor 2900 RPM
      // Estado B: Compresor 1500 RPM
      engine.setCompressorRpm(1500.0);

      // Estado C: Compresor 3200 RPM
      engine.setCompressorRpm(3200.0);
      final snapCOriginal = coordinator.captureCurrentSnapshot('Estado C original');

      // UNDO: Regresa a B (1500 RPM)
      coordinator.undo();
      expect(engine.state.circuit.compressor?.rpm, equals(1500.0));

      // REDO: Recupera C (3200 RPM)
      expect(coordinator.canRedo, isTrue);
      final redoSuccess = coordinator.redo();
      expect(redoSuccess, isTrue);

      final snapCRestored = coordinator.captureCurrentSnapshot('Estado C restaurado');
      expect(
        snapCRestored.isPhysicallyIdenticalTo(snapCOriginal),
        isTrue,
        reason: 'C_restaurado tras REDO debe coincidir exactamente con C_original',
      );
      expect(engine.state.circuit.compressor?.rpm, equals(3200.0));
    });

    test('TEST DE RAMIFICACIÓN LIMPIA (Sección 24): A -> B -> C -> UNDO -> D => REDO no disponible para C', () {
      // A -> B
      engine.setCompressorRpm(2000.0);
      // B -> C
      engine.setCompressorRpm(2500.0);

      expect(coordinator.canUndo, isTrue);
      // UNDO -> vuelve a B (2000 RPM)
      coordinator.undo();
      expect(engine.state.circuit.compressor?.rpm, equals(2000.0));
      expect(coordinator.canRedo, isTrue); // C está en el historial de redo

      // Acción nueva D: Cambiar temperatura ambiente a 35 °C (308.15 K)
      engine.setAmbientTemperature(308.15);

      // REGLA ESTRICTA 17: Redo debe eliminarse por completo
      expect(
        coordinator.canRedo,
        isFalse,
        reason: 'Al crear una nueva acción D tras un UNDO, la rama REDO de C debe ser eliminada',
      );
      expect(coordinator.redoCount, equals(0));
    });

    test('TEST DE REINICIO DE PRÁCTICA (Sección 25): Restablece solo la práctica activa', () {
      // Modificamos el montaje de taller añadiendo una tubería
      coordinator.updateWorkshopState(
        coordinator.workshopState.copyWith(
          connections: {
            const WorkshopPipeConnection(
              fromPortId: 'comp_out',
              toPortId: 'cond_in',
              label: 'Descarga',
            ),
          },
          currentStep: CommissioningStep.leakTest,
          leakTestPassed: true,
        ),
        actionDescription: 'Avanzar taller a prueba de fugas',
      );

      // Modificamos también un parámetro de máquina (2200 RPM)
      engine.setCompressorRpm(2200.0);

      // Ejecutamos REINICIAR PRÁCTICA
      coordinator.resetPractice();

      // El taller debe volver al paso 1 sin conexiones
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.assembly));
      expect(coordinator.workshopState.connections.isEmpty, isTrue);
      expect(coordinator.workshopState.leakTestPassed, isFalse);

      // La máquina mantiene sus 2200 RPM (la instalación base no se destruye)
      expect(engine.state.circuit.compressor?.rpm, equals(2200.0));
    });

    test('TEST DE REINICIO DE INSTALACIÓN (Sección 25): Restaura máquina y detiene simulación', () {
      // Arrancamos y modificamos máquina
      engine.start();
      engine.setCompressorRpm(3600.0);
      engine.setCondenserFouling(0.5); // Inyectamos avería

      for (int i = 0; i < 5; i++) {
        engine.step();
      }
      expect(engine.isRunning, isTrue);

      // Ejecutamos REINICIAR INSTALACIÓN
      coordinator.resetInstallation();

      // Debe quedar detenida, con circuito nominal y sin averías
      expect(engine.isRunning, isFalse);
      expect(engine.state.circuit.compressor?.rpm, equals(BasicCyclePreset.create().compressor?.rpm));
      expect(engine.state.circuit.condenser?.foulingFactor, equals(0.0));
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.assembly));
    });

    test('TEST DE REINICIO TOTAL (Sección 25): Limpia historial y PRESERVA progreso educativo', () {
      final tracker = ProgressTracker();
      tracker.markLessonCompleted('lesson_5', newMasteredConcepts: ['Superheat y Subcooling']);
      tracker.markWorkshopPracticeCompleted('practice_01');

      // Operamos la máquina y generamos historial
      engine.start();
      engine.setCompressorRpm(1800.0);
      engine.setValveOpening(60.0);
      expect(coordinator.canUndo, isTrue);

      // REINICIAR TODO
      coordinator.resetAll();

      // Comprobar estado global reiniciado
      expect(engine.isRunning, isFalse);
      expect(coordinator.canUndo, isFalse);
      expect(coordinator.canRedo, isFalse);
      expect(coordinator.undoCount, equals(0));

      // CRÍTICO: Progreso educativo NO debe ser eliminado
      expect(tracker.isLessonCompleted('lesson_5'), isTrue);
      expect(tracker.masteredConcepts.contains('Superheat y Subcooling'), isTrue);
      expect(tracker.completedWorkshopPractices.contains('practice_01'), isTrue);
    });

    test('TEST DE REANUDACIÓN TRAS UNDO (Sección 20): Simulación continúa integrando desde estado restaurado', () {
      // Arrancamos el circuito y dejamos estabilizar
      engine.start();
      for (int i = 0; i < 10; i++) {
        engine.step();
      }
      expect(engine.isRunning, isTrue);

      // Inyectamos una avería (fouling al 80%)
      engine.setCondenserFouling(0.8);
      for (int i = 0; i < 5; i++) {
        engine.step();
      }
      expect(engine.state.circuit.condenser?.foulingFactor, equals(0.8));

      // UNDO: Debe retirar la avería
      final success = coordinator.undo();
      expect(success, isTrue);
      expect(engine.state.circuit.condenser?.foulingFactor, equals(0.0));

      // La máquina DEBE continuar en marcha y seguir calculando físicamente
      expect(engine.isRunning, isTrue);
      engine.step();

      // Balances físicos válidos y ausencia de NaNs
      expect(engine.state.evaporatingPressurePa.isNaN, isFalse);
      expect(engine.state.condensingPressurePa.isNaN, isFalse);
      expect(engine.state.massFlowKgPerSec, greaterThan(0.0));
      expect(engine.state.coolingCapacityWatts, greaterThan(0.0));
    });

    test('TEST DE AISLAMIENTO DEL SNAPSHOT (Sección 12): No contiene objetos gráficos ni UI vivos', () {
      final snap = coordinator.captureCurrentSnapshot('Verificación de aislamiento');

      expect(snap.id.isNotEmpty, isTrue);
      expect(snap.timestamp, isNotNull);
      expect(snap.simulationState, isA<SimulationState>());
      expect(snap.workshopState, isA<WorkshopState>());

      // Verificar que el clone genera instancias independientes
      final clone = snap.clone();
      expect(identical(snap, clone), isFalse);
      expect(snap.isPhysicallyIdenticalTo(clone), isTrue);
    });

    test('TEST DEL TALLER CON UNDO/REDO (Sección 10): Conectar tubería y revertir', () {
      expect(coordinator.workshopState.connections.isEmpty, isTrue);

      const conn = WorkshopPipeConnection(
        fromPortId: 'comp_out',
        toPortId: 'cond_in',
        label: 'Descarga Compresor -> Condensador',
      );

      // Conectar tubería en taller
      coordinator.updateWorkshopState(
        coordinator.workshopState.copyWith(connections: {conn}),
        actionDescription: 'Conectar descarga a condensador',
      );
      expect(coordinator.workshopState.connections.length, equals(1));
      expect(coordinator.canUndo, isTrue);

      // UNDO: Tubería se retira
      coordinator.undo();
      expect(coordinator.workshopState.connections.isEmpty, isTrue);

      // REDO: Tubería se vuelve a colocar
      coordinator.redo();
      expect(coordinator.workshopState.connections.length, equals(1));
    });

    test('TEST DE INVARIANZA FÍSICA (Sección 26 & 33): Primer Principio y dt inalterado tras Undo/Redo', () {
      engine.start();
      // Integrar varios pasos de tiempo canónicos a dt = 0.05s
      for (int i = 0; i < 20; i++) {
        engine.step();
      }

      // Verificación del Primer Principio en estado nominal: Qc ≈ Qe + Wcomp
      final sA = engine.state;
      expect(sA.massFlowKgPerSec, greaterThan(0.005));
      final p1 = sA.coolingCapacityWatts + sA.compressorPowerWatts;
      expect(sA.heatingCapacityWatts, closeTo(p1, p1 * 0.12));

      // Perturbación del usuario: variar RPM
      engine.setCompressorRpm(3400.0);
      for (int i = 0; i < 10; i++) {
        engine.step();
      }

      // UNDO: Volver a 2900 RPM
      coordinator.undo();
      expect(engine.state.circuit.compressor?.rpm, equals(2900.0));

      // Continuar cálculo por varios pasos
      for (int i = 0; i < 15; i++) {
        engine.step();
      }

      final sAfterUndo = engine.state;
      // Demostrar que la conservación de la energía se mantiene
      final p2 = sAfterUndo.coolingCapacityWatts + sAfterUndo.compressorPowerWatts;
      expect(sAfterUndo.heatingCapacityWatts, closeTo(p2, p2 * 0.12));
      expect(SimulationEngine.physicsTimeStepSeconds, equals(0.05));
    });

    test('TEST DE PUESTA EN SERVICIO MULTI-ETAPA CON UNDO (Sección 10): Taller paso a paso', () {
      // 1. Conexión completa
      coordinator.updateWorkshopState(
        WorkshopState.fullyConnected(),
        actionDescription: 'Ciclo completo conectado',
      );
      expect(coordinator.workshopState.connections.length, equals(4));

      // 2. Pasar a prueba de fugas y verificar nitrógeno
      coordinator.updateWorkshopState(
        coordinator.workshopState.copyWith(
          currentStep: CommissioningStep.leakTest,
          leakTestPassed: true,
        ),
        actionDescription: 'Prueba de estanqueidad completada',
      );
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.leakTest));

      // 3. Pasar a vacío y completarlo
      coordinator.updateWorkshopState(
        coordinator.workshopState.copyWith(
          currentStep: CommissioningStep.vacuum,
          vacuumCompleted: true,
          vacuumMicrons: 280.0,
        ),
        actionDescription: 'Vacío completado',
      );
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.vacuum));

      // 4. Pasar a carga y completarla
      coordinator.updateWorkshopState(
        coordinator.workshopState.copyWith(
          currentStep: CommissioningStep.charging,
          chargingCompleted: true,
          chargedMassGrams: 250.0,
        ),
        actionDescription: 'Carga de gas completada',
      );
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.charging));

      // DESHACER paso 4 (Carga): vuelve a Vacío
      coordinator.undo();
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.vacuum));
      expect(coordinator.workshopState.chargingCompleted, isFalse);

      // DESHACER paso 3 (Vacío): vuelve a Prueba de Fugas
      coordinator.undo();
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.leakTest));
      expect(coordinator.workshopState.vacuumCompleted, isFalse);

      // DESHACER paso 2 (Prueba de fugas): vuelve a Montaje inicial
      coordinator.undo();
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.assembly));
      expect(coordinator.workshopState.leakTestPassed, isFalse);
      expect(coordinator.workshopState.connections.length, equals(4));

      // REHACER paso 2: vuelve a Prueba de Fugas
      coordinator.redo();
      expect(coordinator.workshopState.currentStep, equals(CommissioningStep.leakTest));
      expect(coordinator.workshopState.leakTestPassed, isTrue);
    });
  });
}
