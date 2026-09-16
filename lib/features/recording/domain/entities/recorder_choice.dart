enum RecorderChoice { hybrid, widgetPlus, clarity }

extension RecorderChoiceLabels on RecorderChoice {
  String get title => switch (this) {
    RecorderChoice.hybrid => 'Hybrid: screenshots + timeline',
    RecorderChoice.widgetPlus => 'widget_recorder_plus: video',
    RecorderChoice.clarity => 'Microsoft Clarity: session replay',
  };

  String get subtitle => switch (this) {
    RecorderChoice.hybrid =>
      'Event-triggered screenshots + a JSON timeline. No third-party package.',
    RecorderChoice.widgetPlus =>
      'Records the playground as an MP4 via native H.264 encoding.',
    RecorderChoice.clarity =>
      'Session replay reconstructed on Clarity\'s servers, no local file.',
  };
}
