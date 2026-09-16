import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../domain/entities/recording_session_result.dart';

class RemoteInspectionCard extends StatelessWidget {
  const RemoteInspectionCard({super.key, required this.descriptor});

  final RemoteInspectionDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final url = descriptor.url;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.cloud, size: 18),
              const SizedBox(width: 8),
              Text(descriptor.label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(descriptor.instructions),
          if (url != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
              icon: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 16),
              label: const Text(AppStrings.openClaritySessionButton),
            ),
          ],
        ],
      ),
    );
  }
}
