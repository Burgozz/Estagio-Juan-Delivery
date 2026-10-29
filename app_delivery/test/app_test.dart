import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/app.dart';
import 'package:front_delivery/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('o app abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'ENTRAR'), findsOneWidget);
  });
}
