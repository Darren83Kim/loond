// Suwon 구/동 helpers for benefit profile (subset + free-text fallback).
/// Gu display names for Suwon.
const suwonGuLabels = <String>[
  '장안구',
  '권선구',
  '팔달구',
  '영통구',
];

/// Reasonable dong subset per 구. Users can still type a custom 동.
const suwonDongsByGu = <String, List<String>>{
  '장안구': [
    '파장동',
    '율천동',
    '정자1동',
    '정자2동',
    '정자3동',
    '영화동',
    '송죽동',
    '조원1동',
    '조원2동',
    '연무동',
  ],
  '권선구': [
    '세류1동',
    '세류2동',
    '세류3동',
    '평동',
    '서둔동',
    '구운동',
    '금곡동',
    '호매실동',
    '권선1동',
    '권선2동',
    '곡선동',
    '입북동',
  ],
  '팔달구': [
    '매교동',
    '매산동',
    '고등동',
    '화서1동',
    '화서2동',
    '지동',
    '우만1동',
    '우만2동',
    '인계동',
    '행궁동',
  ],
  '영통구': [
    '매탄1동',
    '매탄2동',
    '매탄3동',
    '매탄4동',
    '원천동',
    '영통1동',
    '영통2동',
    '영통3동',
    '망포1동',
    '망포2동',
    '광교1동',
    '광교2동',
  ],
};

List<String> dongsForGu(String? gu) {
  if (gu == null || gu.isEmpty) return const [];
  return suwonDongsByGu[gu] ?? const [];
}
