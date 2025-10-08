// lib/utils/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database?
  _database; // Private variable to hold the actual database connection

  // Private constructor to enforce the singleton pattern
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

  //Fetch all transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    Database db = await instance.database;
    return await db.query('transactions', orderBy: 'id DESC');
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
      // 1. Insert the Transaction
      int transactionId = await txn.insert('transactions', transactionData);

      // 2. Update the Account Balance
      // We use the calculated balanceChange (+ for income, - for expense)
      await txn.rawUpdate(
        'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
        [balanceChange, accountId],
      );

      // Return the new ID
      return transactionId;
    });
  }

  // You can remove the generic insert/queryAll methods now that you have specific ones.
  // Future<int> insert(String table, Map<String, dynamic> row) async { ... }
  // Future<List<Map<String, dynamic>>> queryAll(String table) async { ... }
}
