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
  String? target,
  String summary = '',
}) {
  return Opportunity(
    id: id,
    region: 'suwon',
    title: title,
    type: type,
    category: 'test',
    summary: summary,
    target: target,
    sourceName: 'test',
    sourceUrl: 'https://example.com/$id',
    status: 'published',
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

  test('soft ranking boosts child-related APPLY when BENEFIT empty', () {
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
      target: '영아 자녀가 있는 가정',
      summary: '아동수당·보육 안내',
    );
    final applyOther = _opp(
      id: 'a2',
      title: '골프 체험',
      type: OpportunityType.apply,
      summary: '레포츠',
    );
    final feed = buildMatchedBenefitFeed(
      benefits: const [],
      allOpportunities: [applyOther, applyChild],
      profile: profile,
    );
    expect(feed.first.id, 'a1');
    expect(benefitMatchScore(applyChild, profile) >
        benefitMatchScore(applyOther, profile), isTrue);
  });
}
