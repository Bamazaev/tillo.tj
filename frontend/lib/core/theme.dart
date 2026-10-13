import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Палитра. Рангҳои замина/матн аз [dark] вобастаанд (ранги равшан — пешфарз);
/// MaterialApp ҳангоми иваз аз нав сохта мешавад, бинобар ин getter-ҳо кофӣ.
class Gold {
  static bool dark = false;

  // Тиллои бренд — дар ҳарду ранг якхела.
  static const gold = Color(0xFFD4AF37);
  static const light = Color(0xFFF6E3A1);
  static const deep = Color(0xFF9C7A1E);
  static const onGold = Color(0xFF1A1405);
  static const danger = Color(0xFFD9534F);

  // Ранги ivory/шампан барои равшан, шаби тиллоӣ барои торик.
  static Color get bg => dark ? const Color(0xFF0A0907) : const Color(0xFFFAF7F1);
  static Color get surface => dark ? const Color(0xFF14110C) : const Color(0xFFFFFFFF);
  static Color get surface2 => dark ? const Color(0xFF1D1912) : const Color(0xFFF5EFE3);
  static Color get line => dark ? const Color(0xFF2E281C) : const Color(0xFFE9DFCB);
  static Color get text => dark ? const Color(0xFFF4EEE0) : const Color(0xFF1C1710);
  static Color get muted => dark ? const Color(0xFFA39A86) : const Color(0xFF7B705C);

  /// Тилло барои матн ва иконкаҳо (дар заминаи равшан — тиратар, то хонда шавад).
  static Color get accent => dark ? gold : const Color(0xFF9A7316);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8892A), Color(0xFFF6E3A1), Color(0xFFD4AF37), Color(0xFF8A6A17)],
    stops: [0, .38, .62, 1],
  );

  /// Градиент барои матни тиллоӣ.
  static LinearGradient get textGradient => dark
      ? gradient
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A5A0E), Color(0xFFC79A2E), Color(0xFFA67C1B), Color(0xFF6B4E0C)],
          stops: [0, .4, .65, 1],
        );

  static List<BoxShadow> get softShadow => dark
      ? const []
      : [
          BoxShadow(color: const Color(0xFF6B5320).withValues(alpha: .07), blurRadius: 24, offset: const Offset(0, 8)),
        ];

  static TextStyle display(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
        height: 1.08,
      );
}

ThemeData buildTheme() {
  final dark = Gold.dark;
  final base = ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: Gold.bg,
    colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: Gold.accent,
      onPrimary: Gold.onGold,
      secondary: Gold.gold,
      surface: Gold.surface,
      onSurface: Gold.text,
      error: Gold.danger,
      outline: Gold.line,
      outlineVariant: Gold.line,
      surfaceContainerHighest: Gold.surface2,
    ),
  );
  final text = base.textTheme.apply(bodyColor: Gold.text, displayColor: Gold.text);
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return base.copyWith(
    textTheme: text,
    dividerColor: Gold.line,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(backgroundColor: Gold.bg, elevation: 0, centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? Gold.surface2 : Gold.surface,
      hintStyle: TextStyle(color: Gold.muted),
      labelStyle: TextStyle(color: Gold.muted),
      floatingLabelStyle: TextStyle(color: Gold.accent),
      prefixIconColor: Gold.muted,
      suffixIconColor: Gold.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(Gold.line),
      enabledBorder: border(Gold.line),
      focusedBorder: border(Gold.accent, 1.4),
      errorBorder: border(Gold.danger),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: dark ? Gold.surface2 : Gold.surface,
      selectedColor: Gold.gold.withValues(alpha: dark ? .18 : .16),
      side: BorderSide(color: Gold.line),
      labelStyle: TextStyle(color: Gold.text, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? Gold.surface2 : const Color(0xFF1C1710),
      contentTextStyle: TextStyle(color: dark ? Gold.text : Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Gold.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: Gold.gold.withValues(alpha: .16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Gold.accent : Gold.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Gold.accent : Gold.muted),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Gold.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Gold.line)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: Gold.surface, surfaceTintColor: Colors.transparent),
    dialogTheme: DialogThemeData(backgroundColor: Gold.surface, surfaceTintColor: Colors.transparent),
    textSelectionTheme: TextSelectionThemeData(cursorColor: Gold.accent),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: Gold.accent),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Gold.accent)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Gold.gold : null),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Gold.gold.withValues(alpha: .35) : null),
    ),
  );
}
