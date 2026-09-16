import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../util/discover_district.dart';

/// Compact schematic map of Suwon's 4 districts (no map SDK).
///
/// Layout (north↑): 장안 north, 권선 southwest, 팔달 center, 영통 southeast.
/// Taps drive the same district ids as [DiscoverDistrict] chips.
class SuwonDistrictMap extends StatelessWidget {
  const SuwonDistrictMap({
    super.key,
    required this.selectedDistrictId,
    required this.onDistrictSelected,
    this.height = 140,
  });

  final String selectedDistrictId;
  final ValueChanged<String> onDistrictSelected;
  final double height;

  static const _guIds = ['jangan', 'gwonsun', 'paldal', 'yeongtong'];

  void _onTapDistrict(String id) {
    onDistrictSelected(
      DiscoverDistrict.toggleSelection(selectedDistrictId, id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = DiscoverDistrict.byId(selectedDistrictId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    '수원 구 선택',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: selectedDistrictId == DiscoverDistrict.all.id
                        ? null
                        : () => onDistrictSelected(DiscoverDistrict.all.id),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      foregroundColor: AppTheme.seed,
                    ),
                    child: Text(
                      '전체',
                      style: TextStyle(
                        fontWeight: selectedDistrictId == DiscoverDistrict.all.id
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              key: const Key('suwon_district_map_canvas'),
              height: height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final id = SuwonDistrictPaths.hitTest(
                        details.localPosition,
                        Size(constraints.maxWidth, constraints.maxHeight),
                      );
                      if (id != null) _onTapDistrict(id);
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _SuwonDistrictPainter(
                        selectedDistrictId: selectedDistrictId,
                        seed: AppTheme.seed,
                        mutedFill: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: theme.colorScheme.outlineVariant,
                      ),
                      child: Stack(
                        children: [
                          for (final id in _guIds)
                            _DistrictLabel(
                              id: id,
                              selected: selectedDistrictId == id,
                              size: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (selectedDistrictId != DiscoverDistrict.all.id)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  '선택: ${selected.fullLabel}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.seed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DistrictLabel extends StatelessWidget {
  const _DistrictLabel({
    required this.id,
    required this.selected,
    required this.size,
  });

  final String id;
  final bool selected;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final d = DiscoverDistrict.byId(id);
    final center = SuwonDistrictPaths.labelAnchor(id, size);
    return Positioned(
      left: center.dx - 28,
      top: center.dy - 10,
      width: 56,
      height: 20,
      child: IgnorePointer(
        child: Text(
          d.shortLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

/// Normalized polygon paths for Suwon 4-gu schematic (unit square).
///
/// Exposed for unit tests (hit-test / geometry).
class SuwonDistrictPaths {
  SuwonDistrictPaths._();

  /// Unit-square polygons: 장안 N, 권선 SW, 팔달 center, 영통 SE.
  static const Map<String, List<Offset>> unitPolygons = {
    'jangan': [
      Offset(0.02, 0.06),
      Offset(0.98, 0.06),
      Offset(0.98, 0.40),
      Offset(0.02, 0.40),
    ],
    'gwonsun': [
      Offset(0.02, 0.40),
      Offset(0.44, 0.40),
      Offset(0.44, 0.94),
      Offset(0.02, 0.94),
    ],
    'paldal': [
      Offset(0.44, 0.40),
      Offset(0.70, 0.40),
      Offset(0.70, 0.72),
      Offset(0.44, 0.72),
    ],
    'yeongtong': [
      Offset(0.70, 0.40),
      Offset(0.98, 0.40),
      Offset(0.98, 0.94),
      Offset(0.44, 0.94),
      Offset(0.44, 0.72),
      Offset(0.70, 0.72),
    ],
  };

  static Path pathFor(String id, Size size) {
    final pts = unitPolygons[id];
    if (pts == null || pts.isEmpty) return Path();
    final path = Path()
      ..moveTo(pts.first.dx * size.width, pts.first.dy * size.height);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    path.close();
    return path;
  }

  /// Returns district id under [local], or null if none.
  static String? hitTest(Offset local, Size size) {
    // Prefer smaller / later districts if overlap (none by design).
    for (final id in const ['paldal', 'gwonsun', 'yeongtong', 'jangan']) {
      if (pathFor(id, size).contains(local)) return id;
    }
    return null;
  }

  static Offset labelAnchor(String id, Size size) {
    final pts = unitPolygons[id]!;
    var sx = 0.0;
    var sy = 0.0;
    for (final p in pts) {
      sx += p.dx;
      sy += p.dy;
    }
    final n = pts.length;
    return Offset((sx / n) * size.width, (sy / n) * size.height);
  }
}

class _SuwonDistrictPainter extends CustomPainter {
  _SuwonDistrictPainter({
    required this.selectedDistrictId,
    required this.seed,
    required this.mutedFill,
    required this.border,
  });

  final String selectedDistrictId;
  final Color seed;
  final Color mutedFill;
  final Color border;

  static const _ids = ['jangan', 'gwonsun', 'paldal', 'yeongtong'];

  @override
  void paint(Canvas canvas, Size size) {
    for (final id in _ids) {
      final path = SuwonDistrictPaths.pathFor(id, size);
      final selected = selectedDistrictId == id;
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = selected ? seed : mutedFill;
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = selected ? seed.withValues(alpha: 0.9) : border;
      canvas.drawPath(path, fill);
      canvas.drawPath(path, edge);
    }
  }

  @override
  bool shouldRepaint(covariant _SuwonDistrictPainter oldDelegate) {
    return oldDelegate.selectedDistrictId != selectedDistrictId ||
        oldDelegate.seed != seed ||
        oldDelegate.mutedFill != mutedFill ||
        oldDelegate.border != border;
  }
}
