import 'dart:math';

import '../models/denomination.dart';

/// Bir alışveriş için hesaplanan ödeme planı.
class PaymentPlan {
  const PaymentPlan({
    required this.priceKurus,
    required this.pay,
    required this.change,
  });

  final int priceKurus;

  /// Cüzdandan verilecek paralar: {küpür değeri: adet}
  final Map<int, int> pay;

  /// Kasiyerden geri alınacak para üstü: {küpür değeri: adet}
  final Map<int, int> change;

  int get paidKurus => PaymentCalculator.total(pay);
  int get changeKurus => paidKurus - priceKurus;
  bool get isExact => changeKurus == 0;
}

/// Uygulamanın çekirdek algoritması.
class PaymentCalculator {
  /// {küpür: adet} haritasındaki toplam tutar.
  static int total(Map<int, int> money) =>
      money.entries.fold(0, (sum, e) => sum + e.key * e.value);

  /// {küpür: adet} haritasını tek tek paralardan oluşan listeye açar (büyükten küçüğe).
  /// {2000: 2, 500: 1} → [2000, 2000, 500]
  static List<int> expand(Map<int, int> money) {
    final values = money.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final v in values)
        for (var i = 0; i < (money[v] ?? 0); i++) v,
    ];
  }

  /// Cüzdandaki paralardan fiyatı karşılayan en uygun kombinasyonu bulur.
  ///
  /// Öncelik sırası:
  ///   1. Fazla ödeme (para üstü) en az olsun.
  ///   2. Aynı tutar için en az sayıda para verilsin.
  ///
  /// Yöntem: sınırlı sırt çantası (bounded knapsack) dinamik programlama.
  /// dp[s] = "s tutarını oluşturmak için gereken en az para sayısı".
  /// Para yetmiyorsa null döner.
  static PaymentPlan? planPayment(
    Map<int, int> wallet,
    int priceKurus, {
    List<int>? changeValues,
  }) {
    if (priceKurus < 0) throw ArgumentError('Fiyat negatif olamaz');
    if (priceKurus == 0) {
      return const PaymentPlan(priceKurus: 0, pay: {}, change: {});
    }

    final groups =
        wallet.entries.where((e) => e.key > 0 && e.value > 0).toList()
          ..sort((a, b) => b.key.compareTo(a.key));
    final available = total(Map.fromEntries(groups));
    if (available < priceKurus) return null;

    // Bütün tutarlar ortak bölenin (g) katı olduğundan diziyi g'ye bölerek küçültürüz.
    var g = 0;
    for (final e in groups) {
      g = _gcd(g, e.key);
    }

    // En iyi ödeme hiçbir zaman "fiyat + en büyük para" tutarına ulaşmaz:
    // ulaşsaydı en büyük parayı çıkarınca bile fiyat karşılanırdı.
    final maxValue = groups.first.key;
    final limit = min(available, priceKurus + maxValue - 1);
    final n = limit ~/ g;

    const inf = 1 << 30;
    var dp = List<int>.filled(n + 1, inf)..[0] = 0;
    final usedPerGroup = <List<int>>[];

    for (final group in groups) {
      final unit = group.key ~/ g;
      final next = List<int>.filled(n + 1, inf);
      final used = List<int>.filled(n + 1, 0);
      for (var s = 0; s <= n; s++) {
        for (var k = 0; k <= group.value; k++) {
          final prev = s - k * unit;
          if (prev < 0) break;
          if (dp[prev] == inf) continue;
          final candidate = dp[prev] + k;
          if (candidate < next[s]) {
            next[s] = candidate;
            used[s] = k;
          }
        }
      }
      dp = next;
      usedPerGroup.add(used);
    }

    // Fiyattan büyük/eşit, oluşturulabilen en küçük tutarı seç.
    final minUnits = (priceKurus + g - 1) ~/ g;
    int? best;
    for (var s = minUnits; s <= n; s++) {
      if (dp[s] < inf) {
        best = s;
        break;
      }
    }
    if (best == null) return null;

    // Hangi paraların kullanıldığını geriye doğru bul.
    final pay = <int, int>{};
    var s = best;
    for (var i = groups.length - 1; i >= 0; i--) {
      final k = usedPerGroup[i][s];
      if (k > 0) pay[groups[i].key] = k;
      s -= k * (groups[i].key ~/ g);
    }

    final paid = best * g;
    return PaymentPlan(
      priceKurus: priceKurus,
      pay: pay,
      change: makeChange(paid - priceKurus, values: changeValues),
    );
  }

  /// Para üstünü küpürlere böler. Türk lirası küpürlerinde açgözlü (greedy)
  /// yöntem en az sayıda parayı verir: her adımda sığan en büyük para seçilir.
  /// 5 kuruştan küçük artan kısım (küpürle verilemeyen) yok sayılır.
  static Map<int, int> makeChange(int amountKurus, {List<int>? values}) {
    final sorted = [...(values ?? kAllValues)]..sort((a, b) => b.compareTo(a));
    final result = <int, int>{};
    var remaining = amountKurus;
    for (final v in sorted) {
      if (remaining <= 0) break;
      final count = remaining ~/ v;
      if (count > 0) {
        result[v] = count;
        remaining -= count * v;
      }
    }
    return result;
  }

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
}
