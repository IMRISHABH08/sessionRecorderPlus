import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:azodha/core/constants/app_strings.dart';
import 'package:azodha/core/services/async_upload_queue.dart';
import 'package:azodha/features/recording/data/session_info/session_chunk_store.dart';
import 'package:azodha/features/recording/domain/entities/recording_session_result.dart';
import 'package:azodha/features/recording/domain/entities/session_chunk.dart';
import 'package:azodha/features/recording/domain/entities/session_metrics.dart';
import 'package:azodha/features/recording/domain/entities/upload_status.dart';
import 'package:azodha/features/recording/domain/repository/upload_repository.dart';
import 'package:azodha/features/recording/domain/usecase/chunk_upload_coordinator.dart';

class _FakeUploadRepository implements UploadRepository {
  _FakeUploadRepository(this.result);

  final UploadStatus result;
  int callCount = 0;
  List<UploadRequest>? lastRequests;
  List<int>? lastZipBytes;

  @override
  Future<UploadStatus> uploadArtifacts(List<UploadRequest> requests) async {
    callCount++;
    lastRequests = requests;
    // Snapshotted here, not re-read later — mirrors the real repository,
    // which streams the file during the upload call itself, before a
    // successful upload's local cleanup ever gets a chance to delete it.
    if (requests.isNotEmpty) {
      lastZipBytes = await File(requests.first.artifact.path).readAsBytes();
    }
    return result;
  }
}

RecordingSessionResult _fakeChunkResult({List<LocalArtifact> artifacts = const []}) {
  return RecordingSessionResult(
    metrics: SessionMetrics(
      implementationName: 'Hybrid: screenshots + timeline',
      startedAt: DateTime(2026, 8, 29, 10),
      duration: const Duration(seconds: 30),
      totalPayloadBytes: artifacts.fold<int>(0, (sum, a) => sum + a.sizeBytes),
      eventCount: 1,
      captureMethod: CaptureMethod.eventTriggeredScreenshots,
    ),
    localArtifacts: artifacts,
  );
}

Future<Directory> _tempDir() async {
  final dir = await Directory.systemTemp.createTemp('chunk_upload_test');
  addTearDown(() => dir.delete(recursive: true));
  return dir;
}

Future<LocalArtifact> _realArtifact(
  Directory dir,
  String name,
  ArtifactKind kind,
) async {
  final file = File('${dir.path}/$name');
  await file.writeAsString('fake content for $name');
  return LocalArtifact(path: file.path, kind: kind, sizeBytes: await file.length());
}

