// Local-only benefit recommendation profile (기기 저장, 계정 없음).

/// Optional gender for rare target notices.
enum BenefitGender {
  none,
  female,
  male,
}

extension BenefitGenderX on BenefitGender {
  String get wire {
    switch (this) {
      case BenefitGender.none:
        return 'none';
      case BenefitGender.female:
        return 'female';
      case BenefitGender.male:
        return 'male';
    }
  }

  String get labelKo {
    switch (this) {
      case BenefitGender.none:
        return '선택안함';
      case BenefitGender.female:
        return '여';
      case BenefitGender.male:
        return '남';
    }
  }

  static BenefitGender fromWire(String? raw) {
    switch (raw) {
      case 'female':
        return BenefitGender.female;
      case 'male':
        return BenefitGender.male;
      case 'none':
      default:
        return BenefitGender.none;
    }
  }
}

/// Child / pregnancy age bands (multi-select).
enum ChildAgeBand {
  pregnancyPlanned,
  infant0_2,
  preschool3_5,
  elementary6_12,
  teen13_18,
}

extension ChildAgeBandX on ChildAgeBand {
  String get wire {
    switch (this) {
      case ChildAgeBand.pregnancyPlanned:
        return 'pregnancy_planned';
      case ChildAgeBand.infant0_2:
        return 'infant0_2';
      case ChildAgeBand.preschool3_5:
        return 'preschool3_5';
      case ChildAgeBand.elementary6_12:
        return 'elementary6_12';
      case ChildAgeBand.teen13_18:
        return 'teen13_18';
    }
  }

  /// Chip label for the profile form.
  String get labelKo {
    switch (this) {
      case ChildAgeBand.pregnancyPlanned:
        return '임신·예정';
      case ChildAgeBand.infant0_2:
        return '영아(0-2)';
      case ChildAgeBand.preschool3_5:
        return '유아(3-5)';
      case ChildAgeBand.elementary6_12:
        return '초등(6-12)';
      case ChildAgeBand.teen13_18:
        return '청소년(13-18)';
    }
  }

  /// Short label for summary chips on My Chance.
  String get summaryLabelKo {
    switch (this) {
      case ChildAgeBand.pregnancyPlanned:
        return '임신·예정';
      case ChildAgeBand.infant0_2:
        return '영아';
      case ChildAgeBand.preschool3_5:
        return '유아';
      case ChildAgeBand.elementary6_12:
        return '초등';
      case ChildAgeBand.teen13_18:
        return '청소년';
    }
  }

  static ChildAgeBand? fromWire(String? raw) {
    switch (raw) {
      case 'pregnancy_planned':
        return ChildAgeBand.pregnancyPlanned;
      case 'infant0_2':
        return ChildAgeBand.infant0_2;
      case 'preschool3_5':
        return ChildAgeBand.preschool3_5;
      case 'elementary6_12':
        return ChildAgeBand.elementary6_12;
      case 'teen13_18':
        return ChildAgeBand.teen13_18;
      default:
        return null;
    }
  }

  static const all = ChildAgeBand.values;
}

/// Life-situation tags (English keys + Korean labels).
enum SituationTag {
  youth,
  jobSeeking,
  employed,
  newlywed,
  pregnancyChildcare,
  singleHousehold,
  senior,
  startup,
}

extension SituationTagX on SituationTag {
  String get wire {
    switch (this) {
      case SituationTag.youth:
        return 'youth';
      case SituationTag.jobSeeking:
        return 'job_seeking';
      case SituationTag.employed:
        return 'employed';
      case SituationTag.newlywed:
        return 'newlywed';
      case SituationTag.pregnancyChildcare:
        return 'pregnancy_childcare';
      case SituationTag.singleHousehold:
        return 'single_household';
      case SituationTag.senior:
        return 'senior';
      case SituationTag.startup:
        return 'startup';
    }
  }

  String get labelKo {
    switch (this) {
      case SituationTag.youth:
        return '청년';
      case SituationTag.jobSeeking:
        return '구직';
      case SituationTag.employed:
        return '재직';
      case SituationTag.newlywed:
        return '신혼·예비';
      case SituationTag.pregnancyChildcare:
        return '임신·육아';
      case SituationTag.singleHousehold:
        return '1인가구';
      case SituationTag.senior:
        return '어르신';
      case SituationTag.startup:
        return '창업';
    }
  }

  static SituationTag? fromWire(String? raw) {
    switch (raw) {
      case 'youth':
        return SituationTag.youth;
      case 'job_seeking':
        return SituationTag.jobSeeking;
      case 'employed':
        return SituationTag.employed;
      case 'newlywed':
        return SituationTag.newlywed;
      case 'pregnancy_childcare':
        return SituationTag.pregnancyChildcare;
      case 'single_household':
        return SituationTag.singleHousehold;
      case 'senior':
        return SituationTag.senior;
      case 'startup':
        return SituationTag.startup;
      default:
        return null;
    }
  }

  static const all = SituationTag.values;
}

/// Interest keywords shared with My Chance chips.
class BenefitKeywords {
  BenefitKeywords._();

  static const all = <String>[
    '청년',
    '창업',
    '문화',
    '관광',
    '체험',
    '교육',
    '복지',
  ];

  static const defaults = <String>{'청년', '문화'};
}

/// Device-local profile used to soft-rank BENEFIT / APPLY candidates.
class BenefitProfile {
  const BenefitProfile({
    this.birthYear,
    this.gender = BenefitGender.none,
    this.cityId,
    this.cityLabel,
    this.district,
    this.dong,
    this.hasChild = false,
    this.childAgeBands = const {},
    this.situationTags = const {},
    this.keywords = const {},
  });

