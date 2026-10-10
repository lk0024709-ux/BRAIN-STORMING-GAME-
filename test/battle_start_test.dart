import 'package:brain_speed_iq/app.dart';
import 'package:brain_speed_iq/controllers/game_controller.dart';
import 'package:brain_speed_iq/screens/gameplay_screen.dart';
import 'package:brain_speed_iq/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('START BATTLE opens gameplay with a question and level header',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      StorageService.keyOnboarding: true,
      StorageService.keyTerms: true,
      StorageService.keyNickname: 'Tester',
      StorageService.keyUserAge: 21,
    });

    await tester.pumpWidget(const BrainSpeedApp());
    await tester.pumpAndSettle();
    expect(find.text('START BATTLE'), findsOneWidget);

    await tester.ensureVisible(find.text('START BATTLE'));
    await tester.tap(find.text('START BATTLE'));
    // The gameplay stopwatch ticks every 50 ms, so settling never completes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(GameplayScreen), findsOneWidget);
    expect(find.textContaining('LEVEL 1 / 120'), findsOneWidget);

    final context = tester.element(find.byType(GameplayScreen));
    expect(context.read<GameController>().question, isNotNull);

    // Unmount the app so the gameplay ticker and any player are disposed.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
