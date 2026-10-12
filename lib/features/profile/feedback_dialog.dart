import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/widgets/common.dart';
import 'user_repository.dart';

/// Pilot feedback: 1–5 stars + optional comment → `feedback` collection.
Future<void> showFeedbackDialog(BuildContext context, WidgetRef ref) async {
  final sent = await showDialog<bool>(context: context, builder: (_) => const _FeedbackDialog());
  if (sent == true && context.mounted) showSnack(context, 'Thank you for your feedback!');
}

class _FeedbackDialog extends ConsumerStatefulWidget {
  const _FeedbackDialog();

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(userRepositoryProvider)
          .sendFeedback(uid, _rating, _comment.text)
          .timeout(const Duration(seconds: 15));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not send. Check your internet connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How was the pilot?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i star${i == 1 ? '' : 's'}',
                    isSelected: i <= _rating,
                    icon: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 32, color: i <= _rating ? Colors.amber.shade700 : null),
                    onPressed: () => setState(() => _rating = i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              maxLength: kFeedbackCommentMax,
              maxLines: 4,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'What should we improve? (optional)'),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: kDialogButtonStyle,
          onPressed: _rating == 0 || _busy ? null : _send,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send'),
        ),
      ],
    );
  }
}
