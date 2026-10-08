import 'package:flutter/foundation.dart';
import '../simulation/engine/simulation_engine.dart';
import '../simulation/engine/simulation_state.dart';
import 'app_snapshot.dart';
import 'history_manager.dart';
import 'workshop_state.dart';

/// Coordinador centralizado de sesión de FrigoLab.
/// Conecta el motor físico de simulación (SimulationEngine), el estado del taller (WorkshopState)
/// y el gestor de historial de operaciones (HistoryManager).
/// Proporciona operaciones deterministas de Deshacer, Rehacer y 3 niveles de Reinicio.
class SessionCoordinator extends ChangeNotifier {
  final SimulationEngine engine;
  final HistoryManager historyManager;

  WorkshopState _workshopState = WorkshopState.initial();

  SessionCoordinator({
    required this.engine,
    HistoryManager? historyManager,
  }) : historyManager = historyManager ?? HistoryManager() {
    engine.addListener(_onEngineChanged);

    // Conectar el callback de acciones del usuario de SimulationEngine
    engine.onUserAction = (description) {
      _recordCurrentSnapshot(description, UserActionCategory.simulation);
    };

    // Guardar snapshot inicial de la sesión
    final initialSnap = captureCurrentSnapshot('Inicio de sesión');
    this.historyManager.setInitialSessionSnapshot(initialSnap);
    this.historyManager.setPracticeInitialSnapshot(initialSnap);
  }

  WorkshopState get workshopState => _workshopState;
  SimulationState get simulationState => engine.state;
  bool get canUndo => historyManager.canUndo;
  bool get canRedo => historyManager.canRedo;
  int get undoCount => historyManager.undoCount;
  int get redoCount => historyManager.redoCount;
  String? get nextUndoDescription => historyManager.nextUndoDescription;
  String? get nextRedoDescription => historyManager.nextRedoDescription;

  void _onEngineChanged() {
    notifyListeners();
  }

  /// Captura un AppSnapshot del estado actual libre de dependencias visuales o UI
  AppSnapshot captureCurrentSnapshot(String description,
      [UserActionCategory category = UserActionCategory.system]) {
    return AppSnapshot(
      id: '${DateTime.now().microsecondsSinceEpoch}_${historyManager.undoCount}',
      timestamp: DateTime.now(),
      actionDescription: description,
      category: category,
      simulationState: engine.state.copyWith(),
      workshopState: _workshopState.copyWith(),
      activeExperiment: engine.activeExperiment?.copyWith(),
    );
  }

  /// Registra una acción de usuario capturando el snapshot previo en la pila de Undo
  void _recordCurrentSnapshot(String description, UserActionCategory category) {
    final snapshot = captureCurrentSnapshot(description, category);
    historyManager.recordSnapshot(snapshot);
  }

  /// Ejecuta una acción discreta explícita del usuario registrando el punto de retorno previo
  void executeUserAction({
    required String description,
    required UserActionCategory category,
    required VoidCallback action,
  }) {
    final snapshot = captureCurrentSnapshot(description, category);
    historyManager.recordSnapshot(snapshot);
    action();
    notifyListeners();
  }

  /// Actualiza el estado del taller registrando la acción en el historial
  void updateWorkshopState(WorkshopState newState, {required String actionDescription}) {
    executeUserAction(
      description: actionDescription,
      category: UserActionCategory.workshop,
      action: () {
        _workshopState = newState;
      },
    );
  }

  /// DESHACER (Undo)
  /// Restaura el estado previo al último cambio del usuario.
  /// La simulación continúa integrando si el estado restaurado estaba en marcha.
  bool undo() {
    if (!canUndo) return false;

    final currentSnapshot = captureCurrentSnapshot(
      'Estado antes de deshacer',
      UserActionCategory.system,
    );
    final targetSnapshot = historyManager.undo(currentSnapshot);

    if (targetSnapshot != null) {
      _applySnapshot(targetSnapshot);
      return true;
    }
    return false;
  }

  /// REHACER (Redo)
  /// Recupera el estado deshecho.
  bool redo() {
    if (!canRedo) return false;

    final currentSnapshot = captureCurrentSnapshot(
      'Estado antes de rehacer',
      UserActionCategory.system,
    );
    final targetSnapshot = historyManager.redo(currentSnapshot);

    if (targetSnapshot != null) {
      _applySnapshot(targetSnapshot);
      return true;
    }
    return false;
  }

  /// REINICIAR PRÁCTICA
  /// Restablece únicamente la práctica activa (del taller o del simulador) a su estado inicial.
  /// No destruye la instalación base ni el historial de undo no relacionado.
  void resetPractice() {
    executeUserAction(
      description: 'Reiniciar práctica actual',
      category: UserActionCategory.experiment,
      action: () {
        // Restablecer taller a paso 1 de montaje
        _workshopState = WorkshopState.initial();

        // Si hay un experimento educativo activo en el motor, restaurar línea base
        final exp = engine.activeExperiment;
        if (exp != null) {
          engine.startExperiment(exp);
        }
      },
    );
  }

  /// REINICIAR INSTALACIÓN
  /// Devuelve la instalación completa a su estado inicial:
  /// 1. Detiene la simulación física si estaba corriendo.
  /// 2. Restablece el circuito predeterminado (BasicCyclePreset).
  /// 3. Restablece componentes, actuadores a valores nominales, sin averías y presiones igualadas.
  /// 4. Asienta el taller y la instrumentación.
  void resetInstallation() {
    executeUserAction(
      description: 'Reiniciar instalación frigorífica',
      category: UserActionCategory.system,
      action: () {
        engine.pause();
        engine.reset();
        _workshopState = WorkshopState.initial();
      },
    );
  }

  /// REINICIAR TODO
  /// Restaura el estado inicial global de FrigoLab:
  /// 1. Detiene y reinicia la instalación.
  /// 2. Reinicia taller y cancela prácticas activas.
  /// 3. Vacía las pilas de Undo y Redo.
  /// REGLA ESTRICTA 13: NO borra el progreso educativo permanente guardado en ProgressTracker.
  void resetAll() {
    engine.pause();
    engine.reset();
    _workshopState = WorkshopState.initial();
    historyManager.clearHistory();

    // Reestablece el snapshot base
    final freshSnap = captureCurrentSnapshot('Reinicio total');
    historyManager.setInitialSessionSnapshot(freshSnap);
    historyManager.setPracticeInitialSnapshot(freshSnap);
    notifyListeners();
  }

  void _applySnapshot(AppSnapshot snapshot) {
    _workshopState = snapshot.workshopState;
    engine.restoreState(
      snapshot.simulationState,
      activeExperiment: snapshot.activeExperiment,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    engine.removeListener(_onEngineChanged);
    super.dispose();
  }
}
