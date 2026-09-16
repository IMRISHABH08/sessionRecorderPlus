import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:azodha/features/recording/data/recorder/hybrid/hybrid_recorder_impl.dart';

void main() {
  test('finalizeChunk ends the current chunk and starts a fresh one', () async {
    final tempDir = await Directory.systemTemp.createTemp('chunk_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final recorder = HybridRecorderImpl(baseDirectory: () async => tempDir);
    await recorder.startSession();

    final firstChunk = await recorder.finalizeChunk();
    final secondChunk = await recorder.stopSession();

    // Each chunk always gets a session_timeline.json, even with zero events.
    final firstMetadataPath = firstChunk.localArtifacts.first.path;
    final secondMetadataPath = secondChunk.localArtifacts.first.path;
    expect(firstMetadataPath, isNot(equals(secondMetadataPath)));

    expect(await File(firstMetadataPath).exists(), isTrue);
    expect(await File(secondMetadataPath).exists(), isTrue);
  });

  test('supportsChunking is true for the hybrid recorder', () {
    expect(HybridRecorderImpl().supportsChunking, isTrue);
  });
}
