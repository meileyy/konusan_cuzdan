/// Alışveriş ekranında görünen ürün.
class Product {
  const Product({
    this.id,
    required this.name,
    required this.emoji,
    required this.priceKurus,
    required this.level,
  });

  final int? id;
  final String name;
  final String emoji;
  final int priceKurus;

  /// Ürünün görüneceği en düşük zorluk seviyesi.
  final int level;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'price_kurus': priceKurus,
    'level': level,
  };

  factory Product.fromMap(Map<String, Object?> map) => Product(
    id: map['id'] as int?,
    name: map['name'] as String,
    emoji: map['emoji'] as String,
    priceKurus: map['price_kurus'] as int,
    level: map['level'] as int,
  );
}
