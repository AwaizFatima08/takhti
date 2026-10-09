import 'package:flutter/material.dart';

enum OnboardingArt { brain, voice, loop }

/// The five steps of the daily loop with their icons (onboarding page 3, Today card).
const loopSteps = <(IconData, String)>[
  (Icons.menu_book_rounded, 'Read'),
  (Icons.play_circle_rounded, 'Watch'),
  (Icons.directions_walk_rounded, 'Do'),
  (Icons.edit_note_rounded, 'Reflect'),
  (Icons.task_alt_rounded, 'Check'),
];

/// Code-drawn placeholder illustrations (no image assets needed).
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.art});

  final OnboardingArt art;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (art == OnboardingArt.loop) {
      return ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final (icon, label) in loopSteps)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(icon, size: 30, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
          ],
        ),
      );
    }
    final icon = art == OnboardingArt.brain ? Icons.psychology_rounded : Icons.record_voice_over_rounded;
    return ExcludeSemantics(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [scheme.primaryContainer, scheme.primaryContainer.withValues(alpha: 0.25)],
          ),
        ),
        child: Icon(icon, size: 110, color: scheme.primary),
      ),
    );
  }
}
