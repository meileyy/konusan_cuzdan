import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/denomination.dart';
import '../services/money_formatter.dart';
import '../state/app_state.dart';
import '../utils/theme.dart';
import '../widgets/kid_scaffold.dart';
import '../widgets/mascot.dart';
import '../widgets/money_view.dart';

/// Cüzdanım: eldeki para, resimlere dokunarak (veya sürükleyerek) girilir.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const _instruction =
      'Aşağıdaki paraya dokun, cüzdanına ekle. Çıkarmak için cüzdandaki paraya dokun.';

  @override
  void initState() {
    super.initState();
    speakAfterFirstFrame(this, _instruction);
  }

  Future<void> _add(Denomination d) async {
    final app = context.read<AppState>();
    app.playCoin();
    await app.addMoney(d.valueKurus);
    app.say(
      '${speakMoney(d.valueKurus)} ekledin. '
      'Cüzdanında ${speakMoney(app.walletTotal)} var.',
    );
  }

  Future<void> _remove(Denomination d) async {
    final app = context.read<AppState>();
    app.playTap();
    await app.removeMoney(d.valueKurus);
    app.say(
      '${speakMoney(d.valueKurus)} çıkardın. '
      'Cüzdanında ${speakMoney(app.walletTotal)} var.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final wallet = app.wallet;
    final inWallet = kDenominations
        .where((d) => (wallet[d.valueKurus] ?? 0) > 0)
        .toList();
    // Seviye 3'te 11 küpür var; palet büyük kalırsa cüzdana yer kalmıyor.
    final paletteWidth = app.allowedDenominations.length > 6 ? 68.0 : 104.0;

    return KidScaffold(
      title: 'Cüzdanım',
      instruction: _instruction,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            MascotBubble(
              pose: MascotPose.wave,
              size: 70,
              text: inWallet.isEmpty
                  ? 'Cüzdanın boş.\nAşağıdan para ekle!'
                  : 'Harika!\nPara birikiyor!',
              speech: _instruction,
            ),
            const SizedBox(height: 8),
            // Turuncu deri cüzdan: para buraya sürüklenebilir.
            Expanded(
              child: DragTarget<Denomination>(
                onAcceptWithDetails: (details) => _add(details.data),
                builder: (context, candidates, _) => _LeatherWallet(
                  hovering: candidates.isNotEmpty,
                  total: app.walletTotal,
                  child: inWallet.isEmpty
                      ? Center(
                          child: Text(
                            'Cüzdanın boş 👛',
                            style: rounded(
                              size: 26,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : _WalletGrid(
                          denominations: inWallet,
                          wallet: wallet,
                          onTap: _remove,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Para seçme paleti
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
              decoration: BoxDecoration(
                color: AppColors.paletteBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final d in app.allowedDenominations)
                        Draggable<Denomination>(
                          data: d,
                          feedback: Material(
                            color: Colors.transparent,
                            child: MoneyView(denomination: d, width: 140),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: MoneyView(
                              denomination: d,
                              width: paletteWidth,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => _add(d),
                            child: MoneyView(
                              denomination: d,
                              width: paletteWidth,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Para ekle 👆',
                      style: rounded(
                        size: 22,
                        weight: FontWeight.w800,
                        color: Colors.white,
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

/// Turuncu deri cüzdan görünümü: sağda düğmeli kapak, altta toplam para.
class _LeatherWallet extends StatelessWidget {
  const _LeatherWallet({
    required this.hovering,
    required this.total,
    required this.child,
  });

  final bool hovering;
  final int total;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hovering
                  ? [AppColors.glow, AppColors.wallet]
                  : [const Color(0xFFF8B652), AppColors.wallet],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.walletDark, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(child: child),
              // Toplam para (dikişli iç cep)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.walletInner,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.walletDark.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Text(
                    formatMoney(total),
                    key: ValueKey(total),
                    textAlign: TextAlign.center,
                    style: rounded(
                      size: 46,
                      weight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Kapak ve düğme
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              width: 46,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.walletDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.yellow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cüzdandaki paralar: 2 sütunlu ızgara. 6 farklı küpüre kadar (3 satır)
/// kaydırmadan sığacak şekilde para boyu alana göre seçilir; daha fazlası
/// varsa ızgara kayar ve alt kenarı soluklaşır.
class _WalletGrid extends StatelessWidget {
  const _WalletGrid({
    required this.denominations,
    required this.wallet,
    required this.onTap,
  });

  final List<Denomination> denominations;
  final Map<int, int> wallet;
  final void Function(Denomination) onTap;

  // Sağdaki kapak (düğme) cüzdanın içine taşar; paralar onun altında kalmasın.
  static const _padding = EdgeInsets.fromLTRB(10, 10, 34, 10);
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = constraints.maxWidth - _padding.horizontal;
        final innerHeight = constraints.maxHeight - _padding.vertical;
        final cellWidth = (innerWidth - _gap) / 2;

        final digits = denominations
            .map((d) => '${wallet[d.valueKurus]}'.length)
            .fold(1, max);
        final tallest = denominations.any((d) => !d.isBanknote) ? 0.62 : 0.5;
        final rows = min(3, (denominations.length / 2).ceil());
        final rowHeight = (innerHeight - (rows - 1) * _gap) / rows;

        // En büyük para boyunu bul: hem hücre genişliğine hem satır yüksekliğine sığsın.
        var moneyWidth = 120.0;
        late double font;
        while (true) {
          font = (moneyWidth * 0.22).clamp(16.0, 24.0);
          final fitsWidth =
              moneyWidth + _WalletRow.badgeWidth(font, digits) <= cellWidth;
          final fitsHeight =
              max(moneyWidth * tallest, _WalletRow.badgeHeight(font)) <=
              rowHeight;
          if ((fitsWidth && fitsHeight) || moneyWidth <= 48) break;
          moneyWidth -= 4;
        }

        return _FadingScroll(
          padding: _padding,
          // Az para varsa ızgara cüzdanın ortasında durur.
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: max(0, innerHeight)),
            child: Center(
              child: Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (final d in denominations)
                    SizedBox(
                      width: cellWidth,
                      // Tahmin tutmazsa (ör. büyük yazı tipi) taşmak yerine küçülür.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _WalletRow(
                          denomination: d,
                          count: wallet[d.valueKurus]!,
                          moneyWidth: moneyWidth,
                          fontSize: font,
                          onTap: () => onTap(d),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// İçerik sığmıyorsa alt kenarı soluklaşan dikey kaydırma alanı
/// ("aşağıda daha var" ipucu). En alta gelince soluklaşma kalkar.
class _FadingScroll extends StatefulWidget {
  const _FadingScroll({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  State<_FadingScroll> createState() => _FadingScrollState();
}

class _FadingScrollState extends State<_FadingScroll> {
  final _controller = ScrollController();
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final hasMore = _controller.position.extentAfter > 1;
    if (hasMore != _hasMore) setState(() => _hasMore = hasMore);
  }

  @override
  Widget build(BuildContext context) {
    // İçerik değişince (para eklenip çıkarılınca) yeniden ölç.
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 0.8, 1],
        colors: [
          Colors.white,
          Colors.white,
          _hasMore ? Colors.transparent : Colors.white,
        ],
      ).createShader(bounds),
      child: SingleChildScrollView(
        controller: _controller,
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}

/// Cüzdandaki bir küpür: banknot + renkli adet etiketi ("×2").
class _WalletRow extends StatelessWidget {
  const _WalletRow({
    required this.denomination,
    required this.count,
    required this.moneyWidth,
    required this.fontSize,
    required this.onTap,
  });

  final Denomination denomination;
  final int count;
  final double moneyWidth;
  final double fontSize;
  final VoidCallback onTap;

  // Yerleşim hesabı için etiketin yaklaşık ölçüleri (kenar boşlukları dahil).
  static double badgeWidth(double fontSize, int digits) =>
      fontSize * (1.85 + 0.55 * digits) + 6;
  static double badgeHeight(double fontSize) => fontSize * 1.3 + 6;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${denomination.valueKurus}-$count'),
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MoneyView(denomination: denomination, width: moneyWidth),
            Container(
              margin: EdgeInsets.only(left: fontSize * 0.27),
              padding: EdgeInsets.symmetric(horizontal: fontSize * 0.5),
              decoration: BoxDecoration(
                color: denomination.color,
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
          ],
        ),
      ),
    );
  }
}
