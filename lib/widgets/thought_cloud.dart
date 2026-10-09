import 'package:flutter/material.dart';

import '../theme/manga_colors.dart';

/// Large central Neo-Brutalist Manga Thought Cloud (💭)
/// displaying the math puzzle and optional in-cloud yellow hint banner.
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
            // Cloud puffs leading to character header
            Positioned(
              left: 24,
              bottom: 2,
              child: _Puff(size: 20),
            ),
            Positioned(
              left: 42,
              bottom: 12,
              child: _Puff(size: 14),
            ),
            Positioned(
              right: 28,
              bottom: 2,
              child: _Puff(size: 18),
            ),
            Positioned(
              right: 44,
              bottom: 12,
              child: _Puff(size: 12),
            ),

            // Main Thought Cloud Body
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
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
                    // Manga Cloud Header Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: MangaColors.paperDeep,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: MangaColors.ink, width: 2),
                      ),
                      child: Text(
                        '💭  $label',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Central Math Puzzle Formula
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formula,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 38,
                          height: 1.1,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Yellow Banner inside Thought Cloud when Hint is activated
                    if (hint != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: MangaColors.yellow,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: MangaColors.ink, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: MangaColors.ink,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hint!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  height: 1.25,
                                  color: MangaColors.ink,
                                ),
                              ),
                            ),
                          ],
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
        boxShadow: const [
          BoxShadow(
            color: MangaColors.ink,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
    );
  }
}
