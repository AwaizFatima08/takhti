import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/journey_logic.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

/// Overridden in main() with the instance loaded before runApp.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// Signed-in Firebase user (userChanges also fires after reload(), e.g. email verified).
final authUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).userChanges(),
);

final uidProvider = Provider<String?>((ref) => ref.watch(authUserProvider).value?.uid);

/// Today's device-local date; refreshed when the app returns to the foreground.
final todayProvider = NotifierProvider<TodayNotifier, String>(TodayNotifier.new);

class TodayNotifier extends Notifier<String> {
  @override
  String build() => localDateOf(DateTime.now());

  void refresh() {
    final now = localDateOf(DateTime.now());
    if (now != state) state = now;
  }
}

/// "Onboarding seen" flag, stored on the device only (design S1).
final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenNotifier, bool>(OnboardingSeenNotifier.new);

class OnboardingSeenNotifier extends Notifier<bool> {
  static const _key = 'onboardingSeen';

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> markSeen() async {
    state = true;
    await ref.read(sharedPrefsProvider).setBool(_key, true);
  }
}

/// True while email sign-up creates the user doc or account deletion removes
/// it, so the router does not treat the account as "signed in without a profile".
final authBusyProvider =
    NotifierProvider<AuthBusy, bool>(AuthBusy.new);

class AuthBusy extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

/// `appConfig/main`, read once per launch; null when unavailable (offline).
final appConfigProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final doc = await ref
        .watch(firestoreProvider)
        .doc('appConfig/main')
        .get()
        .timeout(const Duration(seconds: 6));
    return doc.data();
  } catch (_) {
    return null;
  }
});
