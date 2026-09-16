import 'package:equatable/equatable.dart';

import '../entities/recording_session_result.dart';
import '../entities/upload_status.dart';

// What to name a file once uploaded and what metadata to attach to it —
// naming/metadata is chunk-specific business logic, so it's decided by the
// caller (ChunkUploadCoordinator), not baked into the Drive repository.
class UploadRequest extends Equatable {
  const UploadRequest({
    required this.artifact,
    required this.remoteFileName,
    required this.dayFolderName,
    this.description,
  });

  final LocalArtifact artifact;
  final String remoteFileName;

  // Which subfolder under the root Drive folder this file belongs in
  // (e.g. "29082026") — grouping by day is what a chunk's own filename
  // prefix already implies, so it's decided here rather than in the Drive
  // repository itself.
  final String dayFolderName;

  // Stored in the Drive file's own `description` field, so a server
  // reading via the Drive API gets it atomically with the file — no
  // separate sidecar file to keep in sync or lose.
  final String? description;

  @override
  List<Object?> get props => [artifact, remoteFileName, dayFolderName, description];
}

abstract class UploadRepository {
  Future<UploadStatus> uploadArtifacts(List<UploadRequest> requests);
}
