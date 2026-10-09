import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'controllers/profile_controller.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';
import 'services/storage_service.dart';
import 'theme/manga_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUIOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: MangaColors.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final storage = await StorageService.create();
  final profile = ProfileController(storage);
  await profile.load();
  final ads = AdService();
  final iap = IAPService();
  await iap.start(
    grantPro: () async {
      await profile.unlockPro();
      ads.onProUnlocked();
    },
  );
  runApp(BrainSpeedApp(profile: profile, ads: ads, iap: iap));

  if (!profile.onboardingComplete) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!profile.isProUser && iap.available) {
      unawaited(iap.restore());
    }
    unawaited(
      ads.configure(age: profile.userAge, isPro: profile.isProUser),
    );
  });
}
