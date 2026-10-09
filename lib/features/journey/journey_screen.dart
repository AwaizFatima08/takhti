import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/journey_logic.dart';
import '../../shared/widgets/common.dart';
import '../lesson/progress_repository.dart';

/// S14 — the pilot lessons with Done / Today / Locked chips.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(journeyProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your journey')),
      body: journey == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    'Pilot — ${journey.lessons.length} lessons · ${journey.completedCount} done',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                for (final (i, lesson) in journey.lessons.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Builder(builder: (context) {
                      final a = journey.availabilityOf(lesson);
                      final (chip, icon) = switch (a) {
                        LessonAvailability.done => ('Done', Icons.check_circle),
                        LessonAvailability.today => ('Today', Icons.wb_sunny_outlined),
                        LessonAvailability.locked => ('Locked', Icons.lock_outline),
                      };
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: a == LessonAvailability.locked
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primaryContainer,
                            child: Text('${i + 1}'),
                          ),
                          title: Text(lesson.title),
                          subtitle: a == LessonAvailability.locked &&
                                  i > 0 &&
                                  journey.progressOf(journey.lessons[i - 1]).isComplete
                              ? const Text('Unlocks tomorrow')
                              : null,
                          trailing: Semantics(
                            label: chip,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(icon, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(chip),
                            ]),
                          ),
                          onTap: switch (a) {
                            LessonAvailability.done => () => context.push('/review/${lesson.id}'),
                            LessonAvailability.today => () {
                                final next = journey.progressOf(lesson).nextRequiredStep;
                                context.push('/lesson/${lesson.id}?step=${next?.name ?? 'keyIdea'}');
                              },
                            LessonAvailability.locked => () =>
                                showSnack(context, 'One lesson a day — this one unlocks later.'),
                          },
                        ),
                      );
                    }),
                  ),
              ],
            ),
    );
  }
}
