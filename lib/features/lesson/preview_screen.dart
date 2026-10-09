import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/common.dart';
import 'lesson_flow_screen.dart';
import 'lesson_repository.dart';

/// D3 — Lesson 1's key idea before sign-in, to show value before asking for an account.
class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lessons = ref.watch(lessonsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson 1 preview')),
      body: SafeArea(
        child: lessons.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const MessageView(icon: Icons.cloud_off, title: 'Could not load the preview'),
          data: (list) {
            if (list.isEmpty) return const MessageView(icon: Icons.inbox, title: 'No lessons yet');
            final l = list.first;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(l.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('From: ${l.sourceVideoTitle} — Takhti', style: theme.textTheme.bodySmall),
                const SizedBox(height: 20),
                KeyIdeaList(points: l.keyIdea),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Next in the lesson: a short clip from Takhti, one action for your day, '
                      'and an evening reflection. Create a free account to keep your progress.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => context.go('/sign-in/create'), child: const Text('Create account')),
                TextButton(onPressed: () => context.go('/sign-in'), child: const Text('I already have an account')),
              ],
            );
          },
        ),
      ),
    );
  }
}
