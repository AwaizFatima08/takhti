import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';
import '../../app/providers.dart';
import '../../shared/journey_logic.dart';
import '../../shared/models/lesson.dart';
import '../../shared/models/progress.dart';
import '../../shared/models/reflection.dart';
import '../../shared/widgets/common.dart';
import 'lesson_repository.dart';
import 'progress_repository.dart';
import 'watch_step.dart';

/// S8–S13 — the five-step daily loop, full-screen above the tabs.
class LessonFlowScreen extends ConsumerStatefulWidget {
  const LessonFlowScreen({super.key, required this.lessonId, this.startStep});

  final String lessonId;
  final LessonStep? startStep;

  @override
  ConsumerState<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends ConsumerState<LessonFlowScreen> {
  late LessonStep _step = widget.startStep ?? LessonStep.keyIdea;
  bool _showComplete = false;

  String get _uid => ref.read(uidProvider)!;

  void _go(LessonStep step) => setState(() => _step = step);

  void _finishFlow() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(lessonByIdProvider(widget.lessonId));
    final journey = ref.watch(journeyProvider);
    if (lesson == null || journey == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ref.watch(lessonsProvider).isLoading
            ? const Center(child: CircularProgressIndicator())
            : const MessageView(icon: Icons.search_off, title: 'Lesson not found'),
      );
    }
    final progress = journey.progressOf(lesson);
    final availability = journey.availabilityOf(lesson);

    if (availability == LessonAvailability.locked) {
      return Scaffold(
        appBar: AppBar(),
        body: const MessageView(
          icon: Icons.lock_clock,
          title: 'This lesson unlocks tomorrow',
          body: 'One lesson a day builds the habit.',
        ),
      );
    }

    final Widget body;
    if (_showComplete) {
      body = _CompleteStep(lesson: lesson, journey: journey, onDone: _finishFlow);
    } else if (progress.isComplete && _step != LessonStep.quiz) {
      // Done lessons reopen read-only from Journey.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement('/review/${lesson.id}');
      });
      body = const SizedBox.shrink();
    } else {
      body = switch (_step) {
        LessonStep.keyIdea => _KeyIdeaStep(
            lesson: lesson,
            onNext: () {
              if (!progress.isDone(LessonStep.keyIdea)) {
                ref.read(progressRepositoryProvider).markStep(_uid, lesson.id, LessonStep.keyIdea);
              }
              _go(LessonStep.watch);
            },
          ),
        LessonStep.watch => WatchStep(
            lesson: lesson,
            onWatched: () {
              if (!progress.isDone(LessonStep.watch)) {
                ref.read(progressRepositoryProvider).markStep(_uid, lesson.id, LessonStep.watch);
              }
            },
            onNext: () => _go(progress.actionCommittedAt != null ? LessonStep.reflect : LessonStep.doAction),
          ),
        LessonStep.doAction => _DoStep(
            lesson: lesson,
            committed: progress.actionCommittedAt != null,
            onCommit: () {
              if (!progress.isDone(LessonStep.keyIdea)) {
                ref.read(progressRepositoryProvider).markStep(_uid, lesson.id, LessonStep.keyIdea);
              }
              ref.read(progressRepositoryProvider).markStep(_uid, lesson.id, LessonStep.doAction);
              showSnack(context, 'Saved. Come back this evening to reflect.');
              _finishFlow();
            },
            onReflectNow: () => _go(LessonStep.reflect),
          ),
        LessonStep.reflect => progress.actionCommittedAt == null
            ? _DoStep(
                lesson: lesson,
                committed: false,
                onCommit: () {
                  ref.read(progressRepositoryProvider).markStep(_uid, lesson.id, LessonStep.doAction);
                  _finishFlow();
                },
                onReflectNow: () {},
              )
            : _ReflectStep(
                lesson: lesson,
                onSave: (done, note) {
                  final profile = ref.read(currentProfileProvider);
                  if (profile == null) return;
                  ref.read(progressRepositoryProvider).completeWithReflection(
                        uid: _uid,
                        lesson: lesson,
                        actionDone: done,
                        note: note,
                        profile: profile,
                        today: ref.read(todayProvider),
                      );
                  _go(LessonStep.quiz);
                },
              ),
        LessonStep.quiz => _QuizStep(
            lesson: lesson,
            alreadyDone: progress.quizDoneAt != null,
            onFinish: (answers, score) {
              if (answers != null) {
                ref.read(progressRepositoryProvider).saveQuiz(_uid, lesson.id, answers, score);
              }
              if (progress.isComplete && widget.startStep == LessonStep.quiz) {
                _finishFlow();
              } else {
                setState(() => _showComplete = true);
              }
            },
          ),
      };
    }

    final done = {
      for (final (i, s) in LessonStep.values.indexed)
        if (progress.isDone(s)) i,
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Today',
          icon: const Icon(Icons.arrow_back),
          onPressed: _finishFlow,
        ),
        title: _showComplete ? null : StepDots(current: _step.index, done: done),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: body),
        ),
      ),
    );
  }
}

class _KeyIdeaStep extends StatelessWidget {
  const _KeyIdeaStep({required this.lesson, required this.onNext});
  final Lesson lesson;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Key idea', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 6),
        Text(lesson.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'From: '),
            TextSpan(text: lesson.sourceVideoTitle, style: const TextStyle(fontStyle: FontStyle.italic)),
            const TextSpan(text: ' — Takhti'),
          ]),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        KeyIdeaList(points: lesson.keyIdea),
        const SizedBox(height: 28),
        FilledButton(onPressed: onNext, child: const Text('Next: Watch')),
      ],
    );
  }
}

