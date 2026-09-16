import 'package:flutter/widgets.dart';

import '../entities/recorder_event.dart';
import '../entities/recording_session_result.dart';

abstract class SessionRecorder {
  String get displayName;

  // False for Clarity: its session is continuous and server-managed, so it
  // doesn't fit a "finalize this chunk and start the next one" model.
  bool get supportsChunking => false;

  Future<void> startSession();

  // Ends the current chunk AND immediately starts the next one, so
  // recording never visibly pauses. Only called when supportsChunking.
  Future<RecordingSessionResult> finalizeChunk();

  // Ends the current chunk without starting another. Must be idempotent.
  Future<RecordingSessionResult> stopSession();

  void recordEvent(RecorderEvent event) {}

  // Identity by default; Clarity instruments the app root, not this screen.
  Widget wrapContent(Widget child) => child;

  void dispose() {}
}
