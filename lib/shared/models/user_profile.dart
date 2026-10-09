import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}` document.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.reminderLessonTime,
    this.reminderReflectionTime,
    this.remindersEnabled = false,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedLocalDate,
    this.lessonsCompleted = 0,
  });

  final String uid;
  final String displayName;
  final String? email;

  /// "HH:mm"; null until the reminder screen has been completed once.
  final String? reminderLessonTime;
  final String? reminderReflectionTime;
  final bool remindersEnabled;
  final int currentStreak;
  final int longestStreak;
  final String? lastCompletedLocalDate;
  final int lessonsCompleted;

  bool get remindersChosen => reminderLessonTime != null;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      displayName: m['displayName'] as String? ?? '',
      email: m['email'] as String?,
      reminderLessonTime: m['reminderLessonTime'] as String?,
      reminderReflectionTime: m['reminderReflectionTime'] as String?,
      remindersEnabled: m['remindersEnabled'] as bool? ?? false,
      currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (m['longestStreak'] as num?)?.toInt() ?? 0,
      lastCompletedLocalDate: m['lastCompletedLocalDate'] as String?,
      lessonsCompleted: (m['lessonsCompleted'] as num?)?.toInt() ?? 0,
    );
  }
}
