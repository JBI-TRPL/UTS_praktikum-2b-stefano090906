import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pos_app/models/product_model.dart';
import 'package:pos_app/models/transaction_model.dart'
    as model; // Ditambahkan prefix 'model'
import 'package:pos_app/models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullname TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        totalAmount INTEGER NOT NULL,
        transactionDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_details(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        priceAtTransaction INTEGER NOT NULL,
        FOREIGN KEY (transactionId) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');
  }

  Future<model.Transaction?> getTransactionById(int id) async {
    final db = await instance.database;
    final results = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return model.Transaction.fromMap(results.first);
    }
    return null;
  }

  // User Operations
  Future<User?> login(String username, String password) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (res.isNotEmpty) {
      return User.fromMap(res.first);
    }
    return null;
  }

  Future<int> register(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return User.fromMap(res.first);
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (res.isNotEmpty) return User.fromMap(res.first);
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Product Operations
  Future<int> createProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'type, name');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product> getProductById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      columns: ['id', 'name', 'price', 'type'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction Operations
  // GUNAKAN KODE INI
  Future<int> createTransaction(Map<int, int> cart, int totalAmount) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final transactionId = await txn.insert('transactions', {
        'totalAmount': totalAmount,
        'transactionDate': DateTime.now().toIso8601String(),
      });

      for (var entry in cart.entries) {
        final productId = entry.key;
        final quantity = entry.value;

        // SOLUSI: Lakukan query produk langsung menggunakan objek 'txn'
        final productData = await txn.query(
          'products',
          columns: ['price'],
          where: 'id = ?',
          whereArgs: [productId],
        );

        final price = productData.first['price'] as int;

        await txn.insert('transaction_details', {
          'transactionId': transactionId,
          'productId': productId,
          'quantity': quantity,
          'priceAtTransaction': price,
        });
      }
      return transactionId;
    });
  }

  // Menggunakan prefix 'model.'
  Future<List<model.Transaction>> getTransactions() async {
    final db = await instance.database;
    final result =
        await db.query('transactions', orderBy: 'transactionDate DESC');
    return result.map((json) => model.Transaction.fromMap(json)).toList();
  }

  // Menggunakan prefix 'model.'
  Future<List<model.TransactionDetail>> getTransactionDetails(
      int transactionId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
          SELECT td.quantity, td.priceAtTransaction, p.name 
          FROM transaction_details td
          JOIN products p ON td.productId = p.id
          WHERE td.transactionId = ?
      ''', [transactionId]);

    return result.map((json) => model.TransactionDetail.fromMap(json)).toList();
  }
}
