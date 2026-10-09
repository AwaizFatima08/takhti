import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/journey_logic.dart';
import '../../shared/models/lesson.dart';
import '../../shared/models/progress.dart';
import '../../shared/models/reflection.dart';
import '../../shared/models/user_profile.dart';
import '../profile/user_repository.dart';
import 'lesson_repository.dart';

final progressProvider = StreamProvider<Map<String, Progress>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const {});
  return ref
      .watch(firestoreProvider)
      .collection('users/$uid/progress')
      .snapshots()
      .map((s) => {for (final d in s.docs) d.id: Progress.fromMap(d.id, d.data())});
});

final journeyProvider = Provider<Journey?>((ref) {
  final lessons = ref.watch(lessonsProvider).value;
  final progress = ref.watch(progressProvider).value;
  if (lessons == null || progress == null) return null;
  return Journey(lessons, progress, ref.watch(todayProvider));
});

final progressRepositoryProvider =
    Provider<ProgressRepository>((ref) => ProgressRepository(ref.watch(firestoreProvider)));

/// Writes go to the local cache first and sync later, so they are not awaited
/// (an offline commit only completes once the server has it).
void _fireAndForget(Future<void> f) {
  unawaited(f.catchError((Object e, StackTrace s) {
    FirebaseCrashlytics.instance.recordError(e, s, reason: 'firestore write');
  }));
}

class ProgressRepository {
  ProgressRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _progress(String uid, String lessonId) =>
      _db.doc('users/$uid/progress/$lessonId');

  void markStep(String uid, String lessonId, LessonStep step) {
    final now = Timestamp.now();
    _fireAndForget(_progress(uid, lessonId).set({
      if (step == LessonStep.keyIdea) 'startedAt': now,
      stepField(step): now,
    }, SetOptions(merge: true)));
  }

  /// Saves the evening reflection and completes the lesson (design Section 7:
  /// complete = key idea + watch + do + reflect; quiz optional).
  void completeWithReflection({
    required String uid,
    required Lesson lesson,
    required ActionDone actionDone,
    required String note,
    required UserProfile profile,
    required String today,
  }) {
    final now = Timestamp.now();
    final streak = streakAfterCompletion(
      today: today,
      lastCompletedLocalDate: profile.lastCompletedLocalDate,
      currentStreak: profile.currentStreak,
      longestStreak: profile.longestStreak,
    );
    final batch = _db.batch()
      ..set(
        _db.doc('users/$uid/reflections/${lesson.id}'),
        Reflection(
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          question: lesson.reflectionQuestion,
          actionDone: actionDone,
          note: note.trim(),
          localDate: today,
        ).toMap(),
      )
      ..set(
        _progress(uid, lesson.id),
        {
          'reflectionDoneAt': now,
          'completedAt': now,
          'completedLocalDate': today,
        },
        SetOptions(merge: true),
      )
      ..update(_db.doc('users/$uid'), {
        'currentStreak': streak.current,
        'longestStreak': streak.longest,
        'lastCompletedLocalDate': today,
        'lessonsCompleted': FieldValue.increment(1),
      });
    _fireAndForget(batch.commit());
  }

  void saveQuiz(String uid, String lessonId, List<int> answers, int score) {
    _fireAndForget(_progress(uid, lessonId).set({
      'quizDoneAt': Timestamp.now(),
      'quizAnswers': answers,
      'quizScore': score,
    }, SetOptions(merge: true)));
  }
}

/// Profile of the signed-in user, re-exported for lesson screens.
final currentProfileProvider = Provider<UserProfile?>(
  (ref) => ref.watch(userProfileProvider).value,
);
