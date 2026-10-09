import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/consent_screen.dart';
import '../features/auth/create_account_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_shell.dart';
import '../features/home/splash_screen.dart';
import '../features/home/update_required_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/lesson/lesson_flow_screen.dart';
import '../features/lesson/lesson_review_screen.dart';
import '../features/lesson/preview_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/user_repository.dart';
import '../features/reflections/reflections_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/today/today_screen.dart';
import '../shared/models/progress.dart';
import 'config.dart';
import 'providers.dart';

/// Re-runs the router redirect whenever sign-in state, the user doc or
/// onboarding flag changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authUserProvider, (_, _) => notifyListeners());
    ref.listen(userProfileProvider, (_, _) => notifyListeners());
    ref.listen(onboardingSeenProvider, (_, _) => notifyListeners());
    ref.listen(authBusyProvider, (_, _) => notifyListeners());
    ref.listen(appConfigProvider, (_, _) => notifyListeners());
  }
}

const _signedOutPaths = {'/onboarding', '/sign-in', '/sign-in/create', '/sign-in/forgot', '/preview'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final minBuild = ref.read(appConfigProvider).value?['minSupportedBuild'];
      if (minBuild is num && minBuild > kAppBuild) {
        return path == '/update' ? null : '/update';
      }

      final auth = ref.read(authUserProvider);
      if (auth.isLoading && !auth.hasValue) return path == '/splash' ? null : '/splash';
      final user = auth.value;

      if (user == null) {
        if (_signedOutPaths.contains(path)) return null;
        return ref.read(onboardingSeenProvider) ? '/sign-in' : '/onboarding';
      }

      if (ref.read(authBusyProvider)) return null;

      final profileAsync = ref.read(userProfileProvider);
      if (!profileAsync.hasValue) return path == '/splash' ? null : '/splash';
      final profile = profileAsync.value;
      if (profile == null) return path == '/consent' ? null : '/consent';
      if (!profile.remindersChosen) return path == '/reminders' ? null : '/reminders';

      if (_signedOutPaths.contains(path) ||
          path == '/splash' ||
          path == '/consent' ||
          path == '/reminders') {
        return '/today';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/update', builder: (_, _) => const UpdateRequiredScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/preview', builder: (_, _) => const PreviewScreen()),
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const SignInScreen(),
        routes: [
          GoRoute(path: 'create', builder: (_, _) => const CreateAccountScreen()),
          GoRoute(path: 'forgot', builder: (_, _) => const ForgotPasswordScreen()),
        ],
      ),
      GoRoute(path: '/consent', builder: (_, _) => const ConsentScreen()),
      GoRoute(path: '/reminders', builder: (_, _) => const RemindersScreen(firstRun: true)),
      GoRoute(path: '/settings/reminders', builder: (_, _) => const RemindersScreen(firstRun: false)),
      GoRoute(
        path: '/lesson/:id',
        builder: (_, state) => LessonFlowScreen(
          lessonId: state.pathParameters['id']!,
          startStep: LessonStep.values.asNameMap()[state.uri.queryParameters['step']],
        ),
      ),
      GoRoute(
        path: '/review/:id',
        builder: (_, state) => LessonReviewScreen(lessonId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/today', builder: (_, _) => const TodayScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/journey', builder: (_, _) => const JourneyScreen())]),
          StatefulShellBranch(
            routes: [GoRoute(path: '/reflections', builder: (_, _) => const ReflectionsScreen())],
          ),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});
