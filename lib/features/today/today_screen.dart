import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../shared/journey_logic.dart';
import '../../shared/models/lesson.dart';
import '../../shared/models/progress.dart';
import '../../shared/widgets/common.dart';
import '../lesson/lesson_repository.dart';
import '../lesson/progress_repository.dart';
import '../onboarding/onboarding_art.dart';
import '../profile/feedback_dialog.dart';
import '../profile/user_repository.dart';

/// S7 — greeting, streak and the card for today's step.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final journey = ref.watch(journeyProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final today = ref.watch(todayProvider);
    final theme = Theme.of(context);

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final firstName = (profile?.displayName ?? '').split(' ').first;
    final streak = visibleStreak(
      today: today,
      lastCompletedLocalDate: profile?.lastCompletedLocalDate,
      storedStreak: profile?.currentStreak ?? 0,
    );

    Widget body;
    if (journey == null) {
      body = lessonsAsync.hasError
          ? MessageView(
              icon: Icons.cloud_off,
              title: 'Could not load lessons',
              action: FilledButton(
                onPressed: () => ref.invalidate(lessonsProvider),
                child: const Text('Try again'),
              ),
            )
          : const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    } else {
      body = _TodayCard(journey: journey);
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(todayProvider.notifier).refresh();
            ref.invalidate(lessonsProvider);
          },
          child: ListView(
            children: [
              PageBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            firstName.isEmpty ? greeting : '$greeting, $firstName',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _StreakChip(streak: streak),
                      ],
                    ),
                    const SizedBox(height: 20),
                    body,
                    const SizedBox(height: 16),
                    if (profile?.remindersEnabled == true && profile?.reminderReflectionTime != null)
                      Row(
                        children: [
                          Icon(Icons.nightlight_outlined, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Tonight: reflect at ${profile!.reminderReflectionTime}',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$streak day streak',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text('$streak', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.journey});
  final Journey journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = journey.todayState;
    final total = journey.lessons.length;

    String header(Lesson l) => 'LESSON ${journey.lessons.indexOf(l) + 1} OF $total · PILOT';

    final List<Widget> children;
    switch (state) {
      case NoLessons():
        children = [const Text('No lessons yet. Please check back soon.')];
      case LessonAvailable(:final lesson, :final progress):
        final next = progress.nextRequiredStep ?? LessonStep.keyIdea;
        final started = progress.keyIdeaReadAt != null;
        children = [
          _Eyebrow(header(lesson)),
          Text(lesson.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _StepChecklist(progress: progress),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.push('/lesson/${lesson.id}?step=${next.name}'),
            child: Text(started ? 'Continue: ${_stepLabel(next)}' : 'Start today\'s lesson'),
          ),
        ];
      case ReflectionWaiting(:final lesson, :final progress):
        children = [
          _Eyebrow(header(lesson)),
          Text('How did it go?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Today\'s action: ${lesson.action}',
            style: theme.textTheme.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _StepChecklist(progress: progress),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.push('/lesson/${lesson.id}?step=reflect'),
            child: const Text('Reflect now'),
          ),
        ];
      case DoneForToday(:final lesson, :final progress):
        final last = journey.lessons.last == lesson;
        children = [
          _Eyebrow(header(lesson)),
          Row(children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Lesson complete', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            last
                ? 'That was the last pilot lesson. Come back tomorrow to share your feedback.'
                : 'Next lesson unlocks tomorrow.',
            style: theme.textTheme.bodyLarge,
          ),
          if (progress.quizDoneAt == null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/lesson/${lesson.id}?step=quiz'),
              child: const Text('Take the quick check'),
            ),
          ],
          if (last) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: () => showFeedbackDialog(context, ref), child: const Text('Give feedback')),
          ],
        ];
      case PilotFinished():
        children = [
          const _Eyebrow('PILOT COMPLETE'),
          Text('You\'ve finished the pilot.', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('More lessons are coming. Tell us what to improve.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => showFeedbackDialog(context, ref), child: const Text('Give feedback')),
        ];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

String _stepLabel(LessonStep s) => switch (s) {
      LessonStep.keyIdea => 'Read',
      LessonStep.watch => 'Watch',
      LessonStep.doAction => 'Do',
      LessonStep.reflect => 'Reflect',
      LessonStep.quiz => 'Check',
    };

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

class _StepChecklist extends StatelessWidget {
  const _StepChecklist({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = progress.nextRequiredStep;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (i, step) in LessonStep.values.indexed)
          Builder(builder: (context) {
            final done = progress.isDone(step);
            final current = step == next;
            final (icon, label) = loopSteps[i];
            return Semantics(
              label: '$label: ${done ? 'done' : (current ? 'next' : 'not started')}',
              excludeSemantics: true,
              child: Chip(
                avatar: Icon(done ? Icons.check : icon, size: 18, color: done || current ? scheme.primary : null),
                label: Text(label),
                side: BorderSide(color: current ? scheme.primary : scheme.outlineVariant),
                backgroundColor: done ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
              ),
            );
          }),
      ],
    );
  }
}
