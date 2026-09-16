import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/recording_session_result.dart';
import '../../domain/entities/session_chunk.dart';
import '../../domain/entities/session_metrics.dart';
import '../../domain/repository/session_chunk_repository.dart';

// JSON-array file under app documents dir, rewritten in full on every save.
// Simple read-modify-write is fine at this app's scale (a handful of
// chunks per session, not a high-frequency production log).
class SessionChunkStore implements SessionChunkRepository {
  SessionChunkStore({Future<Directory> Function()? baseDirectory})
    : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDirectory;
  final ValueNotifier<List<SessionChunk>> _chunks = ValueNotifier([]);
  bool _loaded = false;
  Future<File>? _fileFuture;

  @override
  ValueListenable<List<SessionChunk>> get chunks => _chunks;

  Future<File> _file() {
    return _fileFuture ??= _baseDirectory().then(
      (dir) => File('${dir.path}/${StorageNames.sessionChunksFile}'),
    );
  }

  @override
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final file = await _file();
    if (!await file.exists()) return;
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _chunks.value = list.map(_chunkFromJson).toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  @override
  Future<void> save(SessionChunk chunk) async {
    await ensureLoaded();
    final updated = [..._chunks.value];
    final index = updated.indexWhere((c) => c.id == chunk.id);
    if (index >= 0) {
      updated[index] = chunk;
    } else {
      updated.add(chunk);
    }
    updated.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    _chunks.value = updated;

    final file = await _file();
    await file.writeAsString(
      jsonEncode(updated.map(_chunkToJson).toList()),
    );
  }

  Map<String, dynamic> _chunkToJson(SessionChunk c) => {
    'id': c.id,
    'approachName': c.approachName,
    'screenName': c.screenName,
    'capturedAt': c.capturedAt.toIso8601String(),
    'indexValue': c.indexValue,
    'status': c.status.name,
    'driveLinks': c.driveLinks,
    'errorMessage': c.errorMessage,
    'metrics': {
      'implementationName': c.metrics.implementationName,
      'startedAt': c.metrics.startedAt.toIso8601String(),
      'durationMs': c.metrics.duration.inMilliseconds,
      'totalPayloadBytes': c.metrics.totalPayloadBytes,
      'eventCount': c.metrics.eventCount,
      'captureMethod': c.metrics.captureMethod.name,
      'extra': c.metrics.extra,
    },
    'localArtifacts': c.localArtifacts
        .map(
          (a) => {'path': a.path, 'kind': a.kind.name, 'sizeBytes': a.sizeBytes},
        )
        .toList(),
  };

  SessionChunk _chunkFromJson(Map<String, dynamic> json) {
    final metricsJson = json['metrics'] as Map<String, dynamic>;
    final artifactsJson = (json['localArtifacts'] as List)
        .cast<Map<String, dynamic>>();

    return SessionChunk(
      id: json['id'] as String,
      approachName: json['approachName'] as String,
      screenName: json['screenName'] as String? ?? 'playground',
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      indexValue: json['indexValue'] as int? ?? 0,
      status: ChunkUploadStatus.values.byName(json['status'] as String),
      driveLinks: (json['driveLinks'] as List?)?.cast<String>(),
      errorMessage: json['errorMessage'] as String?,
      metrics: SessionMetrics(
        implementationName: metricsJson['implementationName'] as String,
        startedAt: DateTime.parse(metricsJson['startedAt'] as String),
        duration: Duration(milliseconds: metricsJson['durationMs'] as int),
        totalPayloadBytes: metricsJson['totalPayloadBytes'] as int?,
        eventCount: metricsJson['eventCount'] as int,
        captureMethod: CaptureMethod.values.byName(
          metricsJson['captureMethod'] as String,
        ),
        extra: (metricsJson['extra'] as Map).cast<String, dynamic>(),
      ),
      localArtifacts: artifactsJson
          .map(
            (a) => LocalArtifact(
              path: a['path'] as String,
              kind: ArtifactKind.values.byName(a['kind'] as String),
              sizeBytes: a['sizeBytes'] as int,
            ),
          )
          .toList(),
    );
  }
}
