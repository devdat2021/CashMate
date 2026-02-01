import 'package:flutter/material.dart';
import 'package:budget/models/transaction.dart';
import 'package:budget/utils/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:budget/Pages/transaction_page.dart';

class Transaction_card extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  const Transaction_card({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.transactionType == 'expense';
    final color = isExpense ? Colors.red : Colors.green;
    final formattedDate = DateFormat('MMM d, h:mm a').format(transaction.date);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}

class Records extends StatefulWidget {
  const Records({super.key});

  @override
  State<Records> createState() => RecordsState();
}

class RecordsState extends State<Records> {
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

  void refresh() {
    _loadTotals();
    _loadTransactions();
  }

  Future<List<Map<String, dynamic>>> acc_details(int id) async {
    List<Map<String, dynamic>> acc = await DatabaseHelper.instance
        .trans_account(id);
    return acc;
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
      //print("Database Loading Error: $e");
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

  // --- NEW: THE DETAIL WINDOW ---
  void _showTransactionDetails(Transaction t) async {
    final isExpense = t.transactionType == 'expense';
    final color = isExpense ? Colors.red : Colors.green;
    final dateStr = DateFormat('MMMM d, yyyy').format(t.date);
    final timeStr = DateFormat('h:mm a').format(t.date);
    final accDetails = await acc_details(t.accountId);
    if (!mounted) return;

    final account = accDetails.isNotEmpty ? accDetails.first : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(t.iconWidget.icon, color: color, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  t.categoryName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isExpense ? "Expense" : "Income",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                Text(
                  '₹${t.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.calendar_today, "Date", dateStr),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.access_time, "Time", timeStr),
                const SizedBox(height: 10),
                _buildDetailRow(
                  IconData(
                    account?['icon_code'] ?? Icons.account_balance.codePoint,
                    fontFamily: 'MaterialIcons',
                  ),
                  "Account",
                  (account?['name'] ?? 'Unknown'),
                ),
                if (t.note != null && t.note!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.notes, "Note", t.note!),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // EDIT BUTTON
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text(
                        "Edit",
                        style: TextStyle(color: Colors.blue),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionPage(
                              transactionToEdit:
                                  t, // <--- Pass the transaction here!
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadTransactions();
                          _loadTotals();
                        }
                      },
                    ),
                    // DELETE BUTTON
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDeleteTransaction(t.id!);
                      },
                    ),
                  ],
                ),
                // CLOSE BUTTON
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 62, 71, 72),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Close",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper Widget for the Details
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        Text(
          "$label:",
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteTransaction(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Text(
                      "Delete Transaction",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Message
                const Text(
                  "Are you sure?",
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 2.0),
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await DatabaseHelper.instance.deleteTransaction(id);
                        setState(() {
                          _loadTransactions();
                          _loadTotals();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String monthName = DateFormat('MMMM').format(_selectedDate);
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Ensures card takes full width
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: const BorderSide(
                color: Color.fromARGB(255, 247, 236, 139),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                        tooltip: 'Previous Month',
                      ),

                      Text(
                        "$monthName Summary",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
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
                    return Transaction_card(
                      transaction: transactions[index],
                      onTap: () => _showTransactionDetails(transactions[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
