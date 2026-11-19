import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:draft_ono_app/main.dart';
import 'package:draft_ono_app/setup_page.dart';

// Player IDs and salaries used in these tests (from assets/Master.xlsx):
const carmeloAnthony = '19739'; // $5,522,775
const jeffMcInnis = '16637';    // $5,643,862
const mikeDunleavy = '16766';   // $5,699,479
const moochieNorris = '19865';  // $5,985,914
const joelPrzybilla = '15138';  // $4,058,978
const scotPollard = '15803';    // $9,080,740
const kevinGarnett = '16010';   // $47,887,316
const jabariSmith = '18967';    // salary listed as NA

// ---------- Helpers ----------

// Opens the setup page in a desktop-sized test window so everything fits.
Future<void> pumpSetupPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: SetupPage()));
}

// Sets the salary cap slider (in millions), the same way dragging it would.
Future<void> setSalaryCap(WidgetTester tester, double millions) async {
  final slider = tester.widget<Slider>(find.byKey(const Key('salaryCapSlider')));
  slider.onChanged!(millions);
  await tester.pump();
}

// Opens the setup page, sets the salary cap, and starts a 3-team draft.
Future<void> startDraftWithCap(WidgetTester tester, double millions) async {
  await pumpSetupPage(tester);
  await setSalaryCap(tester, millions);
  await tester.tap(find.text('Start draft'));
  await tester.pumpAndSettle();
}

// Types an ID and presses Enter.
Future<void> pickWithEnter(WidgetTester tester, String id) async {
  await tester.enterText(find.byKey(const Key('idTextField')), id);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

// Types an ID and clicks the Make Pick button.
Future<void> pickWithButton(WidgetTester tester, String id) async {
  await tester.enterText(find.byKey(const Key('idTextField')), id);
  await tester.tap(find.byKey(const Key('SubmitPickButton')));
  await tester.pump();
}

Future<void> undoPick(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('UndoPickButton')));
  await tester.pump();
}

// Returns the text shown in a grid square, e.g. "Pick: Carmelo Anthony".
String? gridText(WidgetTester tester, int index) =>
    tester.widget<Text>(find.byKey(Key('Grid $index'))).data;

// Each pick starts the countdown timer. Letting it run out stops it,
// so no timer is still running when the test ends.
Future<void> finishTimer(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 500));
}

// ---------- Tests ----------

void main() {
  setUpAll(() async {
    final idAndSalaryList = await readExcel();
    ids = idAndSalaryList[0] as HashMap<String, String>;
    salary = idAndSalaryList[1] as HashMap<String, int>;
  });

  group('Salary cap slider', () {
    testWidgets('Defaults to \$110 million with a range of \$10 to \$200 million',
        (tester) async {
      await pumpSetupPage(tester);

      final slider = tester.widget<Slider>(find.byKey(const Key('salaryCapSlider')));
      expect(slider.value, 110);
      expect(slider.min, 10);
      expect(slider.max, 200);
      expect(find.text('\$110 Million'), findsOneWidget);
    });

    testWidgets('The cap chosen on the setup page is the cap used in the draft',
        (tester) async {
      // Garnett costs about $47.9M, so he's allowed under a $50M cap.
      // (The $10M tests below show he's rejected under a lower cap.)
      await startDraftWithCap(tester, 50);
      await pickWithEnter(tester, kevinGarnett);
      expect(gridText(tester, 0), 'Pick: Kevin Garnett');
      await finishTimer(tester);
    });
  });

  group('Picks over the salary cap (Story 8)', () {
    testWidgets('A player under the cap can be drafted', (tester) async {
      await startDraftWithCap(tester, 10);

      await pickWithEnter(tester, carmeloAnthony); // $5.5M of $10M

      expect(gridText(tester, 0), 'Pick: Carmelo Anthony');
      await finishTimer(tester);
    });

    testWidgets('A player over the cap is rejected and the grid does not change (Enter key)',
        (tester) async {
      await startDraftWithCap(tester, 10);

      await pickWithEnter(tester, kevinGarnett); // $47.9M of $10M

      expect(gridText(tester, 0), 'Pick: ');
      // The same team is still on the clock, so a cheaper player goes in square 0.
      await pickWithEnter(tester, carmeloAnthony);
      expect(gridText(tester, 0), 'Pick: Carmelo Anthony');
      await finishTimer(tester);
    });

    testWidgets('A player over the cap is rejected and the grid does not change (Make Pick button)',
        (tester) async {
      await startDraftWithCap(tester, 10);

      await pickWithButton(tester, kevinGarnett);

      expect(gridText(tester, 0), 'Pick: ');
      await pickWithButton(tester, carmeloAnthony);
      expect(gridText(tester, 0), 'Pick: Carmelo Anthony');
      await finishTimer(tester);
    });
  });

  group('Salary tracking (Story 11)', () {
    testWidgets('A team\'s spending adds up across its picks', (tester) async {
      await startDraftWithCap(tester, 10); // 3 teams by default

      // Round 1: one pick for each team.
      await pickWithEnter(tester, carmeloAnthony); // team 1 spends $5.52M
      await pickWithEnter(tester, jeffMcInnis);    // team 2
      await pickWithEnter(tester, mikeDunleavy);   // team 3

      // Round 2, team 1: $5.52M + $5.99M = $11.51M, over the $10M cap.
      await pickWithEnter(tester, moochieNorris);
      expect(gridText(tester, 3), 'Pick: ');

      // $5.52M + $4.06M = $9.58M fits, so this pick goes through.
      await pickWithEnter(tester, joelPrzybilla);
      expect(gridText(tester, 3), 'Pick: Joel Przybilla');
      await finishTimer(tester);
    });

    testWidgets('Each team\'s salary is tracked separately', (tester) async {
      await startDraftWithCap(tester, 10);

      await pickWithEnter(tester, carmeloAnthony); // team 1 spends $5.52M
      // Team 2 has spent nothing, so a $5.99M player fits even though
      // $5.52M + $5.99M would be over the cap if the teams shared one total.
      await pickWithEnter(tester, moochieNorris);

      expect(gridText(tester, 1), 'Pick: Moochie Norris');
      await finishTimer(tester);
    });

    testWidgets('Undoing a pick gives the salary back to the team', (tester) async {
      await startDraftWithCap(tester, 10);

      await pickWithEnter(tester, carmeloAnthony); // team 1 spends $5.52M
      await undoPick(tester);                      // team 1 back to $0
      expect(gridText(tester, 0), 'Pick: ');

      // $9.08M only fits if the $5.52M was returned ($14.6M otherwise).
      await pickWithEnter(tester, scotPollard);
      expect(gridText(tester, 0), 'Pick: Scot Pollard');
      await finishTimer(tester);
    });
  });

  group('Players with no salary listed', () {
    // Documents the current behavior: players whose salary is NA in
    // Master.xlsx can never be drafted. Update this test if the team decides
    // to handle them differently.
    testWidgets('A player with an NA salary cannot be drafted, even at the highest cap',
        (tester) async {
      await startDraftWithCap(tester, 200);

      await pickWithEnter(tester, jabariSmith);

      expect(gridText(tester, 0), 'Pick: ');
    });
  });
}
