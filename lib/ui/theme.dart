import 'package:flutter/material.dart';

/// Cuanly palette: warm cream background, sunny yellow primary, candy accents.
class C {
  static const bg = Color(0xFFFFF8E7);
  static const ink = Color(0xFF4A3426);
  static const darkBg = Color(0xFF1E1812);
  static const darkCard = Color(0xFF2B2219);
  static const darkInk = Color(0xFFF3E6CC);
  static const yellow = Color(0xFFFFC93C);
  static const mint = Color(0xFF7BE0B0);
  static const coral = Color(0xFFFF8A80);
  static const lilac = Color(0xFFC9B6FF);
  static const sky = Color(0xFF8EC9FF);
  static const pink = Color(0xFFFF9FCB);
  static const orange = Color(0xFFFFA45C);

  static const chart = [coral, yellow, mint, lilac, sky, pink, orange, Color(0xFFB8E986)];
  static const accents = [sky, pink, lilac, mint, orange];

  /// Text/outline color for the current theme (dark brown on light, cream on dark).
  static Color fg(BuildContext context) => Theme.of(context).colorScheme.onSurface;
}

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? C.darkBg : C.bg;
  final fg = dark ? C.darkInk : C.ink; // text and outlines
  final card = dark ? C.darkCard : Colors.white;
  final border = BorderSide(color: fg, width: 2);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: border);
  final scheme = ColorScheme.fromSeed(seedColor: C.yellow, brightness: brightness).copyWith(
    primary: C.yellow,
    onPrimary: C.ink,
    secondary: C.mint,
    onSecondary: C.ink,
    surface: bg,
    onSurface: fg,
    error: C.coral,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Roboto',
    textTheme: ThemeData(brightness: brightness).textTheme.apply(bodyColor: fg, displayColor: fg),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(color: card, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 6), shape: shape),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: C.yellow,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: fg)),
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? C.ink : fg)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: C.yellow,
      foregroundColor: C.ink,
      elevation: 0,
      shape: shape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.yellow,
        foregroundColor: C.ink,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: border),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: fg,
      unselectedLabelColor: fg.withValues(alpha: .6),
      indicatorColor: C.yellow,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        side: BorderSide(color: fg, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: fg, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: border),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: border),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: fg, width: 3)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: card,
      selectedColor: C.mint,
      side: BorderSide(color: fg, width: 1.5),
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w700),
      secondaryLabelStyle: const TextStyle(color: C.ink, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.yellow : card),
        foregroundColor:
            WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.ink : fg),
        side: WidgetStateProperty.all(BorderSide(color: fg, width: 2)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: bg,
      shape: shape,
      titleTextStyle: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w800),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: border,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: fg,
      linearTrackColor: fg.withValues(alpha: 0.12),
      linearMinHeight: 10,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    ),
  );
}

final _lightTheme = buildTheme();

/// Card with a pastel fill. Always uses the light theme inside, so dark brown text stays readable in dark mode.
class PastelCard extends StatelessWidget {
  const PastelCard({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(data: _lightTheme, child: Card(color: color, child: child));
}
