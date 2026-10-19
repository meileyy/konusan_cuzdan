import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/money_formatter.dart';
import '../state/app_state.dart';
import '../utils/theme.dart';
import '../utils/transitions.dart';
import '../widgets/kid_scaffold.dart';
import '../widgets/mascot.dart';
import '../widgets/price_keypad_dialog.dart';
import '../widgets/product_image.dart';
import 'payment_screen.dart';

/// Alışveriş: çocuk almak istediği ürünün resmine dokunur.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _instruction = 'Ne almak istersin? Bir ürüne dokun.';

  @override
  void initState() {
    super.initState();
    speakAfterFirstFrame(this, _instruction);
  }

  void _buy(Product p) {
    final app = context.read<AppState>();
    app.playTap();
    app.say('${p.name}. ${speakMoney(p.priceKurus)}.');
    Navigator.of(context).push(
      slideUpRoute(
        PaymentScreen(
          productName: p.name,
          productEmoji: p.emoji,
          priceKurus: p.priceKurus,
          heroTag: 'product-${p.id}',
        ),
      ),
    );
  }

  Future<void> _customPrice() async {
    final app = context.read<AppState>();
    app.playTap();
    app.say('Fiyatı yaz.');
    final price = await showPriceKeypad(context, allowKurus: app.level >= 3);
    if (price == null || !mounted) return;
    Navigator.of(context).push(
      slideUpRoute(
        PaymentScreen(
          productName: 'Alışveriş',
          productEmoji: '🛍️',
          priceKurus: price,
          heroTag: 'product-custom',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppState>().visibleProducts;
    return KidScaffold(
      title: 'Alışveriş',
      titleColor: AppColors.purple,
      instruction: _instruction,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const MascotBubble(
              pose: MascotPose.shop,
              size: 90,
              text: 'Hadi, alışveriş\nyapalım!',
              speech: _instruction,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final p in products)
                    _ProductCard(
                      emoji: p.emoji,
                      name: p.name,
                      price: formatMoney(p.priceKurus),
                      heroTag: 'product-${p.id}',
                      onTap: () => _buy(p),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                const WalletTotalChip(),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _customPrice,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(88, 60),
                      shape: const StadiumBorder(),
                    ),
                    child: const FittedBox(child: Text('Başka fiyat')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Beyaz ürün kartı: solda resim, sağda isim ve turuncu fiyat etiketi.
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.emoji,
    required this.name,
    required this.price,
    required this.heroTag,
    required this.onTap,
  });

  final String emoji;
  final String name;
  final String price;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Hero(
                  tag: heroTag,
                  child: ProductImage(emoji: emoji, size: 90),
                ),
              ),
              FittedBox(
                child: Text(
                  name,
                  style: rounded(size: 22, weight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  price,
                  style: rounded(
                    size: 24,
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
