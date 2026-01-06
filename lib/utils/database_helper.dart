import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database; //variable to hold the actual database connection

  DatabaseHelper._privateConstructor();

  // Getter for the database. Initializes it if it's null.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initializing
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cashmate.db');

    return await openDatabase(
      path,
      version: 1, // Must be an integer
      onCreate: _onCreate, //if db not exist
    );
  }

  //Table definitions s

  Future _onCreate(Database db, int version) async {
    // 1. ACCOUNTS Table
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        current_balance REAL NOT NULL,
        icon_code INTEGER NOT NULL DEFAULT 57408
      )
    ''');

    // 2. CATEGORIES Table
    await db.execute('''
  CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL,
    budget_limit REAL DEFAULT 0.0,
    icon_code INTEGER NOT NULL DEFAULT 59473 -- 59473 is the code point for Icons.category
  )
''');

    // 3. TRANSACTIONS Table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date INTEGER NOT NULL, 
        transaction_type TEXT NOT NULL, 
        note TEXT,
        account_id INTEGER NOT NULL,
        category_id INTEGER,
        related_transaction_id INTEGER,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  //Insert a new account
  Future<int> insertAccount(Map<String, dynamic> account) async {
    Database db = await instance.database;
    return await db.insert('accounts', account);
  }

  //Query all accounts
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    Database db = await instance.database;
    return await db.query('accounts');
  }

  //Insert a new account
  Future<int> insertCategory(Map<String, dynamic> category) async {
    Database db = await instance.database;
    return await db.insert('categories', category);
  }

  /// R: Queries only categories marked as 'income'.
  Future<List<Map<String, dynamic>>> getIncomeCategories() async {
    Database db = await instance.database;
    return await db.query(
      'categories',
      where: 'type = ?', // The SQL WHERE clause
      whereArgs: ['income'], // The value to match
      orderBy: 'name ASC',
    );
  }

  /// R: Queries only categories marked as 'expense'.
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    Database db = await instance.database;
    return await db.query(
      'categories',
      where: 'type = ?', // The SQL WHERE clause
      whereArgs: ['expense'], // The value to match
      orderBy: 'name ASC',
    );
  }

  // //Fetch all transactions
  // Future<List<Map<String, dynamic>>> getAllTransactions() async {
  //   Database db = await instance.database;
  //   return await db.query('transactions', orderBy: 'id DESC');
  // }
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    Database db = await instance.database;

    // We select ALL transaction fields (t.*)
    // AND specific category fields (c.name, c.iconCode)
    // We use LEFT JOIN so that even if a transaction has NO category, it still shows up.
    return await db.rawQuery('''
    SELECT 
      t.*, 
      c.name AS category_name, 
      c.icon_code AS category_icon
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    ORDER BY t.date DESC
  ''');
  }

  /// Inserts a transaction and updates the associated account's balance in one atomic operation.
  /// NOTE: For transfers, call this logic twice within an external transaction.
  Future<int> saveNewTransaction(
    Map<String, dynamic> transactionData,
    double amount,
    int accountId,
  ) async {
    Database db = await instance.database;

    // Check if the transaction is an expense or income to determine the balance change
    String type = transactionData['transaction_type'];
    double balanceChange = (type == 'expense') ? -amount : amount;

    return await db.transaction((txn) async {
      int transactionId = await txn.insert('transactions', transactionData);

      await txn.rawUpdate(
        'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
        [balanceChange, accountId],
      );

      return transactionId;
    });
  }

  //to calculate total income and expense throughout
  Future<Map<String, double>> getTotals() async {
    final db = await instance.database;

    final result = await db.rawQuery('''
    SELECT 
      SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) as income,
      SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END) as expense
    FROM transactions
  ''');

    final row = result.first;

    return {
      'income': (row['income'] as num?)?.toDouble() ?? 0.0,
      'expense': (row['expense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<Map<String, double>> getMonthlyTotals() async {
    final db = await instance.database;
    final now = DateTime.now();

    //This was AI logic not mine but simple
    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    ).millisecondsSinceEpoch;

    final endOfMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    ).millisecondsSinceEpoch;

    final result = await db.rawQuery(
      '''
    SELECT 
      SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) as income,
      SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END) as expense
    FROM transactions
    WHERE date >= ? AND date < ?
  ''',
      [startOfMonth, endOfMonth],
    );

    final row = result.first;

    return {
      'income': (row['income'] as num?)?.toDouble() ?? 0.0,
      'expense': (row['expense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<Map<String, dynamic>?> getCategoryInfo(int id) async {
    Database db = await instance.database;
    final results = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  // You can remove the generic insert/queryAll methods now that you have specific ones.
  // Future<int> insert(String table, Map<String, dynamic> row) async { ... }
  // Future<List<Map<String, dynamic>>> queryAll(String table) async { ... }
}
