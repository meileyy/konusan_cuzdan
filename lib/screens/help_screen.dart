import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../state/app_state.dart';
import '../utils/theme.dart';
import '../widgets/kid_scaffold.dart';
import '../widgets/mascot.dart';

/// Nasıl kullanılır: tanıtım videosu ve dokununca okunan adım kartları.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  /// Bu dosyayı ekleyince video otomatik görünür (düşük çözünürlüklü, kısa).
  static const _videoAsset = 'assets/video/tanitim.mp4';
  static const _instruction = 'Bir resme dokun, sana anlatayım.';

  /// (resim, açıklama, kart rengi) — resimler Canva tasarımından.
  static const _steps = [
    (
      'ikon_cuzdan',
      'Önce cüzdanına para koy. Paraya dokunman yeterli.',
      AppColors.success,
    ),
    (
      'ikon_alisveris',
      'Alışverişte almak istediğin ürüne dokun.',
      AppColors.primary,
    ),
    ('kasa', 'Parlayan paraları kasaya ver.', AppColors.orange),
    (
      'maskot_tebrik',
      'Para üstünü al. Cüzdanına kendiliğinden girer.',
      AppColors.coral,
    ),
    ('ikon_oyun', 'Oyunda doğru parayı bul, yıldız kazan!', AppColors.game),
  ];

  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _loadVideo();
    speakAfterFirstFrame(this, _instruction);
  }

  Future<void> _loadVideo() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!manifest.listAssets().contains(_videoAsset)) return;
      final controller = VideoPlayerController.asset(_videoAsset);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(() => setState(() {}));
      setState(() => _video = controller);
    } catch (e) {
      debugPrint('Video yüklenemedi: $e');
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final v = _video!;
    context.read<AppState>().stopSpeaking();
    v.value.isPlaying ? v.pause() : v.play();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return KidScaffold(
      title: 'Nasıl\nKullanılır?',
      titleSize: 32,
      instruction: _instruction,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const MascotBubble(
            pose: MascotPose.wave,
            size: 90,
            text: 'Sana anlatayım!\nBir resme dokun.',
            speech: _instruction,
          ),
          const SizedBox(height: 12),
          if (video != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: video.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(video),
                    IconButton.filled(
                      iconSize: 56,
                      onPressed: _togglePlay,
                      icon: Icon(
                        video.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (final (i, step) in _steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: step.$3.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.read<AppState>().say(step.$2),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: step.$3,
                          child: Text(
                            '${i + 1}',
                            style: rounded(
                              size: 24,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Image.asset(
                          'assets/images/${step.$1}.png',
                          width: 64,
                          height: 64,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.$2,
                            style: rounded(
                              size: 21,
                              weight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
