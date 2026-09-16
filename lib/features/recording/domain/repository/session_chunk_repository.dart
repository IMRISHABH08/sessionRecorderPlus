import 'package:flutter/foundation.dart';

import '../entities/session_chunk.dart';

abstract class SessionChunkRepository {
  // Upserts by id — a chunk's status changes over its lifetime
  // (queued -> uploading -> succeeded/failed).
  Future<void> save(SessionChunk chunk);

  // Live view of all persisted chunks, most-recent-first. Session Info
  // rebuilds from this directly, so status changes show up without a
  // manual refresh even while the app is elsewhere.
  ValueListenable<List<SessionChunk>> get chunks;

  Future<void> ensureLoaded();
}
