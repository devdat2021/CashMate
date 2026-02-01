// import 'package:flutter/material.dart';
// import 'package:budget/models/account.dart';
// import 'package:budget/models/transaction.dart';
// import 'package:budget/models/category.dart';
// import 'package:budget/utils/database_helper.dart';

import 'package:flutter/material.dart';
import 'package:budget/utils/database_helper.dart';
import 'package:intl/intl.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense'; // 'expense' or 'income'
  List<Map<String, dynamic>> _breakdown = [];
  double _totalAmount = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    // 1. Fetch data using your existing helper function
    final data = await DatabaseHelper.instance.getCategoryBreakdown(
      _selectedDate,
      _type,
    );

    // 2. Calculate the total (so we can show percentages)
    double total = 0.0;
    for (var item in data) {
      total += (item['total'] as num).toDouble();
    }

    if (mounted) {
      setState(() {
        _breakdown = data;
        _totalAmount = total;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + monthsToAdd,
        1,
      );
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == 'expense';
    final color = isExpense ? Colors.red : Colors.green;
    String monthName = DateFormat('MMMM yyyy').format(_selectedDate);

    return Scaffold(
      // 1. TOP BAR: Month Selector
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              monthName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 2. TYPE TOGGLE & TOTAL
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Toggle Button
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense')),
                    ButtonSegment(value: 'income', label: Text('Income')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _type = newSelection.first;
                    });
                    _loadData();
                  },
                  style: ButtonStyle(
                    // Optional: Customize colors if you want
                  ),
                ),
                const SizedBox(height: 20),

                // Big Total Amount
                Text(
                  "Total $_type",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  "₹${_totalAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // 3. THE LIST (The Analysis)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _breakdown.isEmpty
                ? Center(
                    child: Text(
                      "No $_type records this month",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _breakdown.length,
                    itemBuilder: (context, index) {
                      final item = _breakdown[index];
                      final amount = (item['total'] as num).toDouble();
                      final name = item['name'] as String;
                      final iconCode = item['icon_code'] as int;

                      // Calculate Percentage (0.0 to 1.0)
                      final double percentage = _totalAmount == 0
                          ? 0
                          : (amount / _totalAmount);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            // Row with Icon, Name, and Amount
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconData(
                                      iconCode,
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  "₹${amount.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // The Progress Bar
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${(percentage * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
