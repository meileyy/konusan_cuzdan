/// Kuruş cinsinden tutarı ekranda gösterilecek metne çevirir.
/// 1500 → "15 TL", 1750 → "17,50 TL", 3803375 → "38.033,75 TL"
String formatMoney(int kurus) {
  if (kurus < 0) return '-${formatMoney(-kurus)}';
  final lira = _groupThousands(kurus ~/ 100);
  final kr = kurus % 100;
  if (kr == 0) return '$lira TL';
  return '$lira,${kr.toString().padLeft(2, '0')} TL';
}

/// Binlik ayraç (Türkçe yazımda nokta): 40000 → "40.000"
String _groupThousands(int n) {
  final digits = '$n';
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Kuruş cinsinden tutarı sesli okunacak metne çevirir.
/// 1500 → "15 lira", 1750 → "17 lira 50 kuruş", 25 → "25 kuruş"
String speakMoney(int kurus) {
  final lira = kurus ~/ 100;
  final kr = kurus % 100;
  if (lira == 0 && kr == 0) return 'sıfır lira';
  final parts = <String>[if (lira > 0) '$lira lira', if (kr > 0) '$kr kuruş'];
  return parts.join(' ');
}

final _digitsOnly = RegExp(r'^\d*$');

/// Noktalarla 3'erli gruplanmış tam sayı: "1.500", "10.000", "1.000.000"
final _thousandsGrouped = RegExp(r'^\d{1,3}(\.\d{3})+$');

/// Bir fiyat girişini kuruşa çevirir. Geçersiz girişte null döner.
///
/// - Virgül varsa virgül ondalık, noktalar binlik ayraçtır: "10.000,50"
/// - Virgül yoksa ve noktadan sonra 3 rakam varsa nokta binliktir: "10.000"
/// - Virgül yoksa ve noktadan sonra 1–2 rakam varsa nokta ondalıktır: "17.50"
int? parseMoneyInput(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  String whole;
  var fraction = '';
  if (text.contains(',')) {
    final parts = text.split(',');
    if (parts.length != 2) return null;
    whole = parts[0];
    fraction = parts[1];
    if (whole.contains('.')) {
      if (!_thousandsGrouped.hasMatch(whole)) return null;
      whole = whole.replaceAll('.', '');
    }
  } else if (_thousandsGrouped.hasMatch(text)) {
    whole = text.replaceAll('.', '');
  } else {
    final parts = text.split('.');
    if (parts.length > 2) return null;
    whole = parts[0];
    if (parts.length == 2) fraction = parts[1];
  }
  if (!_digitsOnly.hasMatch(whole) || !_digitsOnly.hasMatch(fraction)) {
    return null;
  }
  if (fraction.length > 2 || (whole.isEmpty && fraction.isEmpty)) return null;
  final lira = whole.isEmpty ? 0 : int.tryParse(whole);
  if (lira == null) return null;
  final kr = fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0'));
  return lira * 100 + kr;
}
