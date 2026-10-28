// Varsayılan "Counter" testi (MyApp) bu projede olmadığı için derlenmiyordu.
// Yerine sesli okuma ve fiyat girişi için saf Dart testleri kondu.
import 'package:flutter_test/flutter_test.dart';
import 'package:konusan_cuzdan/services/audio_phrase_service.dart';
import 'package:konusan_cuzdan/services/money_formatter.dart';

void main() {
  test('Sayılar ses kayıtlarına doğru bölünür', () {
    expect(AudioPhraseService.numberKeys(35), ['sayi_30', 'sayi_5']);
    expect(AudioPhraseService.numberKeys(1000), ['sayi_1000']);
    expect(AudioPhraseService.numberKeys(2500), [
      'sayi_2',
      'sayi_1000',
      'sayi_500',
    ]);
  });

  test('Fiyat girişi kuruşa çevrilir', () {
    expect(parseMoneyInput('15'), 1500);
    expect(parseMoneyInput('17,5'), 1750);
    expect(parseMoneyInput('17,50'), 1750);
    expect(parseMoneyInput('a'), isNull);
  });

  test('Fiyat girişinde nokta: binlik mi ondalık mı', () {
    // Virgül varsa virgül ondalık, noktalar binlik.
    expect(parseMoneyInput('10.000,50'), 1000050);
    expect(parseMoneyInput('1.000.000,05'), 100000005);
    // Virgül yok, noktadan sonra 3 rakam: binlik.
    expect(parseMoneyInput('10.000'), 1000000);
    expect(parseMoneyInput('1.500'), 150000);
    // Virgül yok, noktadan sonra 1–2 rakam: ondalık.
    expect(parseMoneyInput('17.50'), 1750);
    expect(parseMoneyInput('17.5'), 1750);
    // Geçersizler
    expect(parseMoneyInput('1.2.3'), isNull);
    expect(parseMoneyInput('10.00,50'), isNull);
    expect(parseMoneyInput('1,5,0'), isNull);
    expect(parseMoneyInput('17,505'), isNull);
    expect(parseMoneyInput('1234.567'), isNull);
    expect(parseMoneyInput('-5'), isNull);
    expect(parseMoneyInput(','), isNull);
    expect(parseMoneyInput('99999999999999999999999'), isNull);
  });
}
