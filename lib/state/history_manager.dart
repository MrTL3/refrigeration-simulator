import 'package:flutter/foundation.dart';
import 'app_snapshot.dart';

/// Gestor centralizado del historial de estados de FrigoLab (Pilas Undo/Redo y Snapshots).
/// Implementa la arquitectura de ramificación estricta:
/// Cualquier acción nueva tras un Undo vacía de inmediato la pila de Redo.
class HistoryManager extends ChangeNotifier {
  final int maxHistoryLength;
  final List<AppSnapshot> _undoStack = [];
  final List<AppSnapshot> _redoStack = [];
  AppSnapshot? _initialSessionSnapshot;
  AppSnapshot? _practiceInitialSnapshot;

  HistoryManager({this.maxHistoryLength = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  List<AppSnapshot> get undoStack => List.unmodifiable(_undoStack);
  List<AppSnapshot> get redoStack => List.unmodifiable(_redoStack);

  String? get nextUndoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.actionDescription : null;
  String? get nextRedoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.actionDescription : null;

  AppSnapshot? get initialSessionSnapshot => _initialSessionSnapshot;
  AppSnapshot? get practiceInitialSnapshot => _practiceInitialSnapshot;

  void setInitialSessionSnapshot(AppSnapshot snapshot) {
    _initialSessionSnapshot = snapshot.clone();
  }

  void setPracticeInitialSnapshot(AppSnapshot snapshot) {
    _practiceInitialSnapshot = snapshot.clone();
  }

  /// Registra una instantánea de estado anterior a una acción de usuario.
  /// REGLA ESTRICTA 17: Al registrar una nueva acción, se vacía completamente la pila de Redo.
  void recordSnapshot(AppSnapshot snapshot) {
    _undoStack.add(snapshot);
    if (_undoStack.length > maxHistoryLength) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    notifyListeners();
  }

  /// Deshace la última acción:
  /// Transfiere el estado actual a la pila de redo y devuelve el último snapshot de undo.
  AppSnapshot? undo(AppSnapshot currentSnapshot) {
    if (!canUndo) return null;
    final target = _undoStack.removeLast();
    _redoStack.add(currentSnapshot);
    notifyListeners();
    return target;
  }

  /// Rehace la última acción:
  /// Transfiere el estado actual a la pila de undo y devuelve el último snapshot de redo.
  AppSnapshot? redo(AppSnapshot currentSnapshot) {
    if (!canRedo) return null;
    final target = _redoStack.removeLast();
    _undoStack.add(currentSnapshot);
    notifyListeners();
    return target;
  }

  /// Limpia todo el historial de undo y redo sin afectar a los estados iniciales de referencia.
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
