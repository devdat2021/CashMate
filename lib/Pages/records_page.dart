import 'package:flutter/material.dart';
import 'package:budget/models/transaction.dart';
import 'package:budget/utils/database_helper.dart';
import 'package:intl/intl.dart';

class Transaction_card extends StatelessWidget {
  final Transaction transaction;

  const Transaction_card({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.transactionType == 'expense';
    final color = isExpense ? Colors.red : Colors.green;
    final formattedDate = DateFormat('MMM d, h:mm a').format(transaction.date);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(
            alpha: 0.3,
          ), // Light background circle
          child: Icon(
            transaction.iconWidget.icon, // reuse the same IconData
            color: const Color.fromARGB(255, 53, 52, 52),
          ),
        ),
        //leading:transaction.iconWidget ?? Icon(IconData(59473, fontFamily: 'MaterialIcons')),
        title: Text(
          transaction.categoryName,
          style: const TextStyle(fontSize: 18),
        ),
        subtitle: Text(
          formattedDate,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          '₹${transaction.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class Records extends StatefulWidget {
  const Records({super.key});

  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records> {
  Map<String, double> _totals = {'income': 0.0, 'expense': 0.0};
  List<Transaction> transactions = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  void _loadTotals() async {
    final totals = await DatabaseHelper.instance.getMonthlyTotals(
      _selectedDate,
    );
    setState(() {
      _totals = totals;
    });
  }

  void _loadTransactions() async {
    try {
      List<Map<String, dynamic>> raw_transactions = await DatabaseHelper
          .instance
          .getAllTransactions(_selectedDate);
      List<Transaction> loadedAccounts = raw_transactions.map((map) {
        return Transaction.fromMap(map);
      }).toList();

      setState(() {
        transactions = loadedAccounts;
        _isLoading = false;
      });
    } catch (e) {
      // Crucial: Print any database error to the console!
      print("Database Loading Error: $e");
      setState(() {
        _isLoading = false; // Stop loading even if there's an error
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTotals();
    _loadTransactions();
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + monthsToAdd,
        1,
      );
    });
    _loadTotals();
    _loadTransactions(); // Refresh data for the new month
  }

  @override
  Widget build(BuildContext context) {
    String monthName = DateFormat('MMMM').format(_selectedDate);
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Ensures card takes full width
      children: [
        Padding(
          // Padding only needed on the outside edges
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Pushes arrows to the edges
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1), // Go back 1 month
                        tooltip: 'Previous Month',
                      ),

                      Text(
                        "$monthName Summary", // Removed "Month" to save space, or keep it if you prefer
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1), // Go forward 1 month
                        tooltip: 'Next Month',
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Expense Widget
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "Expense",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 49, 47, 47),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_totals['expense']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Vertical Divider
                      const SizedBox(
                        height: 40,
                        child: VerticalDivider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),

                      // Income Widget
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "Income",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 49, 47, 47),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_totals['income']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator()) // Show spinner
              : transactions.isEmpty
              ? const Center(child: Text("No records for this month"))
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return Transaction_card(transaction: transactions[index]);
                  },
                ),
        ),
      ],
    );
  }
}