class KeyIdeaList extends StatelessWidget {
  const KeyIdeaList({super.key, required this.points});
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (i, p) in points.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${i + 1}',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(p, style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

class _DoStep extends StatelessWidget {
  const _DoStep({
    required this.lesson,
    required this.committed,
    required this.onCommit,
    required this.onReflectNow,
  });

  final Lesson lesson;
  final bool committed;
  final VoidCallback onCommit;
  final VoidCallback onReflectNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Today\'s action', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ActionCard(text: lesson.action),
        const SizedBox(height: 16),
        Text('Try it during your day. This evening we\'ll ask how it went.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        if (committed)
          FilledButton(onPressed: onReflectNow, child: const Text('Reflect now'))
        else
          FilledButton(onPressed: onCommit, child: const Text('I\'ll do this today')),
      ],
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.directions_walk_rounded, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectStep extends StatefulWidget {
  const _ReflectStep({required this.lesson, required this.onSave});
  final Lesson lesson;
  final void Function(ActionDone done, String note) onSave;

  @override
  State<_ReflectStep> createState() => _ReflectStepState();
}

class _ReflectStepState extends State<_ReflectStep> {
  ActionDone? _done;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Did you do today\'s action?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(widget.lesson.action, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          children: [
            for (final d in ActionDone.values)
              ChoiceChip(
                label: Text(d.label),
                selected: _done == d,
                onSelected: (_) => setState(() => _done = d),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(widget.lesson.reflectionQuestion, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          maxLength: kReflectionNoteMax,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Write a line (optional)'),
        ),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('Only you can see this.', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _done == null ? null : () => widget.onSave(_done!, _note.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _QuizStep extends StatefulWidget {
  const _QuizStep({required this.lesson, required this.alreadyDone, required this.onFinish});
  final Lesson lesson;
  final bool alreadyDone;

  /// answers == null when the quiz was skipped.
  final void Function(List<int>? answers, int score) onFinish;

  @override
  State<_QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<_QuizStep> {
  int _index = 0;
  int? _picked;
  final _answers = <int>[];

  @override
  void initState() {
    super.initState();
    if (widget.lesson.quiz.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinish(null, 0));
    }
  }

  void _next() {
    _answers.add(_picked!);
    if (_index + 1 >= widget.lesson.quiz.length) {
      var score = 0;
      for (final (i, a) in _answers.indexed) {
        if (widget.lesson.quiz[i].correctIndex == a) score++;
      }
      widget.onFinish(widget.alreadyDone ? null : _answers, score);
    } else {
      setState(() {
        _index++;
        _picked = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.lesson.quiz;
    if (quiz.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final q = quiz[_index];
    final answered = _picked != null;
    final correct = _picked == q.correctIndex;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Quick check · ${_index + 1} of ${quiz.length}',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            ),
            if (_index == 0 && !answered)
              TextButton(onPressed: () => widget.onFinish(null, 0), child: const Text('Skip quiz')),
          ],
        ),
        const SizedBox(height: 8),
        Text(q.question, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        for (final (i, option) in q.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              text: option,
              state: !answered
                  ? _OptionState.idle
                  : i == q.correctIndex
                      ? _OptionState.correct
                      : (i == _picked ? _OptionState.wrong : _OptionState.idle),
              onTap: answered ? null : () => setState(() => _picked = i),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(correct ? Icons.check_circle : Icons.info_outline,
                color: correct ? theme.colorScheme.primary : theme.colorScheme.error),
            const SizedBox(width: 8),
            Text(correct ? 'Correct' : 'Not quite',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(q.explanation, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _next,
            child: Text(_index + 1 >= quiz.length ? 'Finish' : 'Next question'),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.text, required this.state, this.onTap});
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (border, icon, semantic) = switch (state) {
      _OptionState.correct => (scheme.primary, Icons.check_circle, ', correct answer'),
      _OptionState.wrong => (scheme.error, Icons.cancel, ', your answer, not correct'),
      _OptionState.idle => (scheme.outlineVariant, null, ''),
    };
    return Semantics(
      button: onTap != null,
      label: '$text$semantic',
      excludeSemantics: true,
      child: Material(
        color: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: state == _OptionState.idle ? 1 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
                if (icon != null) Icon(icon, color: border),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteStep extends ConsumerStatefulWidget {
  const _CompleteStep({required this.lesson, required this.journey, required this.onDone});
  final Lesson lesson;
  final Journey journey;
  final VoidCallback onDone;

  @override
  ConsumerState<_CompleteStep> createState() => _CompleteStepState();
}

class _CompleteStepState extends ConsumerState<_CompleteStep> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.journey.lessons.indexOf(widget.lesson) + 1;
    final last = n == widget.journey.lessons.length;
    final profile = ref.watch(currentProfileProvider);
    final streak = visibleStreak(
      today: ref.watch(todayProvider),
      lastCompletedLocalDate: profile?.lastCompletedLocalDate,
      storedStreak: profile?.currentStreak ?? 0,
    );
    return MessageView(
      icon: Icons.emoji_events_outlined,
      title: 'Lesson $n complete',
      body: '🔥 $streak day streak\n\n'
          '${last ? 'You\'ve finished all the pilot lessons.' : 'Next lesson unlocks tomorrow.'}',
      action: FilledButton(onPressed: widget.onDone, child: const Text('Back to Today')),
    );
  }
}
