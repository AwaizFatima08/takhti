import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takhti_grow/shared/journey_logic.dart';
import 'package:takhti_grow/shared/models/lesson.dart';
import 'package:takhti_grow/shared/models/progress.dart';

Lesson _lesson(int order) => Lesson(
      id: 'l$order',
      order: order,
      title: 'Lesson $order',
      sourceVideoTitle: '',
      youtubeId: 'x',
      clipStartSec: 0,
      clipEndSec: 10,
      keyIdea: const ['a', 'b', 'c'],
      action: 'act',
      reflectionQuestion: 'q',
      quiz: const [],
    );

Progress _done(String id, String date) => Progress.fromMap(id, {
      'keyIdeaReadAt': Timestamp.now(),
      'actionCommittedAt': Timestamp.now(),
      'reflectionDoneAt': Timestamp.now(),
      'completedAt': Timestamp.now(),
      'completedLocalDate': date,
    });

void main() {
  final lessons = [_lesson(3), _lesson(1), _lesson(2), _lesson(4)];

  group('dates', () {
    test('previousLocalDate crosses month and year', () {
      expect(previousLocalDate('2026-11-01'), '2026-10-31');
      expect(previousLocalDate('2027-01-01'), '2026-12-31');
      expect(previousLocalDate('2028-03-01'), '2028-02-29');
    });

    test('prettyLocalDate', () {
      expect(prettyLocalDate('2026-10-10'), 'Sat 10 Oct 2026');
    });
  });

  group('unlock rules', () {
    test('first lesson is available, others locked', () {
      final j = Journey(lessons, {}, '2026-10-10');
      expect(j.lessons.map((l) => l.order), [1, 2, 3, 4]);
      expect(j.availabilityOf(j.lessons[0]), LessonAvailability.today);
      expect(j.availabilityOf(j.lessons[1]), LessonAvailability.locked);
      expect(j.todayState, isA<LessonAvailable>());
    });

    test('next lesson stays locked on the completion day, opens the next day', () {
      final p = {'l1': _done('l1', '2026-10-10')};
      final sameDay = Journey(lessons, p, '2026-10-10');
      expect(sameDay.availabilityOf(sameDay.lessons[1]), LessonAvailability.locked);
      expect(sameDay.todayState, isA<DoneForToday>());

      final nextDay = Journey(lessons, p, '2026-10-11');
      expect(nextDay.availabilityOf(nextDay.lessons[1]), LessonAvailability.today);
      final state = nextDay.todayState as LessonAvailable;
      expect(state.lesson.id, 'l2');
    });

    test('committed action without reflection shows reflection waiting', () {
      final p = {
        'l1': Progress.fromMap('l1', {'keyIdeaReadAt': Timestamp.now(), 'actionCommittedAt': Timestamp.now()}),
      };
      final j = Journey(lessons, p, '2026-10-10');
      expect(j.todayState, isA<ReflectionWaiting>());
      expect(j.progressOf(j.lessons[0]).nextRequiredStep, LessonStep.reflect);
    });

    test('skipped clip still lets the user continue to the action', () {
      final p = Progress.fromMap('l1', {'keyIdeaReadAt': Timestamp.now()});
      expect(p.nextRequiredStep, LessonStep.watch);
    });

    test('pilot finished after all four, done-for-today on the last day', () {
      final p = {
        'l1': _done('l1', '2026-10-10'),
        'l2': _done('l2', '2026-10-11'),
        'l3': _done('l3', '2026-10-12'),
        'l4': _done('l4', '2026-10-13'),
      };
      expect(Journey(lessons, p, '2026-10-13').todayState, isA<DoneForToday>());
      expect(Journey(lessons, p, '2026-10-14').todayState, isA<PilotFinished>());
      expect(Journey(lessons, p, '2026-10-14').completedCount, 4);
    });

    test('changing the phone date backwards keeps the next lesson locked', () {
      final p = {'l1': _done('l1', '2026-10-10')};
      final j = Journey(lessons, p, '2026-10-09');
      expect(j.availabilityOf(j.lessons[1]), LessonAvailability.locked);
    });
  });

  group('streak', () {
    test('first completion starts at 1', () {
      final s = streakAfterCompletion(today: '2026-10-10', lastCompletedLocalDate: null, currentStreak: 0, longestStreak: 0);
      expect(s, (current: 1, longest: 1));
    });

    test('consecutive day adds one; gap resets to 1', () {
      expect(
        streakAfterCompletion(today: '2026-10-11', lastCompletedLocalDate: '2026-10-10', currentStreak: 3, longestStreak: 3),
        (current: 4, longest: 4),
      );
      expect(
        streakAfterCompletion(today: '2026-10-13', lastCompletedLocalDate: '2026-10-10', currentStreak: 3, longestStreak: 5),
        (current: 1, longest: 5),
      );
    });

    test('visible streak drops to 0 after a whole missed day', () {
      expect(visibleStreak(today: '2026-10-11', lastCompletedLocalDate: '2026-10-10', storedStreak: 2), 2);
      expect(visibleStreak(today: '2026-10-12', lastCompletedLocalDate: '2026-10-10', storedStreak: 2), 0);
      expect(visibleStreak(today: '2026-10-12', lastCompletedLocalDate: null, storedStreak: 0), 0);
    });
  });
}
