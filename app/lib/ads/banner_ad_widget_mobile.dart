import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_stub.dart';
import '../theme/app_theme.dart';
import 'ad_config.dart';

/// Bottom banner with 「광고」 label. Fixed slot height; no-op when ads disabled.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdConfig.adsEnabled) return;
    _load();
  }

  void _load() {
    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _loaded = true;
          });
          AnalyticsStub.adImpression('banner', AdConfig.bannerAdUnitId);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // ignore: avoid_print
          print('[ads] banner failed: $error');
        },
      ),
    );
    banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.adsEnabled) {
      return const SizedBox.shrink();
    }
    final h = AdSize.banner.height.toDouble();
    final w = AdSize.banner.width.toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '광고',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
        ColoredBox(
          color: AppTheme.surfaceMuted,
          child: SizedBox(
            width: double.infinity,
            height: h,
            child: !_loaded || _banner == null
                ? const SizedBox.shrink()
                : Center(
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: ClipRect(child: AdWidget(ad: _banner!)),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
