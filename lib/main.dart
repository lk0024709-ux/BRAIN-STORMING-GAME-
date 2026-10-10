import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'theme/manga_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Render a real Flutter frame before waiting on or calling platform channels.
  runApp(const BrainSpeedApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_configureSystemChrome());
  });
}

Future<void> _configureSystemChrome() async {
  try {
    await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: MangaColors.paper,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (error, stackTrace) {
    // A chrome/orientation plugin failure must not prevent the game from
    // rendering; the Android manifest also requests portrait orientation.
    debugPrint('System UI setup skipped: $error\n$stackTrace');
  }
}
