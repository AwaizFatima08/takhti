import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../shared/models/lesson.dart';
import '../../shared/widgets/common.dart';

/// S9 — embedded clip from clipStartSec to clipEndSec with English captions
/// requested. Calls [onWatched] when the clip ends, or on Next after ≥ 10 s of playback.
class WatchStep extends StatefulWidget {
  const WatchStep({super.key, required this.lesson, required this.onWatched, required this.onNext});

  final Lesson lesson;
  final VoidCallback onWatched;
  final VoidCallback onNext;

  @override
  State<WatchStep> createState() => _WatchStepState();
}

class _WatchStepState extends State<WatchStep> {
  late final YoutubePlayerController _controller;
  final _subs = <StreamSubscription<Object?>>[];
  bool _failed = false;
  bool _reported = false;
  Duration _played = Duration.zero;
  Duration? _lastPosition;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        enableCaption: true,
        captionLanguage: 'en',
        interfaceLanguage: 'en',
        strictRelatedVideos: true,
        playsInline: true,
      ),
      onWebResourceError: (e) {
        if (e.isForMainFrame ?? true) _fail();
      },
    );
    _controller.cueVideoById(
      videoId: l.youtubeId,
      startSeconds: l.clipStartSec.toDouble(),
      endSeconds: l.clipEndSec.toDouble(),
    );
    _subs.add(_controller.stream.listen((v) {
      if (v.error != YoutubeError.none) _fail();
      if (v.playerState == PlayerState.ended) _watched();
    }));
    _subs.add(_controller.videoStateStream.listen((s) {
      final last = _lastPosition;
      _lastPosition = s.position;
      if (last == null) return;
      final step = s.position - last;
      // Count normal playback only (ignore seeks).
      if (step > Duration.zero && step < const Duration(seconds: 3)) {
        _played += step;
      }
    }));
  }

  void _fail() {
    if (mounted && !_failed) setState(() => _failed = true);
  }

  void _watched() {
    if (_reported) return;
    _reported = true;
    widget.onWatched();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _controller.close();
    super.dispose();
  }

  String _mmss(int sec) => '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = widget.lesson;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Watch', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Clip ${_mmss(l.clipStartSec)} – ${_mmss(l.clipEndSec)}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _failed
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 36),
                            const SizedBox(height: 8),
                            Text('This clip can\'t play right now.', style: theme.textTheme.titleMedium),
                            const Text('It needs internet, or the video may be unavailable.',
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  )
                : YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
          ),
        ),
        const SizedBox(height: 12),
        Text('Clip from Takhti Online · ${l.sourceVideoTitle}', style: theme.textTheme.bodyMedium),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openLink(context, l.fullVideoUri),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(_failed ? 'Open in YouTube' : 'Watch the full video'),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            // Design S9: Next is always enabled; the clip counts as watched
            // when it reached its end or played for at least 10 seconds.
            if (_played >= const Duration(seconds: 10)) _watched();
            widget.onNext();
          },
          child: const Text('Next: Do'),
        ),
      ],
    );
  }
}
