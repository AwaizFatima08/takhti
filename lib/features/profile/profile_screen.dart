import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_repository.dart';
import '../auth/validators.dart';
import '../home/splash_screen.dart';
import '../reminders/notification_service.dart';
import 'feedback_dialog.dart';
import 'user_repository.dart';

/// S16 — profile and settings, including in-app account deletion (Play requirement).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final user = ref.watch(authUserProvider).value;
    final auth = ref.read(authRepositoryProvider);
    final verified = user?.emailVerified ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(profile?.displayName ?? ''),
            subtitle: const Text('Name'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editName(context, ref, profile?.displayName ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(user?.email ?? ''),
            subtitle: verified ? const Text('Email') : const Text('Email not verified'),
            trailing: verified
                ? null
                : TextButton(
                    onPressed: () async {
                      try {
                        await auth.resendVerification();
                        if (context.mounted) showSnack(context, 'Verification email sent');
                      } catch (e) {
                        if (context.mounted) showSnack(context, authMessage(e));
                      }
                    },
                    child: const Text('Resend'),
                  ),
            onTap: verified ? null : auth.reloadUser,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Reminders'),
            subtitle: Text(profile?.remindersEnabled == true
                ? 'Lesson ${profile!.reminderLessonTime} · Reflection ${profile.reminderReflectionTime}'
                : 'Off'),
            onTap: () => context.push('/settings/reminders'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Takhti'),
            onTap: () => _about(context),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: const Text('Give pilot feedback'),
            onTap: () => showFeedbackDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openLink(context, Uri.parse(kPrivacyUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openLink(context, Uri.parse(kTermsUrl)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => auth.signOut(),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
            title: Text('Delete account', style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _deleteAccount(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text('Takhti Grow · pilot build $kAppBuild', style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final error = validateName(controller.text);
          return AlertDialog(
            title: const Text('Your name'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(errorText: error),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                style: kDialogButtonStyle,
                onPressed: error == null ? () => Navigator.pop(context, controller.text) : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    final uid = ref.read(uidProvider);
    if (name == null || uid == null) return;
    try {
      await ref.read(userRepositoryProvider).updateName(uid, name);
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not save. Check your internet connection.');
    }
  }

  void _about(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: TakhtiLogo(size: 64)),
              const SizedBox(height: 16),
              Text('About Takhti', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Takhti is a science channel in Urdu hosted by Adeel Imtiaz — science communicator, '
                'TEDx speaker and author of NEURO-OS Industrial. Takhti Grow turns its neuroscience '
                'videos into one small daily lesson.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text('App by HomiLabs Solutions SMC Pvt Ltd. Content © Takhti Online, used with permission.',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => openLink(context, Uri.parse(kChannelUrl)),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Takhti on YouTube'),
              ),
              const SizedBox(height: 20),
              Text(kDisclaimer, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes:\n'
          '• your profile (name, email, reminder times)\n'
          '• your lesson progress and streak\n'
          '• all your reflections\n'
          '• any feedback you sent\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: kDialogButtonStyle.copyWith(
              backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final auth = ref.read(authRepositoryProvider);
    String? password;
    if (!auth.usesGoogle) {
      password = await _askPassword(context);
      if (password == null) return;
    }
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Deleting your account…')),
        ])),
      ),
    );
    final nav = Navigator.of(context, rootNavigator: true);
    var dialogOpen = true;
    void closeDialog() {
      if (dialogOpen) {
        dialogOpen = false;
        nav.pop();
      }
    }

    final uid = ref.read(uidProvider);
    final busy = ref.read(authBusyProvider.notifier)..set(true);
    try {
      await auth.reauthenticate(password: password);
      if (uid != null) await ref.read(userRepositoryProvider).deleteAllUserData(uid);
      await ref.read(notificationServiceProvider).cancelAll();
      await ref.read(sharedPrefsProvider).clear();
      ref.invalidate(onboardingSeenProvider);
      // Close the dialog before the auth user goes: the router then replaces
      // the whole stack with onboarding (design 5.2: back to S1).
      closeDialog();
      await auth.deleteAuthUser();
    } on AuthCancelled {
      closeDialog();
    } catch (e) {
      closeDialog();
      if (context.mounted) {
        showSnack(
          context,
          e is AuthFailure ? e.message : 'Could not delete the account. Check your internet connection and try again.',
        );
      }
    } finally {
      busy.set(false);
    }
  }

  Future<String?> _askPassword(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm your password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: kDialogButtonStyle,
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}
