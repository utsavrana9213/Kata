// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:servekeen/home_page.dart';
import 'package:servekeen/login_screen.dart';
import 'package:servekeen/main.dart';

void main() {
  testWidgets('App builds and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('ServeKeen'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
    final onSplash = find.text('ServeKeen').evaluate().isNotEmpty;
    final onLogin = find.byType(LoginScreen).evaluate().isNotEmpty || find.text('Welcome Back!').evaluate().isNotEmpty;
    final onHome = find.byType(HomePage).evaluate().isNotEmpty;
    expect(onSplash || onLogin || onHome, isTrue);
  });
}
