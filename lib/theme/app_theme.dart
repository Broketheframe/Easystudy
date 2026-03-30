import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final bool isPulse;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color panel;
  final Color border;
  final Color track;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const AppColors({
    required this.isPulse,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.panel,
    required this.border,
    required this.track,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  @override
  AppColors copyWith({
    bool? isPulse,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? panel,
    Color? border,
    Color? track,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
  }) {
    return AppColors(
      isPulse: isPulse ?? this.isPulse,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      panel: panel ?? this.panel,
      border: border ?? this.border,
      track: track ?? this.track,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      isPulse: t < 0.5 ? isPulse : other.isPulse,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      border: Color.lerp(border, other.border, t)!,
      track: Color.lerp(track, other.track, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

class AppTheme {
  static const Color darkBase = Color(0xFF131F24);
  static const Color darkAccent = Color(0xFF49C0F7);

  static ThemeData light({bool usePulse = false}) {
    const classicColors = AppColors(
      isPulse: false,
      background: Colors.white,
      surface: Color(0xFFF1F4F6),
      surfaceAlt: Color(0xFFE8EDF1),
      panel: Color(0xFFF7FAFC),
      border: Color(0xFFD0D7DE),
      track: Color(0xFFCBD5DC),
      textPrimary: darkBase,
      textSecondary: Color(0xFF37464F),
      accent: darkBase,
    );

    const pulseColors = AppColors(
      isPulse: true,
      background: Color(0xFFF4F8FF),
      surface: Colors.white,
      surfaceAlt: Color(0xFFEAF2FF),
      panel: Color(0xFFF0F5FF),
      border: Color(0xFFD5E1F4),
      track: Color(0xFFBAC9E0),
      textPrimary: Color(0xFF10233A),
      textSecondary: Color(0xFF5E6D84),
      accent: Color(0xFF0A66E8),
    );

    return _buildThemeData(
      brightness: Brightness.light,
      colors: usePulse ? pulseColors : classicColors,
    );
  }

  static ThemeData dark({required Color background, bool usePulse = false}) {
    final classicColors = AppColors(
      isPulse: false,
      background: background,
      surface: const Color(0xFF1A2A34),
      surfaceAlt: const Color(0xFF1F2C36),
      panel: const Color(0xFF0A1519),
      border: const Color(0xFF2A3A42),
      track: const Color(0xFF37464F),
      textPrimary: Colors.white,
      textSecondary: Colors.white70,
      accent: darkAccent,
    );

    final pulseColors = AppColors(
      isPulse: true,
      background: const Color(0xFF0D1A2E),
      surface: const Color(0xFF12233D),
      surfaceAlt: const Color(0xFF162B49),
      panel: const Color(0xFF0B1627),
      border: const Color(0xFF244266),
      track: const Color(0xFF2E4E74),
      textPrimary: const Color(0xFFEAF1FF),
      textSecondary: const Color(0xFFB6C4DC),
      accent: const Color(0xFF63A5FF),
    );

    return _buildThemeData(
      brightness: Brightness.dark,
      colors: usePulse ? pulseColors : classicColors,
    );
  }

  static ThemeData _buildThemeData({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final String bodyFont = colors.isPulse ? 'NunitoSans' : 'Roboto';
    final String headingFont = colors.isPulse ? 'Rubik' : 'Roboto';
    final String titleFont = colors.isPulse ? 'Rubik' : 'Roboto';

    final base = (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;
    final textTheme = base
        .apply(
          bodyColor: colors.textPrimary,
          displayColor: colors.textPrimary,
          fontFamily: bodyFont,
        )
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: headingFont,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: headingFont,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: headingFont,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: headingFont,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: titleFont,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: titleFont,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: titleFont,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: base.bodyLarge?.copyWith(fontFamily: bodyFont),
          bodyMedium: base.bodyMedium?.copyWith(fontFamily: bodyFont),
          bodySmall: base.bodySmall?.copyWith(fontFamily: bodyFont),
        );

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: colors.accent,
            onPrimary: Colors.white,
            secondary: colors.accent,
            onSecondary: Colors.white,
            surface: colors.surface,
            onSurface: colors.textPrimary,
            outline: colors.border,
          )
        : ColorScheme.light(
            primary: colors.accent,
            onPrimary: Colors.white,
            secondary: colors.accent,
            onSecondary: Colors.white,
            surface: colors.surface,
            onSurface: colors.textPrimary,
            outline: colors.border,
          );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(colors.isPulse ? 16 : 10),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: bodyFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontFamily: headingFont,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: colors.isPulse ? 0 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accent,
        inactiveTrackColor: colors.border,
        thumbColor: colors.accent,
        overlayColor: colors.accent.withValues(alpha: 0.16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: buttonShape,
          elevation: colors.isPulse ? 0 : 1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.titleMedium?.copyWith(fontFamily: headingFont),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.titleSmall?.copyWith(fontFamily: titleFont),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
          textStyle: textTheme.titleSmall?.copyWith(fontFamily: titleFont),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(colors.isPulse ? 16 : 10),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(colors.isPulse ? 16 : 10),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
      ),
      extensions: [colors],
    );
  }
}
