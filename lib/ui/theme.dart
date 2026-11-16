import 'package:flutter/material.dart';

/// Cuanly palette: warm cream background, sunny yellow primary, candy accents.
class C {
  static const bg = Color(0xFFFFF8E7);
  static const ink = Color(0xFF4A3426);
  static const yellow = Color(0xFFFFC93C);
  static const mint = Color(0xFF7BE0B0);
  static const coral = Color(0xFFFF8A80);
  static const lilac = Color(0xFFC9B6FF);
  static const sky = Color(0xFF8EC9FF);
  static const pink = Color(0xFFFF9FCB);
  static const orange = Color(0xFFFFA45C);

  static const chart = [coral, yellow, mint, lilac, sky, pink, orange, Color(0xFFB8E986)];
  static const accents = [sky, pink, lilac, mint, orange];
}

ThemeData buildTheme() {
  const border = BorderSide(color: C.ink, width: 2);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: border);
  final scheme = ColorScheme.fromSeed(seedColor: C.yellow, brightness: Brightness.light).copyWith(
    primary: C.yellow,
    onPrimary: C.ink,
    secondary: C.mint,
    onSecondary: C.ink,
    surface: C.bg,
    onSurface: C.ink,
    error: C.coral,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    fontFamily: 'Roboto',
    textTheme: ThemeData.light().textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: C.ink, fontSize: 22, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 6), shape: shape),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: C.yellow,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      iconTheme: WidgetStateProperty.all(const IconThemeData(color: C.ink)),
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
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: C.ink, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: border),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: border),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.ink, width: 3)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: C.mint,
      side: const BorderSide(color: C.ink, width: 1.5),
      labelStyle: const TextStyle(color: C.ink, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.yellow : Colors.white),
        foregroundColor: WidgetStateProperty.all(C.ink),
        side: WidgetStateProperty.all(const BorderSide(color: C.ink, width: 2)),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: C.bg, shape: shape),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: border,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: C.ink,
      linearTrackColor: Color(0x1A4A3426),
      linearMinHeight: 10,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );
}
