/// Web / non-IO stub — disk cache disabled.
class FeedDiskCache {
  FeedDiskCache([Object? ignored]);

  Future<String?> readManifest() async => null;

  Future<void> writeManifest(String body) async {}

  Future<({String raw, String? metaJson})?> readRegion(String regionId) async =>
      null;

  Future<void> writeRegion(
    String regionId,
    String raw,
    String metaJson,
  ) async {}

  Future<List<({String id, String? metaJson, String metaPath})>>
      listRegionMetas() async => [];

  Future<void> deleteRegion(String regionId) async {}
}
