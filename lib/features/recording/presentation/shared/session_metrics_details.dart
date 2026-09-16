import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/recording_session_result.dart';
import '../../domain/entities/session_metrics.dart';
import 'artifact_tile.dart';
import 'format_utils.dart';
import 'stat_tile.dart';

class SessionMetricsDetails extends StatelessWidget {
  const SessionMetricsDetails({
    super.key,
    required this.metrics,
    required this.localArtifacts,
  });

  final SessionMetrics metrics;
  final List<LocalArtifact> localArtifacts;

  @override
  Widget build(BuildContext context) {
    final bitrate = formatBitrate(metrics.totalPayloadBytes, metrics.duration);
    final screenshotCount = localArtifacts
        .where((a) => a.kind == ArtifactKind.screenshot)
        .length;

    final stats = [
      StatTile(
        icon: FontAwesomeIcons.box,
        label: AppStrings.payloadSizeLabel,
        value: formatBytes(metrics.totalPayloadBytes),
      ),
      StatTile(
        icon: FontAwesomeIcons.stopwatch,
        label: AppStrings.durationLabel,
        value: formatDuration(metrics.duration),
      ),
      // widget_recorder_plus never calls recordEvent() — it's continuous
      // video, not a discrete event log — so this would always read 0.
      if (metrics.captureMethod != CaptureMethod.nativeVideoEncoding)
        StatTile(
          icon: FontAwesomeIcons.bolt,
          label: AppStrings.eventsLabel,
          value: '${metrics.eventCount}',
        ),
      StatTile(
        icon: FontAwesomeIcons.shapes,
        label: AppStrings.captureMethodLabel,
        value: metrics.captureMethod.label,
      ),
      if (bitrate != null)
        StatTile(
          icon: FontAwesomeIcons.gaugeHigh,
          label: AppStrings.effectiveBitrateLabel,
          value: bitrate,
        ),
      if (screenshotCount > 0)
        StatTile(
          icon: FontAwesomeIcons.images,
          label: AppStrings.screenshotsCapturedLabel,
          value: '$screenshotCount',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          stats[i],
          if (i != stats.length - 1) const Divider(height: 1),
        ],
        if (localArtifacts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            AppStrings.artifactsHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          ...localArtifacts.map((artifact) => ArtifactTile(artifact: artifact)),
        ],
      ],
    );
  }
}
