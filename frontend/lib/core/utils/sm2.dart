enum Grade { again, hard, good, easy }

class SM2Result {
  final double ease;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;

  SM2Result({
    required this.ease,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReviewAt,
    required this.lastReviewedAt,
  });
}

SM2Result calculateNext({
  required double ease,
  required int intervalDays,
  required int repetitions,
  required Grade grade,
}) {
  final now = DateTime.now();

  switch (grade) {
    case Grade.again:
      return SM2Result(
        ease: (ease - 0.2).clamp(1.3, 3.0),
        intervalDays: 0,
        repetitions: 0,
        nextReviewAt: now.add(const Duration(minutes: 10)),
        lastReviewedAt: now,
      );
    case Grade.hard:
      intervalDays = intervalDays.clamp(1, 999999);
      ease = (ease - 0.15).clamp(1.3, 3.0);
    case Grade.good:
      intervalDays = intervalDays == 0 ? 1 : (intervalDays * ease).round();
      repetitions += 1;
    case Grade.easy:
      intervalDays = (intervalDays * ease * 1.3).round().clamp(1, 999999);
      ease = (ease + 0.1).clamp(1.3, 3.0);
      repetitions += 1;
  }

  return SM2Result(
    ease: ease,
    intervalDays: intervalDays,
    repetitions: repetitions,
    nextReviewAt: now.add(Duration(days: intervalDays)),
    lastReviewedAt: now,
  );
}
