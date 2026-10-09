import 'package:cloud_firestore/cloud_firestore.dart';

enum ActionDone {
  yes('Yes'),
  partly('Partly'),
  no('No');

  const ActionDone(this.label);
  final String label;
}

/// `users/{uid}/reflections/{lessonId}` document (one reflection per lesson).
class Reflection {
  const Reflection({
    required this.lessonId,
    required this.question,
    required this.actionDone,
    required this.note,
    required this.localDate,
    this.lessonTitle,
  });

  final String lessonId;
  final String question;
  final ActionDone actionDone;
  final String note;
  final String localDate;
  final String? lessonTitle;

  factory Reflection.fromMap(Map<String, dynamic> m) => Reflection(
        lessonId: m['lessonId'] as String,
        question: m['question'] as String? ?? '',
        actionDone: ActionDone.values.byName(m['actionDone'] as String? ?? 'no'),
        note: m['note'] as String? ?? '',
        localDate: m['localDate'] as String? ?? '',
        lessonTitle: m['lessonTitle'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'lessonId': lessonId,
        'lessonTitle': ?lessonTitle,
        'question': question,
        'actionDone': actionDone.name,
        'note': note,
        'localDate': localDate,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
