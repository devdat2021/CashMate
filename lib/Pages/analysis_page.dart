// import 'package:flutter/material.dart';
// import 'package:budget/models/account.dart';
// import 'package:budget/models/transaction.dart';
// import 'package:budget/models/category.dart';
// import 'package:budget/utils/database_helper.dart';

import 'package:flutter/material.dart';
import 'package:budget/utils/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense'; // 'expense' or 'income'
  List<Map<String, dynamic>> _breakdown = [];
  List<Map<String, dynamic>> _monthlyTrends = [];
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

    // 2. Fetch monthly trends for the last 6 months
    final trends = await DatabaseHelper.instance.getMonthlyTrends(6);

    // 3. Calculate the total (so we can show percentages)
    double total = 0.0;
    for (var item in data) {
      total += (item['total'] as num).toDouble();
    }

    if (mounted) {
      setState(() {
        _breakdown = data;
        _monthlyTrends = trends;
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

  // Build pie chart for category breakdown
  Widget _buildPieChart() {
    if (_breakdown.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final isExpense = _type == 'expense';
    final List<Color> colors = isExpense
        ? [
            Colors.red.shade400,
            Colors.red.shade300,
            Colors.red.shade200,
            Colors.red.shade100,
            Colors.pink.shade300,
            Colors.pink.shade200,
            Colors.pink.shade100,
            Colors.orange.shade300,
          ]
        : [
            Colors.green.shade400,
            Colors.green.shade300,
            Colors.green.shade200,
            Colors.green.shade100,
            Colors.teal.shade300,
            Colors.teal.shade200,
            Colors.teal.shade100,
            Colors.lightGreen.shade300,
          ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _breakdown.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final amount = (item['total'] as num).toDouble();
                final percentage = _totalAmount == 0 ? 0 : (amount / _totalAmount) * 100;
                
                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: amount,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _breakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final name = item['name'] as String;
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // Build bar chart for monthly trends
  Widget _buildBarChart() {
    if (_monthlyTrends.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    double maxY = 0;
    for (var trend in _monthlyTrends) {
      final income = trend['income'] as double;
      final expense = trend['expense'] as double;
      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;
    }
    
    // Add 20% padding to max value
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return Column(
      children: [
        const Text(
          'Monthly Income vs Expense',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = _monthlyTrends[group.x.toInt()]['month'] as DateTime;
                    final monthName = DateFormat('MMM').format(month);
                    final type = rodIndex == 0 ? 'Income' : 'Expense';
                    return BarTooltipItem(
                      '$monthName\n$type: ₹${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= _monthlyTrends.length) {
                        return const Text('');
                      }
                      final month = _monthlyTrends[value.toInt()]['month'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MMM').format(month),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${(value / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 5,
              ),
              borderData: FlBorderData(show: false),
              barGroups: _monthlyTrends.asMap().entries.map((entry) {
                final index = entry.key;
                final trend = entry.value;
                final income = trend['income'] as double;
                final expense = trend['expense'] as double;
                
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: income,
                      color: Colors.green,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: expense,
                      color: Colors.red,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.green, 'Income'),
            const SizedBox(width: 24),
            _buildLegendItem(Colors.red, 'Expense'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
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

                  // 3. PIE CHART - Category Breakdown
                  if (_breakdown.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category Distribution',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPieChart(),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 4. BAR CHART - Monthly Trends
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildBarChart(),
                      ),
                    ),
                  ),

                  // 5. CATEGORY LIST WITH PROGRESS BARS
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _breakdown.isEmpty
                            ? Center(
                                child: Text(
                                  "No $_type records this month",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
