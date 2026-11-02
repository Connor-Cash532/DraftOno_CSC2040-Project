// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:draft_ono_app/main.dart';

void main() {

    Future<void> completeSetup( WidgetTester tester) async{
      await tester.pumpWidget(const MainDraftPage());
      await tester.pump();

      await tester.tap(find.text('Start draft'));
      await tester.pumpAndSettle();
    }
  
  setUpAll(() async {
    ids = await readExcel();
  });
  
  
    testWidgets('Reveal ID', (WidgetTester tester) async {
      await completeSetup(tester);
      
      await tester.pumpWidget(const MainDraftPage());

      final expectedTextField = find.byKey(Key('idTextField'));
      expect(expectedTextField, findsOneWidget);

      await tester.enterText(expectedTextField, '16010');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      
      final grid1 = find.byKey(Key('Grid 0'));
      final Text textGrid1 = tester.widget<Text>(grid1);
      final String? actualTextGrid1 = textGrid1.data;
      expect(actualTextGrid1, "Pick: Kevin Garnett");

      await tester.enterText(expectedTextField, 'helloworld');
      await tester.pump(); 

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      Finder grid2 = find.byKey(Key('Grid 1'));
      Text textGrid2 = tester.widget<Text>(grid2);
      String? actualTextGrid2 = textGrid2.data;
      expect(actualTextGrid2, "Pick: ");

      await tester.enterText(expectedTextField, '18290');
      await tester.pump(); 

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      textGrid2 = tester.widget<Text>(grid2);
      actualTextGrid2 = textGrid2.data;
      expect(actualTextGrid2, "Pick: Sam Cassell");
  });

  testWidgets('Reveal ID Button', (WidgetTester tester) async {
    await completeSetup(tester);
    
    final expectedTextField = find.byKey(Key('idTextField'));
    expect(expectedTextField, findsOneWidget);

    await tester.enterText(expectedTextField, '16010');
    await tester.pump();

    final submitTextButton = find.byKey(Key('SubmitPickButton'));
    await tester.tap(submitTextButton);
    await tester.pump();

    final grid1 = find.byKey(Key('Grid 0'));
    final Text textGrid1 = tester.widget<Text>(grid1);
    final String? actualTextGrid1 = textGrid1.data;
    expect(actualTextGrid1, "Pick: Kevin Garnett");

  });

    testWidgets('Can not pick same player twice', (WidgetTester tester) async {
    await completeSetup(tester);

    final expectedTextField = find.byKey(Key('idTextField'));
    expect(expectedTextField, findsOneWidget);

    await tester.enterText(expectedTextField, '16010');
    await tester.pump();

    final submitTextButton = find.byKey(Key('SubmitPickButton'));
    await tester.tap(submitTextButton);
    await tester.pump();

    final grid1 = find.byKey(Key('Grid 0'));
    final Text textGrid1 = tester.widget<Text>(grid1);
    final String? actualTextGrid1 = textGrid1.data;
    expect(actualTextGrid1, "Pick: Kevin Garnett");

    await tester.enterText(expectedTextField, '16010');
    await tester.pump();

    await tester.tap(submitTextButton);
    await tester.pump();

    final grid2 = find.byKey(Key('Grid 1'));
    Text textGrid2 = tester.widget<Text>(grid2);
    String? actualTextGrid2 = textGrid2.data;
    expect(actualTextGrid2, "Pick: ");

    await tester.enterText(expectedTextField, '18045');
    await tester.pump();

    await tester.tap(submitTextButton);
    await tester.pump();

    textGrid2 = tester.widget<Text>(grid2);
    actualTextGrid2 = textGrid2.data;

    expect(actualTextGrid2, "Pick: Michael Redd");

  });
}
