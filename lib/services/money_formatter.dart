/// Kuruş cinsinden tutarı ekranda gösterilecek metne çevirir.
/// 1500 → "15 TL", 1750 → "17,50 TL"
String formatMoney(int kurus) {
  final lira = kurus ~/ 100;
  final kr = kurus % 100;
  if (kr == 0) return '$lira TL';
  return '$lira,${kr.toString().padLeft(2, '0')} TL';
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

/// "15", "15,5", "15,50" veya "15.50" gibi bir girişi kuruşa çevirir.
/// Geçersiz girişte null döner.
int? parseMoneyInput(String input) {
  final text = input.trim().replaceAll('.', ',');
  if (text.isEmpty) return null;
  final parts = text.split(',');
  if (parts.length > 2) return null;
  final lira = parts[0].isEmpty ? 0 : int.tryParse(parts[0]);
  if (lira == null || lira < 0) return null;
  var kr = 0;
  if (parts.length == 2 && parts[1].isNotEmpty) {
    if (parts[1].length > 2) return null;
    final parsed = int.tryParse(parts[1].padRight(2, '0'));
    if (parsed == null) return null;
    kr = parsed;
  }
  return lira * 100 + kr;
}
