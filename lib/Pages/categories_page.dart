import 'package:budget/models/category.dart';
import 'package:flutter/material.dart';
import 'package:budget/utils/database_helper.dart';

class Category_card extends StatelessWidget {
  final Category cat;
  const Category_card({super.key, required this.cat});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: cat.iconWidget,
        title: Text(cat.name, style: const TextStyle(fontSize: 18)),

        trailing: cat.budget == 0.0
            ? null
            : Text(
                '₹${cat.budget.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  String type = "expense";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // Start loading data when the widget is created
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    type = 'expense';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 1. Wrap the AlertDialog in a StatefulBuilder
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Category'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Type'),
                    const SizedBox(height: 5),
                    SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment(value: 'expense', label: Text('Expense')),
                        ButtonSegment(value: 'income', label: Text('Income')),
                      ],
                      selected: {type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setDialogState(() {
                          type = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final String name = nameController.text;
                      final String catType = type;

                      setState(() {
                        if (catType == "expense") {
                          _expenseCategories.add(
                            Category(
                              name: name,
                              iconCode: Icons.monetization_on_rounded.codePoint,
                              type: catType,
                            ),
                          );
                          DatabaseHelper.instance.insertCategory(
                            _expenseCategories.last.toMap(),
                          );
                        } else if (catType == "income") {
                          _incomeCategories.add(
                            Category(
                              name: name,
                              iconCode: Icons.monetization_on_rounded.codePoint,
                              type: catType,
                            ),
                          );
                          DatabaseHelper.instance.insertCategory(
                            _incomeCategories.last.toMap(),
                          );
                        }
                      });

                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
      print("Database Loading Error: $e"); //for debugging purpose :)
      setState(() {
        _isLoading = false; // Stop loading even if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_incomeCategories.isEmpty && _expenseCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              "No Categories added!",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Center(
              child: FloatingActionButton.extended(
                onPressed: () => _showAddCategoryDialog(),
                label: const Text(
                  'Add Category',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.add_circle_outline),
                backgroundColor: const Color.fromARGB(255, 91, 246, 189),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Makes cards span the width
      children: [
        const SizedBox(height: 20),
        const Text(
          "\t\t\tIncome",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ), // Spacer

        const Divider(
          color: Colors.grey, // Color of the line
          thickness: 1, // How thick the line is
          indent: 20, // Space from the left edge
          endIndent: 20, // Space from the right edge
          height:
              10, // Total vertical space the divider takes up (padding top + bottom)
        ),
        Expanded(
          child: ListView(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _incomeCategories.length,
                itemBuilder: (context, index) {
                  return Category_card(cat: _incomeCategories[index]);
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "\t\t\tExpense",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ), // Spacer
        const Divider(
          color: Colors.grey, // Color of the line
          thickness: 1, // How thick the line is
          indent: 20, // Space from the left edge
          endIndent: 20, // Space from the right edge
          height:
              10, // Total vertical space the divider takes up (padding top + bottom)
        ),
        Expanded(
          child: ListView(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _expenseCategories.length,
                itemBuilder: (context, index) {
                  return Category_card(cat: _expenseCategories[index]);
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
        Center(
          child: FloatingActionButton.extended(
            onPressed: () => _showAddCategoryDialog(),
            label: const Text(
              'Add Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.add_circle_outline),
            backgroundColor: const Color.fromARGB(255, 91, 246, 189),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
