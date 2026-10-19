/// Kayıtlı insan sesinden cümle kurar.
///
/// Gönüllünün okuduğu her kayıt bir "anahtar" ile adlandırılır
/// (ör. `cuzdaninda` → assets/voice/cuzdaninda.mp3). Uygulamanın söylemek
/// istediği metin, bu kayıtların art arda dizilmesiyle kurulur:
///
///   "Cüzdanında 35 lira var."
///   → cuzdaninda + sayi_30 + sayi_5 + lira + var
///
/// Metnin bir parçası bile kayıtlarla karşılanamazsa (ör. eğitmenin sonradan
/// eklediği bir ürün adı) [compose] null döner ve cümlenin tamamı bilgisayar
/// sesiyle okunur. Böylece tek cümlede iki farklı ses karışmaz.
///
/// Kayıt listesi (gönüllünün okuyacağı metin): tasarim/ses_kayit_listesi.md
class AudioPhraseService {
  const AudioPhraseService();

  /// Anahtar → kaydedilecek metin.
  ///
  /// Sabit yönergeler tek parça kaydedilir (doğal tonlama için); tutarlı
  /// cümleler ise küçük parçalardan birleştirilir.
  static const Map<String, String> phrases = {
    // ---- Ana sayfa ----
    'selam_ne_yapmak': 'Merhaba! Ne yapmak istersin?',
    'ne_yapmak': 'Ne yapmak istersin?',
    'menu_cuzdanim': 'Cüzdanım',
    'menu_alisveris': 'Alışveriş',
    'menu_oyun': 'Oyun',
    'menu_gecmis': 'Geçmiş',

    // ---- Cüzdanım ----
    'cuzdan_yonerge':
        'Aşağıdaki paraya dokun, cüzdanına ekle. '
        'Çıkarmak için cüzdandaki paraya dokun.',
    'cuzdaninda': 'Cüzdanında',
    'var': 'var.',
    'ekledin': 'ekledin.',
    'cikardin': 'çıkardın.',

    // ---- Alışveriş ----
    'alisveris_yonerge': 'Ne almak istersin? Bir ürüne dokun.',
    'fiyati_yaz': 'Fiyatı yaz.',

    // ---- Ödeme ----
    'kasaya_ver': 'Parlayan paraları kasaya ver.',
    'tam': 'Tam',
    'vereceksin': 'vereceksin.',
    'para_ustu_verilecek': 'Sana para üstü verilecek.',
    'paran_yetmiyor': 'Paran yetmiyor.',
    'daha_lazim': 'daha lazım.',
    'yanlis_para': 'Bu parayı değil. Parlayan parayı ver.',
    'guzel': 'Güzel!',
    'odeme_tamam': 'Aferin! Ödemeyi yaptın.',

    // ---- Para üstü ----
    'tam_para': 'Aferin! Tam para verdin. Para üstü yok.',
    'aferin_para_ustun': 'Aferin! Para üstün',
    'cuzdanina_koydum': 'Cüzdanına koydum.',

    // ---- Oyun ----
    'hangi_para': 'Hangi parayı verirsin?',
    'oyun_dogru': 'Doğru! Aferin!',
    'oyun_yildiz': 'Harika! Bir yıldız kazandın!',
    'oyun_yetmez': 'Bu para yetmez. Daha büyük bir para seç.',
    'oyun_daha_kucuk':
        'Bu para da yeter. Ama daha küçük bir parayla ödeyebilirsin.',

    // ---- Geçmiş ----
    'gecmis_yonerge': 'Burada aldığın şeyler var. Dinlemek için birine dokun.',
    'gecmis_bos': 'Henüz alışveriş yapmadın!',
    'aldin': 'aldın.',
    'verdin': 'verdin.',
    'para_ustu': 'Para üstü',
    'para_ustu_yoktu': 'Para üstü yoktu.',

    // ---- Nasıl oynanır? ----
    'yardim_yonerge': 'Bir resme dokun, sana anlatayım.',
    'yardim_cuzdan': 'Önce cüzdanına para koy. Paraya dokunman yeterli.',
    'yardim_alisveris': 'Alışverişte almak istediğin ürüne dokun.',
    'yardim_para_ustu': 'Para üstünü al. Cüzdanına kendiliğinden girer.',
    'yardim_oyun': 'Oyunda doğru parayı bul, yıldız kazan!',

    // ---- Eğitmen paneli (ses denemesi) ----
    'panel_tanitim':
        'Merhaba! Ben Konuşan Cüzdan. Hadi birlikte alışveriş yapalım!',

    // ---- Hazır ürünler ----
    'urun_elma': 'Elma',
    'urun_su': 'Su',
    'urun_ekmek': 'Ekmek',
    'urun_meyve_suyu': 'Meyve Suyu',
    'urun_defter': 'Defter',
    'urun_sut': 'Süt',
    'urun_muz': 'Muz',
    'urun_oyuncak': 'Oyuncak',
    'urun_simit': 'Simit',
    'urun_dondurma': 'Dondurma',

    // ---- Tutarlar ----
    'lira': 'lira',
    'kurus': 'kuruş',
    'sayi_0': 'sıfır',
    ..._numberPhrases,
  };

