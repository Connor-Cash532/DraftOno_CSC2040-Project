import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:draft_ono_app/setup_page.dart';

// Opens the setup page in a desktop-sized test window.
Future<void> pumpSetupPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: SetupPage()));
}

// Sets the slider to a value the same way dragging it would.
Future<void> setTimerSlider(WidgetTester tester, double seconds) async {
  final slider = tester.widget<Slider>(find.byKey(const Key('timerSlider')));
  slider.onChanged!(seconds);
  await tester.pump();
}

Future<void> startDraft(WidgetTester tester) async {
  await tester.tap(find.text('Start draft'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Timer slider defaults to 120 seconds', (tester) async {
    await pumpSetupPage(tester);

    expect(find.text('Pick timer: 120 seconds'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byKey(const Key('timerSlider')));
    expect(slider.value, 120);
  });

  testWidgets('Moving the slider updates the displayed time', (tester) async {
    await pumpSetupPage(tester);

    await setTimerSlider(tester, 60);

    expect(find.text('Pick timer: 60 seconds'), findsOneWidget);
  });

  testWidgets('Slider is limited to 30 to 300 seconds', (tester) async {
    await pumpSetupPage(tester);

    final slider = tester.widget<Slider>(find.byKey(const Key('timerSlider')));
    expect(slider.min, 30);
    expect(slider.max, 300);
  });

  testWidgets('Draft timer starts at the default 120 seconds', (tester) async {
    await pumpSetupPage(tester);

    await startDraft(tester);

    expect(find.text('120'), findsOneWidget);
  });

  testWidgets('Draft timer starts at the time chosen on the setup page',
      (tester) async {
    await pumpSetupPage(tester);

    await setTimerSlider(tester, 60);
    await startDraft(tester);

    expect(find.text('60'), findsOneWidget);
  });

  testWidgets('Reset returns the timer to the chosen time, not 120',
      (tester) async {
    await pumpSetupPage(tester);

    await setTimerSlider(tester, 60);
    await startDraft(tester);

    // Run the timer for 3 seconds.
    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('57'), findsOneWidget);

    // Reset also stops the timer, so no timer is left running when the test ends.
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('60'), findsOneWidget);
  });
}
