import 'package:equatable/equatable.dart';

enum CaptureMethod {
  nativeVideoEncoding,
  eventTriggeredScreenshots,
  remoteSdkTelemetry,
}

extension CaptureMethodLabel on CaptureMethod {
  String get label => switch (this) {
    CaptureMethod.nativeVideoEncoding => 'Native video',
    CaptureMethod.eventTriggeredScreenshots => 'Event screenshots',
    CaptureMethod.remoteSdkTelemetry => 'Remote telemetry',
  };
}

class SessionMetrics extends Equatable {
  const SessionMetrics({
    required this.implementationName,
    required this.startedAt,
    required this.duration,
    required this.totalPayloadBytes,
    required this.eventCount,
    required this.captureMethod,
    this.extra = const {},
  });

  final String implementationName;
  final DateTime startedAt;
  final Duration duration;

  // Null for Clarity — payload size is unknowable client-side.
  final int? totalPayloadBytes;

  final int eventCount;
  final CaptureMethod captureMethod;
  final Map<String, dynamic> extra;

  @override
  List<Object?> get props => [
    implementationName,
    startedAt,
    duration,
    totalPayloadBytes,
    eventCount,
    captureMethod,
    extra,
  ];
}
