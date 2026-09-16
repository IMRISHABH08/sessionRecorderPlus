import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../domain/entities/recorder_event.dart';
import '../../../domain/entities/recording_session_result.dart';
import '../../../domain/entities/session_metrics.dart';
import '../../../domain/repository/session_recorder.dart';
import 'screenshot_capture.dart';
import 'session_timeline.dart';

class HybridRecorderImpl extends SessionRecorder {
  HybridRecorderImpl({
    this.minCaptureInterval = const Duration(milliseconds: 500),
    Future<Directory> Function()? baseDirectory,
  }) : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  final Duration minCaptureInterval;
  final Future<Directory> Function() _baseDirectory;
  final GlobalKey _boundaryKey = GlobalKey();
  final ScreenshotCapture _screenshotCapture = const ScreenshotCapture();

  SessionTimeline? _timeline;
  DateTime? _startedAt;
  DateTime? _lastCaptureAt;
  Future<void>? _pendingCapture;
  bool _stopped = false;

  @override
  String get displayName => 'Hybrid: screenshots + timeline';

  @override
  bool get supportsChunking => true;

  @override
  Future<void> startSession() => _startNewChunk();

  Future<void> _startNewChunk() async {
    final startedAt = DateTime.now();
    _startedAt = startedAt;
    _lastCaptureAt = null;
    _pendingCapture = null;
    final sessionId = startedAt.millisecondsSinceEpoch.toString();
    final docsDir = await _baseDirectory();
    final sessionDir = Directory(
      '${docsDir.path}/${StorageNames.sessionsDir}/$sessionId',
    );
    await sessionDir.create(recursive: true);
    _timeline = SessionTimeline(sessionId: sessionId, sessionDir: sessionDir);
  }

  @override
  void recordEvent(RecorderEvent event) {
    final timeline = _timeline;
    final startedAt = _startedAt;
    final notRecording = timeline == null || startedAt == null || _stopped;
    if (notRecording) return;

    final elapsedSeconds =
        event.timestamp.difference(startedAt).inMilliseconds / 1000.0;

    final withinCooldown = _lastCaptureAt != null &&
        event.timestamp.difference(_lastCaptureAt!) < minCaptureInterval;

    if (withinCooldown) {
      timeline.addEntry(
        TimelineEntry(
          timestampSeconds: elapsedSeconds,
          type: event.type,
          data: event.data,
        ),
      );
      return;
    }

    _lastCaptureAt = event.timestamp;
    final frameFileName = timeline.allocateFrameFileName();
    _pendingCapture = _captureAndAppend(
      timeline,
      frameFileName,
      elapsedSeconds,
      event,
    );
  }

  Future<void> _captureAndAppend(
    SessionTimeline timeline,
    String frameFileName,
    double elapsedSeconds,
    RecorderEvent event,
  ) async {
    final framePath = '${timeline.framesDir.path}/$frameFileName';
    final bytes = await _screenshotCapture.captureToFile(
      _boundaryKey,
      framePath,
    );
    timeline.addEntry(
      TimelineEntry(
        timestampSeconds: elapsedSeconds,
        type: event.type,
        screenshotRelativePath: bytes != null ? 'frames/$frameFileName' : null,
        data: event.data,
      ),
    );
  }

  @override
  Widget wrapContent(Widget child) =>
      RepaintBoundary(key: _boundaryKey, child: child);

  @override
  Future<RecordingSessionResult> finalizeChunk() async {
    final result = await _finalizeCurrentChunk();
    await _startNewChunk();
    return result;
  }

  @override
  Future<RecordingSessionResult> stopSession() async {
    if (_stopped) return _buildResult();
    _stopped = true;
    return _finalizeCurrentChunk();
  }

  Future<RecordingSessionResult> _finalizeCurrentChunk() async {
    await _pendingCapture;
    final timeline = _timeline;
    final startedAt = _startedAt ?? DateTime.now();
    if (timeline != null) {
      await timeline.writeMetadata(
        startedAt: startedAt,
        duration: DateTime.now().difference(startedAt),
      );
    }
    return _buildResult();
  }

  Future<RecordingSessionResult> _buildResult() async {
    final timeline = _timeline;
    final startedAt = _startedAt ?? DateTime.now();
    final duration = DateTime.now().difference(startedAt);
    final artifacts = <LocalArtifact>[];

    if (timeline != null) {
      final metadataFile = File(
        '${timeline.sessionDir.path}/${StorageNames.sessionTimelineFile}',
      );
      if (await metadataFile.exists()) {
        artifacts.add(
          LocalArtifact(
            path: metadataFile.path,
            kind: ArtifactKind.timelineJson,
            sizeBytes: await metadataFile.length(),
          ),
        );
      }
      if (await timeline.framesDir.exists()) {
        await for (final entity in timeline.framesDir.list()) {
          if (entity is File) {
            artifacts.add(
              LocalArtifact(
                path: entity.path,
                kind: ArtifactKind.screenshot,
                sizeBytes: await entity.length(),
              ),
            );
          }
        }
      }
    }

    return RecordingSessionResult(
      metrics: SessionMetrics(
        implementationName: displayName,
        startedAt: startedAt,
        duration: duration,
        totalPayloadBytes: artifacts.fold<int>(0, (sum, a) => sum + a.sizeBytes),
        eventCount: timeline?.entries.length ?? 0,
        captureMethod: CaptureMethod.eventTriggeredScreenshots,
        extra: {'screenshotCount': timeline?.screenshotCount ?? 0},
      ),
      localArtifacts: artifacts,
    );
  }

  @override
  void dispose() {}
}
