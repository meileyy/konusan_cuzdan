import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Uygulamadaki kısa ses efektleri.
enum Sfx {
  tap('tap.wav'),
  coin('coin.wav'),
  success('success.wav'),
  tryAgain('try_again.wav');

  const Sfx(this.file);
  final String file;
}

/// assets/sounds klasöründeki ses efektlerini çalar.
///
/// Her efekt için açılışta bir [AudioPool] hazırlanır. Havuz, Android'de
/// SoundPool (lowLatency) kullanır: ses bir kez belleğe yüklenir ve her
/// dokunuşta dosya yeniden açılmadan çalınır. Böylece çocuk paralara art arda
/// hızlıca dokunsa bile ana iş parçacığı (main thread) tıkanmaz.
class SoundService {
  bool enabled = true;
  final Map<Sfx, AudioPool> _pools = {};
  final Map<Sfx, DateTime> _lastPlayed = {};

  /// Aynı efekt bu süreden daha sık çalınmaz (çok hızlı dokunuşlarda).
  static const _minGap = Duration(milliseconds: 90);

  Future<void> init() async {
    try {
      // Efektler sesli anlatımı (TTS) susturmasın, birlikte çalsın.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );
    } catch (e) {
      debugPrint('Ses ayarı yapılamadı: $e');
    }
    for (final sfx in Sfx.values) {
      try {
        _pools[sfx] = await AudioPool.create(
          source: AssetSource('sounds/${sfx.file}'),
          maxPlayers: 3,
          playerMode: PlayerMode.lowLatency,
        );
      } catch (e) {
        debugPrint('Ses yüklenemedi (${sfx.file}): $e');
      }
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    final pool = _pools[sfx];
    if (pool == null) return;

    final now = DateTime.now();
    final last = _lastPlayed[sfx];
    if (last != null && now.difference(last) < _minGap) return;
    _lastPlayed[sfx] = now;

    try {
      await pool.start(volume: 1.0);
    } catch (e) {
      debugPrint('Ses çalınamadı: $e');
    }
  }

  Future<void> dispose() async {
    for (final pool in _pools.values) {
      await pool.dispose();
    }
    _pools.clear();
  }
}
