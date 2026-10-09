import 'package:flutter/material.dart';

import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/neo_widgets.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: MangaColors.ink),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      NeoBox(
                        color: MangaColors.white,
                        child: Text(
                          body.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            fontSize: 14,
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
