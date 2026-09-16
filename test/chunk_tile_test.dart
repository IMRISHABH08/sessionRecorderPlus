import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:azodha/features/recording/domain/entities/recording_session_result.dart';
import 'package:azodha/features/recording/domain/entities/session_chunk.dart';
import 'package:azodha/features/recording/domain/entities/session_metrics.dart';
import 'package:azodha/features/recording/presentation/session_info/components/chunk_tile.dart';

void main() {
  testWidgets('expanded ChunkTile renders the stat grid without overflowing', (
    tester,
  ) async {
    final chunk = SessionChunk(
      id: '1',
      approachName: 'widget_recorder_plus: video',
      screenName: 'playground',
      capturedAt: DateTime(2026, 8, 29, 11, 59),
      indexValue: 0,
      metrics: SessionMetrics(
        implementationName: 'widget_recorder_plus: video',
        startedAt: DateTime(2026, 8, 29, 11, 59),
        duration: const Duration(seconds: 11),
        totalPayloadBytes: 442368,
        eventCount: 0,
        captureMethod: CaptureMethod.nativeVideoEncoding,
      ),
      localArtifacts: const [
        LocalArtifact(
          path: '/tmp/widget_rec_1787984996247.mp4',
          kind: ArtifactKind.video,
          sizeBytes: 442368,
        ),
      ],
      status: ChunkUploadStatus.succeeded,
      driveLinks: const ['https://drive.google.com/file/d/12KDY46mExampleId/view'],
    );

    // Same nested width constraint as the real Session Info list: a
    // 375-wide phone body with 16px page padding on each side.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 375,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [ChunkTile(chunk: chunk, onRetry: () {})],
            ),
          ),
        ),
      ),
    );

    // Expand the tile so the stat grid (the thing that overflowed before)
    // actually builds and lays out.
    await tester.tap(find.text('widget_recorder_plus: video'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('432.0 KB'), findsWidgets);
    expect(find.text('0m 11s'), findsOneWidget);
  });
}
