import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';

import '../../../domain/entities/recorder_event.dart';
import '../../../domain/entities/recording_session_result.dart';
import '../../../domain/entities/session_metrics.dart';
import '../../../domain/repository/session_recorder.dart';

class WidgetRecorderPlusImpl extends SessionRecorder {
  late final WidgetRecorderController _controller;
  Completer<String?>? _completion;
  DateTime? _startedAt;
  bool _initialized = false;
  bool _stopped = false;
  RecordingSessionResult? _lastResult;

  @override
  String get displayName => 'widget_recorder_plus: video';

  @override
  bool get supportsChunking => true;

  void _ensureController() {
    if (_initialized) return;
    _initialized = true;
    _controller = WidgetRecorderController(
      recordAudio: false,
      // The package can call both onComplete and onError for a single
      // stop() (observed: onComplete fires with the saved path, then
      // onError fires anyway) — guard against completing twice.
      onComplete: (path) {
        if (_completion?.isCompleted == false) _completion?.complete(path);
      },
      onError: (error) {
        if (_completion?.isCompleted == false) {
          _completion?.completeError(Exception(error));
        }
      },
    );
    _controller.applyVideoQuality(VideoQuality.medium);
  }

  @override
  Future<void> startSession() async {
    _ensureController();
    _startedAt = DateTime.now();
    await _controller.start();
  }

  @override
  void recordEvent(RecorderEvent event) {}

  @override
  Widget wrapContent(Widget child) =>
      WidgetRecorder(controller: _controller, child: child);

  @override
  Future<RecordingSessionResult> finalizeChunk() async {
    final startedAt = _startedAt ?? DateTime.now();
    final completion = Completer<String?>();
    _completion = completion;

    // EXPERIMENTAL: stop() and start() fired concurrently rather than
    // sequentially. The package's native stopRecording call appears to
    // block its platform thread for several seconds finalizing the MP4
    // (observed: 15s+), which freezes the UI regardless of how Dart
    // sequences its own awaits — this doesn't fix that block. What it can
    // help is the *recording gap*: previously the next chunk couldn't
    // start() until stop() fully resolved, so a 15s native stall meant
    // 15s of real content silently not being recorded, not just 15s of
    // frozen UI. Dispatching start() immediately, without waiting behind
    // that stall, should shrink that gap.
    //
    // Real risk: the native side now briefly handles a startRecording
    // call while the previous stopRecording may still be finalizing. If
    // that's not reentrant-safe, watch for a corrupted/truncated video or
    // a dropped chunk. Revert to sequential stop() then start() if so.
    // Not awaited: completion is already tracked via the controller's own
    // onComplete/onError callbacks feeding `completion` above. Errors are
    // swallowed here specifically because they're not; this just stops an
    // unawaited Future's failure from surfacing as an unhandled exception.
    unawaited(_controller.stop().catchError((_) => null));
    final endedAt = DateTime.now();

    _startedAt = DateTime.now();
    await _controller.start();

    final path = await _awaitSavedPath(completion);
    return _buildResult(startedAt: startedAt, endedAt: endedAt, path: path);
  }

  @override
  Future<RecordingSessionResult> stopSession() async {
    if (_stopped) return _lastResult!;
    _stopped = true;

    final startedAt = _startedAt ?? DateTime.now();
    final completion = Completer<String?>();
    _completion = completion;

    await _controller.stop();
    final endedAt = DateTime.now();

    final path = await _awaitSavedPath(completion);
    final result = _buildResult(startedAt: startedAt, endedAt: endedAt, path: path);
    _lastResult = result;
    return result;
  }

  Future<String?> _awaitSavedPath(Completer<String?> completion) async {
    try {
      return await completion.future.timeout(const Duration(seconds: 30));
    } catch (_) {
      return null;
    }
  }

  RecordingSessionResult _buildResult({
    required DateTime startedAt,
    required DateTime endedAt,
    required String? path,
  }) {
    final duration = endedAt.difference(startedAt);
    final artifacts = <LocalArtifact>[];
    if (path != null) {
      final file = File(path);
      final sizeBytes = file.existsSync() ? file.lengthSync() : null;
      if (sizeBytes != null) {
        artifacts.add(
          LocalArtifact(path: path, kind: ArtifactKind.video, sizeBytes: sizeBytes),
        );
      }
    }

    return RecordingSessionResult(
      metrics: SessionMetrics(
        implementationName: displayName,
        startedAt: startedAt,
        duration: duration,
        totalPayloadBytes: artifacts.isNotEmpty ? artifacts.first.sizeBytes : null,
        eventCount: 0,
        captureMethod: CaptureMethod.nativeVideoEncoding,
      ),
      localArtifacts: artifacts,
    );
  }

  @override
  void dispose() {
    if (_initialized) _controller.dispose();
  }
}
