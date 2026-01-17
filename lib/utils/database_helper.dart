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

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

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
      where: 'type = ?',
      whereArgs: ['income'],
      orderBy: 'name ASC',
    );
  }

  /// R: Queries only categories marked as 'expense'.
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    Database db = await instance.database;
    return await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: ['expense'],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions(DateTime date) async {
    Database db = await instance.database;

    final startOfMonth = DateTime(
      date.year,
      date.month,
      1,
    ).millisecondsSinceEpoch;
    final endOfMonth = DateTime(
      date.year,
      date.month + 1,
      1,
    ).millisecondsSinceEpoch;

    return await db.rawQuery(
      '''
      SELECT 
        t.*, 
        c.name AS category_name, 
        c.icon_code AS category_icon
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.date >= ? AND t.date < ?
      ORDER BY t.date DESC
    ''',
      [startOfMonth, endOfMonth],
    );
  }

  /// Inserts a transaction and updates the associated account's balance in one atomic operation.
  ///For transfers call this logic twice within an external transaction.
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

  Future<Map<String, double>> getMonthlyTotals(DateTime date) async {
    final db = await instance.database;
    //This was AI logic not mine but simple
    final startOfMonth = DateTime(
      date.year,
      date.month,
      1,
    ).millisecondsSinceEpoch;

    final endOfMonth = DateTime(
      date.year,
      date.month + 1,
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

  //function to fetch all income/expense categories along with the total money based on the given month
  Future<List<Map<String, dynamic>>> getCategoryBreakdown(
    DateTime month,
    String type,
  ) async {
    final db = await instance.database;

    // Calculate start and end of the selected month
    final start = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final end = DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;

    // Query: Join Transactions with Categories
    // Filter by: Date Range AND Transaction Type
    // Group by: Category
    return await db.rawQuery(
      '''
      SELECT 
        c.name, 
        c.icon_code, 
        SUM(t.amount) as total 
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.transaction_type = ? 
        AND t.date >= ? 
        AND t.date < ?
      GROUP BY t.category_id 
      ORDER BY total DESC
    ''',
      [type, start, end],
    );
  }

  //function to fetch all accounts along with their expenses and income throughout a given month
  Future<List<Map<String, dynamic>>> getAccountBreakdown(
    DateTime month,
    String type,
  ) async {
    final db = await instance.database;

    final start = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final end = DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;

    // Query: Join Transactions with Accounts
    return await db.rawQuery(
      '''
      SELECT 
        a.name, 
        a.icon_code, 
        SUM(t.amount) as total 
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.transaction_type = ? 
        AND t.date >= ? 
        AND t.date < ?
      GROUP BY t.account_id 
      ORDER BY total DESC
    ''',
      [type, start, end],
    );
  }

  // --- ACCOUNT OPERATIONS ---
  Future<int> updateAccount(Map<String, dynamic> account) async {
    Database db = await instance.database;
    return await db.update(
      'accounts',
      account,
      where: 'id = ?',
      whereArgs: [account['id']],
    );
  }

  Future<int> deleteAccount(int id) async {
    Database db = await instance.database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCategory(Map<String, dynamic> category) async {
    Database db = await instance.database;
    return await db.update(
      'categories',
      category,
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  Future<int> deleteCategory(int id) async {
    Database db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> trans_account(int id) async {
    Database db = await instance.database;
    return await db.rawQuery(
      "SELECT name, icon_code from accounts where id=? ",
      [id],
    );
  }
}
