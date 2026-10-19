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
import 'change_screen.dart';
import 'wallet_screen.dart';

/// Ödeme: uygulama hangi paraların verileceğini hesaplar ve o paraları
/// parlatır. Çocuk parlayan paraları kasaya dokunarak veya sürükleyerek verir.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.productName,
    required this.productEmoji,
    required this.priceKurus,
    required this.heroTag,
  });

  final String productName;
  final String productEmoji;
  final int priceKurus;
  final String heroTag;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

/// Cüzdandaki tek bir para.
class _Piece {
  _Piece(this.valueKurus, {required this.toGive});
  final int valueKurus;
  final bool toGive;
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentPlan? _plan;
  late final List<_Piece> _pieces;
  late final int _walletTotal;
  final List<int> _given = []; // kasaya verilen paraların sırası
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final wallet = app.wallet;
    _walletTotal = app.walletTotal;
    _plan = PaymentCalculator.planPayment(wallet, widget.priceKurus);

    // Cüzdandaki paraları tek tek aç; her küpürden plan kadarını "verilecek" işaretle.
    final pay = _plan?.pay ?? const <int, int>{};
    final values = wallet.keys.toList()..sort((a, b) => b.compareTo(a));
    _pieces = [
      for (final v in values)
        for (var i = 0; i < wallet[v]!; i++)
          _Piece(v, toGive: i < (pay[v] ?? 0)),
    ];

    speakAfterFirstFrame(this, _instruction);
  }

  String get _instruction {
    final plan = _plan;
    if (plan == null) {
      final missing = widget.priceKurus - _walletTotal;
      return 'Paran yetmiyor. ${speakMoney(missing)} daha lazım.';
    }
    if (plan.isExact) {
      return 'Parlayan paraları kasaya ver. Tam ${speakMoney(plan.paidKurus)} vereceksin.';
    }
    return 'Parlayan paraları kasaya ver. ${speakMoney(plan.paidKurus)} vereceksin. '
        'Sana para üstü verilecek.';
  }

  int get _remainingToGive =>
      _pieces.where((p) => p.toGive).length - _given.length;

  void _give(int index) {
    if (_finishing || _given.contains(index)) return;
    final app = context.read<AppState>();
    final piece = _pieces[index];
    if (!piece.toGive) {
      app.playTryAgain();
      app.say('Bu parayı değil. Parlayan parayı ver.');
      return;
    }
    app.playCoin();
    setState(() => _given.add(index));
    if (_remainingToGive == 0) {
      _finish();
    } else {
      app.say('${speakMoney(piece.valueKurus)}. Güzel!');
    }
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final app = context.read<AppState>();
    final plan = _plan!;
    app.playSuccess();
    app.say('Aferin! Ödemeyi yaptın.');
    await app.completePurchase(
      productName: widget.productName,
      productEmoji: widget.productEmoji,
      plan: plan,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      fadeScaleRoute(
        ChangeScreen(
          plan: plan,
          productName: widget.productName,
          productEmoji: widget.productEmoji,
          heroTag: widget.heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return KidScaffold(
      title: 'Ödeme',
      instruction: _instruction,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _ProductHeader(
              emoji: widget.productEmoji,
              name: widget.productName,
              price: widget.priceKurus,
              heroTag: widget.heroTag,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: plan == null ? _buildNotEnough() : _buildPayment(plan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayment(PaymentPlan plan) {
    final givenSet = _given.toSet();
    return Column(
      children: [
        _InfoStrip(
          text: 'Vereceğin para: ${formatMoney(plan.paidKurus)}',
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        // Kasa
        Expanded(
          flex: 4,
          child: DragTarget<int>(
            onAcceptWithDetails: (d) => _give(d.data),
            builder: (context, candidates, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              decoration: BoxDecoration(
                color: candidates.isNotEmpty
                    ? AppColors.glow.withValues(alpha: 0.4)
                    : AppColors.register,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary, width: 5),
              ),
              child: Column(
                children: [
                  Text(
                    'Kasa',
                    style: rounded(
                      size: 30,
                      weight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                  ),
                  Expanded(
                    child: _given.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Image.asset('assets/images/kasa.png'),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final i in _given)
                                  TweenAnimationBuilder<double>(
                                    key: ValueKey('given-$i'),
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 450),
                                    curve: Curves.easeOutBack,
                                    builder: (_, t, child) =>
                                        Transform.scale(scale: t, child: child),
                                    child: MoneyView(
                                      denomination: denominationOf(
                                        _pieces[i].valueKurus,
                                      ),
                                      width: 90,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Cüzdandaki paralar
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8, top: 14),
            child: Wrap(
              spacing: 14,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < _pieces.length; i++)
                  if (!givenSet.contains(i)) _buildPiece(i),
              ],
            ),
          ),
        ),
        MascotBubble(
          pose: MascotPose.point,
          size: 72,
          text: 'Parlayan paraları\nkasaya ver',
          speech: _instruction,
        ),
      ],
    );
  }

  Widget _buildPiece(int index) {
    final piece = _pieces[index];
    final d = denominationOf(piece.valueKurus);
    final view = MoneyView(
      denomination: d,
      width: 110,
      highlight: piece.toGive,
      dimmed: !piece.toGive,
    );
    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: MoneyView(denomination: d, width: 130),
      ),
      childWhenDragging: Opacity(opacity: 0.2, child: view),
      child: GestureDetector(onTap: () => _give(index), child: view),
    );
  }

  Widget _buildNotEnough() {
    final missing = widget.priceKurus - _walletTotal;
    final missingMoney = PaymentCalculator.expand(
      PaymentCalculator.makeChange(missing),
    );
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text('😟', style: TextStyle(fontSize: 72)),
          const Text(
            'Paran yetmiyor',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _InfoStrip(
            text: 'Cüzdanında: ${formatMoney(_walletTotal)}',
            color: AppColors.walletBorder,
          ),
          const SizedBox(height: 8),
          _InfoStrip(
            text: 'Eksik: ${formatMoney(missing)}',
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu kadar daha para lazım:',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final v in missingMoney)
                MoneyView(denomination: denominationOf(v), width: 100),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .pushReplacement(fadeScaleRoute(const WalletScreen())),
            icon: const Text('👛', style: TextStyle(fontSize: 28)),
            label: const Text('Cüzdanıma para ekle'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.emoji,
    required this.name,
    required this.price,
    required this.heroTag,
  });

  final String emoji;
  final String name;
  final int price;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AppState>().say('$name. ${speakMoney(price)}.'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 2),
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
            Hero(
              tag: heroTag,
              child: ProductImage(emoji: emoji, size: 76),
            ),
            const SizedBox(width: 18),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: rounded(
                      size: 26,
                      weight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    formatMoney(price),
                    style: rounded(
                      size: 42,
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
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
