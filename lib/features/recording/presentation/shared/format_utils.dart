import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../domain/entities/recording_session_result.dart';

String formatBytes(int? bytes) {
  if (bytes == null) return 'N/A';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '${m}m ${s}s';
}

// file size ≈ bitrate × duration (recordingRequirement.md) — shown in
// reverse here so the payload size number means something on its own.
String? formatBitrate(int? bytes, Duration duration) {
  final cannotComputeBitrate = bytes == null || duration.inMilliseconds <= 0;
  if (cannotComputeBitrate) return null;
  final bits = bytes * 8;
  final seconds = duration.inMilliseconds / 1000;
  final mbps = bits / seconds / 1000000;
  return '${mbps.toStringAsFixed(2)} Mbps';
}

FaIconData iconForArtifactKind(ArtifactKind kind) => switch (kind) {
  ArtifactKind.video => FontAwesomeIcons.film,
  ArtifactKind.screenshot => FontAwesomeIcons.image,
  ArtifactKind.timelineJson => FontAwesomeIcons.fileLines,
  ArtifactKind.archive => FontAwesomeIcons.fileZipper,
};
