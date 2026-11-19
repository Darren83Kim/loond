/// The detail banner takes height only after a successful load.
///
/// Consent off, in-flight, and no-fill stay at zero so 「공식 원문 보기」
/// is not left under a blank gap.
bool showLoadedBannerSlot({required bool allowed, required bool loaded}) {
  return allowed && loaded;
}
