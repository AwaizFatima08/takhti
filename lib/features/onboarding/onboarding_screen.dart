import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../shared/widgets/common.dart';
import 'onboarding_art.dart';

/// S1 — three pages shown once per install, before sign-in.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  Future<void> _finish([String to = '/sign-in']) async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go(to);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == 2;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: last ? null : () => _finish(),
                  child: Text(last ? '' : 'Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _Page(
                    art: OnboardingArt.brain,
                    title: 'Your brain can change, at any age.',
                    body: 'We were told the brain is fixed after childhood. '
                        'Neuroscience now shows it keeps rewiring itself.',
                  ),
                  _Page(
                    art: OnboardingArt.voice,
                    title: 'I used to be terrified of speaking.',
                    // TODO(content): Adeel's story text + Course Launch clip (1:10–2:00)
                    // from Content Pack v0.1, Screen 2.
                    body: 'Adeel Imtiaz, host of Takhti, on how small steps, repeated '
                        'daily, changed what he could do.',
                  ),
                  _Page(
                    art: OnboardingArt.loop,
                    title: 'How this works',
                    body: 'One small lesson a day:\nRead · Watch · Do · Reflect · Check.\n'
                        'About five minutes, plus one action to try in your day.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  Semantics(
                    label: 'Page ${_index + 1} of 3',
                    child: StepDots(current: _index, done: const {}, count: 3),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: last
                        ? () => _finish()
                        : () => _pages.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                    child: Text(last ? 'Get started' : 'Next'),
                  ),
                  if (last)
                    TextButton(
                      onPressed: () => _finish('/preview'),
                      child: const Text('Peek at Lesson 1 first'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.art, required this.title, required this.body});

  final OnboardingArt art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          OnboardingIllustration(art: art),
          const SizedBox(height: 32),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(body, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
