import 'package:flutter/material.dart';

import '../data/benefit_profile_store.dart';
import '../models/benefit_profile.dart';
import '../models/region.dart';
import '../theme/app_theme.dart';
import '../util/suwon_localities.dart';

/// 맞춤 설정 — device-local benefit recommendation profile.
class BenefitProfileScreen extends StatefulWidget {
  const BenefitProfileScreen({
    super.key,
    required this.store,
    required this.region,
    this.initial,
  });

  final BenefitProfileStore store;
  final Region region;
  final BenefitProfile? initial;

  @override
  State<BenefitProfileScreen> createState() => _BenefitProfileScreenState();
}

class _BenefitProfileScreenState extends State<BenefitProfileScreen> {
  late int? _birthYear;
  late BenefitGender _gender;
  late String _cityId;
  late String _cityLabel;
  String? _district;
  String? _dong;
  late bool _hasChild;
  late Set<ChildAgeBand> _childBands;
  late Set<SituationTag> _situationTags;
  late Set<String> _keywords;
  bool _saving = false;

  static final int _yearNow = DateTime.now().year;
  static final List<int> _yearOptions =
      List<int>.generate(80, (i) => _yearNow - 15 - i); // ~15..94

  @override
  void initState() {
    super.initState();
    final p = widget.initial ?? BenefitProfile.empty;
    _birthYear = p.birthYear;
    _gender = p.gender;
    _cityId = p.cityId ?? widget.region.id;
    _cityLabel = p.cityLabel ?? widget.region.chipLabel;
    _district = p.district;
    _dong = p.dong;
    _hasChild = p.hasChild;
    _childBands = Set<ChildAgeBand>.from(p.childAgeBands);
    _situationTags = Set<SituationTag>.from(p.situationTags);
    _keywords = p.keywords.isEmpty
        ? Set<String>.from(BenefitKeywords.defaults)
        : Set<String>.from(p.keywords);
  }

  BenefitProfile _buildProfile() {
    return BenefitProfile(
      birthYear: _birthYear,
      gender: _gender,
      cityId: _cityId,
      cityLabel: _cityLabel,
      district: _district,
      dong: _dong,
      hasChild: _hasChild,
      childAgeBands: _hasChild ? Set<ChildAgeBand>.from(_childBands) : {},
      situationTags: Set<SituationTag>.from(_situationTags),
      keywords: Set<String>.from(_keywords),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.store.save(_buildProfile());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCity() async {
    final selected = await showModalBottomSheet<Region>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '시 선택',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              for (final r in RegionRegistry.all)
                ListTile(
                  title: Text(r.chipLabel),
                  trailing: r.id == _cityId
                      ? const Icon(Icons.check, color: AppTheme.seed)
                      : null,
                  onTap: () => Navigator.pop(ctx, r),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      _cityId = selected.id;
      _cityLabel = selected.chipLabel;
      // Clear gu/dong when leaving Suwon (lists are Suwon-specific).
      if (selected.id != 'suwon') {
        _district = null;
        _dong = null;
      }
    });
  }

  Future<void> _pickDistrict() async {
    if (_cityId != 'suwon') {
      // Free-text for non-Suwon cities.
      final controller = TextEditingController(text: _district ?? '');
      final value = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('구 입력'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '예: 분당구',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (value == null || !mounted) return;
      setState(() {
        _district = value.isEmpty ? null : value;
        _dong = null;
      });
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '구 선택',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              for (final gu in suwonGuLabels)
                ListTile(
                  title: Text(gu),
                  trailing: gu == _district
                      ? const Icon(Icons.check, color: AppTheme.seed)
                      : null,
                  onTap: () => Navigator.pop(ctx, gu),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (_district != selected) {
        _dong = null;
      }
      _district = selected;
    });
  }

  Future<void> _pickDong() async {
    final dongs = _cityId == 'suwon' ? dongsForGu(_district) : const <String>[];
    final controller = TextEditingController(text: _dong ?? '');

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final q = controller.text.trim();
            final filtered = q.isEmpty
                ? dongs
                : dongs.where((d) => d.contains(q)).toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(ctx).height * 0.55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          '동 선택',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: '동 이름 검색 또는 직접 입력',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setModal(() {}),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: [
                            if (q.isNotEmpty && !dongs.contains(q))
                              ListTile(
                                leading: const Icon(Icons.edit_outlined),
                                title: Text('"$q" 직접 사용'),
                                onTap: () => Navigator.pop(ctx, q),
                              ),
                            for (final d in filtered)
                              ListTile(
                                title: Text(d),
                                trailing: d == _dong
                                    ? const Icon(
                                        Icons.check,
                                        color: AppTheme.seed,
                                      )
                                    : null,
                                onTap: () => Navigator.pop(ctx, d),
                              ),
                            if (filtered.isEmpty && q.isEmpty)
                              const ListTile(
                                title: Text('구를 먼저 고르거나 동을 직접 입력해 주세요'),
                              ),
                          ],
                        ),
                      ),
                      if (q.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, q),
                            child: Text('"$q" 저장'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _dong = selected.isEmpty ? null : selected);
  }

