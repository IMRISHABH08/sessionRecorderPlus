import 'dart:convert';
import 'dart:io';

import '../../../../../core/constants/app_strings.dart';
import '../../../domain/entities/recorder_event.dart';

class TimelineEntry {
  const TimelineEntry({
    required this.timestampSeconds,
    required this.type,
    this.screenshotRelativePath,
    this.data = const {},
  });

  final double timestampSeconds;
  final RecorderEventType type;
  final String? screenshotRelativePath;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'timestamp': timestampSeconds,
    'type': type.wireName,
    if (screenshotRelativePath != null) 'screenshot': screenshotRelativePath,
    ...data,
  };
}

class SessionTimeline {
  SessionTimeline({required this.sessionId, required this.sessionDir});

  final String sessionId;
  final Directory sessionDir;

  final List<TimelineEntry> _entries = [];
  int _frameCount = 0;

  Directory get framesDir =>
      Directory('${sessionDir.path}/${StorageNames.framesDir}');

  List<TimelineEntry> get entries => List.unmodifiable(_entries);

  String allocateFrameFileName() {
    final name = '${_frameCount.toString().padLeft(3, '0')}.jpg';
    _frameCount++;
    return name;
  }

  void addEntry(TimelineEntry entry) => _entries.add(entry);

  int get screenshotCount =>
      _entries.where((e) => e.screenshotRelativePath != null).length;

  Future<File> writeMetadata({
    required DateTime startedAt,
    required Duration duration,
  }) async {
    final file = File(
      '${sessionDir.path}/${StorageNames.sessionTimelineFile}',
    );
    final json = {
      'sessionId': sessionId,
      'startedAt': startedAt.toIso8601String(),
      'duration': duration.inSeconds,
      'events': _entries.map((e) => e.toJson()).toList(),
    };
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(json));
    return file;
  }
}
