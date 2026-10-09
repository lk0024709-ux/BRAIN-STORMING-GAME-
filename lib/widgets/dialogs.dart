import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/manga_colors.dart';
import 'neo_widgets.dart';

enum ShortageChoice { coins, freeHint }

Future<ShortageChoice?> showCoinShortageDialog({
  required BuildContext context,
  required int cost,
  required int balance,
  required bool canWatchAd,
  required bool offerFreeHint,
}) {
  return showDialog<ShortageChoice>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: NeoBox(
          color: MangaColors.paper,
          offset: const Offset(6, 6),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'NOT ENOUGH COINS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'This tool costs $cost. You have $balance.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (!canWatchAd)
                const Text(
                  'Ads are off for this player. Solve rounds to earn coins.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                )
              else ...[
                if (offerFreeHint)
                  MangaButton(
                    label: 'WATCH AD FOR A FREE HINT',
                    color: MangaColors.yellow,
                    onPressed: () =>
                        Navigator.pop(context, ShortageChoice.freeHint),
                  ),
                if (offerFreeHint) const SizedBox(height: 8),
                MangaButton(
                  label: 'WATCH AD FOR +20 COINS',
                  color: MangaColors.blue,
                  onPressed: () => Navigator.pop(context, ShortageChoice.coins),
                ),
              ],
              const SizedBox(height: 8),
              MangaButton(
                label: 'NOT NOW',
                color: MangaColors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> showParentalGate(BuildContext context) async {
  final random = Random();
  final a = 4 + random.nextInt(8);
  final b = 3 + random.nextInt(8);
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      String? error;
      return StatefulBuilder(
        builder: (context, setLocal) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: NeoBox(
              color: MangaColors.paper,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'PARENT CHECK',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A grown-up needs to solve $a + $b before a purchase.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: MangaColors.white,
                      hintText: 'Answer',
                      errorText: error,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: MangaColors.ink, width: 3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  MangaButton(
                    label: 'CHECK',
                    color: MangaColors.yellow,
                    onPressed: () {
                      if (int.tryParse(controller.text.trim()) == a + b) {
                        Navigator.pop(context, true);
                      } else {
                        setLocal(() => error = 'Not quite. Try again.');
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  MangaButton(
                    label: 'CANCEL',
                    color: MangaColors.white,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  controller.dispose();
  return result == true;
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  Color confirmColor = MangaColors.red,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: NeoBox(
          color: MangaColors.paper,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              MangaButton(
                label: confirmLabel,
                color: confirmColor,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              MangaButton(
                label: 'CANCEL',
                color: MangaColors.white,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}
