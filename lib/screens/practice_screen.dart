import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/denomination.dart';
import '../services/money_formatter.dart';
import '../state/app_state.dart';
import '../utils/theme.dart';
import '../widgets/kid_scaffold.dart';
import '../widgets/mascot.dart';
import '../widgets/money_view.dart';
import '../widgets/product_image.dart';

/// Oyun modu: "Bu ürünü almak için hangi parayı verirsin?"
///
/// Doğru cevap, fiyatı karşılayan en küçük paradır. Sonuçlar veritabanına
/// yazılır ve eğitmen panelinde ilerleme olarak görünür.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _Question {
  _Question({
    required this.emoji,
    required this.name,
    required this.priceKurus,
    required this.options,
    required this.correct,
  });

  final String emoji;
  final String name;
  final int priceKurus;
  final List<Denomination> options;
  final int correct;
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _rng = Random();
  final _confetti = ConfettiController(duration: const Duration(seconds: 1));
  late _Question _q;
  int _stars = 0;
  bool _wrongOnce = false;
  bool _locked = false;
  int? _wrongValue;

  @override
  void initState() {
    super.initState();
    _q = _makeQuestion();
    speakAfterFirstFrame(this, _questionText);
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String get _questionText =>
      '${_q.name}. ${speakMoney(_q.priceKurus)}. Hangi parayı verirsin?';

  _Question _makeQuestion() {
    final app = context.read<AppState>();
    final allowed = app.allowedDenominations;
    final maxValue = allowed.map((d) => d.valueKurus).reduce(max);
    final candidates = app.visibleProducts
        .where((p) => p.priceKurus <= maxValue)
        .toList();

    String emoji = '🛍️', name = 'Alışveriş';
    int price;
    if (candidates.isNotEmpty) {
      final p = candidates[_rng.nextInt(candidates.length)];
      emoji = p.emoji;
      name = p.name;
      price = p.priceKurus;
    } else {
      price = (1 + _rng.nextInt(maxValue ~/ 100)) * 100;
    }

    // Fiyatı karşılayan en küçük para = doğru cevap.
    final sortedAsc = [...allowed]
      ..sort((a, b) => a.valueKurus.compareTo(b.valueKurus));
    final best = sortedAsc.firstWhere((d) => d.valueKurus >= price);
    final smaller = sortedAsc.where((d) => d.valueKurus < price).toList()
      ..shuffle(_rng);
    final larger =
        sortedAsc.where((d) => d.valueKurus > best.valueKurus).toList()
          ..shuffle(_rng);

    // Seçenekler: doğru cevap + mümkünse yetmeyen 2 para, yoksa daha büyükler.
    final options = <Denomination>[best, ...smaller.take(2)];
    for (final d in larger) {
      if (options.length >= 3) break;
      options.add(d);
    }
    options.shuffle(_rng);

    return _Question(
      emoji: emoji,
      name: name,
      priceKurus: price,
      options: options,
      correct: best.valueKurus,
    );
  }

  Future<void> _answer(Denomination d) async {
    if (_locked) return;
    final app = context.read<AppState>();

    if (d.valueKurus == _q.correct) {
      setState(() {
        _locked = true;
        _wrongValue = null;
        if (!_wrongOnce) _stars++;
      });
      _confetti.play();
      app.playSuccess();
      app.say(_wrongOnce ? 'Doğru! Aferin!' : 'Harika! Bir yıldız kazandın!');
      await app.db.addProgress(
        level: app.level,
        priceKurus: _q.priceKurus,
        correct: !_wrongOnce,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      setState(() {
        _q = _makeQuestion();
        _wrongOnce = false;
        _locked = false;
      });
      app.say(_questionText);
      return;
    }

    setState(() {
      _wrongOnce = true;
      _wrongValue = d.valueKurus;
    });
    app.playTryAgain();
    if (d.valueKurus < _q.priceKurus) {
      app.say('Bu para yetmez. Daha büyük bir para seç.');
    } else {
      app.say('Bu para da yeter. Ama daha küçük bir parayla ödeyebilirsin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      title: 'Oyun',
      titleColor: AppColors.game,
      instruction: _questionText,
      headerExtra: _StarCounter(stars: _stars),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Soru: ürün kartı
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Container(
                      key: ValueKey('${_q.name}-${_q.priceKurus}-$_stars'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProductImage(emoji: _q.emoji, size: 110),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Column(
                              children: [
                                Text(
                                  _q.name,
                                  style: rounded(
                                    size: 28,
                                    weight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  formatMoney(_q.priceKurus),
                                  style: rounded(
                                    size: 46,
                                    weight: FontWeight.w800,
                                    color: AppColors.orange,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  MascotBubble(
                    pose: MascotPose.point,
                    size: 80,
                    text: 'Hangi parayı\nverirsin?',
                    speech: _questionText,
                  ),
                  const SizedBox(height: 14),
                  // Cevaplar
                  Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final d in _q.options)
                        GestureDetector(
                          onTap: () => _answer(d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _locked && d.valueKurus == _q.correct
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : _wrongValue == d.valueKurus
                                  ? AppColors.coral.withValues(alpha: 0.12)
                                  : AppColors.paletteBg,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                width: 5,
                                color: _locked && d.valueKurus == _q.correct
                                    ? AppColors.success
                                    : _wrongValue == d.valueKurus
                                    ? AppColors.coral
                                    : Colors.transparent,
                              ),
                            ),
                            child: MoneyView(denomination: d, width: 160),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 20,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Başlığın yanındaki sarı yıldız sayacı. Yıldız artınca zıplar.
class _StarCounter extends StatelessWidget {
  const _StarCounter({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(stars),
      tween: Tween(begin: 1.4, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Text(
          '⭐ $stars',
          style: rounded(size: 26, weight: FontWeight.w800, height: 1.4),
        ),
      ),
    );
  }
}
