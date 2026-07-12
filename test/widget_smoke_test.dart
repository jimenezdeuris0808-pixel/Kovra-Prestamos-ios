import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kovra_mobile/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen muestra los campos de usuario y contraseña',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
