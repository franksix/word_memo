import 'package:flutter/material.dart';

// 定义四种主题风格
enum AppThemeStyle { monet, paper, glacier, peach }

// 保留这个名字，兼容之前练习页用到的 success 颜色提取
@immutable
class MonetAccents extends ThemeExtension<MonetAccents> {
  final Color success;
  final Color onSuccess;

  const MonetAccents({required this.success, required this.onSuccess});

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

// 统一的生成器
ThemeData buildAppTheme(AppThemeStyle style, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  Color surface, onSurface, outlineVariant, surfaceContainerHighest, onSurfaceVariant;
  Color primary, onPrimary, primaryContainer, onPrimaryContainer;
  Color secondary, onSecondary, secondaryContainer, onSecondaryContainer;
  Color success, onSuccess;
  Color error, onError, errorContainer, onErrorContainer;

  if (style == AppThemeStyle.monet) {
    if (!isDark) {
      surface = const Color(0xFFF2F5F1);
      onSurface = const Color(0xFF2B3230);
      outlineVariant = const Color(0xFFCFD2C8);
      surfaceContainerHighest = const Color(0xFFE6ECE8);
      onSurfaceVariant = const Color(0xFF4F5650);
      primary = const Color(0xFF4A7A73);
      onPrimary = Colors.white;
      primaryContainer = const Color(0xFFC8E0DC);
      onPrimaryContainer = const Color(0xFF0F2926);
      secondary = const Color(0xFF6E7E96);
      onSecondary = Colors.white;
      secondaryContainer = const Color(0xFFD8DFE8);
      onSecondaryContainer = const Color(0xFF232B3A);
      success = const Color(0xFF4F7E5D);
      onSuccess = Colors.white;
      error = const Color(0xFFA85454);
      onError = Colors.white;
      errorContainer = const Color(0xFFF5D5D5);
      onErrorContainer = const Color(0xFF4A1F1F);
    } else {
      surface = const Color(0xFF16201F);
      onSurface = const Color(0xFFE4E7E1);
      outlineVariant = const Color(0xFF3F4643);
      surfaceContainerHighest = const Color(0xFF2A3532);
      onSurfaceVariant = const Color(0xFFC4C9C2);
      primary = const Color(0xFF9CC4BE);
      onPrimary = const Color(0xFF0F2926);
      primaryContainer = const Color(0xFF3A5B55);
      onPrimaryContainer = const Color(0xFFC8E0DC);
      secondary = const Color(0xFFB0BCCE);
      onSecondary = const Color(0xFF232B3A);
      secondaryContainer = const Color(0xFF444E60);
      onSecondaryContainer = const Color(0xFFD8DFE8);
      success = const Color(0xFF9CC49E);
      onSuccess = const Color(0xFF0F2926);
      error = const Color(0xFFE8A5A5);
      onError = const Color(0xFF4A1F1F);
      errorContainer = const Color(0xFF6B3232);
      onErrorContainer = const Color(0xFFF5D5D5);
    }
  } else if (style == AppThemeStyle.paper) {
    if (!isDark) {
      surface = const Color(0xFFF6F3E9);
      onSurface = const Color(0xFF3E362E);
      outlineVariant = const Color(0xFFE0D8C8);
      surfaceContainerHighest = const Color(0xFFEBE6D8);
      onSurfaceVariant = const Color(0xFF6B6054);
      primary = const Color(0xFF8B6D50);
      onPrimary = Colors.white;
      primaryContainer = const Color(0xFFE6D5C3);
      onPrimaryContainer = const Color(0xFF332215);
      secondary = const Color(0xFFA69B8A);
      onSecondary = Colors.white;
      secondaryContainer = const Color(0xFFE8E0D5);
      onSecondaryContainer = const Color(0xFF3D362D);
      success = const Color(0xFF6B8E5C);
      onSuccess = Colors.white;
      error = const Color(0xFFA85454);
      onError = Colors.white;
      errorContainer = const Color(0xFFF5D5D5);
      onErrorContainer = const Color(0xFF4A1F1F);
    } else {
      surface = const Color(0xFF1E1B18);
      onSurface = const Color(0xFFE8E2D8);
      outlineVariant = const Color(0xFF4A443E);
      surfaceContainerHighest = const Color(0xFF2E2924);
      onSurfaceVariant = const Color(0xFFC5BCAE);
      primary = const Color(0xFFD4B594);
      onPrimary = const Color(0xFF3D2E18);
      primaryContainer = const Color(0xFF584226);
      onPrimaryContainer = const Color(0xFFF0E0C8);
      secondary = const Color(0xFFC9B9A6);
      onSecondary = const Color(0xFF3D362D);
      secondaryContainer = const Color(0xFF544B40);
      onSecondaryContainer = const Color(0xFFE8E0D5);
      success = const Color(0xFFA8C3A6);
      onSuccess = const Color(0xFF1E1B18);
      error = const Color(0xFFE8A5A5);
      onError = const Color(0xFF4A1F1F);
      errorContainer = const Color(0xFF6B3232);
      onErrorContainer = const Color(0xFFF5D5D5);
    }
  } else if (style == AppThemeStyle.glacier) {
    if (!isDark) {
      surface = const Color(0xFFF7F8FA);
      onSurface = const Color(0xFF2D333B);
      outlineVariant = const Color(0xFFD5D9E0);
      surfaceContainerHighest = const Color(0xFFEDEFF2);
      onSurfaceVariant = const Color(0xFF5B6573);
      primary = const Color(0xFF45526B);
      onPrimary = Colors.white;
      primaryContainer = const Color(0xFFD1D8E5);
      onPrimaryContainer = const Color(0xFF161D2B);
      secondary = const Color(0xFF7D8A9E);
      onSecondary = Colors.white;
      secondaryContainer = const Color(0xFFE0E4EA);
      onSecondaryContainer = const Color(0xFF2D333B);
      success = const Color(0xFF3C8A70);
      onSuccess = Colors.white;
      error = const Color(0xFFA85454);
      onError = Colors.white;
      errorContainer = const Color(0xFFF5D5D5);
      onErrorContainer = const Color(0xFF4A1F1F);
    } else {
      surface = const Color(0xFF13161A);
      onSurface = const Color(0xFFDDE1E8);
      outlineVariant = const Color(0xFF3B424D);
      surfaceContainerHighest = const Color(0xFF21262D);
      onSurfaceVariant = const Color(0xFFA7B0BD);
      primary = const Color(0xFFA4B5C9);
      onPrimary = const Color(0xFF1A212E);
      primaryContainer = const Color(0xFF3A485B);
      onPrimaryContainer = const Color(0xFFD1D8E5);
      secondary = const Color(0xFF8FA0B5);
      onSecondary = const Color(0xFF2D333B);
      secondaryContainer = const Color(0xFF404A58);
      onSecondaryContainer = const Color(0xFFE0E4EA);
      success = const Color(0xFF82C0AC);
      onSuccess = const Color(0xFF13161A);
      error = const Color(0xFFE8A5A5);
      onError = const Color(0xFF4A1F1F);
      errorContainer = const Color(0xFF6B3232);
      onErrorContainer = const Color(0xFFF5D5D5);
    }
  } else {
    // peach
    if (!isDark) {
      surface = const Color(0xFFF9F6F5);
      onSurface = const Color(0xFF3E3232);
      outlineVariant = const Color(0xFFE8DCD8);
      surfaceContainerHighest = const Color(0xFFF0E9E7);
      onSurfaceVariant = const Color(0xFF6B5B5B);
      primary = const Color(0xFF8C6A6A);
      onPrimary = Colors.white;
      primaryContainer = const Color(0xFFF0D5D5);
      onPrimaryContainer = const Color(0xFF3D1F1F);
      secondary = const Color(0xFFA89992);
      onSecondary = Colors.white;
      secondaryContainer = const Color(0xFFEBE2DF);
      onSecondaryContainer = const Color(0xFF423834);
      success = const Color(0xFF6C8A6B);
      onSuccess = Colors.white;
      error = const Color(0xFFA85454);
      onError = Colors.white;
      errorContainer = const Color(0xFFF5D5D5);
      onErrorContainer = const Color(0xFF4A1F1F);
    } else {
      surface = const Color(0xFF1A1818);
      onSurface = const Color(0xFFEAE2E2);
      outlineVariant = const Color(0xFF4A3D3D);
      surfaceContainerHighest = const Color(0xFF2A2525);
      onSurfaceVariant = const Color(0xFFC7B8B8);
      primary = const Color(0xFFD6ADAD);
      onPrimary = const Color(0xFF3D1F1F);
      primaryContainer = const Color(0xFF584242);
      onPrimaryContainer = const Color(0xFFF0D5D5);
      secondary = const Color(0xFFC7B8B1);
      onSecondary = const Color(0xFF423834);
      secondaryContainer = const Color(0xFF584B46);
      onSecondaryContainer = const Color(0xFFEBE2DF);
      success = const Color(0xFFA7C4A3);
      onSuccess = const Color(0xFF1A1818);
      error = const Color(0xFFE8A5A5);
      onError = const Color(0xFF4A1F1F);
      errorContainer = const Color(0xFF6B3232);
      onErrorContainer = const Color(0xFFF5D5D5);
    }
  }

  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: primary,
    onTertiary: onPrimary,
    tertiaryContainer: primaryContainer,
    onTertiaryContainer: onPrimaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: onSurfaceVariant.withValues(alpha: 0.5),
    outlineVariant: outlineVariant,
    inverseSurface: onSurface,
    onInverseSurface: surface,
    inversePrimary: primary,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: <ThemeExtension<dynamic>>[
      MonetAccents(success: success, onSuccess: onSuccess),
    ],
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
  );
}