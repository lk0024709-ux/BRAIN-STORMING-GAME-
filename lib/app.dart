import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/profile_controller.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';
import 'theme/manga_theme.dart';

class BrainSpeedApp extends StatelessWidget {
  const BrainSpeedApp({
    super.key,
    required this.profile,
    required this.ads,
    required this.iap,
  });

  final ProfileController profile;
  final AdService ads;
  final IAPService iap;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>.value(value: profile),
        ChangeNotifierProvider<AdService>.value(value: ads),
        ChangeNotifierProvider<IAPService>.value(value: iap),
      ],
      child: MaterialApp(
        title: 'BrainSpeed IQ',
        debugShowCheckedModeBanner: false,
        theme: MangaTheme.build(),
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final ready = context.watch<ProfileController>().onboardingComplete;
    return ready ? const HomeScreen() : const OnboardingScreen();
  }
}
