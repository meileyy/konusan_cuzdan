import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';
import '../models/transaction_record.dart';
import '../services/payment_calculator.dart';

/// Cihaz üzerindeki SQLite veritabanını yönetir. İnternet bağlantısı gerekmez.
///
/// Tablolar:
///   wallet            → cüzdandaki paralar (küpür, adet)
///   products          → alışveriş ürünleri
///   transactions      → yapılan alışverişler
///   transaction_items → her alışverişte verilen ve alınan paralar
///   progress          → oyun modundaki doğru/yanlış cevaplar
///   settings          → ayarlar (seviye, PIN, konuşma hızı, ses)
class DatabaseHelper {
  DatabaseHelper._(this._factory, this._path);

  static final DatabaseHelper instance = DatabaseHelper._(null, null);

  /// Testlerde bellek içi veritabanı kullanmak için.
  factory DatabaseHelper.forTesting(DatabaseFactory factory, String path) =>
      DatabaseHelper._(factory, path);

  final DatabaseFactory? _factory;
  final String? _path;
  Database? _db;

  static const _dbName = 'konusan_cuzdan.db';
  static const _dbVersion = 1;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final path = _path ?? join(await getDatabasesPath(), _dbName);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallet (
        value_kurus INTEGER PRIMARY KEY,
        count INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        price_kurus INTEGER NOT NULL,
        level INTEGER NOT NULL DEFAULT 1
      )''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        product_name TEXT NOT NULL,
        product_emoji TEXT NOT NULL,
        price_kurus INTEGER NOT NULL,
        paid_kurus INTEGER NOT NULL,
        change_kurus INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL
          REFERENCES transactions(id) ON DELETE CASCADE,
        value_kurus INTEGER NOT NULL,
        count INTEGER NOT NULL,
        direction TEXT NOT NULL CHECK (direction IN ('verilen', 'alinan'))
      )''');
    await db.execute('''
      CREATE TABLE progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        level INTEGER NOT NULL,
        price_kurus INTEGER NOT NULL,
        correct INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )''');

    // Başlangıç verileri
    final batch = db.batch();
    for (final p in _seedProducts) {
      batch.insert('products', p.toMap()..remove('id'));
    }
    _defaultSettings.forEach((key, value) {
      batch.insert('settings', {'key': key, 'value': value});
    });
    await batch.commit(noResult: true);
  }

  static const _seedProducts = [
    Product(name: 'Elma', emoji: '🍎', priceKurus: 500, level: 1),
    Product(name: 'Su', emoji: '💧', priceKurus: 1000, level: 1),
    Product(name: 'Ekmek', emoji: '🍞', priceKurus: 1500, level: 1),
    Product(name: 'Meyve Suyu', emoji: '🧃', priceKurus: 2000, level: 1),
    Product(name: 'Defter', emoji: '📒', priceKurus: 3500, level: 2),
    Product(name: 'Süt', emoji: '🥛', priceKurus: 4500, level: 2),
    Product(name: 'Muz', emoji: '🍌', priceKurus: 6000, level: 2),
    Product(name: 'Oyuncak', emoji: '🧸', priceKurus: 15000, level: 2),
    Product(name: 'Simit', emoji: '🥯', priceKurus: 1750, level: 3),
    Product(name: 'Dondurma', emoji: '🍦', priceKurus: 2750, level: 3),
  ];

  static const _defaultSettings = {
    'level': '1',
    'pin': '1234',
    'speech_rate': '0.42',
    'pitch': '1.1',
    'sound': '1',
  };

  // ---------------- Cüzdan ----------------

  Future<Map<int, int>> getWallet() async {
    final db = await database;
    final rows = await db.query('wallet', where: 'count > 0');
    return {for (final r in rows) r['value_kurus'] as int: r['count'] as int};
  }

  Future<void> setWalletCount(int valueKurus, int count) async {
    final db = await database;
    if (count <= 0) {
      await db.delete(
        'wallet',
        where: 'value_kurus = ?',
        whereArgs: [valueKurus],
      );
    } else {
      await db.insert('wallet', {
        'value_kurus': valueKurus,
        'count': count,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> clearWallet() async {
    final db = await database;
    await db.delete('wallet');
  }

  /// Alışverişi tek bir veritabanı işleminde (transaction) kaydeder:
  /// verilen paralar cüzdandan düşer, para üstü cüzdana eklenir,
  /// alışveriş geçmişe yazılır. Bir adım hata verirse hiçbiri kaydedilmez.
  Future<void> savePurchase({
    required String productName,
    required String productEmoji,
    required PaymentPlan plan,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      Future<int> countOf(int value) async {
        final rows = await txn.query(
          'wallet',
          where: 'value_kurus = ?',
          whereArgs: [value],
        );
        return rows.isEmpty ? 0 : rows.first['count'] as int;
      }

      Future<void> setCount(int value, int count) async {
        if (count <= 0) {
          await txn.delete(
            'wallet',
            where: 'value_kurus = ?',
            whereArgs: [value],
          );
        } else {
          await txn.insert('wallet', {
            'value_kurus': value,
            'count': count,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      for (final e in plan.pay.entries) {
        final current = await countOf(e.key);
        if (current < e.value) {
          throw StateError('Cüzdanda yeterli ${e.key} kuruşluk para yok');
        }
        await setCount(e.key, current - e.value);
      }
      for (final e in plan.change.entries) {
        await setCount(e.key, await countOf(e.key) + e.value);
      }

      final record = TransactionRecord(
        createdAt: DateTime.now(),
        productName: productName,
        productEmoji: productEmoji,
        priceKurus: plan.priceKurus,
        paidKurus: plan.paidKurus,
        changeKurus: plan.changeKurus,
      );
      final id = await txn.insert('transactions', record.toMap()..remove('id'));
      for (final e in plan.pay.entries) {
        await txn.insert('transaction_items', {
          'transaction_id': id,
          'value_kurus': e.key,
          'count': e.value,
          'direction': 'verilen',
        });
      }
      for (final e in plan.change.entries) {
        await txn.insert('transaction_items', {
          'transaction_id': id,
          'value_kurus': e.key,
          'count': e.value,
          'direction': 'alinan',
        });
      }
    });
  }

  // ---------------- Ürünler ----------------

  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'level, price_kurus');
    return rows.map(Product.fromMap).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert('products', product.toMap()..remove('id'));
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Geçmiş ----------------

  Future<List<TransactionRecord>> getTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'id DESC');
    return rows.map(TransactionRecord.fromMap).toList();
  }

  /// Bir alışverişte verilen ('verilen') veya alınan ('alinan') paralar.
  Future<Map<int, int>> getTransactionItems(
    int transactionId,
    String direction,
  ) async {
    final db = await database;
    final rows = await db.query(
      'transaction_items',
      where: 'transaction_id = ? AND direction = ?',
      whereArgs: [transactionId, direction],
    );
    return {for (final r in rows) r['value_kurus'] as int: r['count'] as int};
  }

  Future<void> clearTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  // ---------------- İlerleme ----------------

  Future<void> addProgress({
    required int level,
    required int priceKurus,
    required bool correct,
  }) async {
    final db = await database;
    await db.insert('progress', {
      'created_at': DateTime.now().toIso8601String(),
      'level': level,
      'price_kurus': priceKurus,
      'correct': correct ? 1 : 0,
    });
  }

  /// (toplam soru, ilk denemede doğru) sayıları.
  Future<({int total, int correct})> getProgressStats() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total, COALESCE(SUM(correct), 0) AS correct FROM progress',
    );
    final row = rows.first;
    return (total: row['total'] as int, correct: row['correct'] as int);
  }

  Future<void> clearProgress() async {
    final db = await database;
    await db.delete('progress');
  }

  // ---------------- Ayarlar ----------------

  Future<Map<String, String>> getSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    return {
      ..._defaultSettings,
      for (final r in rows) r['key'] as String: r['value'] as String,
    };
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
