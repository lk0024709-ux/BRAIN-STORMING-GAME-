import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/profile_controller.dart';
import '../services/iap_service.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/manga_avatar.dart';
import '../widgets/neo_widgets.dart';

class ProUpgradeScreen extends StatelessWidget {
  const ProUpgradeScreen({super.key});

  Future<void> _buy(BuildContext context) async {
    final profile = context.read<ProfileController>();
    if (profile.isChild) {
      final allowed = await showParentalGate(context);
      if (!allowed || !context.mounted) return;
    }
    await context.read<IAPService>().buy();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final iap = context.watch<IAPService>();
    final pro = profile.isProUser;
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Text(
                        'PRO',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    if (pro) const ProBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                NeoBox(
                  color: MangaColors.gold,
                  offset: const Offset(6, 6),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          MangaAvatar(rival: false, pro: true, size: 96),
                          MangaAvatar(rival: true, size: 96),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The rival hates this offer.',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Text(
                        iap.productTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _Perk(
                  icon: '🚫',
                  title: 'Ad-free',
                  body:
                      'Banner and interstitial ads turn off the moment Pro unlocks. Rewarded ads stay optional if you still want bonus coins.',
                ),
                const _Perk(
                  icon: '⚡',
                  title: '2× XP',
                  body:
                      'Every correct solve pays double XP. Coins stay the same. Rank forges faster.',
                ),
                const _Perk(
                  icon: '👑',
                  title: 'VIP cosmetics',
                  body:
                      'Glowing golden nameplate and a crown badge on your avatar. Not sold in the coin shop.',
                ),
                const SizedBox(height: 8),
                NeoBox(
                  color: MangaColors.white,
                  child: Text(
                    pro
                        ? 'Pro is unlocked on this device.'
                        : 'Lifetime unlock · ${iap.priceLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (iap.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    iap.error!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: MangaColors.red,
                    ),
                  ),
                ],
                if (iap.statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    iap.statusMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 12),
                MangaButton(
                  label: pro
                      ? 'PRO UNLOCKED'
                      : iap.purchasePending
                          ? 'WAITING ON THE STORE...'
                          : 'UPGRADE NOW',
                  subtitle: profile.isChild
                      ? 'Parent check required'
                      : 'Google Play billing · ${AppConfig.proProductId}',
                  color: MangaColors.gold,
                  onPressed: pro || iap.purchasePending ? null : () => _buy(context),
                ),
                const SizedBox(height: 8),
                MangaButton(
                  label: 'RESTORE PURCHASES',
                  color: MangaColors.white,
                  onPressed: iap.purchasePending ? null : () => iap.restore(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeoBox(
        color: MangaColors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
