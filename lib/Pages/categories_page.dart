import 'package:budget/models/category.dart';
import 'package:flutter/material.dart';
import 'package:budget/utils/database_helper.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // Start loading data when the widget is created
  }

  void _loadAccounts() async {
    try {
      //raw expense category
      List<Map<String, dynamic>> rawExpense = await DatabaseHelper.instance
          .getExpenseCategories();

      //Converted to categories class format
      List<Category> loadedexp = rawExpense.map((map) {
        return Category.fromMap(map);
      }).toList();

      List<Map<String, dynamic>> rawIncome = await DatabaseHelper.instance
          .getIncomeCategories();
      List<Category> loadedinc = rawIncome.map((map) {
        return Category.fromMap(map);
      }).toList();

      // 3. Update the UI state
      setState(() {
        _incomeCategories = loadedinc;
        _expenseCategories = loadedexp;
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
  Widget build(BuildContext context) {
    return const Text("Categories bvc");
  }
}
