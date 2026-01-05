import 'package:flutter/material.dart';
import 'package:budget/utils/database_helper.dart';
import 'package:budget/models/account.dart';
import 'package:budget/models/category.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  // Controllers for text fields
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // State variables
  String _transactionType = 'expense'; // Default to expense
  DateTime _selectedDate = DateTime.now();

  // Lists to hold database data
  List<Account> _accounts = [];
  List<Category> _categories = [];

  // Selected items
  Account? _selectedAccount;
  Category? _selectedCategory;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fetch Accounts and Categories from DB
  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;

    // 1. Fetch Accounts
    final accountMaps = await db.getAllAccounts();
    final accounts = accountMaps.map((e) => Account.fromMap(e)).toList();

    // 2. Fetch Categories (based on current type)
    await _loadCategories(db);

    if (mounted) {
      setState(() {
        _accounts = accounts;
        // Auto-select first account if available
        if (_accounts.isNotEmpty) {
          _selectedAccount = _accounts[0];
        }
        _isLoading = false;
      });
    }
  }

  // Helper to switch categories when type changes (Expense <-> Income)
  Future<void> _loadCategories(DatabaseHelper db) async {
    List<Map<String, dynamic>> categoryMaps;
    if (_transactionType == 'expense') {
      categoryMaps = await db.getExpenseCategories();
    } else {
      categoryMaps = await db.getIncomeCategories();
    }

    setState(() {
      _categories = categoryMaps.map((e) => Category.fromMap(e)).toList();
      // Reset selected category because the list changed
      _selectedCategory = null;
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories[0];
      }
    });
  }

  // Date Picker
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Save to Database
  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount and select an account'),
        ),
      );
      return;
    }

    final double amount = double.parse(_amountController.text);

    // Create the map to send to DatabaseHelper
    Map<String, dynamic> row = {
      'amount': amount,
      'transaction_type': _transactionType,
      'date': _selectedDate.millisecondsSinceEpoch,
      'note': _noteController.text,
      'account_id': _selectedAccount!.id,
      'category_id': _selectedCategory?.id, // Nullable
    };

    // Use your existing helper function
    await DatabaseHelper.instance.saveNewTransaction(
      row,
      amount,
      _selectedAccount!.id!,
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _transactionType == 'expense';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: isExpense ? Colors.redAccent : Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. Type Toggle (Expense / Income)
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'income', label: Text('Income')),
                    ],
                    selected: {_transactionType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _transactionType = newSelection.first;
                        _loadCategories(DatabaseHelper.instance);
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Amount Input
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  //Date Picker
                  ListTile(
                    title: Text(
                      "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  //Account Dropdown
                  DropdownButtonFormField<Account>(
                    value: _selectedAccount,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                    items: _accounts.map((Account account) {
                      return DropdownMenuItem<Account>(
                        value: account,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (Account? newValue) {
                      setState(() {
                        _selectedAccount = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  //Category Dropdown
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((Category category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              IconData(
                                category.iconCode,
                                fontFamily: 'MaterialIcons',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 6. Note Input
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 7. Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExpense
                            ? Colors.redAccent
                            : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saveTransaction,
                      child: const Text(
                        'SAVE TRANSACTION',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
