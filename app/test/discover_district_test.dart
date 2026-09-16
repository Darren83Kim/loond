import 'package:flutter_test/flutter_test.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/util/discover_district.dart';

Opportunity _discover({
  required String id,
  String title = '제목',
  String summary = '',
  String? description,
  String? location,
  String? lDongSignguCd,
  String category = 'tour_spot',
}) {
  return Opportunity(
    id: id,
    region: 'suwon',
    title: title,
    type: OpportunityType.discover,
    category: category,
    summary: summary,
    description: description,
    location: location,
    sourceName: 'test',
    sourceUrl: 'https://example.com/$id',
    lDongSignguCd: lDongSignguCd,
  );
}

void main() {
  group('DiscoverDistrict.matches', () {
    test('영통구 location passes 영통 filter via string when meta missing', () {
      final o = _discover(
        id: 'yt-loc',
        location: '경기도 수원시 영통구 광교호수로 127',
      );
      final yeongtong = DiscoverDistrict.byId('yeongtong');
      expect(yeongtong.matches(o), isTrue);
      expect(DiscoverDistrict.byId('jangan').matches(o), isFalse);
      expect(DiscoverDistrict.all.matches(o), isTrue);
    });

    test('meta lDongSignguCd 117 matches 영통; other gu rejected', () {
      final o = _discover(
        id: 'yt-meta',
        location: '수원 어딘가', // no 구 in text
        lDongSignguCd: '117',
      );
      expect(DiscoverDistrict.byId('yeongtong').matches(o), isTrue);
      expect(DiscoverDistrict.byId('paldal').matches(o), isFalse);
      expect(DiscoverDistrict.byId('gwonsun').matches(o), isFalse);
      expect(DiscoverDistrict.byId('jangan').matches(o), isFalse);
    });

    test('meta present wins over conflicting location text', () {
      // Code says 장안(111) even if location mentions 영통구.
      final o = _discover(
        id: 'conflict',
        location: '경기도 수원시 영통구 테스트',
        lDongSignguCd: '111',
      );
      expect(DiscoverDistrict.byId('jangan').matches(o), isTrue);
      expect(DiscoverDistrict.byId('yeongtong').matches(o), isFalse);
    });

    test('fromJson reads meta.lDongSignguCd', () {
      final o = Opportunity.fromJson({
        'id': 'json-yt',
        'region': 'suwon',
        'title': '광교중앙공원',
        'type': 'DISCOVER',
        'category': 'tour_spot',
        'summary': '공원',
        'location': '경기도 수원시 영통구 이의동',
        'sourceName': 'TourAPI',
        'sourceUrl': 'https://example.com',
        'meta': {
          'lDongSignguCd': '117',
          'lDongRegnCd': '41',
        },
      });
      expect(o.lDongSignguCd, '117');
      expect(DiscoverDistrict.byId('yeongtong').matches(o), isTrue);
      expect(DiscoverDistrict.labelFor(o), '영통구');
    });

    test('labelFor falls back to location 구 name', () {
      final o = _discover(
        id: 'pd',
        location: '경기도 수원시 팔달구 인계동',
      );
      expect(DiscoverDistrict.labelFor(o), '팔달구');
    });

    test('suwonGus chip ids and codes', () {
      expect(DiscoverDistrict.suwonGus.map((d) => d.shortLabel).toList(), [
        '전체',
        '장안',
        '권선',
        '팔달',
        '영통',
      ]);
      expect(DiscoverDistrict.byId('gwonsun').signguCd, '113');
      expect(DiscoverDistrict.byId('paldal').signguCd, '115');
    });
  });
}
