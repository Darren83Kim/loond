/// EPIC 3/6 이벤트 스텁 — 실제 전송 없이 print 로깅.
class AnalyticsStub {
  static void opportunityOpen(String opportunityId) {
    // ignore: avoid_print
    print('[analytics] opportunity_open id=$opportunityId');
  }

  static void outboundClick(String opportunityId, String url) {
    // ignore: avoid_print
    print('[analytics] outbound_click id=$opportunityId url=$url');
  }

  /// Alongside outbound_click for CTR vs ad exposure analysis (EPIC 6).
  static void adImpression(String format, String adUnitId) {
    // ignore: avoid_print
    print('[analytics] ad_impression format=$format unit=$adUnitId');
  }
}
