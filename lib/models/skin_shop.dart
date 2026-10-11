/// Battle Dojo skin vault data: polygon rarity frames, coin pricing, and the
/// per-skin art shipped in `assets/skins/`.
///
/// `assets/skins/store_config.json` is the generated contract for the art
/// pipeline (see `tools/generate_store_assets.py`). [SkinCatalog.defaults]
/// mirrors it for runtime use so the shop never blocks on a bundle read,
/// and `test/skin_shop_test.dart` asserts the two stay identical.
library;

import 'dart:convert';

/// A polygon rarity frame: shape, neon border colour and whether the tier
/// carries the red heart badge.
class SkinFrame {
  const SkinFrame({
    required this.id,
    required this.rarity,
    required this.borderHex,
    required this.shape,
    required this.hasHeart,
  });

  final String id;

  /// `common`, `rare`, `epic`, `legendary`, `mythic`, `ultimate`.
  final String rarity;
  final int borderHex;

  /// `hex`, `oct`, `diamond`, `pentagon`, `triangle`, `golden_hex`.
  final String shape;
  final bool hasHeart;

  String get label => rarity.toUpperCase();

  factory SkinFrame.fromJson(String id, Map<String, dynamic> json) {
    return SkinFrame(
      id: id,
      rarity: (json['rarity'] as String?) ?? 'common',
      borderHex: parseHexColor(json['border'], 0xFF00FFFF),
      shape: (json['shape'] as String?) ?? 'hex',
      hasHeart: json['heart'] == true,
    );
  }
}

/// One purchasable skin and the art that represents it.
class SkinItem {
  const SkinItem({
    required this.id,
    required this.name,
    required this.price,
    required this.frameId,
    required this.hasHeart,
    required this.cardHex,
    required this.cardAsset,
    required this.equippedAsset,
    required this.bustAsset,
  });

  final String id;
  final String name;
  final int price;
  final String frameId;
  final bool hasHeart;

  /// Border colour sampled from the matching [SkinFrame].
  final int cardHex;
  final String cardAsset;
  final String equippedAsset;
  final String bustAsset;

  /// Card asset for the owned/equipped state.
  String cardFor(bool equipped) => equipped ? equippedAsset : cardAsset;
}

/// The whole store: frames keyed by id, the ordered skin list, and the colour
/// rules the art pipeline follows (coin yellow, heart red).
class SkinCatalog {
  const SkinCatalog({
    required this.frames,
    required this.skins,
    this.coinColorHex = 0xFFFFD700,
    this.heartColorHex = 0xFFFF0000,
    this.coinSuffix = 'coin',
    this.levelLabel = 'Lv.12',
  });

  final Map<String, SkinFrame> frames;
  final List<SkinItem> skins;
  final int coinColorHex;
  final int heartColorHex;
  final String coinSuffix;
  final String levelLabel;

  SkinItem? byId(String id) {
    for (final skin in skins) {
      if (skin.id == id) return skin;
    }
    return null;
  }

  SkinFrame frameFor(SkinItem skin) {
    return frames[skin.frameId] ??
        const SkinFrame(
          id: 'hexagon',
          rarity: 'common',
          borderHex: 0xFF00FFFF,
          shape: 'hex',
          hasHeart: false,
        );
  }

  bool ownsFrameFor(SkinItem skin, List<String> ownedSkinIds) =>
      ownedSkinIds.contains(skin.id);

  String priceLabel(SkinItem skin) => '${formatCoinAmount(skin.price)} $coinSuffix';

