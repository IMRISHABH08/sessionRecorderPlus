import 'package:equatable/equatable.dart';

import 'session_metrics.dart';

enum ArtifactKind { video, screenshot, timelineJson, archive }

class LocalArtifact extends Equatable {
  const LocalArtifact({
    required this.path,
    required this.kind,
    required this.sizeBytes,
  });

  final String path;
  final ArtifactKind kind;
  final int sizeBytes;

  @override
  List<Object?> get props => [path, kind, sizeBytes];
}

class RemoteInspectionDescriptor extends Equatable {
  const RemoteInspectionDescriptor({
    required this.label,
    required this.instructions,
    this.url,
  });

  final String label;
  final String? url;
  final String instructions;

  @override
  List<Object?> get props => [label, url, instructions];
}

class RecordingSessionResult extends Equatable {
  const RecordingSessionResult({
    required this.metrics,
    this.localArtifacts = const [],
    this.remoteInspection,
  });

  final SessionMetrics metrics;

  // Empty for Clarity — it writes nothing locally.
  final List<LocalArtifact> localArtifacts;

  // Non-null only when there's no local artifact (Clarity).
  final RemoteInspectionDescriptor? remoteInspection;

  @override
  List<Object?> get props => [metrics, localArtifacts, remoteInspection];
}
