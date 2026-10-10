import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../content/legal_copy.dart';
import '../controllers/profile_controller.dart';
import '../models/age_band.dart';
import '../services/question_generator.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/neo_widgets.dart';
import 'legal_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  double _age = 12;
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

  Future<void> _enter() async {
    if (!_canEnter) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final profile = context.read<ProfileController>();
    try {
      // Save the age gate before any optional ad or billing SDK is initialized.
      await profile.completeOnboarding(
        nickname: _name.text.trim(),
        age: _ageValue,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save onboarding: $error\n$stackTrace');
      if (mounted) {
        setState(() => _saveError = 'Could not save your profile. Please try again.');
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
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const Text(
                  'BRAINSPEED IQ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    letterSpacing: -0.5,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Age gate first. Then the dojo opens.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                NeoBox(
                  color: MangaColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Nickname'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _name,
                        maxLength: 16,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'What should the rival call you?',
                          filled: true,
                          fillColor: MangaColors.paper,
                          counterText: '',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MangaColors.ink,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                NeoBox(
                  color: MangaColors.yellow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle('Age  ·  $_ageValue${_ageValue >= 60 ? '+' : ''}'),
                      const SizedBox(height: 4),
                      Text(
                        _ageTouched
                            ? '${band.label} dojo · ${band.blurb}'
                            : 'Move the slider so we know which dojo to open.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Slider(
                        value: _age,
                        min: 6,
                        max: 60,
                        divisions: 54,
                        activeColor: MangaColors.ink,
                        inactiveColor: MangaColors.white,
                        label: _ageValue >= 60 ? '60+' : '$_ageValue',
                        onChanged: (value) {
                          setState(() {
                            _age = value;
                            _ageTouched = true;
                          });
                        },
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          _AgeChip(
                            label: 'Kid · 8',
                            onTap: () => setState(() {
                              _age = 8;
                              _ageTouched = true;
                            }),
                          ),
                          _AgeChip(
                            label: 'Teen · 14',
                            onTap: () => setState(() {
                              _age = 14;
                              _ageTouched = true;
                            }),
                          ),
                          _AgeChip(
                            label: 'Adult · 21',
                            onTap: () => setState(() {
                              _age = 21;
                              _ageTouched = true;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sample cloud: ${preview.display}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      if (child) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Under 13: no ads, no ad tracking. COPPA mode stays on until the saved age changes.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                NeoBox(
                  color: MangaColors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _accepted = !_accepted),
                        child: Icon(
                          _accepted
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: MangaColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _accepted = !_accepted),
                              child: const Text(
                                'I agree to the ',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _Link(
                              label: 'Terms',
                              onTap: () => _openLegal('Terms of Use', LegalCopy.terms),
                            ),
                            const Text(
                              ' and ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            _Link(
                              label: 'Privacy Policy',
                              onTap: () => _openLegal(
                                'Privacy Policy',
                                LegalCopy.privacy,
                              ),
                            ),
                            const Text(
                              '.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 12),
                  NeoBox(
                    color: const Color(0xFFFFE8EE),
                    child: Text(
                      _saveError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MangaColors.red,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                MangaButton(
                  label: _saving ? 'OPENING...' : 'ENTER THE DOJO',
                  color: MangaColors.pink,
                  onPressed: _canEnter ? _enter : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900, color: MangaColors.ink),
      ),
      backgroundColor: MangaColors.white,
      side: const BorderSide(color: MangaColors.ink, width: 2),
      onPressed: onTap,
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
