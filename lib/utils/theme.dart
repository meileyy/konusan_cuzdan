import 'package:flutter/material.dart';

/// Uygulama renkleri. Canva ekran tasarımından alındı: krem zemin,
/// canlı ama yumuşak renkler ve koyu lacivert başlıklar.
class AppColors {
  static const background = Color(0xFFFDF8EE);
  static const text = Color(0xFF16325C); // lacivert başlık/metin
  static const primary = Color(0xFF3A8DDE); // mavi
  static const orange = Color(0xFFF7931E);
  static const purple = Color(0xFF7B4FD6);
  static const success = Color(0xFF3FB65A); // yeşil
  static const coral = Color(0xFFF2626B);
  static const yellow = Color(0xFFFFC94D);
  static const warning = orange;
  static const glow = Color(0xFFFFD43B);

  // Cüzdan (turuncu deri)
  static const wallet = Color(0xFFF6A93B);
  static const walletDark = Color(0xFFD9822B);
  static const walletInner = Color(0xFFFDF1DC);
  static const walletBorder = walletDark;

  // Paneller
  static const paletteBg = Color(0xFFDDEBFA);
  static const register = Color(0xFFE6F1FD);
  static const cardBorder = Color(0xFFF1E6D3);

  // Ana sayfa kutuları
  static const wallets = success;
  static const shop = primary;
  static const game = Color(0xFF9B6BE0);
  static const history = coral;
  static const help = yellow;
}

/// Baloo 2 değişken (variable) bir yazı tipidir; kalınlığı 'wght' ekseniyle
/// verilir. Bu yardımcı, FontWeight ile aynı kalınlığı yazı tipine uygular.
TextStyle rounded({
  double size = 20,
  FontWeight weight = FontWeight.w700,
  Color color = AppColors.text,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Baloo2',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color,
    height: height,
  );
}

/// Bütün ekranlarda ortak tema: büyük yazılar ve büyük dokunma alanları.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Baloo2',
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
      fontFamily: 'Baloo2',
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: rounded(size: 26, weight: FontWeight.w800),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(88, 72),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        textStyle: rounded(size: 24, weight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 72),
        textStyle: rounded(size: 22, weight: FontWeight.w700),
        side: const BorderSide(color: AppColors.primary, width: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
  );
}
