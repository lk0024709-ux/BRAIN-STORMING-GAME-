import 'package:flutter/material.dart';

import 'manga_colors.dart';

class MangaTheme {
  MangaTheme._();

  static ThemeData build() {
    const ink = MangaColors.ink;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: MangaColors.paper,
      colorScheme: const ColorScheme.light(
        primary: ink,
        onPrimary: Colors.white,
        secondary: MangaColors.pink,
        onSecondary: ink,
        surface: MangaColors.paper,
        onSurface: ink,
        error: MangaColors.red,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: ink,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: -0.5,
          height: 0.95,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: 0.2,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w900,
          color: ink,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: ink,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.3,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

String formatStopwatch(Duration duration) {
  final seconds = duration.inMilliseconds / 1000.0;
  if (seconds >= 3600) {
    return seconds.toStringAsFixed(0);
  }
  final raw = seconds.toStringAsFixed(1);
  return raw.padLeft(4, '0');
}

class DojoFrame extends StatelessWidget {
  const DojoFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: child,
      ),
    );
  }
}
