import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../content/legal_copy.dart';
import '../controllers/profile_controller.dart';
import '../models/age_band.dart';
import '../services/ad_service.dart';
import '../services/iap_service.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/neo_widgets.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  int? _draftAge;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: context.read<ProfileController>().nickname,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _ageChanged(double value) async {
    final profile = context.read<ProfileController>();
    final ads = context.read<AdService>();
    await profile.updateAge(value.round());
    await ads.configure(age: profile.userAge, isPro: profile.isProUser);
    if (!mounted) return;
    if (ads.needsRestartForChildMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ads are off. Restart the app so child-safe mode fully applies.',
          ),
        ),
      );
    }
  }

  Future<void> _reset() async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'RESET TRAINING?',
      body:
          'XP, coins, rank, streaks, and tokens go back to a fresh dojo. Pro and your age stay.',
      confirmLabel: 'RESET',
    );
    if (!ok || !mounted) return;
    await context.read<ProfileController>().resetTraining();
  }

  void _legal(String title, String body) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LegalScreen(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final ads = context.watch<AdService>();
    final iap = context.watch<IAPService>();
    final data = profile.profile;
    final band = ageBandFor(data.userAge);
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Text(
                      'SETTINGS',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
                    ),
                  ],
                ),
                NeoBox(
                  color: MangaColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Nickname'),
                      TextField(
                        controller: _name,
                        maxLength: 16,
                        decoration: const InputDecoration(counterText: ''),
                        onSubmitted: profile.updateNickname,
                      ),
                      MangaButton(
                        label: 'SAVE NAME',
                        color: MangaColors.yellow,
                        onPressed: () => profile.updateNickname(_name.text),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                NeoBox(
                  color: MangaColors.paperDeep,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(
                        'Age ${data.userAge}${data.userAge >= 60 ? '+' : ''} · ${band.label}',
                      ),
                      Text(
                        data.isChild
                            ? 'COPPA mode: ad SDK stays off.'
                            : band.blurb,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Slider(
                        value: (_draftAge ?? data.userAge).toDouble(),
                        min: 6,
                        max: 60,
                        divisions: 54,
                        activeColor: MangaColors.ink,
                        label: '${(_draftAge ?? data.userAge).round()}',
                        onChanged: (value) => setState(() => _draftAge = value.round()),
                        onChangeEnd: (value) async {
                          await _ageChanged(value);
                          if (mounted) setState(() => _draftAge = null);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                NeoBox(
                  color: MangaColors.white,
                  onTap: () => profile.setSound(!data.soundOn),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.soundOn ? 'Sound on' : 'Sound off',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Icon(data.soundOn ? Icons.volume_up : Icons.volume_off),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                MangaButton(
                  label: 'PRIVACY POLICY',
                  color: MangaColors.white,
                  onPressed: () => _legal('Privacy Policy', LegalCopy.privacy),
                ),
                const SizedBox(height: 8),
                MangaButton(
                  label: 'TERMS OF USE',
                  color: MangaColors.white,
                  onPressed: () => _legal('Terms of Use', LegalCopy.terms),
                ),
                if (ads.privacyOptionsRequired) ...[
                  const SizedBox(height: 8),
                  MangaButton(
                    label: 'AD PRIVACY OPTIONS',
                    color: MangaColors.blue,
                    onPressed: ads.showPrivacyOptions,
                  ),
                ],
                const SizedBox(height: 8),
                MangaButton(
                  label: 'RESTORE PURCHASES',
                  color: MangaColors.gold,
                  onPressed: iap.restore,
                ),
                const SizedBox(height: 8),
                MangaButton(
                  label: 'RESET TRAINING DATA',
                  color: MangaColors.red,
                  onPressed: _reset,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  MangaButton(
                    label: data.isProUser ? 'DEBUG: DROP PRO' : 'DEBUG: GRANT PRO',
                    color: MangaColors.paperDeep,
                    onPressed: () async {
                      await profile.setProForDebug(!data.isProUser);
                      if (profile.isProUser) {
                        ads.onProUnlocked();
                      } else {
                        await ads.configure(
                          age: profile.userAge,
                          isPro: false,
                        );
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  '${AppConfig.appName} ${AppConfig.versionLabel}\n${ads.mediationLabel}\n${ads.usingTestUnits ? 'Test ad units are on. Replace them before release.' : 'Production ad units.'}\n${AppConfig.supportEmail}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
