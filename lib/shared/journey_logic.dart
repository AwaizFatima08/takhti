import 'models/lesson.dart';
import 'models/progress.dart';

/// Device-local calendar date as "yyyy-MM-dd" (design Section 7: time zone rule).
String localDateOf(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "2026-10-10" → "Sat 10 Oct 2026".
String prettyLocalDate(String date) {
  final d = DateTime.tryParse(date);
  if (d == null) return date;
  return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';
}

String previousLocalDate(String date) {
  final d = DateTime.parse(date);
  return localDateOf(DateTime(d.year, d.month, d.day - 1));
}

enum LessonAvailability { done, today, locked }

/// What the Today card shows.
sealed class TodayState {
  const TodayState();
}

class LessonAvailable extends TodayState {
  const LessonAvailable(this.lesson, this.progress);
  final Lesson lesson;
  final Progress progress;
}

/// Action committed, reflection not done yet.
class ReflectionWaiting extends TodayState {
  const ReflectionWaiting(this.lesson, this.progress);
  final Lesson lesson;
  final Progress progress;
}

/// A lesson was completed today; the next one unlocks tomorrow.
class DoneForToday extends TodayState {
  const DoneForToday(this.lesson, this.progress);
  final Lesson lesson;
  final Progress progress;
}

class PilotFinished extends TodayState {
  const PilotFinished(this.lastLesson, this.lastProgress);
  final Lesson lastLesson;
  final Progress lastProgress;
}

class NoLessons extends TodayState {
  const NoLessons();
}

/// Rules from design Section 7: lessons go in order; lesson N+1 opens at
/// local midnight after the day lesson N was completed.
class Journey {
  Journey(List<Lesson> lessons, this.progress, this.today)
      : lessons = [...lessons]..sort((a, b) => a.order.compareTo(b.order));

  final List<Lesson> lessons;
  final Map<String, Progress> progress;
  final String today;

  Progress progressOf(Lesson l) => progress[l.id] ?? Progress.empty(l.id);

  LessonAvailability availabilityOf(Lesson lesson) {
    final i = lessons.indexOf(lesson);
    if (progressOf(lesson).isComplete) return LessonAvailability.done;
    if (i == 0) return LessonAvailability.today;
    final prev = progressOf(lessons[i - 1]);
    if (!prev.isComplete) return LessonAvailability.locked;
    final doneOn = prev.completedLocalDate;
    if (doneOn != null && doneOn.compareTo(today) >= 0) {
      return LessonAvailability.locked; // unlocks tomorrow
    }
    return LessonAvailability.today;
  }

  TodayState get todayState {
    if (lessons.isEmpty) return const NoLessons();
    for (var i = 0; i < lessons.length; i++) {
      final l = lessons[i];
      final p = progressOf(l);
      if (p.isComplete) continue;
      if (availabilityOf(l) == LessonAvailability.locked) {
        return DoneForToday(lessons[i - 1], progressOf(lessons[i - 1]));
      }
      if (p.actionCommittedAt != null && p.reflectionDoneAt == null) {
        return ReflectionWaiting(l, p);
      }
      return LessonAvailable(l, p);
    }
    final last = lessons.last;
    final lastP = progressOf(last);
    if (lastP.completedLocalDate == today) return DoneForToday(last, lastP);
    return PilotFinished(last, lastP);
  }

  int get completedCount => lessons.where((l) => progressOf(l).isComplete).length;
}

/// Streak after completing a lesson today (design Section 7).
({int current, int longest}) streakAfterCompletion({
  required String today,
  required String? lastCompletedLocalDate,
  required int currentStreak,
  required int longestStreak,
}) {
  final int current;
  if (lastCompletedLocalDate == today) {
    current = currentStreak < 1 ? 1 : currentStreak;
  } else if (lastCompletedLocalDate == previousLocalDate(today)) {
    current = currentStreak + 1;
  } else {
    current = 1;
  }
  return (current: current, longest: current > longestStreak ? current : longestStreak);
}

/// Streak to show: a stored streak is broken once a whole local day passed
/// without a completed lesson.
int visibleStreak({
  required String today,
  required String? lastCompletedLocalDate,
  required int storedStreak,
}) {
  if (lastCompletedLocalDate == null) return 0;
  if (lastCompletedLocalDate == today ||
      lastCompletedLocalDate == previousLocalDate(today)) {
    return storedStreak;
  }
  return 0;
}
