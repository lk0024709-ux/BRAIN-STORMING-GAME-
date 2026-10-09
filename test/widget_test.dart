import 'package:brain_speed_iq/models/rank_tier.dart';
import 'package:brain_speed_iq/theme/manga_theme.dart';
import 'package:brain_speed_iq/widgets/neo_widgets.dart';
import 'package:brain_speed_iq/widgets/rank_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rank badge and brutalist button render', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MangaTheme.build(),
        home: Scaffold(
          body: Column(
            children: [
              const RankBadge(tier: RankTier.gold, size: 120),
              MangaButton(
                label: 'START BATTLE',
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('GOLD'), findsOneWidget);
    expect(find.text('START BATTLE'), findsOneWidget);
    await tester.tap(find.text('START BATTLE'));
    expect(taps, 1);
  });

  test('stopwatch label pads under ten seconds', () {
    expect(formatStopwatch(const Duration(milliseconds: 4200)), '04.2');
    expect(formatStopwatch(const Duration(milliseconds: 12800)), '12.8');
  });
}
