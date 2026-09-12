import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawboleh/main.dart';

void main() {
  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'kirana@atelier.my');
    await tester.enterText(find.byType(TextField).at(1), 'paw1234');
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> finishPanelTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('all three main tabs render and can be selected', (tester) async {
    await tester.pumpWidget(const PawBolehApp());
    await signIn(tester);
    expect(find.text('Good morning, Sis!'), findsOneWidget);

    await tester.tap(find.text('Paw Live').last);
    await tester.pump();
    expect(find.text('Admin quick-reply'), findsOneWidget);

    await tester.tap(find.text('Paw Snap').last);
    await tester.pump();
    expect(find.text('Target audience: Gen Z'), findsOneWidget);
    expect(find.text('Product name'), findsOneWidget);
    expect(find.text('Generate Paw Snap'), findsOneWidget);
  });

  testWidgets('notifications panel opens and marks unread items as read', (tester) async {
    await tester.pumpWidget(const PawBolehApp());
    await signIn(tester);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await finishPanelTransition(tester);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('3 new updates'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pump();
    expect(find.text('3 new updates'), findsNothing);
  });

  testWidgets('profile panel can sign out', (tester) async {
    await tester.pumpWidget(const PawBolehApp());
    await signIn(tester);

    await tester.tap(find.text('KA'));
    await finishPanelTransition(tester);
    expect(find.text('Paw Live reminders'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Welcome to PawBoleh'), findsOneWidget);
  });
}
