import 'package:equatable/equatable.dart';

import 'recording_session_result.dart';
import 'session_metrics.dart';

enum ChunkUploadStatus {
  queued,
  uploading,
  succeeded,
  failed;

  bool get isQueued => this == queued;
  bool get isUploading => this == uploading;
  bool get isSucceeded => this == succeeded;
  bool get isFailed => this == failed;
}

// A persisted record of one finalized chunk, independent of the recorder
// that produced it — this is what Session Info reads and displays, and
// what travels with the upload so a server can reconstruct a whole day's
// recording without relying on upload arrival order.
class SessionChunk extends Equatable {
  const SessionChunk({
    required this.id,
    required this.approachName,
    required this.screenName,
    required this.capturedAt,
    required this.indexValue,
    required this.metrics,
    required this.localArtifacts,
    required this.status,
    this.driveLinks,
    this.errorMessage,
  });

  final String id;
  final String approachName;

  // Which app screen/section this chunk's recording started on.
  final String screenName;

  final DateTime capturedAt;

  // Sequence number within its recording session (0, 1, 2, ...) — chunks
  // upload independently and can arrive at a server out of order, so this
  // is what makes correct chronological ordering possible without relying
  // on arrival time.
  final int indexValue;

  final SessionMetrics metrics;
  final List<LocalArtifact> localArtifacts;
  final ChunkUploadStatus status;
  final List<String>? driveLinks;
  final String? errorMessage;

  SessionChunk copyWith({
    ChunkUploadStatus? status,
    List<String>? driveLinks,
    String? errorMessage,
  }) {
    return SessionChunk(
      id: id,
      approachName: approachName,
      screenName: screenName,
      capturedAt: capturedAt,
      indexValue: indexValue,
      metrics: metrics,
      localArtifacts: localArtifacts,
      status: status ?? this.status,
      driveLinks: driveLinks ?? this.driveLinks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    approachName,
    screenName,
    capturedAt,
    indexValue,
    metrics,
    localArtifacts,
    status,
    driveLinks,
    errorMessage,
  ];
}