  /// Sayı kayıtları: 1–20, onlar (30–90), yüzler (100–900) ve "bin".
  static const Map<String, String> _numberPhrases = {
    'sayi_1': 'bir',
    'sayi_2': 'iki',
    'sayi_3': 'üç',
    'sayi_4': 'dört',
    'sayi_5': 'beş',
    'sayi_6': 'altı',
    'sayi_7': 'yedi',
    'sayi_8': 'sekiz',
    'sayi_9': 'dokuz',
    'sayi_10': 'on',
    'sayi_11': 'on bir',
    'sayi_12': 'on iki',
    'sayi_13': 'on üç',
    'sayi_14': 'on dört',
    'sayi_15': 'on beş',
    'sayi_16': 'on altı',
    'sayi_17': 'on yedi',
    'sayi_18': 'on sekiz',
    'sayi_19': 'on dokuz',
    'sayi_20': 'yirmi',
    'sayi_30': 'otuz',
    'sayi_40': 'kırk',
    'sayi_50': 'elli',
    'sayi_60': 'altmış',
    'sayi_70': 'yetmiş',
    'sayi_80': 'seksen',
    'sayi_90': 'doksan',
    'sayi_100': 'yüz',
    'sayi_200': 'iki yüz',
    'sayi_300': 'üç yüz',
    'sayi_400': 'dört yüz',
    'sayi_500': 'beş yüz',
    'sayi_600': 'altı yüz',
    'sayi_700': 'yedi yüz',
    'sayi_800': 'sekiz yüz',
    'sayi_900': 'dokuz yüz',
    'sayi_1000': 'bin',
  };

  /// Sayıyı kayıt anahtarlarına böler. 35 → [sayi_30, sayi_5],
  /// 2500 → [sayi_2, sayi_1000, sayi_500]. Bir milyon ve üstü için null.
  static List<String>? numberKeys(int n) {
    if (n < 0 || n >= 1000000) return null;
    if (n == 0) return const ['sayi_0'];
    final thousands = n ~/ 1000;
    return [
      // Türkçede "bir bin" denmez, sadece "bin".
      if (thousands > 1) ..._under1000(thousands),
      if (thousands > 0) 'sayi_1000',
      ..._under1000(n % 1000),
    ];
  }

  static List<String> _under1000(int n) {
    final hundreds = n ~/ 100 * 100;
    final rest = n % 100;
    return [
      if (hundreds > 0) 'sayi_$hundreds',
      if (rest > 0 && rest <= 20) 'sayi_$rest',
      if (rest > 20) 'sayi_${rest ~/ 10 * 10}',
      if (rest > 20 && rest % 10 > 0) 'sayi_${rest % 10}',
    ];
  }

  /// Metni kayıt anahtarlarına çevirir. Karşılanamayan bir parça varsa null.
  ///
  /// Büyük/küçük harf ve noktalama dikkate alınmaz. Rakamlar sayı
  /// kayıtlarına bölünür; geri kalan kelimeler [phrases] içindeki en uzun
  /// eşleşmeden başlanarak aranır.
  List<String>? compose(String text) {
    final words = _words(text);
    if (words.isEmpty) return null;
    return _match(words, 0, {});
  }

  /// Her kaydın kelimeleri; en uzun ifade önce denensin diye sıralı.
  static final List<(String, List<String>)> _phraseWords = [
    for (final e in phrases.entries) (e.key, _words(e.value)),
  ]..sort((a, b) => b.$2.length.compareTo(a.$2.length));

  List<String>? _match(
    List<String> words,
    int start,
    Map<int, List<String>?> memo,
  ) {
    if (start == words.length) return const [];
    if (memo.containsKey(start)) return memo[start];
    List<String>? result;

    final number = int.tryParse(words[start]);
    if (number != null) {
      final keys = numberKeys(number);
      final rest = keys == null ? null : _match(words, start + 1, memo);
      if (keys != null && rest != null) result = [...keys, ...rest];
    } else {
      for (final (key, phrase) in _phraseWords) {
        if (!_startsWith(words, start, phrase)) continue;
        final rest = _match(words, start + phrase.length, memo);
        if (rest != null) {
          result = [key, ...rest];
          break;
        }
      }
    }
    memo[start] = result;
    return result;
  }

  static bool _startsWith(List<String> words, int start, List<String> phrase) {
    if (start + phrase.length > words.length) return false;
    for (var i = 0; i < phrase.length; i++) {
      if (words[start + i] != phrase[i]) return false;
    }
    return true;
  }

  /// Küçük harfe çevirip (Türkçe İ/I kuralıyla) kelimelere ayırır.
  static List<String> _words(String text) {
    final lower = text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    return RegExp(r'[0-9]+|[a-zçğıöşü]+')
        .allMatches(lower)
        .map((m) => m.group(0)!)
        .toList();
  }
}
