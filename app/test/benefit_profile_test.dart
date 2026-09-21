import 'package:flutter_test/flutter_test.dart';
import 'package:loond/data/benefit_profile_store.dart';
import 'package:loond/models/benefit_profile.dart';
import 'package:loond/models/opportunity.dart';
import 'package:loond/util/benefit_matching.dart';
import 'package:shared_preferences/shared_preferences.dart';

Opportunity _opp({
  required String id,
  required String title,
  required OpportunityType type,
  String category = 'test',
  String? target,
  String summary = '',
  DateTime? applicationEnd,
  String region = 'suwon',
  BenefitEligibility? eligibility,
}) {
  return Opportunity(
    id: id,
    region: region,
    title: title,
    type: type,
    category: category,
    summary: summary,
    target: target,
    applicationEnd: applicationEnd,
    sourceName: 'test',
    sourceUrl: 'https://example.com/$id',
    status: 'published',
    eligibility: eligibility,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('BenefitProfile JSON round-trip', () {
    const p = BenefitProfile(
      birthYear: 1992,
      gender: BenefitGender.female,
      cityId: 'suwon',
      cityLabel: '수원시',
      district: '영통구',
      dong: '원천동',
      hasChild: true,
      childAgeBands: {ChildAgeBand.infant0_2},
      situationTags: {SituationTag.youth, SituationTag.pregnancyChildcare},
      keywords: {'청년', '복지'},
    );
    final again = BenefitProfile.fromJson(p.toJson());
    expect(again.birthYear, 1992);
    expect(again.gender, BenefitGender.female);
    expect(again.dong, '원천동');
    expect(again.childAgeBands, {ChildAgeBand.infant0_2});
    expect(again.situationTags.contains(SituationTag.youth), isTrue);
    expect(again.keywords, {'청년', '복지'});
    expect(again.isConfigured, isTrue);
    expect(again.summaryChips(), contains('원천동'));
    expect(again.summaryChips(), contains('영아'));
  });

  test('BenefitProfileStore persists', () async {
    final store = BenefitProfileStore();
    await store.save(
      const BenefitProfile(
        birthYear: 1990,
        district: '장안구',
        hasChild: true,
        childAgeBands: {ChildAgeBand.elementary6_12},
        keywords: {'교육'},
      ),
    );
    final loaded = await store.load();
    expect(loaded.birthYear, 1990);
    expect(loaded.district, '장안구');
    expect(loaded.childAgeBands, {ChildAgeBand.elementary6_12});
  });

  test('empty BENEFIT feed never mixes APPLY under 혜택', () {
    const profile = BenefitProfile(
      hasChild: true,
      childAgeBands: {ChildAgeBand.infant0_2},
      situationTags: {SituationTag.pregnancyChildcare},
      keywords: {'복지'},
    );
    final applyChild = _opp(
      id: 'a1',
      title: '영아 보육 지원',
      type: OpportunityType.apply,
      category: 'support_apply',
      target: '영아 자녀가 있는 가정',
      summary: '아동수당·보육 안내',
    );
    final feed = buildMatchedBenefitFeed(
      benefits: const [],
      profile: profile,
    );
    expect(feed, isEmpty);
    expect(feed.any((o) => o.type == OpportunityType.apply), isFalse);

    // Soft score still ranks child-related APPLY higher for related section.
    final applyOther = _opp(
      id: 'a2',
      title: '골프 체험',
      type: OpportunityType.apply,
      category: 'experience_apply',
      summary: '레포츠',
    );
    expect(
      benefitMatchScore(applyChild, profile) >
          benefitMatchScore(applyOther, profile),
      isTrue,
    );
  });

  test('BENEFIT primary stays BENEFIT-only when inventory non-empty', () {
    const profile = BenefitProfile(
      keywords: {'복지'},
      situationTags: {SituationTag.youth},
    );
    final benefit = _opp(
      id: 'b1',
      title: '청년 복지 바우처',
      type: OpportunityType.benefit,
      summary: '복지 지원',
    );
    final apply = _opp(
      id: 'a1',
      title: '영아 보육 지원',
      type: OpportunityType.apply,
      category: 'support_apply',
      target: '영아',
      summary: '아동수당',
    );
    final feed = buildMatchedBenefitFeed(
      benefits: [benefit],
      profile: profile,
    );
    expect(feed.map((o) => o.id), ['b1']);
    expect(feed.every((o) => o.type == OpportunityType.benefit), isTrue);
    // UI hides 「관련 신청」 when benefits.isNotEmpty (see MyChanceTab).
    expect(apply.type, OpportunityType.apply);
  });

  test('related APPLY excludes home top-5 and respects score floor', () {
    const profile = BenefitProfile(
      hasChild: true,
      childAgeBands: {ChildAgeBand.infant0_2},
      situationTags: {SituationTag.pregnancyChildcare},
      keywords: {'복지', '교육'},
    );

    final now = DateTime.now();
    // Home deadline sort: soonest applicationEnd first → these 5 are top-N.
    final homeTop = <Opportunity>[
      for (var i = 0; i < 5; i++)
        _opp(
          id: 'home-$i',
          title: '홈 노출 $i',
          type: OpportunityType.apply,
          category: 'support_apply',
          summary: '영아 보육 복지 아동수당',
          target: '영아 가정',
          applicationEnd: now.add(Duration(days: i + 1)),
        ),
    ];
    final relatedStrong = _opp(
      id: 'rel-strong',
      title: '영아 보육 지원금',
      type: OpportunityType.apply,
      category: 'support_apply',
      summary: '아동수당·보육 복지',
      target: '영아 자녀가 있는 가정',
      applicationEnd: now.add(const Duration(days: 30)),
    );
    final thinKeywordOnly = _opp(
      id: 'rel-thin',
      title: '문화 행사 안내',
      type: OpportunityType.apply,
      category: 'tour_apply',
      summary: '문화', // single default-ish keyword hit → score 3 < floor 5
      applicationEnd: now.add(const Duration(days: 40)),
    );
    final tourHigh = _opp(
      id: 'rel-tour',
      title: '영아 가족 관광 체험',
      type: OpportunityType.apply,
      category: 'tour_apply',
      summary: '영아 보육 체험 관광',
      target: '영아 자녀',
      applicationEnd: now.add(const Duration(days: 35)),
    );

    final all = [...homeTop, relatedStrong, thinKeywordOnly, tourHigh];

    final topIds = homeNowApplyTopIds(all, regionId: 'suwon');
    expect(topIds.length, 5);
    expect(topIds, containsAll(['home-0', 'home-1', 'home-2', 'home-3', 'home-4']));

    final related = buildRelatedApplyFeed(
      allOpportunities: all,
      profile: profile,
      regionId: 'suwon',
    );

    expect(related.any((o) => topIds.contains(o.id)), isFalse);
    expect(related.map((o) => o.id), contains('rel-strong'));
    expect(related.map((o) => o.id), isNot(contains('rel-thin')));
    // Floor: thin keyword alone must not dump the pool.
    for (final o in related) {
      expect(benefitMatchScore(o, profile) >= kRelatedApplyMinScore, isTrue);
    }
    // Soft demote tour vs support when both pass floor.
    if (related.any((o) => o.id == 'rel-tour') &&
        related.any((o) => o.id == 'rel-strong')) {
      expect(related.first.id, 'rel-strong');
    }
  });

  test('default keywords alone do not fill related APPLY (Suwon-like)', () {
    final profile = BenefitProfile(
      keywords: Set<String>.from(BenefitKeywords.defaults),
    );
    final pool = <Opportunity>[
      for (var i = 0; i < 12; i++)
        _opp(
          id: 'pool-$i',
          title: i < 5 ? '문화 골목여행 $i' : '일반 공고 $i',
          type: OpportunityType.apply,
          category: i < 5 ? 'tour_apply' : 'course_local',
          summary: i < 5 ? '문화 관광 방문객' : '주민자치 프로그램',
          applicationEnd: DateTime.now().add(Duration(days: 10 + i)),
        ),
    ];
    final related = buildRelatedApplyFeed(
      allOpportunities: pool,
      profile: profile,
      regionId: 'suwon',
    );
    // defaults 청년·문화 → at most keyword hits of 3; floor 5 → empty.
    expect(related, isEmpty);
  });

  test('hard exclude: 40s + elementary hides infant/youth BENEFIT', () {
    final year = DateTime.now().year;
    final profile = BenefitProfile(
      birthYear: year - 42,
      hasChild: true,
      childAgeBands: {ChildAgeBand.elementary6_12},
      keywords: {'복지', '청년'},
    );
    final parental = _opp(
      id: 'parental',
      title: '부모급여',
      type: OpportunityType.benefit,
      summary: '영아 0~23개월',
      eligibility: const BenefitEligibility(
        requiresChild: true,
        childAgeBands: [ChildAgeBand.infant0_2],
      ),
    );
    final youthIncome = _opp(
      id: 'youth-income',
      title: '청년기본소득',
      type: OpportunityType.benefit,
      summary: '청년 수당',
      eligibility: const BenefitEligibility(ageMin: 23, ageMax: 25),
    );
    final youthHousing = _opp(
      id: 'youth-housing',
      title: '청년주거급여',
      type: OpportunityType.benefit,
      summary: '청년 주거',
      eligibility: const BenefitEligibility(ageMin: 19, ageMax: 34),
    );
    final housing = _opp(
      id: 'housing',
      title: '주거급여',
      type: OpportunityType.benefit,
      summary: '주거비 지원',
    );
    final childAllow = _opp(
      id: 'child-allow',
      title: '아동수당',
      type: OpportunityType.benefit,
      summary: '만 9세 미만',
      eligibility: const BenefitEligibility(
        requiresChild: true,
        childAgeBands: [
          ChildAgeBand.infant0_2,
          ChildAgeBand.preschool3_5,
          ChildAgeBand.elementary6_12,
        ],
      ),
    );

    final feed = buildMatchedBenefitFeed(
      benefits: [parental, youthIncome, youthHousing, housing, childAllow],
      profile: profile,
    );
    final ids = feed.map((o) => o.id).toSet();
    expect(ids.contains('parental'), isFalse);
    expect(ids.contains('youth-income'), isFalse);
    expect(ids.contains('youth-housing'), isFalse);
    expect(ids.contains('housing'), isTrue);
    expect(ids.contains('child-allow'), isTrue);
  });

  test('hard exclude: infant child can see 부모급여', () {
    const profile = BenefitProfile(
      hasChild: true,
      childAgeBands: {ChildAgeBand.infant0_2},
      keywords: {'복지'},
    );
    final parental = _opp(
      id: 'parental',
      title: '부모급여',
      type: OpportunityType.benefit,
      summary: '영아',
      eligibility: const BenefitEligibility(
        requiresChild: true,
        childAgeBands: [ChildAgeBand.infant0_2],
      ),
    );
    final feed = buildMatchedBenefitFeed(
      benefits: [parental],
      profile: profile,
    );
    expect(feed.map((o) => o.id), ['parental']);
  });

  test('hard exclude: age 25 can see youth BENEFIT', () {
    final year = DateTime.now().year;
    final profile = BenefitProfile(
      birthYear: year - 25,
      keywords: {'청년'},
    );
    final youthIncome = _opp(
      id: 'youth-income',
      title: '청년기본소득',
      type: OpportunityType.benefit,
      summary: '청년',
      eligibility: const BenefitEligibility(ageMin: 23, ageMax: 25),
    );
    final youthHousing = _opp(
      id: 'youth-housing',
      title: '청년주거급여',
      type: OpportunityType.benefit,
      summary: '청년 주거',
      eligibility: const BenefitEligibility(ageMin: 19, ageMax: 34),
    );
    final feed = buildMatchedBenefitFeed(
      benefits: [youthIncome, youthHousing],
      profile: profile,
    );
    expect(feed.map((o) => o.id).toSet(), {'youth-income', 'youth-housing'});
  });

  test('BenefitEligibility parses from opportunity JSON meta', () {
    final o = Opportunity.fromJson({
      'id': 'x',
      'region': 'suwon',
      'title': '부모급여',
      'type': 'BENEFIT',
      'category': 'welfare_support',
      'summary': '영아',
      'sourceName': 't',
      'sourceUrl': 'https://example.com',
      'status': 'published',
      'opportunityScore': 0,
      'meta': {
        'eligibility': {
          'requiresChild': true,
          'childAgeBands': ['infant0_2'],
          'ageMin': 20,
          'ageMax': 40,
        },
      },
    });
    expect(o.eligibility, isNotNull);
    expect(o.eligibility!.requiresChild, isTrue);
    expect(o.eligibility!.childAgeBands, [ChildAgeBand.infant0_2]);
    expect(o.eligibility!.ageMin, 20);
    expect(o.eligibility!.ageMax, 40);
  });

}
