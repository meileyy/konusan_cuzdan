import 'package:flutter/material.dart';

/// Paranın türü: kağıt para (banknot) veya madeni para.
enum MoneyType { banknote, coin }

/// Türk lirası küpürlerinden birini temsil eder.
///
/// Bütün tutarlar kuruş cinsinden tam sayı (int) olarak tutulur.
/// Böylece 0.1 + 0.2 gibi ondalık (float) hesaplama hataları oluşmaz.
class Denomination {
  const Denomination({
    required this.valueKurus,
    required this.type,
    required this.color,
    required this.level,
    this.imageAsset,
  });

  /// Paranın değeri (kuruş). 20 TL = 2000.
  final int valueKurus;
  final MoneyType type;

  /// Paranın çiziminde kullanılan ana renk (gerçek banknot renklerine yakın).
  final Color color;

  /// Bu paranın hangi zorluk seviyesinde açıldığı (1 = en kolay).
  final int level;

  /// İsteğe bağlı gerçek fotoğraf (ör. 'assets/images/money/2000.webp').
  /// Boş bırakılırsa para uygulama içinde çizilir.
  final String? imageAsset;

  bool get isBanknote => type == MoneyType.banknote;

  /// Paranın üzerinde yazan sayı: "20" veya "50".
  String get label =>
      valueKurus >= 100 ? '${valueKurus ~/ 100}' : '$valueKurus';

  /// Paranın birimi: "TL" veya "kr".
  String get unit => valueKurus >= 100 ? 'TL' : 'kr';
}

/// Uygulamada kullanılan bütün küpürler (büyükten küçüğe).
const List<Denomination> kDenominations = [
  Denomination(
    valueKurus: 20000,
    type: MoneyType.banknote,
    color: Color(0xFFB0457A),
    level: 2,
  ),
  Denomination(
    valueKurus: 10000,
    type: MoneyType.banknote,
    color: Color(0xFF2F6DB5),
    level: 2,
  ),
  Denomination(
    valueKurus: 5000,
    type: MoneyType.banknote,
    color: Color(0xFFE07B24),
    level: 2,
  ),
  Denomination(
    valueKurus: 2000,
    type: MoneyType.banknote,
    color: Color(0xFF2E8B57),
    level: 1,
  ),
  Denomination(
    valueKurus: 1000,
    type: MoneyType.banknote,
    color: Color(0xFFC0392B),
    level: 1,
  ),
  Denomination(
    valueKurus: 500,
    type: MoneyType.banknote,
    color: Color(0xFF7D5A7A),
    level: 1,
  ),
  Denomination(
    valueKurus: 100,
    type: MoneyType.coin,
    color: Color(0xFFD4AF37),
    level: 2,
  ),
  Denomination(
    valueKurus: 50,
    type: MoneyType.coin,
    color: Color(0xFFB8BCC2),
    level: 3,
  ),
  Denomination(
    valueKurus: 25,
    type: MoneyType.coin,
    color: Color(0xFFCFA54A),
    level: 3,
  ),
  Denomination(
    valueKurus: 10,
    type: MoneyType.coin,
    color: Color(0xFFCFA54A),
    level: 3,
  ),
  Denomination(
    valueKurus: 5,
    type: MoneyType.coin,
    color: Color(0xFFCFA54A),
    level: 3,
  ),
];

/// Bütün küpür değerleri (büyükten küçüğe), para üstü hesabında kullanılır.
final List<int> kAllValues = kDenominations.map((d) => d.valueKurus).toList();

/// Değerden küpürü bulur.
Denomination denominationOf(int valueKurus) =>
    kDenominations.firstWhere((d) => d.valueKurus == valueKurus);
