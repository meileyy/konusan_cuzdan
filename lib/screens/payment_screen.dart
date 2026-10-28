import 'dart:math';

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

class _PaymentScreenState extends State<PaymentScreen> {
  /// Gövde bundan kısa kalırsa (ör. çok büyük yazı tipi) ekran taşmak yerine
  /// dikey kaydırılır. 360x640 telefonda gövde bundan uzundur.
  static const _minBodyHeight = 440.0;

  late final PaymentPlan? _plan;
  late final int _walletTotal;

  /// Ödemeden sonra cüzdanda kalacak paralar: {küpür: adet}
  late final Map<int, int> _kept;

  /// Kasaya verilen paralar: {küpür: adet}
  final Map<int, int> _given = {};
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final wallet = app.wallet;
    _walletTotal = app.walletTotal;
    _plan = PaymentCalculator.planPayment(wallet, widget.priceKurus);

    final pay = _pay;
    _kept = {
      for (final e in wallet.entries)
        if (e.value - (pay[e.key] ?? 0) > 0) e.key: e.value - (pay[e.key] ?? 0),
    };

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

  /// Verilmesi gereken paralar: {küpür: adet}
  Map<int, int> get _pay => _plan?.pay ?? const <int, int>{};

  /// Bu küpürden daha kaç tane verilecek.
  int _leftOf(int value) => (_pay[value] ?? 0) - (_given[value] ?? 0);

  int get _remainingToGive => _countOf(_pay) - _countOf(_given);

  void _give(int value) {
    if (_finishing) return;
    if (_leftOf(value) <= 0) {
      _wrongPiece();
      return;
    }
    final app = context.read<AppState>();
    app.playCoin();
    setState(() => _given.update(value, (n) => n + 1, ifAbsent: () => 1));
    if (_remainingToGive == 0) {
      _finish();
    } else {
      app.say('${speakMoney(value)}. Güzel!');
    }
  }

