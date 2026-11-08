import 'package:flutter/material.dart';

/// 莫奈主题调色板。
class MonetPalette {
  MonetPalette._();

  // ---------------- 浅色：晨雾睡莲 ----------------
  static const lightPrimary = Color(0xFF4A7A73);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFC8E0DC);
  static const lightOnPrimaryContainer = Color(0xFF0F2926);

  static const lightSecondary = Color(0xFF6E7E96);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFD8DFE8);
  static const lightOnSecondaryContainer = Color(0xFF232B3A);

  static const lightTertiary = Color(0xFFA97C4E);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightTertiaryContainer = Color(0xFFF0E0C8);
  static const lightOnTertiaryContainer = Color(0xFF3D2E18);

  static const lightError = Color(0xFFA85454);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFF5D5D5);
  static const lightOnErrorContainer = Color(0xFF4A1F1F);

  static const lightSurface = Color(0xFFF5F2EA);
  static const lightOnSurface = Color(0xFF2B3230);
  static const lightSurfaceVariant = Color(0xFFE6E4DC);
  static const lightOnSurfaceVariant = Color(0xFF4F5650);
  static const lightOutline = Color(0xFF8A9088);
  static const lightOutlineVariant = Color(0xFFCFD2C8);

  static const lightSuccess = Color(0xFF4F7E5D);

  // ---------------- 深色：夜色睡莲 ----------------
  static const darkPrimary = Color(0xFF9CC4BE);
  static const darkOnPrimary = Color(0xFF0F2926);
  static const darkPrimaryContainer = Color(0xFF3A5B55);
  static const darkOnPrimaryContainer = Color(0xFFC8E0DC);

  static const darkSecondary = Color(0xFFB0BCCE);
  static const darkOnSecondary = Color(0xFF232B3A);
  static const darkSecondaryContainer = Color(0xFF444E60);
  static const darkOnSecondaryContainer = Color(0xFFD8DFE8);

  static const darkTertiary = Color(0xFFDCC094);
  static const darkOnTertiary = Color(0xFF3D2E18);
  static const darkTertiaryContainer = Color(0xFF584226);
  static const darkOnTertiaryContainer = Color(0xFFF0E0C8);

  static const darkError = Color(0xFFE8A5A5);
  static const darkOnError = Color(0xFF4A1F1F);
  static const darkErrorContainer = Color(0xFF6B3232);
  static const darkOnErrorContainer = Color(0xFFF5D5D5);

  static const darkSurface = Color(0xFF16201F);
  static const darkOnSurface = Color(0xFFE4E7E1);
  static const darkSurfaceVariant = Color(0xFF2A3532);
  static const darkOnSurfaceVariant = Color(0xFFC4C9C2);
  static const darkOutline = Color(0xFF6E7770);
  static const darkOutlineVariant = Color(0xFF3F4643);

  static const darkSuccess = Color(0xFF9CC49E);
}

/// 莫奈主题扩展：M3 ColorScheme 没有 success 槽位，
/// 用 ThemeExtension 单独补充，供练习对错反馈使用。
@immutable
class MonetAccents extends ThemeExtension<MonetAccents> {
  final Color success;
  final Color onSuccess;

  const MonetAccents({
    required this.success,
    required this.onSuccess,
  });

  @override
  MonetAccents copyWith({Color? success, Color? onSuccess}) {
    return MonetAccents(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  MonetAccents lerp(covariant MonetAccents? other, double t) {
    if (other == null) return this;
    return MonetAccents(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}

ThemeData buildMonetLightTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: MonetPalette.lightPrimary,
    onPrimary: MonetPalette.lightOnPrimary,
    primaryContainer: MonetPalette.lightPrimaryContainer,
    onPrimaryContainer: MonetPalette.lightOnPrimaryContainer,
    secondary: MonetPalette.lightSecondary,
    onSecondary: MonetPalette.lightOnSecondary,
    secondaryContainer: MonetPalette.lightSecondaryContainer,
    onSecondaryContainer: MonetPalette.lightOnSecondaryContainer,
    tertiary: MonetPalette.lightTertiary,
    onTertiary: MonetPalette.lightOnTertiary,
    tertiaryContainer: MonetPalette.lightTertiaryContainer,
    onTertiaryContainer: MonetPalette.lightOnTertiaryContainer,
    error: MonetPalette.lightError,
    onError: MonetPalette.lightOnError,
    errorContainer: MonetPalette.lightErrorContainer,
    onErrorContainer: MonetPalette.lightOnErrorContainer,
    surface: MonetPalette.lightSurface,
    onSurface: MonetPalette.lightOnSurface,
    surfaceContainerHighest: MonetPalette.lightSurfaceVariant,
    onSurfaceVariant: MonetPalette.lightOnSurfaceVariant,
    outline: MonetPalette.lightOutline,
    outlineVariant: MonetPalette.lightOutlineVariant,
    inverseSurface: MonetPalette.darkSurface,
    onInverseSurface: MonetPalette.darkOnSurface,
    inversePrimary: MonetPalette.darkPrimary,
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
  );

  return _decorate(
    scheme,
    const MonetAccents(
      success: MonetPalette.lightSuccess,
      onSuccess: MonetPalette.lightOnPrimary,
    ),
  );
}

ThemeData buildMonetDarkTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: MonetPalette.darkPrimary,
    onPrimary: MonetPalette.darkOnPrimary,
    primaryContainer: MonetPalette.darkPrimaryContainer,
    onPrimaryContainer: MonetPalette.darkOnPrimaryContainer,
    secondary: MonetPalette.darkSecondary,
    onSecondary: MonetPalette.darkOnSecondary,
    secondaryContainer: MonetPalette.darkSecondaryContainer,
    onSecondaryContainer: MonetPalette.darkOnSecondaryContainer,
    tertiary: MonetPalette.darkTertiary,
    onTertiary: MonetPalette.darkOnTertiary,
    tertiaryContainer: MonetPalette.darkTertiaryContainer,
    onTertiaryContainer: MonetPalette.darkOnTertiaryContainer,
    error: MonetPalette.darkError,
    onError: MonetPalette.darkOnError,
    errorContainer: MonetPalette.darkErrorContainer,
    onErrorContainer: MonetPalette.darkOnErrorContainer,
    surface: MonetPalette.darkSurface,
    onSurface: MonetPalette.darkOnSurface,
    surfaceContainerHighest: MonetPalette.darkSurfaceVariant,
    onSurfaceVariant: MonetPalette.darkOnSurfaceVariant,
    outline: MonetPalette.darkOutline,
    outlineVariant: MonetPalette.darkOutlineVariant,
    inverseSurface: MonetPalette.lightSurface,
    onInverseSurface: MonetPalette.lightOnSurface,
    inversePrimary: MonetPalette.lightPrimary,
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
  );

  return _decorate(
    scheme,
    const MonetAccents(
      success: MonetPalette.darkSuccess,
      onSuccess: MonetPalette.darkOnPrimary,
    ),
  );
}

ThemeData _decorate(ColorScheme scheme, MonetAccents accents) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: <ThemeExtension<dynamic>>[accents],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 0.6,
      space: 0.6,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
    ),
  );
}