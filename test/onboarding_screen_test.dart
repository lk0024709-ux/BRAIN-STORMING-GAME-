import 'package:brain_speed_iq/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('neon age gate renders and age presets update the quiz track',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('BRAINSPEED IQ'), findsOneWidget);
    expect(find.text('NICKNAME'), findsOneWidget);
    expect(find.text('AGE GATE · VERIFY TO ENTER THE DOJO'), findsOneWidget);
    expect(find.text('ENTER THE DOJO'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('KID'));
    await tester.pumpAndSettle();
    expect(find.text('KIDS TRACK · Addition and subtraction'), findsOneWidget);
    expect(
      find.text('UNDER 13 · PARENT CHECK BEFORE PURCHASES · NO ADS'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
