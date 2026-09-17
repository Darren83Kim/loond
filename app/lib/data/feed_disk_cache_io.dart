import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Documents/feeds disk cache for mobile/desktop.
class FeedDiskCache {
  FeedDiskCache([Directory? cacheRoot]) : _injectedRoot = cacheRoot;

  final Directory? _injectedRoot;

  Future<Directory?> _feedsDir() async {
    try {
      final injected = _injectedRoot;
      if (injected != null) {
        final dir = Directory('${injected.path}/feeds');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir;
      }
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/feeds');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (_) {
      return null;
    }
  }

  Future<String?> readManifest() async {
    final dir = await _feedsDir();
    if (dir == null) return null;
    final file = File('${dir.path}/manifest.json');
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<void> writeManifest(String body) async {
    final dir = await _feedsDir();
    if (dir == null) return;
    await File('${dir.path}/manifest.json').writeAsString(body, flush: true);
  }

  Future<({String raw, String? metaJson})?> readRegion(String regionId) async {
    final dir = await _feedsDir();
    if (dir == null) return null;
    final jsonFile = File('${dir.path}/$regionId.json');
    if (!await jsonFile.exists()) return null;
    final raw = await jsonFile.readAsString();
    final metaFile = File('${dir.path}/$regionId.meta.json');
    final metaJson =
        await metaFile.exists() ? await metaFile.readAsString() : null;
    return (raw: raw, metaJson: metaJson);
  }

  Future<void> writeRegion(
    String regionId,
    String raw,
    String metaJson,
  ) async {
    final dir = await _feedsDir();
    if (dir == null) return;
    await File('${dir.path}/$regionId.json').writeAsString(raw, flush: true);
    await File('${dir.path}/$regionId.meta.json')
        .writeAsString(metaJson, flush: true);
  }

  Future<List<({String id, String? metaJson, String metaPath})>>
      listRegionMetas() async {
    final dir = await _feedsDir();
    if (dir == null) return [];
    final out = <({String id, String? metaJson, String metaPath})>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isEmpty
          ? entity.path
          : entity.uri.pathSegments.last;
      if (!name.endsWith('.meta.json')) continue;
      final id = name.substring(0, name.length - '.meta.json'.length);
      String? metaJson;
      try {
        metaJson = await entity.readAsString();
      } catch (_) {}
      out.add((id: id, metaJson: metaJson, metaPath: entity.path));
    }
    return out;
  }

  Future<void> deleteRegion(String regionId) async {
    final dir = await _feedsDir();
    if (dir == null) return;
    for (final suffix in ['.json', '.meta.json']) {
      final f = File('${dir.path}/$regionId$suffix');
      try {
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }
}
