import 'package:flutter_test/flutter_test.dart';

import 'package:azodha/main.dart';

void main() {
  testWidgets('Home page lists the non-Clarity recorder approaches', (
    tester,
  ) async {
    await tester.pumpWidget(const RecorderComparisonApp());

    expect(find.text('Recorder comparison'), findsWidgets);
    expect(find.text('Hybrid: screenshots + timeline'), findsOneWidget);
    expect(find.text('widget_recorder_plus: video'), findsOneWidget);
    // Clarity is hidden from the home page, not removed — its code path
    // stays reachable, just not linked from here.
    expect(find.text('Microsoft Clarity: session replay'), findsNothing);
  });
}
