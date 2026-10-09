import 'package:flutter/material.dart';

import '../../app/config.dart';
import '../../shared/widgets/common.dart';

/// Shown when appConfig/main.minSupportedBuild is newer than this build.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: MessageView(
            icon: Icons.system_update,
            title: 'Please update Takhti Grow',
            body: 'This version is no longer supported. Update from Google Play to continue.',
            action: FilledButton(
              onPressed: () => openLink(context, Uri.parse(kPlayStoreUrl)),
              child: const Text('Open Google Play'),
            ),
          ),
        ),
      );
}
