import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/opportunity.dart';
import 'feed_disk_cache.dart';
import 'feed_load_result.dart';
import 'feed_remote_config.dart';

/// Published feed loader: remote per-region + disk cache + suwon seed (P3).
class OpportunityRepository {
  OpportunityRepository({
    http.Client? client,
    FeedDiskCache? diskCache,
    AssetBundle? bundle,
  })  : _client = client ?? http.Client(),
        _disk = diskCache ?? FeedDiskCache(),
        _bundle = bundle ?? rootBundle;

  static const assetPath = FeedRemoteConfig.seedAssetPath;

  final http.Client _client;
  final FeedDiskCache _disk;
  final AssetBundle _bundle;

  /// Best-effort manifest refresh (picker open / app start). Returns null on failure.
  Future<FeedManifest?> refreshManifest() async {
    try {
      return await _refreshManifest();
    } catch (_) {
      return _readCachedManifest();
    }
  }

    /// Legacy entry — loads the seed region only (suwon). Prefer [loadForRegion].
  Future<OpportunityBundle> loadPublished() async {
    final result = await loadForRegion(FeedRemoteConfig.seedRegionId);
    return result.bundle;
  }

  /// Load one city's feed.
  ///
  /// Order: disk cache if etag/updatedAt matches manifest → GET region JSON →
  /// validate → write cache → return. On network failure: disk cache → seed
  /// (suwon only) → error.
  Future<FeedLoadResult> loadForRegion(
    String regionId, {
    bool forceRefresh = false,
  }) async {
    final id = regionId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(regionId, 'regionId', 'empty');
    }

    FeedManifest? manifest;
    try {
      manifest = await _refreshManifest();
    } catch (_) {
      manifest = await _readCachedManifest();
    }

    final entry = manifest?.region(id);
    if (!forceRefresh) {
      final cached = await _readCachedRegion(id);
      if (cached != null && _cacheFresh(cached.meta, entry)) {
        return FeedLoadResult(
          bundle: cached.bundle,
          source: FeedSource.diskCache,
        );
      }
    }

