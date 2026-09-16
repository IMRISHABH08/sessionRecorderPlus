import 'package:clarity_flutter/clarity_flutter.dart';

import '../../../domain/entities/recorder_event.dart';
import '../../../domain/entities/recording_session_result.dart';
import '../../../domain/entities/session_metrics.dart';
import '../../../domain/repository/session_recorder.dart';

// Identity wrapContent: Clarity instruments the app root (see main.dart's
// ClarityWidget), not a single screen's RepaintBoundary.
class ClarityRecorderImpl extends SessionRecorder {
  DateTime? _startedAt;
  String? _claritySessionId;
  int _eventCount = 0;

  @override
  String get displayName => 'Microsoft Clarity: session replay';

  @override
  Future<void> startSession() async {
    _startedAt = DateTime.now();
    _eventCount = 0;
    Clarity.resume();
    Clarity.setCurrentScreenName('playground');
    Clarity.startNewSession((sessionId) => _claritySessionId = sessionId);
  }

  @override
  void recordEvent(RecorderEvent event) {
    Clarity.sendCustomEvent(event.type.wireName);
    _eventCount++;
  }

  @override
  Future<RecordingSessionResult> finalizeChunk() {
    throw UnsupportedError(
      'Clarity does not support chunking — its session is continuous and '
      'server-managed. supportsChunking is false, so this should never '
      'actually be called.',
    );
  }

  @override
  Future<RecordingSessionResult> stopSession() async {
    final startedAt = _startedAt ?? DateTime.now();
    Clarity.pause();
    final sessionUrl = Clarity.getCurrentSessionUrl();

    return RecordingSessionResult(
      metrics: SessionMetrics(
        implementationName: displayName,
        startedAt: startedAt,
        duration: DateTime.now().difference(startedAt),
        totalPayloadBytes: null,
        eventCount: _eventCount,
        captureMethod: CaptureMethod.remoteSdkTelemetry,
        extra: {
          if (_claritySessionId != null) 'claritySessionId': _claritySessionId,
        },
      ),
      remoteInspection: RemoteInspectionDescriptor(
        label: 'Clarity session',
        url: sessionUrl,
        instructions: sessionUrl != null
            ? 'Open the session in the Clarity dashboard below.'
            : 'Session uploads once the device is next online; check the '
                'Clarity dashboard for this project in a couple of minutes.',
      ),
    );
  }

  @override
  void dispose() {}
}
