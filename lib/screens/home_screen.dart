import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../utils/theme.dart';
import '../utils/transitions.dart';
import '../widgets/kid_scaffold.dart';
import '../widgets/mascot.dart';
import '../widgets/pin_dialog.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'parent_screen.dart';
import 'practice_screen.dart';
import 'shop_screen.dart';
import 'wallet_screen.dart';

/// Ana menü: maskot karşılar, büyük renkli butonlarla ekran seçilir.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _greeting = 'Merhaba! Ne yapmak istersin?';

  @override
  void initState() {
    super.initState();
    speakAfterFirstFrame(this, _greeting);
  }

  void _open(String label, Widget page) {
    final app = context.read<AppState>();
    app.playTap();
    app.say(label);
    Navigator.of(context).push(fadeScaleRoute(page)).then((_) {
      // Ana sayfaya dönünce kısa bir karşılama.
      if (mounted) app.say('Ne yapmak istersin?');
    });
  }

  Future<void> _openParentPanel() async {
    final app = context.read<AppState>();
    final ok = await showPinDialog(context, app.pin);
    if (ok && mounted) {
      Navigator.of(context).push(slideUpRoute(const ParentScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
          child: Column(
            children: [
              // Başlık: iki renkli "Konuşan / Cüzdan"
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konuşan',
                          style: rounded(
                            size: 44,
                            weight: FontWeight.w800,
                            color: AppColors.orange,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'Cüzdan',
                          style: rounded(
                            size: 44,
                            weight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SpeakButton(text: _greeting),
                  IconButton(
                    tooltip: 'Eğitmen paneli',
                    iconSize: 26,
                    color: Colors.black26,
                    icon: const Icon(Icons.lock_rounded),
                    onPressed: _openParentPanel,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: WalletTotalChip(big: true),
              ),
              const SizedBox(height: 6),
              const MascotBubble(
                pose: MascotPose.wave,
                text: 'Merhaba!\nNe yapmak istersin?',
                speech: _greeting,
                size: 120,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _HomeTile(
                            icon: 'ikon_cuzdan',
                            label: 'Cüzdanım',
                            color: AppColors.wallets,
                            onTap: () =>
                                _open('Cüzdanım', const WalletScreen()),
                          ),
                          const SizedBox(width: 14),
                          _HomeTile(
                            icon: 'ikon_alisveris',
                            label: 'Alışveriş',
                            color: AppColors.shop,
                            onTap: () => _open('Alışveriş', const ShopScreen()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Row(
                        children: [
                          _HomeTile(
                            icon: 'ikon_oyun',
                            label: 'Oyun',
                            color: AppColors.game,
                            onTap: () => _open('Oyun', const PracticeScreen()),
                          ),
                          const SizedBox(width: 14),
                          _HomeTile(
                            icon: 'ikon_gecmis',
                            label: 'Geçmiş',
                            color: AppColors.history,
                            onTap: () => _open('Geçmiş', const HistoryScreen()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _HelpButton(
                onTap: () => _open('Nasıl kullanılır', const HelpScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Beyaz yuvarlak içinde ikon + yazı bulunan renkli büyük buton.
class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(26),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/$icon.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  child: Text(
                    label,
                    style: rounded(
                      size: 26,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.yellow,
      borderRadius: BorderRadius.circular(26),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '?',
                  style: rounded(
                    size: 30,
                    weight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Nasıl Kullanılır?',
                style: rounded(size: 26, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
