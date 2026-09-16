import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/async_queue.dart';
import '../entities/recording_session_result.dart';
import '../entities/session_chunk.dart';
import '../entities/upload_status.dart';
import '../repository/upload_repository.dart';
import '../repository/session_chunk_repository.dart';

class ChunkUploadCoordinator {
  ChunkUploadCoordinator({
    required this.chunkUploadQueue,
    required this.sessionChunkStore,
    required this.driveUploadRepository,
    Future<Directory> Function()? baseDirectory,
  }) : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  final AsyncQueue chunkUploadQueue;
  final SessionChunkRepository sessionChunkStore;
  final UploadRepository driveUploadRepository;
  final Future<Directory> Function() _baseDirectory;

  Future<void> enqueueNewChunk(
    RecordingSessionResult chunkResult, {
    required String screenName,
    required int indexValue,
  }) async {
    final id = _generateChunkId();

    if (chunkResult.localArtifacts.isEmpty) {
      await sessionChunkStore.save(
        SessionChunk(
          id: id,
          approachName: chunkResult.metrics.implementationName,
          screenName: screenName,
          capturedAt: chunkResult.metrics.startedAt,
          indexValue: indexValue,
          metrics: chunkResult.metrics,
          localArtifacts: const [],
          status: ChunkUploadStatus.succeeded,
        ),
      );
      return;
    }

    final metadataArtifact = await _writeMetadataArtifact(
      id: id,
      screenName: screenName,
      indexValue: indexValue,
      capturedAt: chunkResult.metrics.startedAt,
      approachName: chunkResult.metrics.implementationName,
      durationMs: chunkResult.metrics.duration.inMilliseconds,
    );

    final chunk = SessionChunk(
      id: id,
      approachName: chunkResult.metrics.implementationName,
      screenName: screenName,
      capturedAt: chunkResult.metrics.startedAt,
      indexValue: indexValue,
      metrics: chunkResult.metrics,
      localArtifacts: [...chunkResult.localArtifacts, metadataArtifact],
      status: ChunkUploadStatus.queued,
    );
    await sessionChunkStore.save(chunk);
    retry(chunk);
  }

  Future<void> resumePendingUploads() async {
    await sessionChunkStore.ensureLoaded();
    final pending = sessionChunkStore.chunks.value.where(
      (c) => c.status.isQueued || c.status.isUploading,
    );
    for (final chunk in pending) {
      retry(chunk);
    }
  }

  void retry(SessionChunk chunk) {
    chunkUploadQueue.enqueue(() async {
      await sessionChunkStore.save(
        chunk.copyWith(status: ChunkUploadStatus.uploading),
      );
      final uploadRequest = await _buildZipUploadRequest(chunk);
      final uploadStatus = await driveUploadRepository.uploadArtifacts([
        uploadRequest,
      ]);
      switch (uploadStatus) {
        case UploadSuccess(fileLinks: final links):
          await sessionChunkStore.save(
            chunk.copyWith(
              status: ChunkUploadStatus.succeeded,
              driveLinks: links,
            ),
          );
          await _deleteLocalFiles(chunk, uploadRequest);
        case UploadNotSignedIn():
          await sessionChunkStore.save(
            chunk.copyWith(
              status: ChunkUploadStatus.failed,
              errorMessage: 'Not signed in to Google Drive.',
            ),
          );
          throw StateError('Not signed in to Google Drive.');
        case UploadError(message: final message):
          await sessionChunkStore.save(
            chunk.copyWith(
              status: ChunkUploadStatus.failed,
              errorMessage: message,
            ),
          );
          throw StateError(message);
        case UploadIdle():
        case UploadInProgress():
          throw StateError('Unexpected upload state: $uploadStatus');
      }
    });
  }

  Future<void> _deleteLocalFiles(
    SessionChunk chunk,
    UploadRequest uploadRequest,
  ) async {
    for (final artifact in chunk.localArtifacts) {
      if (artifact.kind == ArtifactKind.timelineJson) continue;
      final file = File(artifact.path);
      if (await file.exists()) await file.delete();
    }
    final zipFile = File(uploadRequest.artifact.path);
    if (await zipFile.exists()) await zipFile.delete();
  }

