import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:azodha/core/services/async_upload_queue.dart';
import 'package:azodha/features/recording/data/recorder/hybrid/hybrid_recorder_impl.dart';
import 'package:azodha/features/recording/data/session_info/session_chunk_store.dart';
import 'package:azodha/features/recording/data/upload/google_drive_upload_repository_impl.dart';
import 'package:azodha/features/recording/domain/entities/recorder_event.dart';
import 'package:azodha/features/recording/domain/entities/recording_session_result.dart';
import 'package:azodha/features/recording/domain/usecase/chunk_upload_coordinator.dart';
import 'package:azodha/features/recording/presentation/controller/playground_controller.dart';

// Mirrors _PlaygroundPageState.initState exactly: registers the post-frame
// callback synchronously (while the first frame is still in flight) rather
// than from inside start()'s async body — that ordering is what avoids
// racing RenderRepaintBoundary's initial paint.
class _PlaygroundHost extends StatefulWidget {
  const _PlaygroundHost({required this.controller});

  final PlaygroundController controller;

  @override
  State<_PlaygroundHost> createState() => _PlaygroundHostState();
}

class _PlaygroundHostState extends State<_PlaygroundHost> {
  @override
  void initState() {
    super.initState();
    final started = widget.controller.start();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await started;
      if (mounted) widget.controller.fireScreenEnter();
    });
  }

  @override
  Widget build(BuildContext context) => widget.controller.recorder.wrapContent(
    Container(width: 100, height: 100, color: Colors.red),
  );
}

void main() {
  testWidgets('captures a JPEG screenshot and writes a matching timeline', (
    tester,
  ) async {
    late Directory tempDir;
    late HybridRecorderImpl recorder;

    // Real file I/O and toImage() rasterization never resolve under the
    // fake-async test zone, so everything that touches either must run
    // inside runAsync.
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('hybrid_test');
    });
    addTearDown(() => tempDir.delete(recursive: true));

    recorder = HybridRecorderImpl(
      minCaptureInterval: Duration.zero,
      baseDirectory: () async => tempDir,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: recorder.wrapContent(
          Container(
            width: 200,
            height: 200,
            color: Colors.blue,
            child: const Text('hello'),
          ),
        ),
      ),
    );

    late RecordingSessionResult result;
    late List<int> jpegBytes;
    late Map<String, dynamic> json;

    await tester.runAsync(() async {
      await recorder.startSession();
      recorder.recordEvent(
        RecorderEvent(RecorderEventType.screenEnter, DateTime.now()),
      );
      result = await recorder.stopSession();

      final screenshot = result.localArtifacts.firstWhere(
        (a) => a.kind == ArtifactKind.screenshot,
      );
      jpegBytes = await File(screenshot.path).readAsBytes();

      final metadata = result.localArtifacts.singleWhere(
        (a) => a.kind == ArtifactKind.timelineJson,
      );
      json = jsonDecode(await File(metadata.path).readAsString());
    });

    final screenshots = result.localArtifacts
        .where((a) => a.kind == ArtifactKind.screenshot)
        .toList();
    expect(screenshots, hasLength(1));
    expect(screenshots.first.sizeBytes, greaterThan(0));
    expect(jpegBytes[0], 0xFF);
    expect(jpegBytes[1], 0xD8);

    expect(json['events'], hasLength(1));
    expect(json['events'][0]['type'], 'SCREEN_ENTER');
    expect(json['events'][0]['screenshot'], startsWith('frames/'));

    expect(result.metrics.eventCount, 1);
    expect(result.metrics.totalPayloadBytes, greaterThan(0));
  });

  testWidgets(
    'PlaygroundController fires screenEnter on the first frame without crashing',
    (tester) async {
      late Directory tempDir;
      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('hybrid_test');
      });
      addTearDown(() => tempDir.delete(recursive: true));

      final recorder = HybridRecorderImpl(
        minCaptureInterval: Duration.zero,
        baseDirectory: () async => tempDir,
      );
      final controller = PlaygroundController(
        recorder: recorder,
        chunkUploadCoordinator: ChunkUploadCoordinator(
          chunkUploadQueue: AsyncUploadQueue(),
          sessionChunkStore: SessionChunkStore(),
          driveUploadRepository: GoogleDriveUploadRepositoryImpl(),
        ),
      );
      addTearDown(controller.dispose);

      late RecordingSessionResult result;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: _PlaygroundHost(controller: controller)),
        );
        // Lets the post-frame callback's chain (await started; then
        // fireScreenEnter's capture) finish before we stop the session.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        result = await recorder.stopSession();
      });

      expect(tester.takeException(), isNull);
      expect(result.metrics.eventCount, 1);
      final screenshots = result.localArtifacts.where(
        (a) => a.kind == ArtifactKind.screenshot,
      );
      expect(screenshots, hasLength(1));
      expect(screenshots.first.sizeBytes, greaterThan(0));
    },
  );
}
