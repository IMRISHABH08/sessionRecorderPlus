import 'dart:async';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/recording/domain/usecase/chunk_upload_coordinator.dart';

void main() {
  runZonedGuarded(_init, _onZoneError);
}

Future<void> _init() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupErrorHandlers();
  setupInjection();

  unawaited(getIt<ChunkUploadCoordinator>().resumePendingUploads());
  runApp(
    ClarityWidget(
      app: const RecorderComparisonApp(),
      clarityConfig: ClarityConfig(
        projectId: _clarityProjectId,
        logLevel: LogLevel.None,
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => Clarity.pause());
}

void _setupErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('💥 Flutter error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('💥 Platform error: $error\n$stack');
    return true;
  };
}

void _onZoneError(Object error, StackTrace stack) =>
    debugPrint('💥 Zone error: $error\n$stack');

class RecorderComparisonApp extends StatelessWidget {
  const RecorderComparisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.homeTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

String get _clarityProjectId =>
    String.fromEnvironment('CLARITY_PROJECT_ID', defaultValue: '');
