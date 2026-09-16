import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const seed = Color(0xFF3C5AF6);

  static const _background = Color(0xFF0A0A10);
  static const _surfaceContainer = Color(0xFF15151D);
  static const _surfaceContainerHigh = Color(0xFF1E1E29);
  static const _surfaceContainerHighest = Color(0xFF282836);
  static const _onSurface = Color(0xFFEDEDF3);
  static const _onSurfaceVariant = Color(0xFF9E9EAF);
  static const _outline = Color(0xFF2C2C38);

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ).copyWith(
          surface: _background,
          surfaceContainer: _surfaceContainer,
          surfaceContainerHigh: _surfaceContainerHigh,
          surfaceContainerHighest: _surfaceContainerHighest,
          onSurface: _onSurface,
          onSurfaceVariant: _onSurfaceVariant,
          outline: _outline,
          outlineVariant: _outline,
        );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: _background,
      appBarTheme: AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: _onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _outline),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: _outline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textColor: _onSurface,
        subtitleTextStyle: TextStyle(color: _onSurfaceVariant, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceContainerHighest,
        labelStyle: TextStyle(
          color: _onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: _outline, space: 1),
      textTheme: base.textTheme
          .apply(bodyColor: _onSurface, displayColor: _onSurface)
          .copyWith(
            headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _onSurface,
            ),
          ),
    );
  }
}
