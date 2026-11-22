import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapis_app/core/theme.dart';
import 'package:zapis_app/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen не переполняется на 412x915', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: const LoginScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
