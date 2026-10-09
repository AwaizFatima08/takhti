import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((_) => NotificationService.instance);

/// Two local daily reminders (design S6). Inexact scheduling, so no exact-alarm
/// permission or Play declaration is needed.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _lessonId = 1;
  static const _reflectionId = 2;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_takhti'),
      ),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Asks for the Android 13+ permission; true when notifications may be shown.
  Future<bool> requestPermission() async {
    await init();
    return await _android?.requestNotificationsPermission() ?? true;
  }

  Future<bool> areEnabled() async {
    await init();
    return await _android?.areNotificationsEnabled() ?? true;
  }

  Future<void> scheduleDaily({required String lessonTime, required String reflectionTime}) async {
    await init();
    await _plugin.cancelAll();
    await _schedule(
      _lessonId,
      lessonTime,
      'Your lesson is ready',
      'Two minutes for today\'s idea, clip and action.',
    );
    await _schedule(
      _reflectionId,
      reflectionTime,
      'How did today go?',
      'Take a moment to reflect on today\'s action.',
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> _schedule(int id, String hhmm, String title, String body) async {
    final t = parseTime(hhmm);
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: at,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily reminders',
          channelDescription: 'Lesson and evening reflection reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF1F6F6B),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

TimeOfDay parseTime(String hhmm) {
  final parts = hhmm.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
