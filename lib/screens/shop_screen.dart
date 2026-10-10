import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/profile_controller.dart';
import '../models/nameplate.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/neo_widgets.dart';
import 'pro_upgrade_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  Future<void> _buy(Future<String?> Function() action) async {
    final message = await action();
    if (!mounted) return;
    if (message != null) _toast(message);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MangaColors.ink,
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final data = profile.profile;
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Expanded(
                            child: Text(
                              'SHOP',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          CoinChip(coins: data.coins),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const SectionTitle('Token packs'),
                      const SizedBox(height: 8),
                      _Pack(
                        title: '${AppConfig.hintPackCount} hints',
                        detail: 'Cheaper than buying one by one. You hold ${data.hintTokens}.',
                        price: AppConfig.hintPackCost,
                        onBuy: () => _buy(profile.buyHintPack),
                      ),
                      _Pack(
                        title: '${AppConfig.fiftyPackCount} × 50/50',
                        detail: 'You hold ${data.fiftyTokens}.',
                        price: AppConfig.fiftyPackCost,
                        onBuy: () => _buy(profile.buyFiftyPack),
                      ),
                      _Pack(
                        title: '${AppConfig.chancePackCount} second chances',
                        detail: 'You hold ${data.chanceTokens}.',
                        price: AppConfig.chancePackCost,
                        onBuy: () => _buy(profile.buyChancePack),
                      ),
                      const SizedBox(height: 8),
                      const SectionTitle('Nameplates'),
                      const SizedBox(height: 8),
                      for (final style in NameplateStyle.catalog)
                        if (!style.isProOnly)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MangaButton(
                              label: data.ownedNameplates.contains(style.id)
                                  ? data.nameplateId == style.id && !data.isProUser
                                      ? '${style.label} · EQUIPPED'
                                      : 'EQUIP ${style.label}'
                                  : '${style.label} · ${style.cost}',
                              color: Color(style.fillHex),
                              onPressed: () => _buy(
                                () => profile.buyOrEquipNameplate(style),
                              ),
                            ),
                          ),
                      NeoBox(
                        color: MangaColors.gold,
                        child: const Text(
                          '👑 PRO gold nameplate and crown are not sold for coins.',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MangaButton(
                        label: data.isProUser ? 'PRO IS ACTIVE' : 'SEE PRO PERKS',
                        color: MangaColors.pink,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ProUpgradeScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pack extends StatelessWidget {
  const _Pack({
    required this.title,
    required this.detail,
    required this.price,
    required this.onBuy,
  });

  final String title;
  final String detail;
  final int price;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeoBox(
        color: MangaColors.white,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MangaButton(
              label: '🪙 $price',
              expand: false,
              color: MangaColors.mint,
              onPressed: onBuy,
            ),
          ],
        ),
      ),
    );
  }
}
