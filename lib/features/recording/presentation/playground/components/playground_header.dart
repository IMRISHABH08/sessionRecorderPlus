import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/constants/app_strings.dart';

class PlaygroundHeader extends StatelessWidget {
  const PlaygroundHeader({
    super.key,
    required this.onCtaTap,
    required this.applied,
  });

  final VoidCallback onCtaTap;
  final ValueListenable<bool> applied;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                AppStrings.playgroundHeaderImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _placeholder(scheme, loading: true);
                },
                errorBuilder: (context, error, stackTrace) =>
                    _placeholder(scheme, loading: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: applied,
            builder: (context, isApplied, _) {
              return FilledButton.icon(
                onPressed: onCtaTap,
                style: isApplied
                    ? FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      )
                    : null,
                icon: FaIcon(
                  isApplied
                      ? FontAwesomeIcons.solidCircleCheck
                      : FontAwesomeIcons.circleCheck,
                  size: 18,
                ),
                label: Text(
                  isApplied ? AppStrings.appliedButton : AppStrings.applyButton,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme, {required bool loading}) {
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: FaIcon(
        loading ? FontAwesomeIcons.spinner : FontAwesomeIcons.image,
        size: 40,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
