// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tp1/main.dart';

void main() {
  testWidgets('shows the login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('CONNEXION'), findsOneWidget);
    expect(find.text('VAS-Y BG'), findsOneWidget);
    expect(find.text('SE CONNECTER'), findsOneWidget);
    expect(find.text('PAS DE COMPTE ?'), findsOneWidget);
  });

  testWidgets('opens the registration screen from login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PAS DE COMPTE ?'));
    await tester.pumpAndSettle();

    expect(find.text('INSCRIPTION'), findsOneWidget);
    expect(find.text('REJOINS-NOUS'), findsOneWidget);
    expect(find.text('S’INSCRIRE'), findsOneWidget);
  });
}
