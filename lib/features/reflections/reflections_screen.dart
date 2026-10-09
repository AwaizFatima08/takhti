import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journey_logic.dart';
import '../../shared/widgets/common.dart';
import 'reflection_repository.dart';

/// S15 — the user's past reflections, newest first, read-only.
class ReflectionsScreen extends ConsumerWidget {
  const ReflectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(reflectionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reflections')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const MessageView(icon: Icons.cloud_off, title: 'Could not load reflections'),
        data: (list) => list.isEmpty
            ? const MessageView(
                icon: Icons.edit_note,
                title: 'Nothing here yet',
                body: 'Your reflections will appear here after your first evening check-in.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final r = list[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(prettyLocalDate(r.localDate), style: theme.textTheme.labelLarge),
                            ),
                            Chip(label: Text(r.actionDone.label), visualDensity: VisualDensity.compact),
                          ]),
                          if (r.lessonTitle != null)
                            Text(r.lessonTitle!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(r.question, style: theme.textTheme.bodySmall),
                          if (r.note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(r.note, style: theme.textTheme.bodyLarge),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
