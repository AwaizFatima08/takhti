import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../shared/widgets/common.dart';
import '../profile/user_repository.dart';
import 'notification_service.dart';

/// S6 — lesson and reflection reminder times (first run and from Profile).
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key, required this.firstRun});
  final bool firstRun;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  late TimeOfDay _lesson;
  late TimeOfDay _reflection;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final p = ref.read(userProfileProvider).value;
    _lesson = parseTime(p?.reminderLessonTime ?? '08:00');
    _reflection = parseTime(p?.reminderReflectionTime ?? '21:00');
    _enabled = widget.firstRun ? true : (p?.remindersEnabled ?? false);
  }

  Future<void> _pick(bool lesson) async {
    final picked = await showTimePicker(context: context, initialTime: lesson ? _lesson : _reflection);
    if (picked == null) return;
    setState(() => lesson ? _lesson = picked : _reflection = picked);
  }

  Future<void> _save({required bool allow}) async {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    var enabled = allow;
    if (allow) {
      try {
        enabled = await ref.read(notificationServiceProvider).requestPermission();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'notification permission');
        enabled = false;
      }
      if (!enabled && mounted) {
        showSnack(context, 'Notifications are off for Takhti Grow. You can allow them in Android settings.');
      }
    }
    try {
      await ref.read(userRepositoryProvider).saveReminders(
            uid,
            lessonTime: formatTime(_lesson),
            reflectionTime: formatTime(_reflection),
            enabled: enabled,
          );
    } catch (_) {
      if (mounted) showSnack(context, 'Could not save. Check your internet connection.');
      return;
    }
    // reminderSyncProvider schedules or cancels the notifications from the user doc.
    if (!widget.firstRun && mounted) {
      showSnack(context, enabled ? 'Reminders saved' : 'Reminders turned off');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.wb_sunny_outlined),
        title: const Text('Daily lesson'),
        trailing: Text(_lesson.format(context), style: theme.textTheme.titleMedium),
        onTap: () => _pick(true),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.nightlight_outlined),
        title: const Text('Evening reflection'),
        trailing: Text(_reflection.format(context), style: theme.textTheme.titleMedium),
        onTap: () => _pick(false),
      ),
    ];
    return Scaffold(
      appBar: widget.firstRun ? null : AppBar(title: const Text('Reminders')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            padding: EdgeInsets.fromLTRB(24, widget.firstRun ? 40 : 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('When should we remind you?',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                ...tiles,
                const SizedBox(height: 16),
                Text(
                  'We\'ll send two gentle reminders a day. You can change or turn them off any time in Profile.',
                  style: theme.textTheme.bodyLarge,
                ),
                if (!widget.firstRun)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminders on'),
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                const SizedBox(height: 28),
                if (widget.firstRun) ...[
                  BusyButton(label: 'Allow notifications', onPressed: () => _save(allow: true)),
                  TextButton(onPressed: () => _save(allow: false), child: const Text('Not now')),
                ] else
                  BusyButton(label: 'Save', onPressed: () => _save(allow: _enabled)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
