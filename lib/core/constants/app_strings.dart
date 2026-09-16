// User-facing copy and cross-file string identifiers, centralized so no
// two places can silently drift on the same piece of text.
abstract final class AppStrings {
  // Page titles
  static const homeTitle = 'Recorder comparison';
  static const sessionInfoTitle = 'Session info';
  static const sessionSummaryTitle = 'Session summary';

  // Home page
  static const homeDescription =
      'Pick an approach and run the same scenario. Hybrid and '
      'widget_recorder_plus record continuously in 30s chunks, '
      'auto-uploaded in the background — check progress anytime '
      'in Session Info. Compare results in recorderPlan.md.';

  // Tooltips
  static const sessionInfoTooltip = 'Session info';
  static const endSessionTooltip = 'End session';

  // Playground scenario
  static const showDialogButton = 'Show dialog';
  static const dialogAppearedTitle = 'A dialog appeared';
  static const dialogAppearedContent =
      'The hybrid approach captures a screenshot for moments like '
      'this; the video approach simply has it in-frame.';
  static const closeButton = 'Close';
  static const scrollableItemPrefix = 'Scrollable item';
  static const scrollableItemSubtitle = 'Part of the shared test scenario';
  static const applyButton = 'Apply';
  static const appliedButton = 'Applied';

  // Session summary
  static const backToHomeButton = 'Back to home';
  static const openClaritySessionButton = 'Open Clarity session';

  // Session info — empty states
  static const noSessionsYetTitle = 'No sessions yet';
  static const noSessionsYetDescription =
      'Record with Hybrid or widget_recorder_plus and each chunk '
      'will show up here as it uploads.';
  static const noSessionsForApproachTitle = 'No sessions for this approach yet';
  static const approachFilterAllLabel = 'All';

  // Session info — chunk stat labels
  static const retryUploadButton = 'Retry upload';
  static const chunkScreenLabel = 'Screen';
  static const chunkIndexLabel = 'Chunk index';
  static const chunkIdLabel = 'Chunk ID';

  // Shared session-metrics stat labels
  static const payloadSizeLabel = 'Payload size';
  static const durationLabel = 'Duration';
  static const eventsLabel = 'Events';
  static const captureMethodLabel = 'Capture method';
  static const effectiveBitrateLabel = 'Effective bitrate';
  static const screenshotsCapturedLabel = 'Screenshots captured';
  static const artifactsHeading = 'Artifacts';

  // Playground header
  static const playgroundHeaderImageUrl =
      'https://picsum.photos/seed/azodha/800/450';
}

// On-device file/folder names — a chunk's artifacts, its zip, and Drive's
// folder structure all key off these, so a rename here is the one place
// that needs to change.
abstract final class StorageNames {
  static const driveRootFolder = 'AzodhaRecordings';
  static const sessionChunksFile = 'session_chunks.json';
  static const sessionTimelineFile = 'session_timeline.json';
  static const chunkMetadataFile = 'metadata.json';
  static const sessionsDir = 'sessions';
  static const framesDir = 'frames';
  static const chunkMetadataDir = 'chunk_metadata';
  static const chunkUploadsDir = 'chunk_uploads';
}

// snake_case keys of the metadata JSON uploaded with every chunk (both as
// the Drive file's `description` and as the bundled metadata.json) — a
// server-facing wire format, so these must stay in lockstep with whatever
// reads them.
abstract final class ChunkMetadataKeys {
  static const chunkId = 'chunk_id';
  static const screen = 'screen';
  static const approach = 'approach';
  static const capturedAt = 'captured_at';
  static const index = 'index';
  static const durationMs = 'duration_ms';
}
