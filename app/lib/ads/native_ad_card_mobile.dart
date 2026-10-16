import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_stub.dart';
import '../theme/app_theme.dart';
import 'ad_config.dart';
import 'ads_consent.dart';

/// In-feed native ad. Uses [TemplateType.small] with a fixed height so the
/// platform view cannot overflow and paint over neighboring cards.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _started = false;

  /// Small template needs ~90–120 logical px; keep a stable slot.
  static const double _adHeight = 120;

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
      _ad?.dispose();
      _ad = null;
      _started = false;
      setState(() => _loaded = false);
    }
  }

  void _maybeLoad() {
    if (!_allowed || _started || _ad != null) return;
    _started = true;
    _load();
  }

  void _load() {
    final ad = NativeAd(
      adUnitId: AdConfig.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as NativeAd;
            _loaded = true;
          });
          AnalyticsStub.adImpression('native', AdConfig.nativeAdUnitId);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _started = false;
          debugPrint('[ads] native failed: $error');
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppTheme.seed,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF1A1A1A),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF5F6368),
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF5F6368),
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    AdsConsent.instance.removeListener(_onConsent);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.adsEnabled || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              '광고',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: _adHeight,
            width: double.infinity,
            child: ClipRect(
              child: AdWidget(ad: _ad!),
            ),
          ),
        ],
      ),
    );
  }
}
