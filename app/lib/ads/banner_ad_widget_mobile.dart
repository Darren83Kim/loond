import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_stub.dart';
import '../theme/app_theme.dart';
import 'ad_config.dart';
import 'ads_consent.dart';
import 'banner_slot.dart';

/// Banner with 「광고」 label. Zero height until a fill arrives.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _started = false;

  bool get _allowed =>
      AdConfig.adsEnabled && AdsConsent.instance.canRequestAds;

  @override
  void initState() {
    super.initState();
    AdsConsent.instance.addListener(_onConsent);
    _maybeLoad();
  }

  void _onConsent() {
    if (!mounted) return;
    if (_allowed) {
      _maybeLoad();
    } else {
      _banner?.dispose();
      _banner = null;
      _started = false;
      setState(() => _loaded = false);
    }
  }

  void _maybeLoad() {
    if (!_allowed || _started || _banner != null) return;
    _started = true;
    _load();
  }

  void _collapse() {
    if (!mounted) return;
    setState(() {
      _banner = null;
      _loaded = false;
      _started = false;
    });
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
          final loaded = ad as BannerAd;
          if (loaded.size.height <= 0 || loaded.size.width <= 0) {
            loaded.dispose();
            _collapse();
            return;
          }
          setState(() {
            _banner = loaded;
            _loaded = true;
          });
          AnalyticsStub.adImpression('banner', AdConfig.bannerAdUnitId);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[ads] banner failed: $error');
          _collapse();
        },
      ),
    );
    banner.load().catchError((Object error) {
      debugPrint('[ads] banner load threw: $error');
      banner.dispose().catchError((Object _) {});
      _collapse();
    });
  }

  @override
  void dispose() {
    AdsConsent.instance.removeListener(_onConsent);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    final loaded = _loaded &&
        banner != null &&
        banner.size.height > 0 &&
        banner.size.width > 0;
    if (banner == null ||
        !showLoadedBannerSlot(allowed: _allowed, loaded: loaded)) {
      return const SizedBox.shrink();
    }
    final h = banner.size.height.toDouble();
    final w = banner.size.width.toDouble();
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
            child: Center(
              child: SizedBox(
                width: w,
                height: h,
                child: ClipRect(child: AdWidget(ad: banner)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
