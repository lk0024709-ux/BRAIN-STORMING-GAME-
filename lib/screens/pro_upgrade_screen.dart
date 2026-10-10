import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/profile_controller.dart';
import '../services/iap_service.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/manga_avatar.dart';
import '../widgets/neo_widgets.dart';

/// High-converting Manga-style Pro Upgrade Screen.
///
/// Features characters excitedly presenting perks, glowing golden avatar frame
/// showcase, clear neo-brutalist benefit breakdown, and a large "Upgrade Now" button.
class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<IAPService>().prepareStore());
    });
  }

  Future<void> _buy() async {
    final profile = context.read<ProfileController>();
    if (profile.isChild) {
      final allowed = await showParentalGate(context);
      if (!allowed || !mounted) return;
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
                // Top Navigation Bar
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: MangaColors.ink,
                        size: 26,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'VIP PRO UPGRADE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (pro) const ProBadge(),
                  ],
                ),
                const SizedBox(height: 10),

                // Character Presentation Showcase Hero Card
                NeoBox(
                  color: MangaColors.gold,
                  offset: const Offset(6, 6),
                  borderWidth: 3,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MangaColors.ink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '⚡ THE ULTIMATE BRAIN SPEED ⚡',
                          style: TextStyle(
                            color: MangaColors.yellow,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Characters Excitingly Presenting the Perks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const MangaAvatar(
                                rival: false,
                                pro: true,
                                size: 84,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: MangaColors.hero,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'HERO · PRO',
                                  style: TextStyle(
                                    color: MangaColors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Column(
                            children: [
                              Text(
                                'VS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const MangaAvatar(rival: true, size: 84),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: MangaColors.rival,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'RIVAL',
                                  style: TextStyle(
                                    color: MangaColors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Comic Speech Dialogue Reactions
                      NeoBox(
                        color: MangaColors.white,
                        padding: const EdgeInsets.all(10),
                        offset: const Offset(3, 3),
                        borderWidth: 2,
                        child: Column(
                          children: [
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⚡ ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    'HERO: "2× XP on every solve and zero ad popups! Let\'s forge Diamond rank!"',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💢 ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    'RIVAL: "Tch! With 2× XP, you\'ll reach Diamond twice as fast as me?!"',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      height: 1.25,
                                      color: MangaColors.rival,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // High-Converting Manga Perk Cards
                const SectionTitle('PRO PERKS & PRIVILEGES'),
                const SizedBox(height: 10),

                const _PerkCard(
                  icon: '🚫',
                  title: '100% AD-FREE FOREVER',
                  badge: 'PURE FOCUS',
                  badgeColor: MangaColors.pink,
                  body:
                      'Banner and Interstitial ads are completely removed immediately. Zero interruptions while solving so you stay in the flow zone.',
                ),
                const _PerkCard(
                  icon: '⚡',
                  title: '2× SPEED XP BOOST',
                  badge: 'FAST TRACK',
                  badgeColor: MangaColors.yellow,
                  body:
                      'Earn double XP on every correct solve. Sub-5.0s Lightning solves award +80 XP! Forge Diamond Rank in half the time.',
                ),
                const _PerkCard(
                  icon: '👑',
                  title: 'GOLDEN AVATAR FRAME & CROWN',
                  badge: 'VIP COSMETIC',
                  badgeColor: MangaColors.gold,
                  body:
                      'A radiant golden neo-brutalism frame and glowing 👑 PRO crown badge displayed on your avatar across the entire dojo.',
                ),
                const _PerkCard(
                  icon: '🏷️',
                  title: 'PRO GOLD NAMEPLATE',
                  badge: 'EXCLUSIVE',
                  badgeColor: MangaColors.mint,
                  body:
                      'The legendary PRO Gold nameplate is automatically unlocked and equipped in all dialogue strips and match headers.',
                ),
                const _PerkCard(
                  icon: '♾️',
                  title: 'ONE-TIME LIFETIME UNLOCK',
                  badge: 'NO SUBSCRIPTION',
                  badgeColor: MangaColors.blue,
                  body:
                      'Pay once and keep Pro forever. No recurring charges, no hidden fees, and fully works offline.',
                ),

                const SizedBox(height: 12),

                // Pricing Card
                NeoBox(
                  color: MangaColors.white,
                  offset: const Offset(4, 4),
                  borderWidth: 2.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pro
                                  ? 'PRO IS ACTIVE ON THIS DEVICE'
                                  : 'LIFETIME ACCESS',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              pro
                                  ? 'All VIP perks are currently enabled.'
                                  : iap.priceLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: MangaColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Store Error and Status messages
                if (iap.error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8EE),
                      border: Border.all(color: MangaColors.red, width: 2),
                    ),
                    child: Text(
                      iap.error!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: MangaColors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                if (iap.statusMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MangaColors.paperDeep,
                      border: Border.all(color: MangaColors.ink, width: 2),
                    ),
                    child: Text(
                      iap.statusMessage!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                if (!pro && iap.storeQueryDone &&
                    (!iap.available || iap.product == null)) ...[
                  const SizedBox(height: 8),
                  MangaButton(
                    label: 'RECHECK PLAY STORE',
                    color: MangaColors.white,
                    icon: Icons.refresh,
                    onPressed: iap.purchasePending
                        ? null
                        : () => iap.prepareStore(force: true),
                  ),
                ],

                const SizedBox(height: 16),

                // Large "UPGRADE NOW" IAP Action Button
                MangaButton(
                  label: pro
                      ? '👑 PRO UNLOCKED'
                      : iap.purchasePending
                          ? 'WAITING ON THE STORE...'
                          : '⚡ UPGRADE TO PRO NOW',
                  subtitle: pro
                      ? 'You own lifetime VIP perks'
                      : profile.isChild
                          ? 'Parent check required · Google Play'
                          : 'One-time purchase · Instant activation',
                  color: MangaColors.gold,
                  icon: pro ? Icons.check_circle : Icons.workspace_premium,
                  onPressed: pro || iap.purchasePending ? null : _buy,
                ),

                const SizedBox(height: 10),

                // Restore Purchases Button
                MangaButton(
                  label: 'RESTORE PURCHASES',
                  subtitle: 'Already bought Pro on another device?',
                  color: MangaColors.white,
                  icon: Icons.restore,
                  onPressed: iap.purchasePending ? null : () => iap.restore(),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Purchases are processed securely through Google Play Billing. '
                  'Pro is a non-consumable lifetime product.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: MangaColors.disabledInk,
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

class _PerkCard extends StatelessWidget {
  const _PerkCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.body,
  });

  final String icon;
  final String title;
  final String badge;
  final Color badgeColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeoBox(
        color: MangaColors.white,
        offset: const Offset(4, 4),
        borderWidth: 2.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MangaColors.paper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MangaColors.ink, width: 2),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: MangaColors.ink, width: 1.5),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: MangaColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
