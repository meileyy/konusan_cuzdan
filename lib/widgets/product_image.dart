import 'package:flutter/material.dart';

/// Hazır ürünlerin Canva tasarımından alınan resimleri. Eğitmenin eklediği
/// ürünlerde resim yoksa emoji gösterilir.
const _imagesByEmoji = {
  '🍎': 'assets/images/urun_elma.png',
  '💧': 'assets/images/urun_su.png',
  '🍞': 'assets/images/urun_ekmek.png',
  '🧃': 'assets/images/urun_meyve_suyu.png',
};

/// Ürün resmi (varsa) veya emojisi.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.emoji, this.size = 80});

  final String emoji;
  final double size;

  static bool hasImage(String emoji) => _imagesByEmoji.containsKey(emoji);

  @override
  Widget build(BuildContext context) {
    final asset = _imagesByEmoji[emoji];
    if (asset != null) {
      return Image.asset(asset, height: size, width: size, fit: BoxFit.contain);
    }
    return SizedBox(
      height: size,
      width: size,
      child: FittedBox(child: Text(emoji)),
    );
  }
}
