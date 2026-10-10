import 'package:brain_speed_iq/controllers/profile_controller.dart';
import 'package:brain_speed_iq/screens/home_screen.dart';
import 'package:brain_speed_iq/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('cyber home dashboard fits a phone screen and shows the quest',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final profile = ProfileController(await StorageService.create());
    await profile.load();
    await profile.completeOnboarding(nickname: 'Aditya', age: 14);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: profile,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BRAINSPEED IQ'), findsOneWidget);
    expect(find.text('START BATTLE'), findsOneWidget);
    expect(find.text('ADITYA'), findsOneWidget);
    expect(find.text('RIVAL'), findsAtLeastNWidgets(1));
    expect(find.textContaining('120 MATH LEVELS COMPLETE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
