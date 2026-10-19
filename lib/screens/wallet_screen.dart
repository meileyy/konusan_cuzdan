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
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                          children: [
                            for (final d in inWallet)
                              _WalletRow(
                                denomination: d,
                                count: wallet[d.valueKurus]!,
                                onTap: () => _remove(d),
                              ),
                          ],
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
                            child: MoneyView(denomination: d, width: 104),
                          ),
                          child: GestureDetector(
                            onTap: () => _add(d),
                            child: MoneyView(denomination: d, width: 104),
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

/// Cüzdandaki bir küpür satırı: banknot + renkli adet etiketi ("×2").
class _WalletRow extends StatelessWidget {
  const _WalletRow({
    required this.denomination,
    required this.count,
    required this.onTap,
  });

  final Denomination denomination;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
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
              MoneyView(denomination: denomination, width: 150),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: denomination.color,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Text(
                  '×$count',
                  style: rounded(
                    size: 30,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
