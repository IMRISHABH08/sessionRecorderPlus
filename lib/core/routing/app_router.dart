import 'package:flutter/material.dart';

import '../../features/recording/domain/entities/recorder_choice.dart';
import '../../features/recording/presentation/home/home_page.dart';
import '../../features/recording/presentation/playground/playground_page.dart';

class AppRouter {
  AppRouter._();

  static const home = '/';
  static const playground = '/playground';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case playground:
        final choice = settings.arguments as RecorderChoice;
        return MaterialPageRoute(
          builder: (_) => PlaygroundPage(choice: choice),
        );
      case home:
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}
