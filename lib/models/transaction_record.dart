/// Geçmiş ekranında listelenen tek bir alışveriş kaydı.
class TransactionRecord {
  const TransactionRecord({
    this.id,
    required this.createdAt,
    required this.productName,
    required this.productEmoji,
    required this.priceKurus,
    required this.paidKurus,
    required this.changeKurus,
  });

  final int? id;
  final DateTime createdAt;
  final String productName;
  final String productEmoji;
  final int priceKurus;
  final int paidKurus;
  final int changeKurus;

  Map<String, Object?> toMap() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'product_name': productName,
    'product_emoji': productEmoji,
    'price_kurus': priceKurus,
    'paid_kurus': paidKurus,
    'change_kurus': changeKurus,
  };

  factory TransactionRecord.fromMap(Map<String, Object?> map) =>
      TransactionRecord(
        id: map['id'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
        productName: map['product_name'] as String,
        productEmoji: map['product_emoji'] as String,
        priceKurus: map['price_kurus'] as int,
        paidKurus: map['paid_kurus'] as int,
        changeKurus: map['change_kurus'] as int,
      );
}
