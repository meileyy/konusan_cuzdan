import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/denomination.dart';
import '../services/money_formatter.dart';
import '../services/payment_calculator.dart';
import '../state/app_state.dart';
import '../utils/theme.dart';
import '../utils/transitions.dart';
import '../widgets/kid_scaffold.dart';
import '../widgets/mascot.dart';
import '../widgets/money_view.dart';
import '../widgets/product_image.dart';
import 'shop_screen.dart';

/// Para üstü: kasiyerden alınacak paralar sırayla ekrana gelir, konfeti patlar.
class ChangeScreen extends StatefulWidget {
  const ChangeScreen({
    super.key,
    required this.plan,
    required this.productName,
    required this.productEmoji,
    required this.heroTag,
  });

  final PaymentPlan plan;
  final String productName;
  final String productEmoji;
  final String heroTag;

  @override
  State<ChangeScreen> createState() => _ChangeScreenState();
}

class _ChangeScreenState extends State<ChangeScreen> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  String get _message {
    final plan = widget.plan;
    if (plan.isExact) {
      return 'Aferin! Tam para verdin. Para üstü yok.';
    }
    return 'Aferin! Para üstün ${speakMoney(plan.changeKurus)}. '
        'Cüzdanına koydum.';
  }

  @override
  void initState() {
    super.initState();
    _confetti.play();
    speakAfterFirstFrame(this, _message);
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _newPurchase() {
    context.read<AppState>().playTap();
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.push(fadeScaleRoute(const ShopScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final changePieces = PaymentCalculator.expand(plan.change);
    return KidScaffold(
      title: 'Aferin!',
      titleColor: AppColors.orange,
      instruction: _message,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Hero(
                      tag: widget.heroTag,
                      child: ProductImage(emoji: widget.productEmoji, size: 70),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.productName} senin!',
                        style: rounded(size: 28, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Row(
                  label: 'Verdiğin:',
                  value: formatMoney(plan.paidKurus),
                  color: AppColors.orange,
                  background: const Color(0xFFFFF6E5),
                  border: const Color(0xFFF7D9A6),
                ),
                const SizedBox(height: 10),
                if (plan.isExact)
                  _Row(
                    label: 'Para üstü yok',
                    value: '✅',
                    color: AppColors.success,
                    background: const Color(0xFFE8F7EC),
                    border: const Color(0xFFB9E4C4),
                  )
                else ...[
                  _Row(
                    label: 'Para üstün:',
                    value: formatMoney(plan.changeKurus),
                    color: AppColors.primary,
                    background: const Color(0xFFE6F1FD),
                    border: const Color(0xFFB5D4F4),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (var i = 0; i < changePieces.length; i++)
                        _StaggeredPop(
                          index: i,
                          child: MoneyView(
                            denomination: denominationOf(changePieces[i]),
                            width: 120,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                MascotBubble(
                  pose: MascotPose.cheer,
                  size: 120,
                  text: plan.isExact
                      ? 'Harika bir\niş çıkardın!'
                      : 'Para üstün\ncüzdanında!',
                  speech: _message,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _newPurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                        ),
                        icon: const Icon(Icons.shopping_cart_rounded, size: 30),
                        label: const FittedBox(child: Text('Yeni alışveriş')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => goHome(context),
                        icon: const Icon(Icons.home_rounded, size: 30),
                        label: const FittedBox(child: Text('Ana sayfa')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Verdiğin: 20 TL" gibi renkli, kenarlıklı bilgi satırı.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
    required this.border,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: rounded(size: 28, weight: FontWeight.w800)),
          const SizedBox(width: 14),
          Text(
            value,
            style: rounded(size: 36, weight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

/// Para üstü paralarını sırayla (biri bitince diğeri) büyüterek gösterir.
class _StaggeredPop extends StatefulWidget {
  const _StaggeredPop({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredPop> createState() => _StaggeredPopState();
}

class _StaggeredPopState extends State<_StaggeredPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 500 + widget.index * 400), () {
      if (!mounted) return;
      context.read<AppState>().playCoin();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: _controller, child: widget.child),
    );
  }
}
