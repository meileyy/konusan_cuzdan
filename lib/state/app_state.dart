import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../models/denomination.dart';
import '../models/product.dart';
import '../services/payment_calculator.dart';
import '../services/sound_service.dart';
import '../services/speech_service.dart';
import '../services/voice_guide.dart';

/// Uygulamanın ortak durumu (Provider ile bütün ekranlara dağıtılır).
///
/// Cüzdan, ürünler ve ayarlar burada tutulur; her değişiklik hem ekranı
/// günceller (notifyListeners) hem de veritabanına yazılır.
class AppState extends ChangeNotifier {
  AppState({
    DatabaseHelper? db,
    SpeechService? speech,
    SoundService? sound,
    VoiceGuide? voice,
  }) : db = db ?? DatabaseHelper.instance,
       speech = speech ?? SpeechService(),
       sound = sound ?? SoundService() {
    this.voice = voice ?? VoiceGuide(this.speech);
  }

  final DatabaseHelper db;
  final SpeechService speech;
  final SoundService sound;

  /// Kayıtlı insan sesi varsa onu, yoksa [speech] (TTS) kullanır.
  late final VoiceGuide voice;

  Map<int, int> _wallet = {};
  List<Product> _products = [];
  Map<String, String> _settings = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  Future<void> load() async {
    _wallet = await db.getWallet();
    _products = await db.getProducts();
    _settings = await db.getSettings();
    await speech.init(rate: speechRate, pitch: speechPitch);
    await sound.init();
    sound.enabled = soundOn;
    await voice.init();
    voice.useRecordings = useRecordedVoice;
    _loaded = true;
    notifyListeners();
  }

  // ---------------- Ayarlar ----------------

  int get level => int.tryParse(_settings['level'] ?? '') ?? 1;
  String get pin => _settings['pin'] ?? '1234';
  double get speechRate =>
      double.tryParse(_settings['speech_rate'] ?? '') ?? 0.42;

  /// Ses tonu: 1.0 normal; biraz yüksek ton çocuklara daha sıcak gelir.
  double get speechPitch => double.tryParse(_settings['pitch'] ?? '') ?? 1.1;
  bool get soundOn => _settings['sound'] != '0';

  /// "Kayıtlı ses" (varsayılan) veya "Bilgisayar sesi" (tts).
  bool get useRecordedVoice => _settings['voice_source'] != 'tts';

  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
    if (key == 'speech_rate') await speech.setRate(speechRate);
    if (key == 'pitch') await speech.setPitch(speechPitch);
    if (key == 'sound') sound.enabled = soundOn;
    if (key == 'voice_source') voice.useRecordings = useRecordedVoice;
    notifyListeners();
    await db.setSetting(key, value);
  }

  /// Seçili seviyede kullanılabilen paralar.
  List<Denomination> get allowedDenominations =>
      kDenominations.where((d) => d.level <= level).toList();

  // ---------------- Cüzdan ----------------

  Map<int, int> get wallet => Map.unmodifiable(_wallet);
  int get walletTotal => PaymentCalculator.total(_wallet);

  Future<void> addMoney(int valueKurus) async {
    final count = (_wallet[valueKurus] ?? 0) + 1;
    _wallet[valueKurus] = count;
    notifyListeners();
    await db.setWalletCount(valueKurus, count);
  }

  Future<void> removeMoney(int valueKurus) async {
    final count = (_wallet[valueKurus] ?? 0) - 1;
    if (count <= 0) {
      _wallet.remove(valueKurus);
    } else {
      _wallet[valueKurus] = count;
    }
    notifyListeners();
    await db.setWalletCount(valueKurus, count);
  }

  Future<void> clearWallet() async {
    _wallet = {};
    notifyListeners();
    await db.clearWallet();
  }

  /// Ödemeyi veritabanına kaydeder ve cüzdanı günceller.
  Future<void> completePurchase({
    required String productName,
    required String productEmoji,
    required PaymentPlan plan,
  }) async {
    await db.savePurchase(
      productName: productName,
      productEmoji: productEmoji,
      plan: plan,
    );
    _wallet = await db.getWallet();
    notifyListeners();
  }

  // ---------------- Ürünler ----------------

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get visibleProducts =>
      _products.where((p) => p.level <= level).toList();

  Future<void> addProduct(Product product) async {
    await db.insertProduct(product);
    _products = await db.getProducts();
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await db.deleteProduct(id);
    _products = await db.getProducts();
    notifyListeners();
  }

  // ---------------- Ses ----------------

  Future<void> say(String text) => voice.speak(text);

  /// Eğitmen panelinde hız/ton/ses denemesi: her zaman bilgisayar sesi.
  Future<void> sayWithComputer(String text) => voice.speakWithComputer(text);
  Future<void> stopSpeaking() => voice.stop();
  void playTap() => sound.play(Sfx.tap);
  void playCoin() => sound.play(Sfx.coin);
  void playSuccess() => sound.play(Sfx.success);
  void playTryAgain() => sound.play(Sfx.tryAgain);

  @override
  void dispose() {
    voice.dispose();
    sound.dispose();
    super.dispose();
  }
}
