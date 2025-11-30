import "reading_logic.dart";

/// UI status of a session.
/// Drives which screen is shown and whether the user
/// can interact with the current exercise.
sealed class SessionPhase {
  const SessionPhase();
}

/// Phase 1 for the title screen
class LoadingPhase extends SessionPhase {
  const LoadingPhase();
}

/// Phase 2 for the title screen
class TitlePhase extends SessionPhase {
  final List<Map<String, dynamic>> data;
  const TitlePhase({required this.data});
}

/// Phase for the selection screens
/// Selection manager is used
enum SelectionStep {categorySelection, exerciseSelection}

class SelectionPhase extends SessionPhase {
  final SelectionStep step;
  final SelectionManager manager;
  const SelectionPhase({required this.step, required this.manager});
}

/// Phase for the exercise screen
/// Exercise manager is shown
enum ExerciseStep {preparingAnswer, readyToSubmit, correctFeedback, incorrectFeedback}

class ExercisePhase extends SessionPhase {
  final ExerciseStep step;
  final ExerciseManager manager;
  const ExercisePhase({required this.step, required this.manager});
}

/// Phase for the result screen
class ResultPhase extends SessionPhase{
  final int score;
  final int maxScore;
  const ResultPhase({
    required this.score,
    required this.maxScore,
  });
}