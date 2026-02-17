import 'dart:math';

enum FSRSGrade { again, hard, good, easy }

// FSRS-4.5 default weights
const List<double> _w = [
  0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01,
  1.49, 0.14, 0.94, 2.18, 0.05, 0.34, 1.26, 0.29, 2.61,
];

class FSRSResult {
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final String state;
  final int grade;
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;

  const FSRSResult({
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    required this.state,
    required this.grade,
    required this.nextReviewAt,
    required this.lastReviewedAt,
  });
}

FSRSResult calculateFSRS({
  required double currentStability,
  required double currentDifficulty,
  required int reps,
  required int lapses,
  required String state,
  required FSRSGrade grade,
  double requestedRetention = 0.9,
}) {
  final now = DateTime.now();
  final g = grade.index + 1; // again=1, hard=2, good=3, easy=4

  double newStability;
  double newDifficulty;
  int newReps = reps;
  int newLapses = lapses;
  String newState;

  // Calculate new difficulty: D' = D - w[6] * (g - 3), clamped to [1, 10]
  newDifficulty = (currentDifficulty - _w[6] * (g - 3)).clamp(1.0, 10.0);

  if (state == 'new') {
    // Initial stability based on grade
    newStability = _w[g - 1]; // w[0] for again, w[1] for hard, etc.
    newDifficulty = (_w[4] - exp(_w[5] * (g - 1)) + 1).clamp(1.0, 10.0);

    if (g == 1) {
      // Again → learning
      newState = 'learning';
      newReps = 0;
    } else if (g == 2) {
      // Hard → learning
      newState = 'learning';
      newReps = 1;
    } else {
      // Good/Easy → review
      newState = 'review';
      newReps = 1;
    }
  } else {
    // Review/Learning/Relearning cards
    if (g == 1) {
      // Lapse (Again)
      newStability = _w[11] *
          pow(newDifficulty, -_w[12]) *
          (pow(currentStability + 1, _w[13]) - 1) *
          exp(_w[14]);
      newLapses = lapses + 1;
      newReps = 0;
      newState = 'relearning';
    } else {
      // Recall (Hard/Good/Easy)
      // Calculate retrievability
      final elapsedDays = currentStability > 0 ? currentStability : 1.0;
      final r = pow(1 + elapsedDays / (9 * currentStability.clamp(0.01, double.infinity)), -1.0);

      final hardPenalty = g == 2 ? _w[15] : 1.0;
      final easyBonus = g == 4 ? _w[16] : 1.0;

      newStability = currentStability *
          (exp(_w[8]) *
                  (11 - newDifficulty) *
                  pow(currentStability, -_w[9]) *
                  (exp(_w[10] * (1 - r)) - 1) *
                  hardPenalty *
                  easyBonus +
              1);
      newReps = reps + 1;
      newState = 'review';
    }
  }

  // Ensure stability is positive
  newStability = newStability.clamp(0.01, 36500.0);

  // Calculate interval: I = S * 9 * (1/R - 1)
  final interval = newStability * 9 * (1 / requestedRetention - 1);
  final clampedInterval = interval.round().clamp(1, 36500);

  final nextReviewAt = now.add(Duration(days: clampedInterval));

  return FSRSResult(
    stability: newStability,
    difficulty: newDifficulty,
    reps: newReps,
    lapses: newLapses,
    state: newState,
    grade: g,
    nextReviewAt: nextReviewAt,
    lastReviewedAt: now,
  );
}
