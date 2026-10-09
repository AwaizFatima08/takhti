import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../auth/auth_repository.dart';
import '../profile/user_repository.dart';

/// S0 — shown only while the auth state / user doc loads.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TakhtiLogo(size: 96),
                const SizedBox(height: 20),
                Text('Takhti Grow', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('by HomiLabs × Takhti', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 32),
                if (profile.hasError) ...[
                  const Text(
                    'We could not load your account. Check your internet connection.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    child: const Text('Sign out'),
                  ),
                ] else
                  const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder mark until Takhti's logo is confirmed (D10): a sprouting
/// "takhti" (writing board) — a rounded board with a leaf.
class TakhtiLogo extends StatelessWidget {
  const TakhtiLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(size * 0.26)),
          child: Icon(Icons.spa_rounded, color: Colors.white, size: size * 0.6),
        ),
      );
}
