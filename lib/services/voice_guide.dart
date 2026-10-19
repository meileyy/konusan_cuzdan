import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_phrase_service.dart';
import 'speech_service.dart';

/// Sesli yönlendirmenin tek giriş kapısı.
///
/// Bir cümlenin bütün parçaları `assets/voice/<anahtar>.mp3` olarak kayıtlıysa
/// gönüllünün gerçek sesi çalınır; değilse (veya eğitmen "Bilgisayar sesi"ni
/// seçtiyse) cümle [SpeechService] ile cihazın metin okuma motoruna okutulur.
/// Kayıt dosyaları eklenince kod değişmeden kendiliğinden kullanılır.
class VoiceGuide {
  VoiceGuide(this.speech);

  final SpeechService speech;
  final AudioPhraseService _phrases = const AudioPhraseService();

  /// İlk kayıt çalınırken oluşturulur; kayıt yoksa hiç açılmaz.
  AudioPlayer? _player;

  /// Eğitmen panelindeki "Kayıtlı ses / Bilgisayar sesi" seçimi.
  bool useRecordings = true;

  /// Uygulamada bulunan kayıtların anahtarları.
  Set<String> _available = {};

  /// Her yeni cümlede artar; eski cümlenin kalan parçaları çalınmaz.
  int _generation = 0;

  /// Bulunan kayıt sayısı (eğitmen paneli gösterir).
  int get recordingCount =>
      _available.where(AudioPhraseService.phrases.containsKey).length;

  /// Kayıt listesindeki toplam cümle/parça sayısı.
  int get phraseCount => AudioPhraseService.phrases.length;

  static const _folder = 'assets/voice/';
  static const _extension = '.mp3';

  Future<void> init() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _available = {
        for (final path in manifest.listAssets())
          if (path.startsWith(_folder) && path.endsWith(_extension))
            path.substring(_folder.length, path.length - _extension.length),
      };
      debugPrint('Kayıtlı ses dosyası: ${_available.length}');
    } catch (e) {
      debugPrint('Kayıtlı sesler okunamadı: $e');
      _available = {};
    }
  }

  /// Cümleyi söyler: önce kayıtlı ses, olmazsa bilgisayar sesi.
  Future<void> speak(String text) async {
    if (!speech.enabled) return;
    final keys = useRecordings ? _recordedKeys(text) : null;
    if (keys == null) return speakWithComputer(text);

    final generation = ++_generation;
    await speech.stop();
    final played = await _playSequence(keys, generation);
    // Dosya bozuksa veya çalınamadıysa cümle yine de söylensin.
    if (!played && generation == _generation) await speech.speak(text);
  }

  /// Kayıtlı ses açık olsa bile bilgisayar sesiyle okur (eğitmen panelinde
  /// hız, ton ve ses denemesi için).
  Future<void> speakWithComputer(String text) async {
    ++_generation;
    await _stopPlayer();
    await speech.speak(text);
  }

  Future<void> stop() async {
    ++_generation;
    await _stopPlayer();
    await speech.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
  }

  List<String>? _recordedKeys(String text) {
    if (_available.isEmpty) return null;
    final keys = _phrases.compose(text);
    if (keys == null || !keys.every(_available.contains)) return null;
    return keys;
  }

  /// Parçaları art arda çalar. Hata olursa false döner.
  Future<bool> _playSequence(List<String> keys, int generation) async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      for (final key in keys) {
        if (generation != _generation) return true;
        // Bitiş olayını çalmadan önce dinle; kısa kayıtlarda kaçmasın.
        final done = player.onPlayerComplete.first;
        await player.play(AssetSource('voice/$key$_extension'));
        await done.timeout(const Duration(seconds: 15), onTimeout: () {});
      }
      return true;
    } catch (e) {
      debugPrint('Kayıtlı ses çalınamadı: $e');
      return false;
    }
  }

  Future<void> _stopPlayer() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