  final int? birthYear;
  final BenefitGender gender;

  /// Region registry id (e.g. `suwon`).
  final String? cityId;

  /// Display name override (e.g. 수원시); falls back to registry chip label.
  final String? cityLabel;

  /// 구 display name (e.g. 영통구).
  final String? district;

  /// 동 display name (e.g. 원천동) — profile-only, does not narrow feed.
  final String? dong;

  final bool hasChild;
  final Set<ChildAgeBand> childAgeBands;
  final Set<SituationTag> situationTags;

  /// Korean keyword labels aligned with My Chance chips.
  final Set<String> keywords;

  static const empty = BenefitProfile();

  /// True when the user has set at least one matching hint beyond defaults.
  bool get isConfigured {
    if (birthYear != null) return true;
    if (district != null && district!.trim().isNotEmpty) return true;
    if (dong != null && dong!.trim().isNotEmpty) return true;
    if (hasChild) return true;
    if (situationTags.isNotEmpty) return true;
    if (gender != BenefitGender.none) return true;
    return false;
  }

  /// Approximate age from [birthYear] (null if unknown).
  int? ageInYear([int? year]) {
    final by = birthYear;
    if (by == null) return null;
    final y = year ?? DateTime.now().year;
    return y - by;
  }

  /// e.g. `30대` from birth year.
  String? get ageDecadeLabel {
    final age = ageInYear();
    if (age == null || age < 0) return null;
    final decade = (age ~/ 10) * 10;
    if (decade < 10) return '10대 미만';
    return '$decade대';
  }

  /// Compact chips for the My Chance header (나이대 · 동 · 아이 등).
  List<String> summaryChips() {
    final chips = <String>[];
    final decade = ageDecadeLabel;
    if (decade != null) chips.add(decade);

    final d = dong?.trim();
    if (d != null && d.isNotEmpty) {
      chips.add(d);
    } else {
      final gu = district?.trim();
      if (gu != null && gu.isNotEmpty) chips.add(gu);
    }

    if (hasChild) {
      if (childAgeBands.isEmpty) {
        chips.add('아이');
      } else {
        final ordered = ChildAgeBand.values
            .where(childAgeBands.contains)
            .map((b) => b.summaryLabelKo);
        chips.addAll(ordered);
      }
    }

    for (final tag in SituationTag.values) {
      if (situationTags.contains(tag)) {
        // Avoid duplicating pregnancy/childcare when child bands already shown.
        if (tag == SituationTag.pregnancyChildcare && hasChild) continue;
        if (tag == SituationTag.youth && decade != null) continue;
        chips.add(tag.labelKo);
      }
    }

    return chips;
  }

  BenefitProfile copyWith({
    int? birthYear,
    bool clearBirthYear = false,
    BenefitGender? gender,
    String? cityId,
    String? cityLabel,
    String? district,
    bool clearDistrict = false,
    String? dong,
    bool clearDong = false,
    bool? hasChild,
    Set<ChildAgeBand>? childAgeBands,
    Set<SituationTag>? situationTags,
    Set<String>? keywords,
  }) {
    return BenefitProfile(
      birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
      gender: gender ?? this.gender,
      cityId: cityId ?? this.cityId,
      cityLabel: cityLabel ?? this.cityLabel,
      district: clearDistrict ? null : (district ?? this.district),
      dong: clearDong ? null : (dong ?? this.dong),
      hasChild: hasChild ?? this.hasChild,
      childAgeBands: childAgeBands ?? this.childAgeBands,
      situationTags: situationTags ?? this.situationTags,
      keywords: keywords ?? this.keywords,
    );
  }

  Map<String, dynamic> toJson() => {
        'birthYear': birthYear,
        'gender': gender.wire,
        'cityId': cityId,
        'cityLabel': cityLabel,
        'district': district,
        'dong': dong,
        'hasChild': hasChild,
        'childAgeBands':
            childAgeBands.map((e) => e.wire).toList(growable: false),
        'situationTags':
            situationTags.map((e) => e.wire).toList(growable: false),
        'keywords': keywords.toList(growable: false),
      };

  factory BenefitProfile.fromJson(Map<String, dynamic> json) {
    final bands = <ChildAgeBand>{};
    final rawBands = json['childAgeBands'];
    if (rawBands is List) {
      for (final e in rawBands) {
        final band = ChildAgeBandX.fromWire(e?.toString());
        if (band != null) bands.add(band);
      }
    }

    final tags = <SituationTag>{};
    final rawTags = json['situationTags'];
    if (rawTags is List) {
      for (final e in rawTags) {
        final tag = SituationTagX.fromWire(e?.toString());
        if (tag != null) tags.add(tag);
      }
    }

    final kws = <String>{};
    final rawKw = json['keywords'];
    if (rawKw is List) {
      for (final e in rawKw) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) kws.add(s);
      }
    }

    return BenefitProfile(
      birthYear: (json['birthYear'] as num?)?.toInt(),
      gender: BenefitGenderX.fromWire(json['gender'] as String?),
      cityId: json['cityId'] as String?,
      cityLabel: json['cityLabel'] as String?,
      district: json['district'] as String?,
      dong: json['dong'] as String?,
      hasChild: json['hasChild'] == true,
      childAgeBands: bands,
      situationTags: tags,
      keywords: kws,
    );
  }
}
