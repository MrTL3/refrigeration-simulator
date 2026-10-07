import 'package:flutter/foundation.dart';

/// Modelo de progreso y expediente del técnico/alumno en FrigoLab.
class ProgressTracker extends ChangeNotifier {
  static final ProgressTracker _instance = ProgressTracker._internal();
  factory ProgressTracker() => _instance;
  ProgressTracker._internal();

  final Set<String> _completedLessonIds = {'lesson_0'};
  final Set<String> _masteredConcepts = {'Calor Sensible y Latente', 'Ciclo de Compresión de Vapor'};
  final Set<String> _completedWorkshopPractices = {};
  int _correctQuizCount = 0;
  int _totalQuizAttempts = 0;

  Set<String> get completedLessonIds => Set.unmodifiable(_completedLessonIds);
  Set<String> get masteredConcepts => Set.unmodifiable(_masteredConcepts);
  Set<String> get completedWorkshopPractices => Set.unmodifiable(_completedWorkshopPractices);
  int get correctQuizCount => _correctQuizCount;
  int get totalQuizAttempts => _totalQuizAttempts;

  double get syllabusCompletionPercent {
    return (_completedLessonIds.length / 11.0).clamp(0.0, 1.0);
  }

  bool isLessonCompleted(String lessonId) => _completedLessonIds.contains(lessonId);

  void markLessonCompleted(String lessonId, {List<String>? newMasteredConcepts}) {
    if (!_completedLessonIds.contains(lessonId)) {
      _completedLessonIds.add(lessonId);
      if (newMasteredConcepts != null) {
        _masteredConcepts.addAll(newMasteredConcepts);
      }
      notifyListeners();
    }
  }

  void recordQuizAnswer({required bool isCorrect}) {
    _totalQuizAttempts++;
    if (isCorrect) _correctQuizCount++;
    notifyListeners();
  }

  void markWorkshopPracticeCompleted(String practiceId) {
    if (!_completedWorkshopPractices.contains(practiceId)) {
      _completedWorkshopPractices.add(practiceId);
      notifyListeners();
    }
  }

  void resetProgress() {
    _completedLessonIds.clear();
    _completedLessonIds.add('lesson_0');
    _masteredConcepts.clear();
    _masteredConcepts.addAll(['Calor Sensible y Latente', 'Ciclo de Compresión de Vapor']);
    _completedWorkshopPractices.clear();
    _correctQuizCount = 0;
    _totalQuizAttempts = 0;
    notifyListeners();
  }
}
