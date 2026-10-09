import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'features/reminders/reminder_sync.dart';
import 'firebase_options.dart';

/// Test builds only: `--dart-define=USE_EMULATOR=true` talks to the local
/// Firebase emulators (reach them from a USB phone with `adb reverse`).
const bool kUseEmulator = bool.fromEnvironment('USE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kUseEmulator) {
    // Real phone over adb reverse: keep 127.0.0.1 (no 10.0.2.2 mapping).
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8085, automaticHostMapping: false);
  }

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const TakhtiGrowApp(),
    ),
  );
}

class TakhtiGrowApp extends ConsumerStatefulWidget {
  const TakhtiGrowApp({super.key});

  @override
  ConsumerState<TakhtiGrowApp> createState() => _TakhtiGrowAppState();
}

class _TakhtiGrowAppState extends ConsumerState<TakhtiGrowApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(todayProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider);
    return MaterialApp.router(
      title: 'Takhti Grow',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
