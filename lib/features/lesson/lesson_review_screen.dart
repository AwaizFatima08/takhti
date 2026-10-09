import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/common.dart';
import '../reflections/reflection_repository.dart';
import 'lesson_flow_screen.dart';
import 'lesson_repository.dart';
import 'progress_repository.dart';

/// S14 — a done lesson, read-only: key idea, clip link, action, own reflection.
class LessonReviewScreen extends ConsumerWidget {
  const LessonReviewScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lesson = ref.watch(lessonByIdProvider(lessonId));
    final reflections = ref.watch(reflectionsProvider).value ?? const [];
    final progress = ref.watch(progressProvider).value?[lessonId];
    if (lesson == null) {
      return Scaffold(appBar: AppBar(), body: const MessageView(icon: Icons.search_off, title: 'Lesson not found'));
    }
    final mine = reflections.where((r) => r.lessonId == lessonId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson review')),
      body: SafeArea(
        child: PageBody(
          padding: EdgeInsets.zero,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(lesson.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              KeyIdeaList(points: lesson.keyIdea),
              OutlinedButton.icon(
                onPressed: () => openLink(context, lesson.fullVideoUri),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch the clip on YouTube'),
              ),
              const SizedBox(height: 20),
              ActionCard(text: lesson.action),
              const SizedBox(height: 20),
              if (mine != null) ...[
                Text(mine.question, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Chip(label: Text('Did it: ${mine.actionDone.label}')),
                if (mine.note.isNotEmpty) Text(mine.note, style: theme.textTheme.bodyLarge),
              ],
              if (progress?.quizScore != null) ...[
                const SizedBox(height: 16),
                Text('Quick check: ${progress!.quizScore} of ${lesson.quiz.length}', style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
