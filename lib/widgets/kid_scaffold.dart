import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/money_formatter.dart';
import '../state/app_state.dart';
import '../utils/theme.dart';
import '../utils/transitions.dart';

/// Çocuk ekranlarının ortak iskeleti (Canva tasarımı).
///
/// Her ekranda aynı yerde: en üstte solda mavi "Geri", ortada turuncu
/// "Tekrar dinle" hoparlörü, sağda yeşil "Ana sayfa" butonu; altında büyük
/// renkli başlık. Tutarlı yerleşim, çocuğun kaybolmamasına yardım eder.
class KidScaffold extends StatelessWidget {
  const KidScaffold({
    super.key,
    required this.title,
    required this.body,
    this.instruction,
    this.showHome = true,
    this.showBack = true,
    this.titleColor = AppColors.text,
    this.titleSize = 40,
    this.headerExtra,
  });

  final String title;
  final Widget body;

  /// Hoparlör butonuna basınca tekrar okunacak yönerge.
  final String? instruction;
  final bool showHome;
  final bool showBack;
  final Color titleColor;
  final double titleSize;

  /// Başlığın yanında gösterilecek ek öğe (ör. küçük maskot).
  final Widget? headerExtra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst çubuk: Geri · Tekrar dinle · Ana sayfa
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBack)
                    RoundNavButton(
                      icon: Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      tooltip: 'Geri',
                      onTap: () => Navigator.of(context).maybePop(),
                    )
                  else
                    const SizedBox(width: 60),
                  const Spacer(),
                  if (instruction != null) SpeakButton(text: instruction!),
                  const Spacer(),
                  if (showHome)
                    RoundNavButton(
                      icon: Icons.home_rounded,
                      color: AppColors.success,
                      tooltip: 'Ana sayfa',
                      onTap: () => goHome(context),
                    )
                  else
                    const SizedBox(width: 60),
                ],
              ),
            ),
            // Başlık (çok uzunsa küçülmek yerine iki satıra iner)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 16, 4),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      style: rounded(
                        size: titleSize,
                        weight: FontWeight.w800,
                        color: titleColor,
                        height: 1.05,
                      ),
                    ),
                  ),
                  if (headerExtra != null) ...[
                    const SizedBox(width: 10),
                    headerExtra!,
                  ],
                ],
              ),
            ),
            Expanded(child: body),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Üst çubuktaki büyük yuvarlak gezinme butonu (beyaz halkalı).
class RoundNavButton extends StatelessWidget {
  const RoundNavButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.size = 60,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 4),
        ),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.55, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Dokununca verilen metni sesli okuyan turuncu hoparlör ("Tekrar dinle").
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tekrar dinle',
      child: GestureDetector(
        onTap: () => context.read<AppState>().say(text),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: AppColors.orange,
              shape: const CircleBorder(),
              elevation: 3,
              child: const SizedBox(
                width: 60,
                height: 60,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tekrar dinle',
              style: rounded(
                size: 13,
                weight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cüzdandaki toplam parayı gösteren rozet. Dokununca toplamı sesli söyler.
/// Ana sayfa ile cüzdan ekranı arasında Hero animasyonu ile uçar.
class WalletTotalChip extends StatelessWidget {
  const WalletTotalChip({super.key, this.big = false});

  final bool big;

  @override
  Widget build(BuildContext context) {
    final total = context.select<AppState, int>((s) => s.walletTotal);
    return Hero(
      tag: 'wallet-total',
      child: Material(
        color: Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.orange, width: big ? 4 : 3),
        ),
        elevation: 1,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.read<AppState>().say(
            'Cüzdanında ${speakMoney(total)} var.',
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: big ? 26 : 18,
              vertical: big ? 4 : 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👛', style: TextStyle(fontSize: big ? 32 : 24)),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    formatMoney(total),
                    key: ValueKey(total),
                    style: rounded(
                      size: big ? 36 : 26,
                      weight: FontWeight.w800,
                      color: AppColors.orange,
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

/// Ekran açıldıktan hemen sonra yönergeyi sesli okur.
void speakAfterFirstFrame(State state, String text) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (state.mounted) state.context.read<AppState>().say(text);
  });
}
