import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/config.dart';
import '../../shared/widgets/common.dart';

/// The two required tick-boxes (design 5.2): 18+ and Terms/Privacy.
class ConsentChecks extends StatelessWidget {
  const ConsentChecks({
    super.key,
    required this.adult,
    required this.terms,
    required this.onAdult,
    required this.onTerms,
  });

  final bool adult;
  final bool terms;
  final ValueChanged<bool> onAdult;
  final ValueChanged<bool> onTerms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = TextStyle(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
    return Column(
      children: [
        CheckboxListTile(
          value: adult,
          onChanged: (v) => onAdult(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('I confirm I am 18 or older'),
        ),
        CheckboxListTile(
          value: terms,
          onChanged: (v) => onTerms(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text.rich(TextSpan(children: [
            const TextSpan(text: 'I agree to the '),
            TextSpan(
              text: 'Terms',
              style: link,
              recognizer: TapGestureRecognizer()..onTap = () => openLink(context, Uri.parse(kTermsUrl)),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: link,
              recognizer: TapGestureRecognizer()..onTap = () => openLink(context, Uri.parse(kPrivacyUrl)),
            ),
          ])),
        ),
      ],
    );
  }
}