  void _wrongPiece() {
    if (_finishing) return;
    final app = context.read<AppState>();
    app.playTryAgain();
    app.say('Bu parayı değil. Parlayan parayı ver.');
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
      // Balonlu maskot yerine başlığın yanında küçük maskot (yer kaplamaz).
      headerExtra: GestureDetector(
        onTap: () => context.read<AppState>().say(_instruction),
        child: Image.asset(MascotPose.point.asset, height: 44),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ProductHeader(
                  emoji: widget.productEmoji,
                  name: widget.productName,
                  price: widget.priceKurus,
                  heroTag: widget.heroTag,
                  note: _payNote,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: plan == null ? _buildNotEnough() : _buildPayment(plan),
                ),
              ],
            ),
          );
          if (constraints.maxHeight >= _minBodyHeight) return content;
          return SingleChildScrollView(
            child: SizedBox(height: _minBodyHeight, child: content),
          );
        },
      ),
    );
  }

  /// Ürün kartında fiyatın altındaki satır: "Vereceğin: 20 TL · Para üstü: 5 TL"
  String? get _payNote {
    final plan = _plan;
    if (plan == null) return null;
    final paid = 'Vereceğin: ${formatMoney(plan.paidKurus)}';
    if (plan.isExact) return paid;
    return '$paid · Para üstü: ${formatMoney(plan.changeKurus)}';
  }

  Widget _buildPayment(PaymentPlan plan) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          // Kasa küçük ve sabit bir hedef; ekranın asıl yeri paraların.
          SizedBox(
            height: (constraints.maxHeight * 0.22).clamp(90.0, 130.0),
            child: _buildRegister(),
          ),
          const SizedBox(height: 8),
          _buildToGiveTitle(),
          // Vereceğin paralar: artan bütün yer burada. Kaydırılabilir alanda
          // DEĞİL, böylece sürükleme hiçbir kaydırma hareketiyle çakışmaz.
          Expanded(child: _buildToGive(plan)),
          const SizedBox(height: 6),
          _buildKept(),
        ],
      ),
    );
  }

  /// Kasa: solda küçük kasa resmi, sağında verilen paralar küpüre göre
  /// gruplanmış küçük kartlar ("10 TL ×1").
  Widget _buildRegister() {
    final given = _sortedValues(_given);
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => _leftOf(d.data) > 0,
      onAcceptWithDetails: (d) => _give(d.data),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? AppColors.glow.withValues(alpha: 0.4)
              : AppColors.register,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary, width: 4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Column(
                children: [
                  Text(
                    'Kasa',
                    style: rounded(
                      size: 18,
                      weight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                  Expanded(child: Image.asset('assets/images/kasa.png')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: given.isEmpty
                  ? Center(
                      child: Text(
                        'Parlayan parayı\nburaya ver',
                        textAlign: TextAlign.center,
                        style: rounded(
                          size: 17,
                          weight: FontWeight.w800,
                          color: AppColors.primary.withValues(alpha: 0.7),
                          height: 1.2,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      // Çok küpür verildiyse kasadan taşmak yerine küçülür.
                      builder: (context, box) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: box.maxWidth,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final v in given)
                                TweenAnimationBuilder<double>(
                                  key: ValueKey('given-$v'),
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeOutBack,
                                  builder: (_, t, child) =>
                                      Transform.scale(scale: t, child: child),
                                  child: _MoneyGroup(
                                    denomination: denominationOf(v),
                                    count: _given[v]!,
                                    width: 56,
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
      ),
    );
  }

  Widget _buildToGiveTitle() {
    final left = _remainingToGive;
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Vereceğin paralar',
              style: rounded(size: 22, weight: FontWeight.w800, height: 1.2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Container(
            key: ValueKey(left),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: left == 0 ? AppColors.success : AppColors.orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              left == 0 ? 'Hepsi verildi!' : '$left para kaldı',
              style: rounded(
                size: 17,
                weight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Parlayan, büyük kartlar. Her küpürden tek kart; rozet kalan adedi gösterir.
  /// Kartlar bu alanın ortasında durur.
  Widget _buildToGive(PaymentPlan plan) {
    final values = _sortedValues(plan.pay);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Kart boyu bütün plana göre seçilir; paralar verildikçe değişmez.
        final width = _fitPayWidth(constraints.biggest, plan.pay);
        // Hesap yine de sığmazsa (çok fazla farklı küpür) taşmak yerine küçülür.
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: _runGap,
              children: [
                for (final v in values)
                  _ShrinkAway(
                    child: _leftOf(v) > 0
                        ? KeyedSubtree(
                            key: ValueKey('pay-$v'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _sideGap / 2,
                              ),
                              child: _buildPayCard(v, width),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayCard(int value, double width) {
    final d = denominationOf(value);
    final left = _leftOf(value);
    Widget card(int count) =>
        _BigMoney(denomination: d, count: count, width: width);
    return Draggable<int>(
      data: value,
      feedback: Material(
        color: Colors.transparent,
        child: MoneyView(denomination: d, width: width),
      ),
      // Sürüklenen para elden çıkmış gibi rozet bir azalır.
      childWhenDragging: left > 1
          ? card(left - 1)
          : Opacity(opacity: 0.2, child: card(left)),
      child: GestureDetector(onTap: () => _give(value), child: card(left)),
    );
  }

  /// Cüzdanında kalan paralar: küçük, soluk, tek satır ve yatay kaydırılır.
  Widget _buildKept() {
    final values = _sortedValues(_kept);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Cüzdanında kalan',
            style: rounded(
              size: 17,
              weight: FontWeight.w800,
              color: AppColors.text.withValues(alpha: 0.55),
              height: 1.2,
            ),
          ),
        ),
        if (values.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Başka paran kalmayacak.',
              style: rounded(
                size: 16,
                color: AppColors.text.withValues(alpha: 0.55),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                for (final v in values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: GestureDetector(
                      onTap: _wrongPiece,
                      child: _MoneyGroup(
                        denomination: denominationOf(v),
                        count: _kept[v]!,
                        width: 90,
                        dimmed: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotEnough() {
    final missing = widget.priceKurus - _walletTotal;
    // Tek tek açmak yerine küpüre göre grupla (38.000 TL eksikte 190 kart olmasın).
    final missingMoney = PaymentCalculator.makeChange(missing);
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text('😟', style: TextStyle(fontSize: 56)),
          const Text(
            'Paran yetmiyor',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _InfoStrip(
            text: 'Cüzdanında: ${formatMoney(_walletTotal)}',
            color: AppColors.walletBorder,
            oneLine: true,
          ),
          const SizedBox(height: 8),
          _InfoStrip(
            text: 'Eksik: ${formatMoney(missing)}',
            color: AppColors.warning,
            oneLine: true,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu kadar daha para lazım:',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final v in _sortedValues(missingMoney))
                _MoneyGroup(
                  denomination: denominationOf(v),
                  count: missingMoney[v]!,
                  width: 84,
                ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushReplacement(fadeScaleRoute(const WalletScreen())),
            icon: const Text('👛', style: TextStyle(fontSize: 28)),
            label: const Text('Cüzdanıma para ekle'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// "Vereceğin paralar" kartları arasındaki boşluklar.
const double _sideGap = 10;
const double _runGap = 14;

int _countOf(Map<int, int> money) => money.values.fold(0, (a, b) => a + b);

List<int> _sortedValues(Map<int, int> money) =>
    money.keys.toList()..sort((a, b) => b.compareTo(a));

/// "Vereceğin paralar" alanına sığan en büyük kart genişliğini seçer.
/// Kart en fazla 150 (tek kartsa 180) olur; 360 genişlikte 2 kart yan yana sığar.
double _fitPayWidth(Size area, Map<int, int> pay) {
  final n = max(1, pay.length);
  final largest = n == 1 ? 180.0 : 150.0;
  // Madeni paralar banknotlardan daha yüksektir (bkz. MoneyView._coinSize).
  final tallest = pay.keys.any((v) => !denominationOf(v).isBanknote)
      ? 0.62
      : 0.5;

  bool fits(double w, int perRow) {
    final o = _BigMoney.overhang(w);
    final rows = (n / perRow).ceil();
    final rowWidth = perRow * (w + o + _sideGap);
    final height = rows * (w * tallest + o) + (rows - 1) * _runGap;
    return rowWidth <= area.width && height <= area.height;
  }

  // Satır başına 1–4 kart dene; en büyük kartı veren düzeni seç. Birden
  // fazla küpür varsa en az ikisi yan yana dursun.
  var best = 48.0;
  for (var perRow = min(n, 2); perRow <= min(n, 4); perRow++) {
    for (var w = largest; w > best; w -= 2) {
      if (fits(w, perRow)) {
        best = w;
        break;
      }
    }
  }
  return best;
}

/// Verilecek para: büyük ve parlak. Adet rozeti sağ üst köşeye biner;
/// yanda dursaydı 360 genişlikte iki kart yan yana sığmazdı.
class _BigMoney extends StatelessWidget {
  const _BigMoney({
    required this.denomination,
    required this.count,
    required this.width,
  });

  final Denomination denomination;
  final int count;
  final double width;

  static double badgeFont(double width) => max(18, width * 0.17);

  /// Rozetin paranın dışına taştığı pay (üstte ve sağda).
  static double overhang(double width) =>
      _CountBadge.estimateHeight(badgeFont(width)) * 0.35;

  @override
  Widget build(BuildContext context) {
    final o = overhang(width);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: o, right: o),
          child: MoneyView(
            denomination: denomination,
            width: width,
            highlight: true,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _CountBadge(
            color: denomination.color,
            count: count,
            fontSize: badgeFont(width),
            spaced: false,
          ),
        ),
      ],
    );
  }
}

/// Bir küpür: para resmi ve yanında adet rozeti ("×8").
class _MoneyGroup extends StatelessWidget {
  const _MoneyGroup({
    required this.denomination,
    required this.count,
    required this.width,
    this.dimmed = false,
  });

  final Denomination denomination;
  final int count;
  final double width;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final badge = _CountBadge(
      color: denomination.color,
      count: count,
      fontSize: _CountBadge.fontFor(width),
    );
    final group = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MoneyView(denomination: denomination, width: width),
        badge,
      ],
    );
    // MoneyView'in kendi soluklaştırması (0.4) burada fazla silik kalıyordu.
    return dimmed ? Opacity(opacity: 0.7, child: group) : group;
  }
}

/// Küpür renginde, beyaz kenarlıklı "×adet" etiketi (Cüzdanım ekranındaki gibi).
/// Adet değişince hafifçe zıplar.
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.color,
    required this.count,
    required this.fontSize,
    this.spaced = true,
  });

  final Color color;
  final int count;
  final double fontSize;

  /// true ise paranın yanında durur (solda boşluk bırakır); false ise köşeye biner.
  final bool spaced;

  static double fontFor(double moneyWidth) => max(16, moneyWidth * 0.2);

  /// Yerleşim hesabı için yaklaşık yükseklik (kenarlık dahil).
  static double estimateHeight(double fontSize) => fontSize * 1.3 + 6;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        margin: EdgeInsets.only(left: spaced ? fontSize * 0.3 : 0),
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(fontSize * 0.6),
          border: Border.all(
            color: Colors.white,
            width: fontSize >= 24 ? 3 : 2,
          ),
        ),
        child: Text(
          '×$count',
          style: rounded(
            size: fontSize,
            weight: FontWeight.w800,
            color: Colors.white,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

/// [child] null olunca küçülerek ve kapladığı yeri bırakarak kaybolur.
/// (SizeTransition kırptığı için paranın parıltısını kesmemek adına kullanılmadı.)
class _ShrinkAway extends StatelessWidget {
  const _ShrinkAway({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      layoutBuilder: (current, previous) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, c) => Align(
          widthFactor: animation.value,
          heightFactor: animation.value,
          child: c,
        ),
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.emoji,
    required this.name,
    required this.price,
    required this.heroTag,
    this.note,
  });

  final String emoji;
  final String name;
  final int price;
  final String heroTag;

  /// Fiyatın altındaki küçük satır (ör. "Vereceğin: 20 TL · Para üstü: 5 TL").
  final String? note;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AppState>().say('$name. ${speakMoney(price)}.'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
              child: ProductImage(emoji: emoji, size: 56),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: rounded(
                      size: 18,
                      weight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    formatMoney(price),
                    style: rounded(
                      size: 28,
                      weight: FontWeight.w800,
                      color: AppColors.orange,
                      height: 1.1,
                    ),
                  ),
                  if (note != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        note!,
                        maxLines: 1,
                        style: rounded(
                          size: 15,
                          weight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1.2,
                        ),
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
  const _InfoStrip({
    required this.text,
    required this.color,
    this.oneLine = false,
  });

  static const fontSize = 24.0;

  final String text;
  final Color color;

  /// true ise metin alta inmez; sığmazsa tek satırda küçülür.
  final bool oneLine;

  @override
  Widget build(BuildContext context) {
    Widget label = Text(
      text,
      textAlign: TextAlign.center,
      maxLines: oneLine ? 1 : null,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
      ),
    );
    if (oneLine) label = FittedBox(fit: BoxFit.scaleDown, child: label);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: fontSize * 0.4, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: label,
    );
  }
}
