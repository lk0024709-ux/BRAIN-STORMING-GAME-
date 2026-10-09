class NameplateStyle {
  const NameplateStyle({
    required this.id,
    required this.label,
    required this.cost,
    required this.fillHex,
    required this.inkHex,
  });

  final String id;
  final String label;

  /// 0 = owned by default. Positive = coin price. -1 = Pro exclusive.
  final int cost;
  final int fillHex;
  final int inkHex;

  bool get isProOnly => cost < 0;
  bool get isFree => cost == 0;

  static const classic = NameplateStyle(
    id: 'classic',
    label: 'Classic Ink',
    cost: 0,
    fillHex: 0xFFFFFFFF,
    inkHex: 0xFF111111,
  );

  static const sakura = NameplateStyle(
    id: 'sakura',
    label: 'Sakura Panel',
    cost: 80,
    fillHex: 0xFFFF8FB8,
    inkHex: 0xFF111111,
  );

  static const tide = NameplateStyle(
    id: 'tide',
    label: 'Tide Panel',
    cost: 80,
    fillHex: 0xFF7AD7FF,
    inkHex: 0xFF111111,
  );

  static const mint = NameplateStyle(
    id: 'mint',
    label: 'Mint Panel',
    cost: 120,
    fillHex: 0xFF7DFFB3,
    inkHex: 0xFF111111,
  );

  static const proGold = NameplateStyle(
    id: 'pro_gold',
    label: 'PRO Gold',
    cost: -1,
    fillHex: 0xFFFFC400,
    inkHex: 0xFF111111,
  );

  static const List<NameplateStyle> catalog = [
    classic,
    sakura,
    tide,
    mint,
    proGold,
  ];

  static NameplateStyle byId(String id) {
    for (final style in catalog) {
      if (style.id == id) return style;
    }
    return classic;
  }
}
