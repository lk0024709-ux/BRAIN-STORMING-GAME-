import 'dart:convert';
import 'dart:io';

import 'package:brain_speed_iq/controllers/profile_controller.dart';
import 'package:brain_speed_iq/models/skin_shop.dart';
import 'package:brain_speed_iq/services/reward_engine.dart';
import 'package:brain_speed_iq/screens/home_screen.dart';
import 'package:brain_speed_iq/screens/shop_screen.dart';
import 'package:brain_speed_iq/services/storage_service.dart';
import 'package:brain_speed_iq/widgets/skin_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SkinCatalog.defaults', () {
    test('matches the Battle Dojo rarity and price contract', () {
      const catalog = SkinCatalog.defaults;
      expect(catalog.coinColorHex, 0xFFFFD700);
      expect(catalog.heartColorHex, 0xFFFF0000);
      expect(catalog.coinSuffix, 'coin');
      expect(catalog.skins, hasLength(6));

      expect(catalog.frames['hexagon']!.rarity, 'common');
      expect(catalog.frames['hexagon']!.borderHex, 0xFF00FFFF);
      expect(catalog.frames['octagon']!.rarity, 'rare');
      expect(catalog.frames['octagon']!.borderHex, 0xFF8A2BE2);
      expect(catalog.frames['diamond']!.rarity, 'epic');
      expect(catalog.frames['diamond']!.borderHex, 0xFFFF00FF);
      expect(catalog.frames['pentagon']!.rarity, 'legendary');
      expect(catalog.frames['pentagon']!.borderHex, 0xFF00BFFF);
      expect(catalog.frames['triangle']!.rarity, 'mythic');
      expect(catalog.frames['triangle']!.borderHex, 0xFFFF4500);
      expect(catalog.frames['golden_hex']!.rarity, 'ultimate');
      expect(catalog.frames['golden_hex']!.borderHex, 0xFFFFD700);

      // Hearts only on legendary and above.
      expect(catalog.frames['hexagon']!.hasHeart, isFalse);
      expect(catalog.frames['octagon']!.hasHeart, isFalse);
      expect(catalog.frames['diamond']!.hasHeart, isFalse);
      expect(catalog.frames['pentagon']!.hasHeart, isTrue);
      expect(catalog.frames['triangle']!.hasHeart, isTrue);
      expect(catalog.frames['golden_hex']!.hasHeart, isTrue);

      expect(
        catalog.skins.map((skin) => (skin.id, skin.price)).toList(),
        [
          ('neon_ninja', 500),
          ('cyber_samurai', 700),
          ('shadow_assassin', 600),
          ('frost_warrior', 800),
          ('inferno_mask', 900),
          ('golden_emperor', 1200),
        ],
      );
      expect(catalog.byId('golden_emperor')!.frameId, 'golden_hex');
      expect(catalog.byId('missing'), isNull);
    });

    test('every card and bust asset is declared and present on disk', () {
      for (final skin in SkinCatalog.defaults.skins) {
        for (final path in [
          skin.cardAsset,
          skin.equippedAsset,
          skin.bustAsset,
        ]) {
          expect(path, startsWith('assets/skins/'));
          expect(File(path).existsSync(), isTrue, reason: 'missing $path');
        }
        expect(skin.cardFor(false), endsWith('.png'));
        expect(skin.cardFor(true), contains('_equipped'));
      }
    });

    test('the shipped store_config.json decodes to the same catalog', () {
      final source =
          File('assets/skins/store_config.json').readAsStringSync();
      final catalog = SkinCatalog.decode(source);
      const reference = SkinCatalog.defaults;

      expect(catalog.coinColorHex, reference.coinColorHex);
      expect(catalog.heartColorHex, reference.heartColorHex);
      expect(catalog.coinSuffix, reference.coinSuffix);
      expect(catalog.levelLabel, reference.levelLabel);
      expect(catalog.frames.keys.toSet(), reference.frames.keys.toSet());
      for (final frame in reference.frames.values) {
        expect(catalog.frames[frame.id]!.borderHex, frame.borderHex);
        expect(catalog.frames[frame.id]!.rarity, frame.rarity);
        expect(catalog.frames[frame.id]!.hasHeart, frame.hasHeart);
      }
      expect(catalog.skins, hasLength(reference.skins.length));
      for (var i = 0; i < reference.skins.length; i++) {
        final parsed = catalog.skins[i];
        final expected = reference.skins[i];
        expect(parsed.id, expected.id);
        expect(parsed.name, expected.name);
        expect(parsed.price, expected.price);
        expect(parsed.frameId, expected.frameId);
        expect(parsed.hasHeart, expected.hasHeart);
        expect(parsed.cardAsset, expected.cardAsset);
        expect(parsed.bustAsset, expected.bustAsset);
      }
    });

    test('rejects payloads without a store_config block', () {
      expect(() => SkinCatalog.decode('{"other": 1}'),
          throwsA(isA<FormatException>()));
      expect(() => SkinCatalog.decode('[]'),
          throwsA(isA<FormatException>()));
    });

    test('the art spec keeps the 512x512 transparent contract', () {
      final decoded = jsonDecode(
        File('assets/skins/store_config.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final store = decoded['store_config'] as Map<String, dynamic>;
      expect(store['asset_format'], '512x512 PNG transparent');
      expect(store['border_width_px'], 8);
      expect(parseHexColor(store['coin_color'], 0), 0xFFFFD700);
      expect(parseHexColor(store['heart_color'], 0), 0xFFFF0000);
    });
  });

  group('helpers', () {
    test('parseHexColor handles 6 and 8 digit values', () {
      expect(parseHexColor('#FFD700', 0), 0xFFFFD700);
      expect(parseHexColor('FF0000', 0), 0xFFFF0000);
      expect(parseHexColor('#8000FFFF', 0), 0x8000FFFF);
      expect(parseHexColor(null, 0xFF123456), 0xFF123456);
      expect(parseHexColor('nope', 0xFF123456), 0xFF123456);
    });

    test('formatCoinAmount groups thousands', () {
      expect(formatCoinAmount(0), '0');
      expect(formatCoinAmount(500), '500');
      expect(formatCoinAmount(1200), '1,200');
      expect(formatCoinAmount(1234567), '1,234,567');
      expect(formatCoinAmount(-1200), '-1,200');
    });
  });

  group('ProfileController skins', () {
    test('buys, equips, and refuses when the purse is short', () async {
      SharedPreferences.setMockInitialValues({});
      final profile = ProfileController(await StorageService.create());
      await profile.load();
      await profile.completeOnboarding(nickname: 'Aditya', age: 14);

      const catalog = SkinCatalog.defaults;
      final ninja = catalog.byId('neon_ninja')!;

      expect(profile.profile.coins, 40);
      expect(await profile.buyOrEquipSkin(ninja), contains('Not enough coins'));
      expect(profile.ownedSkins, isEmpty);
      expect(profile.equippedSkinId, isEmpty);

      // Earn coins with a lightning-fast solve, then the same skin is buyable.
      while (profile.profile.coins < ninja.price) {
        await profile.applyCorrect(
          reward: RewardEngine().evaluate(
            elapsed: const Duration(milliseconds: 3000),
            isPro: false,
          ),
          timeMs: 3000,
        );
      }
      expect(profile.profile.coins, greaterThanOrEqualTo(ninja.price));
      expect(await profile.buyOrEquipSkin(ninja), isNull);
      expect(profile.equippedSkinId, 'neon_ninja');
    });

    test('an affordable skin is bought, equipped, and re-equipped for free',
        () async {
      SharedPreferences.setMockInitialValues({
        StorageService.keyOnboarding: true,
        StorageService.keyCoins: 2000,
      });
      final profile = ProfileController(await StorageService.create());
      await profile.load();
      expect(profile.profile.coins, 2000);

      const catalog = SkinCatalog.defaults;
      final ninja = catalog.byId('neon_ninja')!;
      final samurai = catalog.byId('cyber_samurai')!;

      expect(await profile.buyOrEquipSkin(ninja), isNull);
      expect(profile.profile.coins, 1500);
      expect(profile.ownedSkins, ['neon_ninja']);
      expect(profile.equippedSkinId, 'neon_ninja');

      expect(await profile.buyOrEquipSkin(samurai), isNull);
      expect(profile.profile.coins, 800);
      expect(profile.equippedSkinId, 'cyber_samurai');

      // Already owned: swapping back must not charge again.
      expect(await profile.buyOrEquipSkin(ninja), isNull);
      expect(profile.profile.coins, 800);
      expect(profile.equippedSkinId, 'neon_ninja');

      await profile.clearEquippedSkin();
      expect(profile.equippedSkinId, '');
      expect(profile.ownedSkins, containsAll(['neon_ninja', 'cyber_samurai']));
    });

    test('purchased skins survive a reset and reload from storage', () async {
      SharedPreferences.setMockInitialValues({
        StorageService.keyOnboarding: true,
        StorageService.keyCoins: 2000,
      });
      final storage = await StorageService.create();
      final profile = ProfileController(storage);
      await profile.load();
      const catalog = SkinCatalog.defaults;
      await profile.buyOrEquipSkin(catalog.byId('shadow_assassin')!);
      await profile.resetTraining();

      final reloaded = ProfileController(await StorageService.create());
      await reloaded.load();
      expect(reloaded.ownedSkins, ['shadow_assassin']);
      expect(reloaded.equippedSkinId, '');
      expect(reloaded.profile.coins, reloaded.profile.startingCoins);
    });
  });

  testWidgets('SkinCard paints the price in coin yellow and hearts in red',
      (tester) async {
    const catalog = SkinCatalog.defaults;
    final ninja = catalog.byId('neon_ninja')!;
    final emperor = catalog.byId('golden_emperor')!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 260,
                child: SkinCard(
                  catalog: catalog,
                  skin: ninja,
                  owned: false,
                  equipped: false,
                  coins: 900,
                  onTap: () {},
                ),
              ),
              SizedBox(
                height: 260,
                child: SkinCard(
                  catalog: catalog,
                  skin: emperor,
                  owned: true,
                  equipped: true,
                  coins: 900,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('500 coin'), findsOneWidget);
    expect(find.text('COMMON'), findsOneWidget);
    expect(find.text('ULTIMATE'), findsOneWidget);
    expect(find.text('EQUIPPED'), findsOneWidget);

    final price = tester.widget<Text>(find.text('500 coin'));
    expect(price.style!.color, const Color(0xFFFFD700));
    expect(price.style!.fontWeight, FontWeight.w900);

    // Only the ultimate tier carries the premium heart badge.
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    final heart = tester.widget<Icon>(find.byIcon(Icons.favorite));
    expect(heart.color, const Color(0xFFFF0000));

    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(images, contains('assets/skins/cards/neon_ninja.png'));
    expect(images, contains('assets/skins/cards/golden_emperor_equipped.png'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('the shop lists all six Battle Dojo skins', (tester) async {
    // Tall viewport so the whole vault is laid out without scrolling.
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      StorageService.keyOnboarding: true,
      StorageService.keyCoins: 100,
    });
    final profile = ProfileController(await StorageService.create());
    await profile.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: profile,
        child: const MaterialApp(home: ShopScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BATTLE DOJO SKIN VAULT'), findsOneWidget);
    expect(find.byType(SkinCard), findsNWidgets(6));
    expect(find.text('500 coin'), findsWidgets);
    expect(find.text('TAP TO EQUIP'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an equipped skin replaces the hero portrait on home',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      StorageService.keyOnboarding: true,
      StorageService.keyTerms: true,
      StorageService.keyNickname: 'Aditya',
      StorageService.keyUserAge: 14,
      StorageService.keyOwnedSkins: ['neon_ninja'],
      StorageService.keyEquippedSkin: 'neon_ninja',
    });
    final profile = ProfileController(await StorageService.create());
    await profile.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: profile,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEON NINJA'), findsOneWidget);
    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(assets, contains('assets/skins/busts/neon_ninja.png'));
    expect(assets, contains('assets/images/rival_avatar.png'));
    expect(tester.takeException(), isNull);
  });
}

