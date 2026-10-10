import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../content/legal_copy.dart';
import '../controllers/profile_controller.dart';
import '../models/age_band.dart';
import '../services/question_generator.dart';
import '../theme/cyber_palette.dart';
import '../theme/manga_theme.dart';
import '../widgets/cyber_widgets.dart';
import 'legal_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  double _age = 14;
  bool _ageTouched = false;
  bool _accepted = false;
  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _ageValue => _age.round();

  bool get _canEnter {
    final name = _name.text.trim();
    return _ageTouched &&
        _accepted &&
        name.isNotEmpty &&
        name.length <= 16 &&
        !_saving;
  }

  void _selectAge(int age) {
    setState(() {
      _age = age.toDouble();
      _ageTouched = true;
    });
  }

  Future<void> _enter() async {
    if (!_canEnter) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final profile = context.read<ProfileController>();
    try {
      // Save the age gate before the player can open a purchase flow.
      await profile.completeOnboarding(
        nickname: _name.text.trim(),
        age: _ageValue,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save onboarding: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _saveError = 'Could not save your profile. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openLegal(String title, String body) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LegalScreen(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final band = ageBandFor(_ageValue);
    final preview = QuestionGenerator(random: Random(_ageValue * 17)).generate(
      _ageValue,
    );
    final child = isCoppaChild(_ageValue);
    final previewFormula = preview.display.contains('?')
        ? preview.display
        : '${preview.display} = ?';

    return Scaffold(
      backgroundColor: CyberPalette.background,
      body: CyberBackdrop(
        child: SafeArea(
          child: DojoFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              children: [
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        CyberPalette.blue,
                        CyberPalette.purple,
                        CyberPalette.pink,
                      ],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      'BRAINSPEED IQ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: CyberPalette.pink,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AGE GATE · VERIFY TO ENTER THE DOJO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CyberPalette.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                CyberPanel(
                  accent: CyberPalette.blue,
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'NICKNAME',
                              style: TextStyle(
                                color: CyberPalette.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 19,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          const _HeroProfilePortrait(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _name,
                        maxLength: 16,
                        textCapitalization: TextCapitalization.words,
                        keyboardType: TextInputType.name,
                        onChanged: (_) => setState(() {}),
                        cursorColor: CyberPalette.pink,
                        style: const TextStyle(
                          color: CyberPalette.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your nickname...',
                          hintStyle: const TextStyle(
                            color: CyberPalette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                          suffixIcon: const Icon(
                            Icons.edit_rounded,
                            color: CyberPalette.pink,
                          ),
                          filled: true,
                          fillColor: CyberPalette.panelDeep,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: CyberPalette.blue.withValues(
                                alpha: 0.75,
                              ),
                              width: 1.4,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: CyberPalette.pink,
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CyberPanel(
                  accent: CyberPalette.pink,
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text(
                              'AGE',
                              style: TextStyle(
                                color: CyberPalette.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 19,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Text(
                            '$_ageValue${_ageValue >= 60 ? '+' : ''}',
                            style: const TextStyle(
                              color: CyberPalette.blue,
                              fontWeight: FontWeight.w900,
                              fontSize: 42,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _ageTouched
                            ? '${band.label} TRACK · ${band.blurb}'
                            : 'Move the slider to confirm your age group.',
                        style: const TextStyle(
                          color: CyberPalette.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: CyberPalette.blue,
                          inactiveTrackColor:
                              CyberPalette.pink.withValues(alpha: 0.55),
                          trackHeight: 8,
                          thumbColor: CyberPalette.pink,
                          overlayColor: CyberPalette.purple.withValues(
                            alpha: 0.2,
                          ),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                            elevation: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 23,
                          ),
                          valueIndicatorColor: CyberPalette.purple,
                          valueIndicatorTextStyle: const TextStyle(
                            color: CyberPalette.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: Slider(
                          value: _age,
                          min: 6,
                          max: 60,
                          divisions: 54,
                          label: _ageValue >= 60 ? '60+' : '$_ageValue',
                          onChanged: (value) {
                            setState(() {
                              _age = value;
                              _ageTouched = true;
                            });
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _AgeGroupButton(
                              title: 'KID',
                              range: '6–12',
                              accent: CyberPalette.blue,
                              selected: band == AgeBand.kids,
                              onTap: () => _selectAge(8),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _AgeGroupButton(
                              title: 'TEEN',
                              range: '13–17',
                              accent: CyberPalette.purple,
                              selected: band == AgeBand.teens,
                              onTap: () => _selectAge(14),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _AgeGroupButton(
                              title: 'ADULT',
                              range: '18+',
                              accent: CyberPalette.pink,
                              selected: band == AgeBand.adults,
                              onTap: () => _selectAge(21),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'SAMPLE CLOUD · ${preview.kind.cloudLabel}',
                    style: const TextStyle(
                      color: CyberPalette.cyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: CyberPalette.blue,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SampleQuestionPreview(
                  formula: previewFormula,
                  ageBand: band.label,
                ),
                const SizedBox(height: 13),
                CyberPanel(
                  accent: CyberPalette.edge,
                  padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
                  radius: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _accepted,
                        activeColor: CyberPalette.pink,
                        checkColor: CyberPalette.text,
                        side: const BorderSide(
                          color: CyberPalette.cyan,
                          width: 1.8,
                        ),
                        visualDensity: VisualDensity.compact,
                        onChanged: (value) =>
                            setState(() => _accepted = value ?? false),
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'I agree to the ',
                              style: TextStyle(
                                color: CyberPalette.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            _LegalLink(
                              label: 'Terms of Service',
                              onTap: () => _openLegal(
                                'Terms of Use',
                                LegalCopy.terms,
                              ),
                            ),
                            const Text(
                              ' and ',
                              style: TextStyle(
                                color: CyberPalette.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            _LegalLink(
                              label: 'Privacy Policy',
                              onTap: () => _openLegal(
                                'Privacy Policy',
                                LegalCopy.privacy,
                              ),
                            ),
                            const Text(
                              '.',
                              style: TextStyle(
                                color: CyberPalette.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 10),
                  CyberPanel(
                    accent: CyberPalette.pink,
                    child: Text(
                      _saveError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CyberPalette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                CyberPrimaryButton(
                  label: _saving ? 'OPENING...' : 'ENTER THE DOJO',
                  subtitle: _saving
                      ? 'SAVING YOUR PROFILE'
                      : 'AGE-BASED QUIZ · ${band.label} TRACK',
                  icon: Icons.login_rounded,
                  onPressed: _canEnter ? _enter : null,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    child
                        ? 'UNDER 13 · PARENT CHECK BEFORE PURCHASES · NO ADS'
                        : 'SECURE PROFILE · NO ADS · AGE-BASED QUESTIONS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CyberPalette.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.2,
                    ),
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

class _HeroProfilePortrait extends StatelessWidget {
  const _HeroProfilePortrait();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [CyberPalette.cyan, CyberPalette.blue, CyberPalette.purple],
        ),
        boxShadow: [
          BoxShadow(
            color: CyberPalette.blue.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: ColoredBox(
          color: CyberPalette.panelDeep,
          child: Image.asset(
            'assets/images/hero_avatar.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.12),
            semanticLabel: 'Hero portrait',
          ),
        ),
      ),
    );
  }
}

class _AgeGroupButton extends StatelessWidget {
  const _AgeGroupButton({
    required this.title,
    required this.range,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String range;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          height: 66,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, CyberPalette.pink],
                  )
                : null,
            color: selected ? null : CyberPalette.panelDeep,
            borderRadius: radius,
            border: Border.all(
              color: accent.withValues(alpha: selected ? 0.95 : 0.65),
              width: selected ? 1.6 : 1.1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: CyberPalette.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                range,
                style: TextStyle(
                  color: CyberPalette.text.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleQuestionPreview extends StatelessWidget {
  const _SampleQuestionPreview({
    required this.formula,
    required this.ageBand,
  });

  final String formula;
  final String ageBand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF211A49),
            Color(0xFF111A37),
            Color(0xFF231541),
          ],
        ),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: CyberPalette.purple.withValues(alpha: 0.8),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: CyberPalette.purple.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud, color: CyberPalette.blue, size: 30),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  formula,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CyberPalette.pink,
                    fontWeight: FontWeight.w900,
                    fontSize: 27,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'QUICK BRAINWARM-UP · $ageBand AGE TRACK · PREVIEW ONLY',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CyberPalette.text,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: CyberPalette.cyan,
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.underline,
          decorationColor: CyberPalette.pink,
        ),
      ),
    );
  }
}