  /// Runtime copy of `assets/skins/store_config.json`.
  static const SkinCatalog defaults = SkinCatalog(
    frames: {
      'hexagon': SkinFrame(
        id: 'hexagon',
        rarity: 'common',
        borderHex: 0xFF00FFFF,
        shape: 'hex',
        hasHeart: false,
      ),
      'octagon': SkinFrame(
        id: 'octagon',
        rarity: 'rare',
        borderHex: 0xFF8A2BE2,
        shape: 'oct',
        hasHeart: false,
      ),
      'diamond': SkinFrame(
        id: 'diamond',
        rarity: 'epic',
        borderHex: 0xFFFF00FF,
        shape: 'diamond',
        hasHeart: false,
      ),
      'pentagon': SkinFrame(
        id: 'pentagon',
        rarity: 'legendary',
        borderHex: 0xFF00BFFF,
        shape: 'pentagon',
        hasHeart: true,
      ),
      'triangle': SkinFrame(
        id: 'triangle',
        rarity: 'mythic',
        borderHex: 0xFFFF4500,
        shape: 'triangle',
        hasHeart: true,
      ),
      'golden_hex': SkinFrame(
        id: 'golden_hex',
        rarity: 'ultimate',
        borderHex: 0xFFFFD700,
        shape: 'golden_hex',
        hasHeart: true,
      ),
    },
    skins: [
      SkinItem(
        id: 'neon_ninja',
        name: 'Neon Ninja',
        price: 500,
        frameId: 'hexagon',
        hasHeart: false,
        cardHex: 0xFF00FFFF,
        cardAsset: 'assets/skins/cards/neon_ninja.png',
        equippedAsset: 'assets/skins/cards/neon_ninja_equipped.png',
        bustAsset: 'assets/skins/busts/neon_ninja.png',
      ),
      SkinItem(
        id: 'cyber_samurai',
        name: 'Cyber Samurai',
        price: 700,
        frameId: 'octagon',
        hasHeart: false,
        cardHex: 0xFF8A2BE2,
        cardAsset: 'assets/skins/cards/cyber_samurai.png',
        equippedAsset: 'assets/skins/cards/cyber_samurai_equipped.png',
        bustAsset: 'assets/skins/busts/cyber_samurai.png',
      ),
      SkinItem(
        id: 'shadow_assassin',
        name: 'Shadow Assassin',
        price: 600,
        frameId: 'diamond',
        hasHeart: false,
        cardHex: 0xFFFF00FF,
        cardAsset: 'assets/skins/cards/shadow_assassin.png',
        equippedAsset: 'assets/skins/cards/shadow_assassin_equipped.png',
        bustAsset: 'assets/skins/busts/shadow_assassin.png',
      ),
      SkinItem(
        id: 'frost_warrior',
        name: 'Frost Warrior',
        price: 800,
        frameId: 'pentagon',
        hasHeart: true,
        cardHex: 0xFF00BFFF,
        cardAsset: 'assets/skins/cards/frost_warrior.png',
        equippedAsset: 'assets/skins/cards/frost_warrior_equipped.png',
        bustAsset: 'assets/skins/busts/frost_warrior.png',
      ),
      SkinItem(
        id: 'inferno_mask',
        name: 'Inferno Mask',
        price: 900,
        frameId: 'triangle',
        hasHeart: true,
        cardHex: 0xFFFF4500,
        cardAsset: 'assets/skins/cards/inferno_mask.png',
        equippedAsset: 'assets/skins/cards/inferno_mask_equipped.png',
        bustAsset: 'assets/skins/busts/inferno_mask.png',
      ),
      SkinItem(
        id: 'golden_emperor',
        name: 'Golden Emperor',
        price: 1200,
        frameId: 'golden_hex',
        hasHeart: true,
        cardHex: 0xFFFFD700,
        cardAsset: 'assets/skins/cards/golden_emperor.png',
        equippedAsset: 'assets/skins/cards/golden_emperor_equipped.png',
        bustAsset: 'assets/skins/busts/golden_emperor.png',
      ),
    ],
  );

  /// Parses the generated `store_config.json` payload. Malformed rows are
  /// skipped so a bad asset drop cannot take the shop down.
  factory SkinCatalog.fromJson(Map<String, dynamic> root) {
    final store = root['store_config'];
    if (store is! Map<String, dynamic>) {
      throw const FormatException('store_config missing');
    }
    final frames = <String, SkinFrame>{};
    final rawFrames = store['frames'];
    if (rawFrames is Map<String, dynamic>) {
      rawFrames.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          frames[key] = SkinFrame.fromJson(key, value);
        }
      });
    }
    final skins = <SkinItem>[];
    final rawSkins = store['skins'];
    if (rawSkins is List) {
      for (final row in rawSkins) {
        if (row is! Map<String, dynamic>) continue;
        final id = row['name'] is String
            ? _slug(row['name'] as String)
            : null;
        if (id == null) continue;
        final frameId = (row['frame'] as String?) ?? 'hexagon';
        final frame = frames[frameId];
        skins.add(
          SkinItem(
            id: id,
            name: row['name'] as String,
            price: (row['price'] as num?)?.toInt() ?? 0,
            frameId: frameId,
            hasHeart: row['heart'] == true,
            cardHex: frame?.borderHex ?? 0xFF00FFFF,
            cardAsset: (row['asset'] as String?) ?? '',
            equippedAsset: (row['equipped_asset'] as String?) ?? '',
            bustAsset: (row['bust'] as String?) ?? '',
          ),
        );
      }
    }
    return SkinCatalog(
      frames: frames,
      skins: skins,
      coinColorHex: parseHexColor(store['coin_color'], 0xFFFFD700),
      heartColorHex: parseHexColor(store['heart_color'], 0xFFFF0000),
      coinSuffix: (store['coin_text_suffix'] as String?) ?? 'coin',
      levelLabel: (store['level_label'] as String?) ?? 'Lv.12',
    );
  }

  static String? _slug(String name) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  factory SkinCatalog.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('store config is not an object');
    }
    return SkinCatalog.fromJson(decoded);
  }
}

/// `#RRGGBB` / `#AARRGGBB` (with or without `#`) to an ARGB int.
int parseHexColor(Object? value, int fallback) {
  if (value is! String) return fallback;
  final cleaned = value.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final parsed = int.tryParse(cleaned, radix: 16);
    return parsed == null ? fallback : 0xFF000000 | parsed;
  }
  if (cleaned.length == 8) {
    return int.tryParse(cleaned, radix: 16) ?? fallback;
  }
  return fallback;
}

/// `1200` -> `1,200`, used for coin prices and balances.
String formatCoinAmount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
