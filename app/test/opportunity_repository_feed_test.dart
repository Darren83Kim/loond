import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loond/data/feed_disk_cache.dart';
import 'package:loond/data/feed_load_result.dart';
import 'package:loond/data/feed_remote_config.dart';
import 'package:loond/data/opportunity_repository.dart';

String _regionJson({
  required String region,
  required String updatedAt,
  String title = '테스트 공고',
}) {
  return jsonEncode({
    'schemaVersion': 1,
    'region': region,
    'regionLabel': region,  // ascii in tests

    'updatedAt': updatedAt,
    'opportunities': [
      {
        'id': '$region-test-1',
        'region': region,
        'title': title,
        'type': 'DISCOVER',
        'category': 'tour_spot',
        'summary': '요약',
        'sourceName': 'test',
        'sourceUrl': 'https://example.com',
        'status': 'published',
      },
    ],
    'counts': {'DISCOVER': 1},
  });
}

String _manifestJson({
  required String updatedAt,
  required String etag,
}) {
  return jsonEncode({
    'schemaVersion': 1,
    'updatedAt': updatedAt,
    'baseUrl': 'https://darren83kim.github.io/loond/regions/',
    'regions': [
      {
        'id': 'suwon',
        'label': '수원',
        'path': 'suwon.json',
        'etag': etag,
        'bytes': 100,
        'counts': {'DISCOVER': 1},
      },
      {
        'id': 'goyang',
        'label': '고양',
        'path': 'goyang.json',
        'etag': 'sha256:goyang',
        'bytes': 100,
        'counts': {'DISCOVER': 1},
      },
    ],
  });
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);
  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final s = _assets[key];
    if (s == null) throw FlutterError('missing asset $key');
    final bytes = utf8.encode(s);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('loond_feed_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('cache hit skips second region GET when etag matches', () async {
    var regionGets = 0;
    const updatedAt = '2026-09-17T12:00:00+09:00';
    const etag = 'sha256:suwon-v1';
    final regionBody = _regionJson(region: 'suwon', updatedAt: updatedAt);
    final manifestBody = _manifestJson(updatedAt: updatedAt, etag: etag);

    final client = MockClient((request) async {
      if (request.url.path.endsWith('/manifest.json')) {
        return http.Response.bytes(utf8.encode(manifestBody), 200);
      }
      if (request.url.path.endsWith('/suwon.json')) {
        regionGets += 1;
        return http.Response.bytes(utf8.encode(regionBody), 200);
      }
      return http.Response('missing', 404);
    });

    final repo = OpportunityRepository(
      client: client,
      diskCache: FeedDiskCache(tempDir),
      bundle: _FakeAssetBundle({
        FeedRemoteConfig.seedAssetPath: regionBody,
      }),
    );

    final first = await repo.loadForRegion('suwon', forceRefresh: true);
    expect(first.source, FeedSource.remote);
    expect(regionGets, 1);

    final second = await repo.loadForRegion('suwon');
    expect(second.source, FeedSource.diskCache);
    expect(regionGets, 1); // no second GET
    expect(second.bundle.opportunities.single.id, 'suwon-test-1');
  });

  test('network failure falls back to seed for suwon', () async {
    final seed = _regionJson(
      region: 'suwon',
      updatedAt: '2026-09-01T00:00:00+09:00',
      title: '시드 항목',
    );
    final client = MockClient((request) async {
      throw const SocketException('offline');
    });

    final repo = OpportunityRepository(
      client: client,
      diskCache: FeedDiskCache(tempDir),
      bundle: _FakeAssetBundle({
        FeedRemoteConfig.seedAssetPath: seed,
      }),
    );

    final result = await repo.loadForRegion('suwon');
    expect(result.source, FeedSource.seed);
    expect(result.warning, isNotNull);
    expect(result.bundle.opportunities.single.title, '시드 항목');
  });

  test('network failure without cache throws for non-seed region', () async {
    final client = MockClient((request) async {
      throw const SocketException('offline');
    });
    final repo = OpportunityRepository(
      client: client,
      diskCache: FeedDiskCache(tempDir),
      bundle: _FakeAssetBundle({
        FeedRemoteConfig.seedAssetPath: _regionJson(
          region: 'suwon',
          updatedAt: '2026-09-01T00:00:00+09:00',
        ),
      }),
    );

    expect(
      () => repo.loadForRegion('goyang'),
      throwsA(isA<FeedLoadException>()),
    );
  });
}
