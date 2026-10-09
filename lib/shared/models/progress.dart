import 'package:cloud_firestore/cloud_firestore.dart';

/// The five steps of the daily loop, in order.
enum LessonStep { keyIdea, watch, doAction, reflect, quiz }

/// `users/{uid}/progress/{lessonId}` document.
class Progress {
  const Progress({
    required this.lessonId,
    this.keyIdeaReadAt,
    this.clipWatchedAt,
    this.actionCommittedAt,
    this.reflectionDoneAt,
    this.quizDoneAt,
    this.completedAt,
    this.completedLocalDate,
    this.quizScore,
  });

  final String lessonId;
  final DateTime? keyIdeaReadAt;
  final DateTime? clipWatchedAt;
  final DateTime? actionCommittedAt;
  final DateTime? reflectionDoneAt;
  final DateTime? quizDoneAt;
  final DateTime? completedAt;
  final String? completedLocalDate;
  final int? quizScore;

  bool get isComplete => completedAt != null;

  bool isDone(LessonStep step) => switch (step) {
        LessonStep.keyIdea => keyIdeaReadAt != null,
        LessonStep.watch => clipWatchedAt != null,
        LessonStep.doAction => actionCommittedAt != null,
        LessonStep.reflect => reflectionDoneAt != null,
        LessonStep.quiz => quizDoneAt != null,
      };

  /// Where "Continue" should go; null once the lesson is complete.
  /// The clip may be skipped (design S9), so after the action is committed
  /// the next step is always the reflection.
  LessonStep? get nextRequiredStep {
    if (reflectionDoneAt != null) return null;
    if (actionCommittedAt != null) return LessonStep.reflect;
    if (keyIdeaReadAt == null) return LessonStep.keyIdea;
    if (clipWatchedAt == null) return LessonStep.watch;
    return LessonStep.doAction;
  }

  static DateTime? _ts(Object? v) => v is Timestamp ? v.toDate() : null;

  factory Progress.fromMap(String lessonId, Map<String, dynamic> m) => Progress(
        lessonId: lessonId,
        keyIdeaReadAt: _ts(m['keyIdeaReadAt']),
        clipWatchedAt: _ts(m['clipWatchedAt']),
        actionCommittedAt: _ts(m['actionCommittedAt']),
        reflectionDoneAt: _ts(m['reflectionDoneAt']),
        quizDoneAt: _ts(m['quizDoneAt']),
        completedAt: _ts(m['completedAt']),
        completedLocalDate: m['completedLocalDate'] as String?,
        quizScore: (m['quizScore'] as num?)?.toInt(),
      );

  static Progress empty(String lessonId) => Progress(lessonId: lessonId);
}

/// Field name in Firestore for each step's timestamp.
String stepField(LessonStep step) => switch (step) {
      LessonStep.keyIdea => 'keyIdeaReadAt',
      LessonStep.watch => 'clipWatchedAt',
      LessonStep.doAction => 'actionCommittedAt',
      LessonStep.reflect => 'reflectionDoneAt',
      LessonStep.quiz => 'quizDoneAt',
    };
