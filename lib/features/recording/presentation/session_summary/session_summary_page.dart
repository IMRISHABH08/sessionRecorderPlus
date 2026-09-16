import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/recording_session_result.dart';
import '../shared/session_metrics_details.dart';
import 'components/remote_inspection_card.dart';

// Only Clarity's flow reaches this page now — Hybrid and widget_recorder_plus
// auto-upload chunks in the background and return straight to Home instead
// (see PlaygroundController.supportsChunking).
class SessionSummaryPage extends StatelessWidget {
  const SessionSummaryPage({super.key, required this.result});

  final RecordingSessionResult result;

  @override
  Widget build(BuildContext context) {
    final remote = result.remoteInspection;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sessionSummaryTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              result.metrics.implementationName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            SessionMetricsDetails(
              metrics: result.metrics,
              localArtifacts: result.localArtifacts,
            ),
            const SizedBox(height: 24),
            if (remote != null) RemoteInspectionCard(descriptor: remote),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text(AppStrings.backToHomeButton),
            ),
          ],
        ),
      ),
    );
  }
}
