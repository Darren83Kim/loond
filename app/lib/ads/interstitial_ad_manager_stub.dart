/// Web / desktop — no interstitial.
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  void preload() {}

  /// Returns false (nothing shown).
  Future<bool> maybeShowAfterDetailPop() async => false;
}