  String _generateChunkId() {
    final now = DateTime.now();
    final secondsSinceMidnight = now.hour * 3600 + now.minute * 60 + now.second;
    return secondsSinceMidnight.toString().padLeft(5, '0');
  }

  Future<LocalArtifact> _writeMetadataArtifact({
    required String id,
    required String screenName,
    required int indexValue,
    required DateTime capturedAt,
    required String approachName,
    required int durationMs,
  }) async {
    final json = jsonEncode(
      _metadataMap(
        id: id,
        screenName: screenName,
        indexValue: indexValue,
        capturedAt: capturedAt,
        approachName: approachName,
        durationMs: durationMs,
      ),
    );

    final docsDir = await _baseDirectory();

    final dir = Directory(
      '${docsDir.path}/${StorageNames.chunkMetadataDir}/$id',
    );
    await dir.create(recursive: true);
    final file = File('${dir.path}/${StorageNames.chunkMetadataFile}');
    await file.writeAsString(json);

    return LocalArtifact(
      path: file.path,
      kind: ArtifactKind.timelineJson,
      sizeBytes: await file.length(),
    );
  }

  Future<UploadRequest> _buildZipUploadRequest(SessionChunk chunk) async {
    final docsDir = await _baseDirectory();
    final dir = Directory('${docsDir.path}/${StorageNames.chunkUploadsDir}');
    await dir.create(recursive: true);
    final namePrefix = _remoteNamePrefix(chunk);
    final zipPath = '${dir.path}/$namePrefix.zip';

    final artifactPaths = chunk.localArtifacts.map((a) => a.path).toList();
    await Isolate.run(() => _writeZipFile(zipPath, artifactPaths));

    final zipFile = File(zipPath);
    final description = jsonEncode(
      _metadataMap(
        id: chunk.id,
        screenName: chunk.screenName,
        indexValue: chunk.indexValue,
        capturedAt: chunk.capturedAt,
        approachName: chunk.approachName,
        durationMs: chunk.metrics.duration.inMilliseconds,
      ),
    );

    return UploadRequest(
      artifact: LocalArtifact(
        path: zipPath,
        kind: ArtifactKind.archive,
        sizeBytes: await zipFile.length(),
      ),
      remoteFileName: '$namePrefix.zip',
      description: description,
      dayFolderName: _ddmmyyyy(chunk.capturedAt),
    );
  }

  Map<String, dynamic> _metadataMap({
    required String id,
    required String screenName,
    required int indexValue,
    required DateTime capturedAt,
    required String approachName,
    required int durationMs,
  }) {
    return {
      ChunkMetadataKeys.chunkId: id,
      ChunkMetadataKeys.screen: screenName,
      ChunkMetadataKeys.approach: approachName,
      ChunkMetadataKeys.capturedAt: capturedAt.toIso8601String(),
      ChunkMetadataKeys.index: indexValue,
      ChunkMetadataKeys.durationMs: durationMs,
    };
  }

  String _ddmmyyyy(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString().padLeft(4, '0');
    return '$dd$mm$yyyy';
  }

  String _remoteNamePrefix(SessionChunk chunk) {
    return '${_ddmmyyyy(chunk.capturedAt)}_${chunk.id}_${chunk.indexValue}';
  }
}

void _writeZipFile(String zipPath, List<String> artifactPaths) {
  final zipFile = File(zipPath);
  if (zipFile.existsSync()) zipFile.deleteSync();

  final encoder = ZipFileEncoder();
  encoder.create(zipPath);
  final usedNames = <String>{};
  for (final path in artifactPaths) {
    encoder.addFileSync(
      File(path),
      _uniqueZipEntryName(path.split('/').last, usedNames),
    );
  }
  encoder.closeSync();
}

String _uniqueZipEntryName(String name, Set<String> usedNames) {
  if (usedNames.add(name)) return name;
  final dotIndex = name.lastIndexOf('.');
  final base = dotIndex > 0 ? name.substring(0, dotIndex) : name;
  final ext = dotIndex > 0 ? name.substring(dotIndex) : '';
  var suffix = 1;
  var candidate = '${base}_$suffix$ext';
  while (!usedNames.add(candidate)) {
    suffix++;
    candidate = '${base}_$suffix$ext';
  }
  return candidate;
}
