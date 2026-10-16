import 'package:flutter_test/flutter_test.dart';
import 'package:loond/ads/ad_config.dart';

void main() {
  test('release units are selected only when useReleaseUnits is true', () {
    expect(
      AdConfig.selectUnit(
        testId: AdConfig.androidTestAppId,
        releaseId: AdConfig.androidReleaseAppId,
        useReleaseUnits: false,
      ),
      'ca-app-pub-3940256099942544~3347511713',
    );
    expect(
      AdConfig.selectUnit(
        testId: 'test-banner',
        releaseId: 'ca-app-pub-8022343674155817/1620279320',
        useReleaseUnits: true,
      ),
      'ca-app-pub-8022343674155817/1620279320',
    );
    expect(
      AdConfig.selectUnit(
        testId: 'test-interstitial',
        releaseId: 'ca-app-pub-8022343674155817/3817313230',
        useReleaseUnits: true,
      ),
      'ca-app-pub-8022343674155817/3817313230',
    );
    expect(
      AdConfig.selectUnit(
        testId: 'test-native',
        releaseId: 'ca-app-pub-8022343674155817/4535498538',
        useReleaseUnits: true,
      ),
      'ca-app-pub-8022343674155817/4535498538',
    );
  });

  test('widget tests run as debug, so Android release units stay off', () {
    expect(AdConfig.useReleaseAdUnits, isFalse);
    expect(AdConfig.bannerAdUnitId, contains('3940256099942544'));
    expect(AdConfig.interstitialAdUnitId, contains('3940256099942544'));
    expect(AdConfig.nativeAdUnitId, contains('3940256099942544'));
  });
}
