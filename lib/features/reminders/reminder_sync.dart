import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_repository.dart';
import 'notification_service.dart';

/// Keeps the two local reminders in line with the user doc: re-schedules on
/// launch (time zone or times may have changed on another phone) and cancels
/// them when the user signs out.
final reminderSyncProvider = Provider<void>((ref) {
  String? lastKey;
  ref.listen(userProfileProvider, (_, next) {
    if (!next.hasValue) return;
    final p = next.value;
    final service = ref.read(notificationServiceProvider);
    final key = p == null
        ? 'off'
        : '${p.uid}|${p.remindersEnabled}|${p.reminderLessonTime}|${p.reminderReflectionTime}';
    if (key == lastKey) return;
    lastKey = key;
    final Future<void> job = p != null && p.remindersEnabled && p.reminderLessonTime != null
        ? service.scheduleDaily(
            lessonTime: p.reminderLessonTime!,
            reflectionTime: p.reminderReflectionTime ?? '21:00',
          )
        : service.cancelAll();
    job.catchError((Object e, StackTrace s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'reminder scheduling');
    });
  }, fireImmediately: true);
});
