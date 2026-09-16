import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../domain/entities/recorder_choice.dart';

class RecorderChoiceCard extends StatelessWidget {
  const RecorderChoiceCard({
    super.key,
    required this.choice,
    required this.onTap,
  });

  final RecorderChoice choice;
  final VoidCallback onTap;

  FaIconData get _icon => switch (choice) {
    RecorderChoice.hybrid => FontAwesomeIcons.tableCells,
    RecorderChoice.widgetPlus => FontAwesomeIcons.video,
    RecorderChoice.clarity => FontAwesomeIcons.cloud,
  };

  Color _accent(ColorScheme scheme) => switch (choice) {
    RecorderChoice.hybrid => scheme.primary,
    RecorderChoice.widgetPlus => scheme.tertiary,
    RecorderChoice.clarity => scheme.secondary,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accent(scheme);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FaIcon(_icon, color: accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      choice.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
