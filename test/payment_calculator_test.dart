import 'package:flutter_test/flutter_test.dart';
import 'package:konusan_cuzdan/services/money_formatter.dart';
import 'package:konusan_cuzdan/services/payment_calculator.dart';

void main() {
  test('Tam para varsa para üstü olmaz', () {
    final plan = PaymentCalculator.planPayment({2000: 1, 1000: 1}, 1000)!;
    expect(plan.pay, {1000: 1});
    expect(plan.isExact, isTrue);
  });

  test('En az fazla ödeme seçilir', () {
    final plan = PaymentCalculator.planPayment({5000: 1, 2000: 2}, 1500)!;
    expect(plan.paidKurus, 2000);
    expect(plan.change, {500: 1});
  });

  test('Para yetmezse null döner', () {
    expect(PaymentCalculator.planPayment({500: 1}, 1000), isNull);
  });

  test('Tutar biçimlendirme', () {
    expect(formatMoney(1750), '17,50 TL');
    expect(speakMoney(1750), '17 lira 50 kuruş');
  });

  test('Tutar biçimlendirmede binlik ayraç', () {
    expect(formatMoney(4000000), '40.000 TL');
    expect(formatMoney(3803375), '38.033,75 TL');
    expect(formatMoney(100000), '1.000 TL');
    expect(formatMoney(99900), '999 TL');
    expect(formatMoney(100000000), '1.000.000 TL');
    expect(formatMoney(1500), '15 TL');
    expect(formatMoney(5), '0,05 TL');
    // Sesli okuma değişmez.
    expect(speakMoney(4000000), '40000 lira');
  });
}
