import 'package:brain_speed_iq/app.dart';
import 'package:brain_speed_iq/screens/home_screen.dart';
import 'package:brain_speed_iq/screens/onboarding_screen.dart';
import 'package:brain_speed_iq/services/iap_service.dart';
import 'package:brain_speed_iq/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the app loads to age-gated onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BrainSpeedApp());
    await tester.pumpAndSettle();

    expect(find.text('BRAINSPEED IQ'), findsOneWidget);
    expect(find.text('Age gate first. Then the dojo opens.'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('returning profiles reach Home without starting native SDKs',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageService.keyOnboarding: true,
    });

    await tester.pumpWidget(const BrainSpeedApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    final context = tester.element(find.byType(HomeScreen));
    expect(context.read<IAPService>().started, isFalse);
    expect(context.read<IAPService>().storeQueryDone, isFalse);
  });
}
