import 'package:flutter/material.dart';

import '../models/denomination.dart';
import '../services/money_formatter.dart';
import '../utils/theme.dart';

/// Bir banknotu veya madeni parayı çizer.
///
/// Gerçek fotoğraf eklenmişse ([Denomination.imageAsset]) onu gösterir,
/// yoksa paranın rengine ve değerine göre sade bir çizim yapar.
class MoneyView extends StatelessWidget {
  const MoneyView({
    super.key,
    required this.denomination,
    this.width = 120,
    this.highlight = false,
    this.dimmed = false,
  });

  final Denomination denomination;

  /// Banknotun genişliği. Madeni paralar bu genişliğe göre ölçeklenir.
  final double width;

  /// true ise para parlar ve hafifçe nabız gibi atar ("bu parayı ver").
  final bool highlight;

  /// true ise para soluk gösterilir ("bu para şimdi lazım değil").
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final d = denomination;
    Widget child;
    if (d.imageAsset != null) {
      child = Image.asset(
        d.imageAsset!,
        width: d.isBanknote ? width : _coinSize,
      );
    } else if (d.isBanknote) {
      child = _Banknote(denomination: d, width: width);
    } else {
      child = _Coin(denomination: d, size: _coinSize);
    }

    if (dimmed) child = Opacity(opacity: 0.4, child: child);
    if (highlight) child = PulseGlow(circle: !d.isBanknote, child: child);

    return Semantics(
      label: speakMoney(d.valueKurus),
      button: true,
      child: child,
    );
  }

  /// Madeni paraların büyüklüğü değerleriyle orantılıdır (gerçekteki gibi).
  double get _coinSize {
    const scale = {100: 0.62, 50: 0.58, 25: 0.53, 10: 0.5, 5: 0.47};
    return width * (scale[denomination.valueKurus] ?? 0.5);
  }
}

class _Banknote extends StatelessWidget {
  const _Banknote({required this.denomination, required this.width});

  final Denomination denomination;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = denomination.color;
    final dark = _shade(color, -0.18);
    final light = _shade(color, 0.18);
    final h = width * 0.5;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.06),
        gradient: LinearGradient(
          colors: [light, color, dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: width * 0.025),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          // Filigran dairesi (sol üstte; yazıların üstüne binmez)
          Positioned(
            left: width * 0.06,
            top: h * 0.1,
            child: Container(
              width: h * 0.5,
              height: h * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Köşedeki küçük değer
          Positioned(
            left: width * 0.05,
            bottom: h * 0.04,
            child: Text(
              denomination.label,
              style: TextStyle(
                fontSize: h * 0.18,
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Büyük değer
          Positioned(
            left: width * 0.33,
            right: width * 0.04,
            top: 0,
            bottom: 0,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    denomination.label,
                    style: TextStyle(
                      fontSize: h * 0.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 3),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'TL',
                    style: TextStyle(
                      fontSize: h * 0.22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  const _Coin({required this.denomination, required this.size});

  final Denomination denomination;
  final double size;

  static const _gold = Color(0xFFD4AF37);
  static const _silver = Color(0xFFC3C7CD);

  @override
  Widget build(BuildContext context) {
    // 1 TL: dışı altın, içi gümüş. 50 kr: dışı gümüş, içi altın. Diğerleri altın.
    final (outer, inner) = switch (denomination.valueKurus) {
      100 => (_gold, _silver),
      50 => (_silver, _gold),
      _ => (denomination.color, denomination.color),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_shade(outer, 0.2), outer, _shade(outer, -0.2)],
          stops: const [0.2, 0.7, 1],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets.all(size * 0.11),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [_shade(inner, 0.25), inner]),
          border: Border.all(color: _shade(inner, -0.25), width: 1),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: EdgeInsets.all(size * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  denomination.label,
                  style: TextStyle(
                    fontSize: size * 0.34,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  denomination.unit,
                  style: TextStyle(
                    fontSize: size * 0.16,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
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

Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// İçindeki öğeyi sarı bir ışıkla parlatır ve hafifçe büyütüp küçültür.
class PulseGlow extends StatefulWidget {
  const PulseGlow({super.key, required this.child, this.circle = false});

  final Widget child;
  final bool circle;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.scale(
          scale: 1 + 0.06 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.circle ? null : BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glow.withValues(alpha: 0.5 + 0.4 * t),
                  blurRadius: 10 + 10 * t,
                  spreadRadius: 2 + 4 * t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}
