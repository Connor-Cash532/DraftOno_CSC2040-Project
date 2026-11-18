import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:draft_ono_app/main.dart';
import 'package:draft_ono_app/setup_page.dart';
import 'package:draft_ono_app/team.dart';

// Opens the setup page in a desktop-sized test window so every
// text field and the full draft grid fit on screen.
Future<void> pumpSetupPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: SetupPage()));
}

// Types each name into the matching team name box, in order.
Future<void> enterTeamNames(WidgetTester tester, List<String> names) async {
  for (int i = 0; i < names.length; i++) {
    await tester.enterText(find.byType(TextField).at(i), names[i]);
  }
}

// Taps "Start draft" and waits for the page change to finish.
Future<void> startDraft(WidgetTester tester) async {
  await tester.tap(find.text('Start draft'));
  await tester.pumpAndSettle();
}

void main() {
  group('Choosing the number of teams', () {
    testWidgets('Setup page starts with 3 team name boxes', (tester) async {
      await pumpSetupPage(tester);

      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('Selecting 4 or 5 teams shows that many name boxes',
        (tester) async {
      await pumpSetupPage(tester);

      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(4));

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(5));
    });
  });

  group('Team name validation', () {
    testWidgets('A blank team name shows an error and does not start the draft',
        (tester) async {
      await pumpSetupPage(tester);

      await enterTeamNames(tester, ['Bulls', '', 'Lions']);
      await startDraft(tester);

      expect(find.text('Enter a name for team 2.'), findsOneWidget);
      expect(find.byType(SetupPage), findsOneWidget);
      expect(find.byType(DraftPage), findsNothing);
    });

    testWidgets('Duplicate names show an error, even with different capitalization',
        (tester) async {
      await pumpSetupPage(tester);

      await enterTeamNames(tester, ['Bulls', 'bulls', 'Lions']);
      await startDraft(tester);

      expect(find.textContaining('different name'), findsOneWidget);
      expect(find.byType(DraftPage), findsNothing);
    });
  });

  group('Starting the draft', () {
    testWidgets('Valid names open the draft page with no way back to setup',
        (tester) async {
      await pumpSetupPage(tester);

      await enterTeamNames(tester, ['Bulls', 'Bears', 'Lions']);
      await startDraft(tester);

      expect(find.byType(DraftPage), findsOneWidget);
      expect(find.byType(SetupPage), findsNothing);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('Team names appear above the grid', (tester) async {
      await pumpSetupPage(tester);

      await enterTeamNames(tester, ['Bulls', 'Bears', 'Lions']);
      await startDraft(tester);

      expect(find.text('Bulls'), findsOneWidget);
      expect(find.text('Bears'), findsOneWidget);
      expect(find.text('Lions'), findsOneWidget);
    });

    testWidgets('Each team header uses that team\'s preset color',
        (tester) async {
      await pumpSetupPage(tester);

      await enterTeamNames(tester, ['Bulls', 'Bears', 'Lions']);
      await startDraft(tester);

      final names = ['Bulls', 'Bears', 'Lions'];
      for (int i = 0; i < names.length; i++) {
        // The nearest Container around the team name is its colored header box.
        final header = tester.widget<Container>(
          find.ancestor(of: find.text(names[i]), matching: find.byType(Container)).first,
        );
        expect((header.decoration as BoxDecoration).color, teamColors[i]);
      }
    });
  });

  group('Draft grid matches the number of teams', () {
    // Runs the same check for 3, 4, and 5 teams.
    for (final numTeams in [3, 4, 5]) {
      testWidgets('$numTeams teams gives $numTeams columns and ${numTeams * 10} picks',
          (tester) async {
        await pumpSetupPage(tester);

        await tester.tap(find.text('$numTeams'));
        await tester.pumpAndSettle();
        await startDraft(tester); // default names "Team 1", "Team 2", ... are valid

        final grid = tester.widget<GridView>(find.byType(GridView));
        final layout = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(layout.crossAxisCount, numTeams);

        // Every empty grid square shows "Pick: " with no player name yet.
        expect(find.text('Pick: '), findsNWidgets(numTeams * 10));
      });
    }
  });
}
