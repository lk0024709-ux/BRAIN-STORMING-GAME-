import 'dart:async';

import 'package:brain_speed_iq/app.dart';
import 'package:brain_speed_iq/screens/home_screen.dart';
import 'package:brain_speed_iq/screens/onboarding_screen.dart';
import 'package:brain_speed_iq/services/iap_service.dart';
import 'package:brain_speed_iq/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_battle_music_player.dart';

void main() {
  testWidgets('the app loads to age-gated onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      BrainSpeedApp(musicPlayer: FakeBattleMusicPlayer()),
    );
    await tester.pumpAndSettle();

    expect(find.text('BRAINSPEED IQ'), findsOneWidget);
    expect(find.text('AGE GATE · VERIFY TO ENTER THE DOJO'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('returning profiles reach Home without starting native SDKs',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageService.keyOnboarding: true,
    });

    await tester.pumpWidget(
      BrainSpeedApp(musicPlayer: FakeBattleMusicPlayer()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    final context = tester.element(find.byType(HomeScreen));
    expect(context.read<IAPService>().started, isFalse);
    expect(context.read<IAPService>().storeQueryDone, isFalse);
  });

  testWidgets('the startup screen waits for the profile before showing the app',
      (tester) async {
    final loading = Completer<StorageService>();
    addTearDown(() {
      if (!loading.isCompleted) loading.completeError(StateError('unused'));
    });
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      BrainSpeedApp(
        musicPlayer: FakeBattleMusicPlayer(),
        storageLoader: () => loading.future,
      ),
    );
    await tester.pump();

    expect(find.text('OPENING THE DOJO...'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);

    loading.complete((await tester.runAsync(StorageService.create))!);
    await tester.pumpAndSettle();

    expect(find.text('OPENING THE DOJO...'), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed profile load shows a retry screen, and retry recovers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var attempts = 0;

    await tester.pumpWidget(
      BrainSpeedApp(
        musicPlayer: FakeBattleMusicPlayer(),
        storageLoader: () async {
          attempts++;
          if (attempts == 1) throw StateError('storage unavailable');
          return StorageService.create();
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('THE DOJO COULD NOT OPEN'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('THE DOJO COULD NOT OPEN'), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
