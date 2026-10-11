import 'package:flutter/material.dart';

import '../models/skin_shop.dart';
import '../theme/manga_colors.dart';
import 'neo_widgets.dart';

/// One Battle Dojo store card: the generated 512x512 polygon art, the rarity
/// tag, and the coin price drawn in the store's yellow (#FFD700). Tiers that
/// carry a heart show it in red (#FF0000).
class SkinCard extends StatelessWidget {
  const SkinCard({
    super.key,
    required this.catalog,
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.coins,
    required this.onTap,
  });

  final SkinCatalog catalog;
  final SkinItem skin;
  final bool owned;
  final bool equipped;
  final int coins;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final frame = catalog.frameFor(skin);
    final accent = Color(skin.cardHex);
    final coin = Color(catalog.coinColorHex);
    final heart = Color(catalog.heartColorHex);
    final affordable = owned || coins >= skin.price;

    return GestureDetector(
      onTap: onTap,
      child: NeoBox(
        color: MangaColors.white,
        padding: const EdgeInsets.all(6),
        offset: const Offset(3, 3),
        borderWidth: 2.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      skin.cardFor(equipped),
                      fit: BoxFit.contain,
                      semanticLabel: '${skin.name} skin card',
                    ),
                  ),
                  Positioned(
                    left: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        border: Border.all(color: MangaColors.ink, width: 1.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        frame.label,
                        style: const TextStyle(
                          color: MangaColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  if (skin.hasHeart)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Icon(
                        Icons.favorite,
                        size: 14,
                        color: heart,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              skin.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 3),
            if (equipped)
              _StatusPill(
                label: 'EQUIPPED',
                fill: MangaColors.green,
              )
            else if (owned)
              _StatusPill(
                label: 'TAP TO EQUIP',
                fill: MangaColors.mint,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on,
                    size: 13,
                    color: affordable ? coin : MangaColors.disabledInk,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      catalog.priceLabel(skin),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: affordable ? coin : MangaColors.disabledInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.fill});

  final String label;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: MangaColors.ink, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: MangaColors.ink,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
