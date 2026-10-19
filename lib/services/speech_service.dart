import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Cihazdaki bir Türkçe ses.
class TtsVoice {
  const TtsVoice(this.name, this.locale);

  final String name;
  final String locale;

  /// İnternetli (sinir ağı tabanlı) sesler daha doğal ve samimi duyulur.
  bool get isNetwork => name.contains('network');

  Map<String, String> toMap() => {'name': name, 'locale': locale};
}

/// Türkçe sesli yönlendirme (Text-to-Speech).
///
/// Uygulamanın sesi sabittir: Google'ın "cfs" Türkçe sesi (kullanıcı
/// testlerinde çocuklar için en sıcak ve doğal bulunan ses). Bu sesin
/// internetli (daha doğal) sürümü kullanılır; internet yoksa veya hata
/// verirse aynı konuşmacının cihazdaki sürümüne geçilir, ses karakteri
/// değişmez. Yönergeler kısa tutulur; yeni cümle eskisini susturur.
class SpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool enabled = true;

  static const _preferredVoice = 'tr-tr-x-cfs-network';
  static const _offlineVoice = 'tr-tr-x-cfs-local';

  /// Cihazdaki Türkçe sesler.
  List<TtsVoice> _voices = [];

  /// Şu an kullanılan ses.
  TtsVoice? currentVoice;

  /// Cihazda Türkçe ses bulundu mu? Bulunmazsa telefon Türkçe metni
  /// İngilizce sesle okur; eğitmen paneli bu durumda uyarı gösterir.
  bool get turkishVoiceFound => _voices.isNotEmpty;

  String? _lastText;
  bool _retried = false;

  Future<void> init({double rate = 0.42, double pitch = 1.1}) async {
    try {
      await _tts.setLanguage('tr-TR');
      await _loadTurkishVoices();
      await _useVoice(_pickVoice());
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      await _tts.setVolume(1.0);
      _tts.setErrorHandler(_onError);
      _ready = true;
    } catch (e) {
      debugPrint('TTS başlatılamadı: $e');
      _ready = false;
    }
  }

  Future<void> _loadTurkishVoices() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;
    _voices = voices
        .whereType<Map>()
        .where((v) => '${v['locale']}'.toLowerCase().startsWith('tr'))
        .map((v) => TtsVoice('${v['name']}', '${v['locale']}'))
        .toList();
    debugPrint('Türkçe TTS sesleri: ${_voices.map((v) => v.name)}');
  }

  TtsVoice? _find(String name) {
    for (final v in _voices) {
      if (v.name == name) return v;
    }
    return null;
  }

  /// Önce sabit sesin internetli sürümü, sonra cihazdaki sürümü; ikisi de
  /// yoksa (başka marka telefon) cihazdaki herhangi bir Türkçe ses.
  TtsVoice? _pickVoice() {
    if (_voices.isEmpty) return null;
    return _find(_preferredVoice) ??
        _find(_offlineVoice) ??
        _voices.firstWhere((v) => v.isNetwork, orElse: () => _voices.first);
  }

  Future<void> _useVoice(TtsVoice? voice) async {
    if (voice == null) return;
    await _tts.setVoice(voice.toMap());
    currentVoice = voice;
  }

  /// İnternetli ses çalışmazsa (ör. internet yok) aynı konuşmacının
  /// cihazdaki sürümüne geçip son cümleyi bir kez daha söyler.
  Future<void> _onError(dynamic message) async {
    debugPrint('TTS hatası: $message');
    final voice = currentVoice;
    if (voice == null || !voice.isNetwork || _retried) return;
    final offline =
        _find(_offlineVoice) ?? _voices.where((v) => !v.isNetwork).firstOrNull;
    if (offline == null) return;
    _retried = true;
    await _useVoice(offline);
    final text = _lastText;
    if (text != null) await _tts.speak(text);
  }

  Future<void> setRate(double rate) async {
    if (!_ready) return;
    try {
      await _tts.setSpeechRate(rate);
    } catch (_) {}
  }

  Future<void> setPitch(double pitch) async {
    if (!_ready) return;
    try {
      await _tts.setPitch(pitch);
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (!_ready || !enabled) return;
    _lastText = text;
    try {
      // Android'de varsayılan kuyruk modu "flush" olduğu için yeni cümle
      // eskisini zaten keser; ayrıca stop() çağırmaya gerek yok.
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS hatası: $e');
    }
  }

  Future<void> stop() async {
    if (!_ready) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