    try {
      final remote = await _fetchRegion(id, entry);
      await _writeCachedRegion(id, remote.raw, remote.meta);
      await _pruneCache(keepId: id);
      return FeedLoadResult(
        bundle: remote.bundle,
        source: FeedSource.remote,
      );
    } catch (e) {
      final cached = await _readCachedRegion(id);
      if (cached != null) {
        return FeedLoadResult(
          bundle: cached.bundle,
          source: FeedSource.diskCache,
          warning: '네트워크 오류 — 저장된 피드를 표시합니다',
        );
      }
      if (id == FeedRemoteConfig.seedRegionId) {
        final seed = await _loadSeedAsset();
        return FeedLoadResult(
          bundle: seed,
          source: FeedSource.seed,
          warning: '네트워크 오류 — 내장 시드 피드를 표시합니다',
        );
      }
      throw FeedLoadException(
        '지역 피드를 불러오지 못했어요 ($id)',
        cause: e,
      );
    }
  }

  Future<OpportunityBundle> _loadSeedAsset() async {
    final raw = await _bundle.loadString(FeedRemoteConfig.seedAssetPath);
    return _parseBundle(raw, expectedRegion: FeedRemoteConfig.seedRegionId);
  }

  Future<FeedManifest?> _refreshManifest() async {
    final response = await _client
        .get(Uri.parse(FeedRemoteConfig.manifestUrl))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw FeedLoadException('manifest HTTP ${response.statusCode}');
    }
    final body = utf8.decode(response.bodyBytes);
    final manifest = FeedManifest.parse(body);
    await _disk.writeManifest(body);
    return manifest;
  }

  Future<_FetchedRegion> _fetchRegion(
    String regionId,
    FeedRegionEntry? entry,
  ) async {
    final url = entry?.resolvedUrl() ?? FeedRemoteConfig.regionUrl(regionId);
    final response =
        await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw FeedLoadException('region HTTP ${response.statusCode}');
    }
    final raw = utf8.decode(response.bodyBytes);
    final bundle = _parseBundle(raw, expectedRegion: regionId);
    final meta = FeedCacheMeta(
      regionId: regionId,
      etag: entry?.etag,
      updatedAt: entry?.updatedAt ?? bundle.updatedAt?.toIso8601String(),
      cachedAt: DateTime.now().toUtc().toIso8601String(),
    );
    return _FetchedRegion(raw: raw, bundle: bundle, meta: meta);
  }

  OpportunityBundle _parseBundle(String raw, {String? expectedRegion}) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('feed root must be a JSON object');
    }
    final schema = (decoded['schemaVersion'] as num?)?.toInt() ?? 0;
    if (schema < 1) {
      throw FormatException('unsupported schemaVersion: $schema');
    }
    final bundle = OpportunityBundle.fromJson(decoded);
    if (expectedRegion != null &&
        bundle.region.isNotEmpty &&
        bundle.region != expectedRegion) {
      final hasTagged =
          bundle.opportunities.any((o) => o.region == expectedRegion);
      if (!hasTagged) {
        throw FormatException(
          'region mismatch: expected $expectedRegion got ${bundle.region}',
        );
      }
    }
    return bundle;
  }

  bool _cacheFresh(FeedCacheMeta meta, FeedRegionEntry? entry) {
    if (entry == null) {
      // No manifest — treat existing disk cache as usable offline.
      return true;
    }
    if (entry.etag != null &&
        meta.etag != null &&
        entry.etag!.isNotEmpty &&
        meta.etag == entry.etag) {
      return true;
    }
    if (entry.updatedAt != null &&
        meta.updatedAt != null &&
        entry.updatedAt == meta.updatedAt) {
      return true;
    }
    return false;
  }

  Future<FeedManifest?> _readCachedManifest() async {
    final body = await _disk.readManifest();
    if (body == null) return null;
    try {
      return FeedManifest.parse(body);
    } catch (_) {
      return null;
    }
  }

  Future<_CachedRegion?> _readCachedRegion(String regionId) async {
    final cached = await _disk.readRegion(regionId);
    if (cached == null) return null;
    try {
      final bundle = _parseBundle(cached.raw, expectedRegion: regionId);
      final FeedCacheMeta meta;
      if (cached.metaJson != null) {
        meta = FeedCacheMeta.fromJson(
          jsonDecode(cached.metaJson!) as Map<String, dynamic>,
        );
      } else {
        meta = FeedCacheMeta(
          regionId: regionId,
          updatedAt: bundle.updatedAt?.toIso8601String(),
          cachedAt: DateTime.now().toUtc().toIso8601String(),
        );
      }
      return _CachedRegion(bundle: bundle, meta: meta);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedRegion(
    String regionId,
    String raw,
    FeedCacheMeta meta,
  ) async {
    await _disk.writeRegion(regionId, raw, jsonEncode(meta.toJson()));
  }

  Future<void> _pruneCache({required String keepId}) async {
    final metas = await _disk.listRegionMetas();
    if (metas.length <= FeedRemoteConfig.maxCachedRegions) return;

    final ranked = <({String id, DateTime cachedAt})>[];
    for (final item in metas) {
      if (item.id == keepId || item.id == FeedRemoteConfig.seedRegionId) {
        continue;
      }
      DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(0);
      if (item.metaJson != null) {
        try {
          final meta = FeedCacheMeta.fromJson(
            jsonDecode(item.metaJson!) as Map<String, dynamic>,
          );
          cachedAt = DateTime.tryParse(meta.cachedAt ?? '') ?? cachedAt;
        } catch (_) {}
      }
      ranked.add((id: item.id, cachedAt: cachedAt));
    }
    ranked.sort((a, b) => a.cachedAt.compareTo(b.cachedAt));
    final overflow = metas.length - FeedRemoteConfig.maxCachedRegions;
    for (var i = 0; i < overflow && i < ranked.length; i++) {
      await _disk.deleteRegion(ranked[i].id);
    }
  }
}

class FeedLoadException implements Exception {
  const FeedLoadException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause == null ? message : '$message (${cause.toString()})';
}

class FeedManifest {
  const FeedManifest({
    required this.schemaVersion,
    this.updatedAt,
    this.baseUrl,
    required this.regions,
  });

  final int schemaVersion;
  final String? updatedAt;
  final String? baseUrl;
  final List<FeedRegionEntry> regions;

  FeedRegionEntry? region(String id) {
    for (final r in regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  static FeedManifest parse(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['regions'] as List<dynamic>? ?? [])
        .map(
          (e) => FeedRegionEntry.fromJson(
            e as Map<String, dynamic>,
            manifestUpdatedAt: map['updatedAt'] as String?,
            baseUrl: map['baseUrl'] as String?,
          ),
        )
        .toList();
    return FeedManifest(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      updatedAt: map['updatedAt'] as String?,
      baseUrl: map['baseUrl'] as String?,
      regions: list,
    );
  }
}

class FeedRegionEntry {
  const FeedRegionEntry({
    required this.id,
    this.label,
    this.path,
    this.etag,
    this.updatedAt,
    this.baseUrl,
  });

  final String id;
  final String? label;
  final String? path;
  final String? etag;
  final String? updatedAt;
  final String? baseUrl;

  factory FeedRegionEntry.fromJson(
    Map<String, dynamic> json, {
    String? manifestUpdatedAt,
    String? baseUrl,
  }) {
    return FeedRegionEntry(
      id: json['id'] as String? ?? '',
      label: json['label'] as String?,
      path: json['path'] as String?,
      etag: json['etag'] as String?,
      updatedAt: json['updatedAt'] as String? ?? manifestUpdatedAt,
      baseUrl: baseUrl,
    );
  }

  String resolvedUrl() {
    final base = (baseUrl == null || baseUrl!.isEmpty)
        ? '${FeedRemoteConfig.siteBaseUrl}regions/'
        : baseUrl!;
    final normalizedBase = base.endsWith('/') ? base : '$base/';
    final p = (path == null || path!.isEmpty) ? '$id.json' : path!;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return '$normalizedBase$p';
  }
}

class FeedCacheMeta {
  const FeedCacheMeta({
    required this.regionId,
    this.etag,
    this.updatedAt,
    this.cachedAt,
  });

  final String regionId;
  final String? etag;
  final String? updatedAt;
  final String? cachedAt;

  factory FeedCacheMeta.fromJson(Map<String, dynamic> json) {
    return FeedCacheMeta(
      regionId: json['regionId'] as String? ?? '',
      etag: json['etag'] as String?,
      updatedAt: json['updatedAt'] as String?,
      cachedAt: json['cachedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'regionId': regionId,
        if (etag != null) 'etag': etag,
        if (updatedAt != null) 'updatedAt': updatedAt,
        if (cachedAt != null) 'cachedAt': cachedAt,
      };
}

class _FetchedRegion {
  const _FetchedRegion({
    required this.raw,
    required this.bundle,
    required this.meta,
  });

  final String raw;
  final OpportunityBundle bundle;
  final FeedCacheMeta meta;
}

class _CachedRegion {
  const _CachedRegion({required this.bundle, required this.meta});

  final OpportunityBundle bundle;
  final FeedCacheMeta meta;
}
