import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/profile_controller.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/iap_service.dart';
import 'services/storage_service.dart';
import 'theme/manga_colors.dart';
import 'theme/manga_theme.dart';
import 'widgets/neo_widgets.dart';

/// Starts the Flutter UI immediately, then loads persisted profile data.
/// Billing is initialized only from explicit purchase flows.
class BrainSpeedApp extends StatefulWidget {
  const BrainSpeedApp({super.key});

  @override
  State<BrainSpeedApp> createState() => _BrainSpeedAppState();
}

class _BrainSpeedAppState extends State<BrainSpeedApp> {
  late Future<_AppServices> _services;

  @override
  void initState() {
    super.initState();
    _services = _loadServices();
  }

  Future<_AppServices> _loadServices() async {
    final storage = await StorageService.create();
    final profile = ProfileController(storage);
    await profile.load();
    return _AppServices(
      profile: profile,
      iap: IAPService(),
    );
  }

  void _retry() {
    setState(() => _services = _loadServices());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainSpeed IQ',
      debugShowCheckedModeBanner: false,
      theme: MangaTheme.build(),
      home: FutureBuilder<_AppServices>(
        future: _services,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StartupErrorScreen(
              error: snapshot.error,
              onRetry: _retry,
            );
          }
          final services = snapshot.data;
          if (services == null) return const _StartupScreen();

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileController>.value(
                value: services.profile,
              ),
              ChangeNotifierProvider<IAPService>.value(value: services.iap),
            ],
            child: const _RootGate(),
          );
        },
      ),
    );
  }
}

class _AppServices {
  const _AppServices({
    required this.profile,
    required this.iap,
  });

  final ProfileController profile;
  final IAPService iap;
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final ready = context.watch<ProfileController>().onboardingComplete;
    return ready ? const HomeScreen() : const OnboardingScreen();
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: Center(
              child: NeoBox(
                color: MangaColors.yellow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BRAINSPEED IQ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: MangaColors.ink,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'OPENING THE DOJO...',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: NeoBox(
                  color: MangaColors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'THE DOJO COULD NOT OPEN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MangaColors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your profile could not be loaded. Your progress has not been changed. Check the device and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (kDebugMode && error != null) ...[
                        const SizedBox(height: 10),
                        SelectableText(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: MangaColors.disabledInk,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      MangaButton(
                        label: 'TRY AGAIN',
                        color: MangaColors.yellow,
                        icon: Icons.refresh,
                        onPressed: onRetry,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