void main() {
  test('a chunk with no artifacts is persisted as succeeded without touching the queue', () async {
    final dir = await _tempDir();
    final store = SessionChunkStore(baseDirectory: () async => dir);
    final fakeRepo = _FakeUploadRepository(const UploadSuccess(fileLinks: []));
    final coordinator = ChunkUploadCoordinator(
      chunkUploadQueue: AsyncUploadQueue(),
      sessionChunkStore: store,
      driveUploadRepository: fakeRepo,
      baseDirectory: () async => dir,
    );

    await coordinator.enqueueNewChunk(
      _fakeChunkResult(),
      screenName: '/playground',
      indexValue: 0,
    );

    expect(fakeRepo.callCount, 0);
    expect(store.chunks.value, hasLength(1));
    expect(store.chunks.value.single.status, ChunkUploadStatus.succeeded);
  });

  test('generated chunk ids are at most 6 digits', () async {
    final dir = await _tempDir();
    final store = SessionChunkStore(baseDirectory: () async => dir);
    final coordinator = ChunkUploadCoordinator(
      chunkUploadQueue: AsyncUploadQueue(),
      sessionChunkStore: store,
      driveUploadRepository: _FakeUploadRepository(const UploadSuccess(fileLinks: [])),
      baseDirectory: () async => dir,
    );

    await coordinator.enqueueNewChunk(
      _fakeChunkResult(),
      screenName: '/playground',
      indexValue: 0,
    );

    expect(store.chunks.value.single.id.length, lessThanOrEqualTo(6));
  });

  test('a successful upload transitions queued -> uploading -> succeeded, uploading exactly one zip', () async {
    final dir = await _tempDir();
    final store = SessionChunkStore(baseDirectory: () async => dir);
    final fakeRepo = _FakeUploadRepository(
      const UploadSuccess(fileLinks: ['https://drive.example/1']),
    );
    final completer = Completer<void>();
    final coordinator = ChunkUploadCoordinator(
      chunkUploadQueue: AsyncUploadQueue(onQueueEmpty: completer.complete),
      sessionChunkStore: store,
      driveUploadRepository: fakeRepo,
      baseDirectory: () async => dir,
    );

    final artifact = await _realArtifact(dir, 'shot.jpg', ArtifactKind.screenshot);
    await coordinator.enqueueNewChunk(
      _fakeChunkResult(artifacts: [artifact]),
      screenName: '/playground',
      indexValue: 2,
    );
    await completer.future;

    expect(fakeRepo.callCount, 1);
    // Exactly one uploaded object per chunk — bundling artifacts + metadata
    // into a single zip, not several separately-linked files.
    expect(fakeRepo.lastRequests, hasLength(1));
    expect(fakeRepo.lastRequests!.single.artifact.kind, ArtifactKind.archive);
    expect(fakeRepo.lastRequests!.single.remoteFileName, endsWith('.zip'));

    final chunk = store.chunks.value.single;
    expect(chunk.status, ChunkUploadStatus.succeeded);
    expect(chunk.driveLinks, ['https://drive.example/1']);
    expect(chunk.indexValue, 2);
    expect(chunk.screenName, '/playground');

    // Drive has a confirmed copy now — the large binary original and the
    // zip built from it are cleaned up so storage doesn't grow unbounded.
    // JSON artifacts (this chunk's generated metadata.json) are kept, so
    // tap-to-expand still works locally for a succeeded chunk.
    expect(await File(artifact.path).exists(), isFalse);
    for (final a in chunk.localArtifacts) {
      final stillExists = await File(a.path).exists();
      expect(stillExists, a.kind == ArtifactKind.timelineJson);
    }
  });

  test('a failing upload retries 3 times then persists as failed', () async {
    final dir = await _tempDir();
    final store = SessionChunkStore(baseDirectory: () async => dir);
    final fakeRepo = _FakeUploadRepository(const UploadError('boom'));
    final completer = Completer<void>();
    final coordinator = ChunkUploadCoordinator(
      chunkUploadQueue: AsyncUploadQueue(onQueueEmpty: completer.complete),
      sessionChunkStore: store,
      driveUploadRepository: fakeRepo,
      baseDirectory: () async => dir,
    );

    final artifact = await _realArtifact(dir, 'shot.jpg', ArtifactKind.screenshot);
    await coordinator.enqueueNewChunk(
      _fakeChunkResult(artifacts: [artifact]),
      screenName: '/playground',
      indexValue: 0,
    );
    await completer.future;

    expect(fakeRepo.callCount, 3);
    final chunk = store.chunks.value.single;
    expect(chunk.status, ChunkUploadStatus.failed);
    expect(chunk.errorMessage, 'boom');
    // The original local artifact is still on disk / still referenced —
    // nothing about the chunk is silently lost even though the queue gave
    // up. A second artifact (this chunk's own metadata.json) is added
    // alongside it.
    expect(chunk.localArtifacts, hasLength(2));
    expect(chunk.localArtifacts, contains(artifact));
  });

  test('the zip is named ddmmyyyy_id_index and its description carries snake_case metadata', () async {
    final dir = await _tempDir();
    final store = SessionChunkStore(baseDirectory: () async => dir);
    final fakeRepo = _FakeUploadRepository(
      const UploadSuccess(fileLinks: ['https://drive.example/1']),
    );
    final completer = Completer<void>();
    final coordinator = ChunkUploadCoordinator(
      chunkUploadQueue: AsyncUploadQueue(onQueueEmpty: completer.complete),
      sessionChunkStore: store,
      driveUploadRepository: fakeRepo,
      baseDirectory: () async => dir,
    );

    final artifact = await _realArtifact(
      dir,
      'widget_rec_1787985007649.mp4',
      ArtifactKind.video,
    );
    // startedAt is Aug 29 2026 per _fakeChunkResult -> expect 29082026.
    await coordinator.enqueueNewChunk(
      _fakeChunkResult(artifacts: [artifact]),
      screenName: '/playground',
      indexValue: 3,
    );
    await completer.future;

    final chunk = store.chunks.value.single;
    final request = fakeRepo.lastRequests!.single;
    expect(request.remoteFileName, '29082026_${chunk.id}_3.zip');
    expect(request.dayFolderName, '29082026');
    expect(chunk.id.length, lessThanOrEqualTo(6));

    final description = jsonDecode(request.description!);
    expect(description[ChunkMetadataKeys.chunkId], chunk.id);
    expect(description[ChunkMetadataKeys.screen], '/playground');
    expect(description[ChunkMetadataKeys.index], 3);
    expect(
      description[ChunkMetadataKeys.capturedAt],
      chunk.capturedAt.toIso8601String(),
    );
    expect(description[ChunkMetadataKeys.durationMs], isA<int>());

    // The zip actually contains both the original artifact and the
    // generated metadata.json, disambiguated if names would collide.
    final archive = ZipDecoder().decodeBytes(fakeRepo.lastZipBytes!);
    final names = archive.files.map((f) => f.name).toSet();
    expect(names, contains('widget_rec_1787985007649.mp4'));
    expect(names, contains('metadata.json'));
  });

  test('resumePendingUploads re-uploads chunks left queued/uploading from a killed app', () async {
    final dir = await _tempDir();

    // Simulate the app being killed right after a chunk was persisted but
    // before its upload ran (or mid-upload) — persist directly via a store
    // instance that never talks to a queue, so nothing actually uploads yet.
    final crashedStore = SessionChunkStore(baseDirectory: () async => dir);
    final artifact = await _realArtifact(dir, 'shot.jpg', ArtifactKind.screenshot);
    await crashedStore.save(
      SessionChunk(
        id: '00001',
        approachName: 'Hybrid: screenshots + timeline',
        screenName: '/playground',
        capturedAt: DateTime(2026, 8, 29, 10),
        indexValue: 0,
        metrics: _fakeChunkResult(artifacts: [artifact]).metrics,
        localArtifacts: [artifact],
        status: ChunkUploadStatus.uploading,
      ),
    );

    // A fresh process would construct a brand-new store/queue/coordinator
    // pointed at the same on-disk file — nothing in-memory survives a kill.
    final freshStore = SessionChunkStore(baseDirectory: () async => dir);
    final fakeRepo = _FakeUploadRepository(
      const UploadSuccess(fileLinks: ['https://drive.example/resumed']),
    );
    final completer = Completer<void>();
    final coordinator = ChunkUploadCoordinator(
      chunkUploadQueue: AsyncUploadQueue(onQueueEmpty: completer.complete),
      sessionChunkStore: freshStore,
      driveUploadRepository: fakeRepo,
      baseDirectory: () async => dir,
    );

    await coordinator.resumePendingUploads();
    await completer.future;

    expect(fakeRepo.callCount, 1);
    final chunk = freshStore.chunks.value.single;
    expect(chunk.status, ChunkUploadStatus.succeeded);
    expect(chunk.driveLinks, ['https://drive.example/resumed']);
  });
}
