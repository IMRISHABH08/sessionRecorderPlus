import 'package:get_it/get_it.dart';

import '../../features/recording/data/recorder/clarity/clarity_recorder_impl.dart';
import '../../features/recording/data/recorder/hybrid/hybrid_recorder_impl.dart';
import '../../features/recording/data/recorder/widget_recorder_plus/widget_recorder_plus_impl.dart';
import '../../features/recording/data/session_info/session_chunk_store.dart';
import '../../features/recording/data/upload/google_drive_upload_repository_impl.dart';
import '../../features/recording/domain/entities/recorder_choice.dart';
import '../../features/recording/domain/repository/upload_repository.dart';
import '../../features/recording/domain/repository/session_chunk_repository.dart';
import '../../features/recording/domain/repository/session_recorder.dart';
import '../../features/recording/domain/usecase/chunk_upload_coordinator.dart';
import '../../features/recording/presentation/controller/playground_controller.dart';
import '../services/async_queue.dart';
import '../services/async_upload_queue.dart';

final getIt = GetIt.instance;

void setupInjection() {
  getIt.registerLazySingleton<UploadRepository>(
    () => GoogleDriveUploadRepositoryImpl(),
  );
  getIt.registerLazySingleton<SessionChunkRepository>(
    () => SessionChunkStore(),
  );
  // Not tied to any page's lifetime — it must keep draining after the user
  // navigates away from the playground mid-upload.
  getIt.registerLazySingleton<AsyncQueue>(
    () => AsyncUploadQueue(),
  );
  getIt.registerLazySingleton<ChunkUploadCoordinator>(
    () => ChunkUploadCoordinator(
      chunkUploadQueue: getIt<AsyncQueue>(),
      sessionChunkStore: getIt<SessionChunkRepository>(),
      driveUploadRepository: getIt<UploadRepository>(),
    ),
  );

  getIt.registerFactory<HybridRecorderImpl>(() => HybridRecorderImpl());
  getIt.registerFactory<WidgetRecorderPlusImpl>(() => WidgetRecorderPlusImpl());
  getIt.registerFactory<ClarityRecorderImpl>(() => ClarityRecorderImpl());
}

// A fresh SessionRecorder per playground entry, so every session starts
// from clean state.
SessionRecorder createRecorder(RecorderChoice choice) => switch (choice) {
  RecorderChoice.hybrid => getIt<HybridRecorderImpl>(),
  RecorderChoice.widgetPlus => getIt<WidgetRecorderPlusImpl>(),
  RecorderChoice.clarity => getIt<ClarityRecorderImpl>(),
};

PlaygroundController createPlaygroundController(RecorderChoice choice) {
  return PlaygroundController(
    recorder: createRecorder(choice),
    chunkUploadCoordinator: getIt<ChunkUploadCoordinator>(),
  );
}
