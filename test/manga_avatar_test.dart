import 'package:brain_speed_iq/widgets/manga_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hero and rival use the bundled generated portraits',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MangaAvatar(rival: false),
              MangaAvatar(rival: true),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(2));
    expect(
      (images[0].image as AssetImage).assetName,
      'assets/images/hero_avatar.png',
    );
    expect(
      (images[1].image as AssetImage).assetName,
      'assets/images/rival_avatar.png',
    );
    expect(tester.takeException(), isNull);
  });
}
