import 'package:flutter/material.dart';

class AppTheme {
  /// Soft blue seed — brighter local-discovery feel (not government gray/green).
  static const Color seed = Color(0xFF3B82F6);
  static const Color accent = Color(0xFFF97316);
  static const Color surfaceMuted = Color(0xFFF4F7FB);
  static const Color categoryApply = Color(0xFF2563EB);
  static const Color categoryEnjoy = Color(0xFF16A34A);
  static const Color categoryDiscover = Color(0xFF9333EA);
  static const Color categoryBenefit = Color(0xFFF97316);
  static const Color labelApply = Color(0xFF059669);
  static const Color labelEnjoy = Color(0xFFDB2777);
  static const Color labelFood = Color(0xFFEA580C);
  static const Color labelTour = Color(0xFF059669);

  static const double cardRadius = 14;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceMuted,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: seed.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
