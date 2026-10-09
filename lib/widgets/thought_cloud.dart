import 'package:flutter/material.dart';

import '../theme/manga_colors.dart';

class ThoughtCloud extends StatelessWidget {
  const ThoughtCloud({
    super.key,
    required this.label,
    required this.formula,
    this.hint,
  });

  final String label;
  final String formula;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 18,
              bottom: 0,
              child: _Puff(size: 18),
            ),
            Positioned(
              left: 34,
              bottom: 10,
              child: _Puff(size: 12),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: MangaColors.cloud,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: MangaColors.ink, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: MangaColors.ink,
                      offset: Offset(5, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '💭  $label',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formula,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: MangaColors.yellow,
                          border: Border.all(color: MangaColors.ink, width: 2.5),
                        ),
                        child: Text(
                          hint!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Puff extends StatelessWidget {
  const _Puff({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MangaColors.cloud,
        shape: BoxShape.circle,
        border: Border.all(color: MangaColors.ink, width: 2.5),
      ),
    );
  }
}
