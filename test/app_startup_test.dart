import 'package:brain_speed_iq/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the app loads to age-gated onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BrainSpeedApp());
    await tester.pumpAndSettle();

    expect(find.text('BRAINSPEED IQ'), findsOneWidget);
    expect(find.text('Age gate first. Then the dojo opens.'), findsOneWidget);
  });
}