  Future<void> _pickBirthYear() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    '출생연도',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _yearOptions.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return ListTile(
                          title: const Text('선택 안 함'),
                          trailing: _birthYear == null
                              ? const Icon(Icons.check, color: AppTheme.seed)
                              : null,
                          onTap: () => Navigator.pop(ctx, -1),
                        );
                      }
                      final y = _yearOptions[i - 1];
                      return ListTile(
                        title: Text('$y'),
                        trailing: y == _birthYear
                            ? const Icon(Icons.check, color: AppTheme.seed)
                            : null,
                        onTap: () => Navigator.pop(ctx, y),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _birthYear = selected < 0 ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceMuted,
      appBar: AppBar(
        title: const Text('맞춤 설정'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _PrivacyBanner(theme: theme),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.person_outline,
                  title: '나',
                  child: Column(
                    children: [
                      _NavRow(
                        label: '출생연도',
                        value: _birthYear?.toString() ?? '선택',
                        onTap: _pickBirthYear,
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Row(
                          children: [
                            Text(
                              '성별',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(선택)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final g in BenefitGender.values)
                            ChoiceChip(
                              label: Text(g.labelKo),
                              selected: _gender == g,
                              onSelected: (_) => setState(() => _gender = g),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.place_outlined,
                  title: '사는 곳',
                  child: Column(
                    children: [
                      _NavRow(
                        label: '시',
                        value: _cityLabel,
                        onTap: _pickCity,
                      ),
                      const Divider(height: 1),
                      _NavRow(
                        label: '구',
                        value: _district ?? '선택',
                        onTap: _pickDistrict,
                      ),
                      const Divider(height: 1),
                      _NavRow(
                        label: '동',
                        value: _dong ?? '선택',
                        onTap: _pickDong,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.child_care_outlined,
                  title: '아이',
                  trailing: Switch.adaptive(
                    value: _hasChild,
                    activeTrackColor: AppTheme.seed,
                    onChanged: (v) {
                      setState(() {
                        _hasChild = v;
                        if (!v) _childBands.clear();
                      });
                    },
                  ),
                  child: _hasChild
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '아이 연령대 (복수 선택)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final band in ChildAgeBand.values)
                                  FilterChip(
                                    label: Text(band.labelKo),
                                    selected: _childBands.contains(band),
                                    onSelected: (v) {
                                      setState(() {
                                        if (v) {
                                          _childBands.add(band);
                                        } else {
                                          _childBands.remove(band);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '여러 명이면 해당 나이대를 모두 골라 주세요.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '아이가 있으면 켜 주세요. 육아·아동 혜택을 먼저 보여 드려요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.sell_outlined,
                  title: '상황 태그 (선택)',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in SituationTag.values)
                        FilterChip(
                          label: Text(tag.labelKo),
                          selected: _situationTags.contains(tag),
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _situationTags.add(tag);
                              } else {
                                _situationTags.remove(tag);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.interests_outlined,
                  title: '관심 키워드',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final kw in BenefitKeywords.all)
                        FilterChip(
                          label: Text(kw),
                          selected: _keywords.contains(kw),
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _keywords.add(kw);
                              } else {
                                _keywords.remove(kw);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_saving ? '저장 중…' : '저장하고 혜택 보기'),
                    if (!_saving) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.seed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppTheme.seed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '혜택 추천에만 쓰고, 기기에만 저장해요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.seed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.seed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: AppTheme.seed),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
