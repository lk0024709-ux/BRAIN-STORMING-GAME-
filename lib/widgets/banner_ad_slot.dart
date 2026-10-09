import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../services/ad_service.dart';
import '../theme/manga_colors.dart';

class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loading = false;
  bool _loaded = false;
  bool _failed = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _load(AdService ads, double width) async {
    if (_loading || _ad != null || !ads.forcedAdsAllowed) return;
    _loading = true;
    _failed = false;
    final adaptive =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );
    if (!mounted || !ads.forcedAdsAllowed) {
      _loading = false;
      return;
    }
    final size = adaptive ?? AdSize.banner;
    final ad = BannerAd(
      adUnitId: AppConfig.bannerUnitId,
      size: size,
      request: ads.request,
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _loaded = true;
            _loading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
            _loading = false;
            _failed = true;
          });
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  void _drop() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdService>();
    if (!ads.forcedAdsAllowed) {
      if (_ad != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_drop);
        });
      }
      return const SizedBox.shrink();
    }
    if (_ad == null && !_loading && !_failed) {
      final width = MediaQuery.sizeOf(context).width;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(ads, width);
      });
    }
    if (!_loaded || _ad == null) {
      return const SizedBox(height: 8);
    }
    final ad = _ad!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: MangaColors.white,
          border: Border.all(color: MangaColors.ink, width: 3),
        ),
        width: double.infinity,
        height: ad.size.height.toDouble() + 8,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
