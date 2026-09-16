import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/recorder_event.dart';
import '../../domain/entities/recording_session_result.dart';
import '../../domain/repository/session_recorder.dart';
import '../../domain/usecase/chunk_upload_coordinator.dart';
import 'session_timer.dart';

// Lives here, not per-recorder, so every approach reacts to the exact same
// scroll behaviour and results stay comparable.
const double kSignificantScrollThresholdPx = 150;

class PlaygroundController extends ChangeNotifier {
  PlaygroundController({
    required this.recorder,
    required this.chunkUploadCoordinator,
    this.screenName = AppRouter.playground,
    this.chunkDuration = const Duration(seconds: 30),
    this.legacyMaxDuration = const Duration(minutes: 5),
  }) : legacyTimer = SessionTimer(cap: legacyMaxDuration);

  final SessionRecorder recorder;
  final ChunkUploadCoordinator chunkUploadCoordinator;

  // Which app screen this recording started on — travels with every
  // chunk's metadata so a server can tell where each recording came from.
  final String screenName;

  // Only meaningful when recorder.supportsChunking.
  final Duration chunkDuration;

  // Only meaningful for non-chunking recorders (Clarity) — its flow is
  // otherwise untouched by the auto-chunking work.
  final Duration legacyMaxDuration;

  Timer? _chunkTimer;

  // Created eagerly (not inside start()) so the UI can safely bind to it
  // from the very first frame, before start()'s async work has resolved —
  // only .start()-ing it is deferred to start().
  final SessionTimer legacyTimer;
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  Timer? _elapsedTicker;
  DateTime? _recordingStartedAt;

  // A real, visible state change on tap — not just a silently-recorded
  // event — so there's something for the recorders to actually capture.
  final ValueNotifier<bool> applied = ValueNotifier(false);

  double _scrollSinceLastFire = 0;
  bool _ended = false;

  // Only populated (and only meaningful) for non-chunking recorders —
  // chunked mode never navigates to a summary page.
  RecordingSessionResult? result;

  bool get supportsChunking => recorder.supportsChunking;

  bool get hasEnded => _ended;

  Future<void> start() async {
    await recorder.startSession();
    _recordingStartedAt = DateTime.now();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value = DateTime.now().difference(_recordingStartedAt!);
    });

    if (supportsChunking) {
      _chunkTimer = Timer.periodic(chunkDuration, (_) => _rotateChunk());
    } else {
      legacyTimer.start(() {
        unawaited(endSession());
      });
    }
  }

  bool _rotating = false;
  int _chunkIndex = 0;

  Future<void> _rotateChunk() async {
    final shouldSkipRotation = _ended || _rotating;
    if (shouldSkipRotation) return;
    _rotating = true;
    try {
      final chunkResult = await recorder.finalizeChunk();
      unawaited(
        chunkUploadCoordinator.enqueueNewChunk(
          chunkResult,
          screenName: screenName,
          indexValue: _chunkIndex++,
        ),
      );
    } finally {
      _rotating = false;
    }
  }

  void onScrollDelta(double delta, double pixels) {
    _scrollSinceLastFire += delta.abs();
    if (_scrollSinceLastFire < kSignificantScrollThresholdPx) return;
    final firedDelta = _scrollSinceLastFire.round();
    _scrollSinceLastFire = 0;
    _fire(
      RecorderEventType.significantScroll,
      data: {'offset': pixels.round(), 'delta': firedDelta},
    );
  }

  void onDialogOpen() => _fire(RecorderEventType.dialogOpen);

  void onDialogClose() => _fire(RecorderEventType.dialogClose);

  void onCtaTap() {
    applied.value = !applied.value;
    _fire(
      RecorderEventType.tap,
      data: {'target': 'apply_button', 'applied': applied.value},
    );
  }

  void onItemTap(String label) =>
      _fire(RecorderEventType.navigation, data: {'target': label});

  void fireScreenEnter() =>
      _fire(RecorderEventType.screenEnter, data: {'screen': screenName});

  void _fire(RecorderEventType type, {Map<String, dynamic> data = const {}}) {
    if (_ended) return;
    recorder.recordEvent(RecorderEvent(type, DateTime.now(), data: data));
  }

  Future<void> endSession() async {
    if (_ended) return;
    _ended = true;
    _elapsedTicker?.cancel();

    if (supportsChunking) {
      _chunkTimer?.cancel();
      final finalChunk = await recorder.stopSession();
      unawaited(
        chunkUploadCoordinator.enqueueNewChunk(
          finalChunk,
          screenName: screenName,
          indexValue: _chunkIndex++,
        ),
      );
    } else {
      legacyTimer.cancel();
      result = await recorder.stopSession();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _chunkTimer?.cancel();
    legacyTimer.dispose();
    _elapsedTicker?.cancel();
    elapsed.dispose();
    applied.dispose();
    recorder.dispose();
    super.dispose();
  }
}
