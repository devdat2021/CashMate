import 'package:budget/models/category.dart';
import 'package:flutter/material.dart';
import 'package:budget/utils/database_helper.dart';

class Category_card extends StatelessWidget {
  final Category cat;
  final VoidCallback onLongPress;

  const Category_card({
    super.key,
    required this.cat,
    required this.onLongPress,
  });
  Color getProgressColor(double value) {
    if (value < 0.4) return Colors.green;
    if (value < 0.7) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color.fromARGB(255, 247, 236, 139),
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        onLongPress: onLongPress,
        leading: cat.iconWidget,
        title: Text(cat.name, style: const TextStyle(fontSize: 18)),
        trailing: (cat.budget == 0.0 || cat.type == 'income')
            ? null
            : SizedBox(
                //fixed column width
                width: 100,
                child: FutureBuilder<double>(
                  future: DatabaseHelper.instance.CatExpense(
                    cat.id!,
                    DateTime.now(),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator(color: Colors.grey);
                    }

                    final double spent = snapshot.data ?? 0.0;
                    final double progress = (spent / cat.budget).clamp(
                      0.0,
                      1.0,
                    );

                    // 3. Determine Color
                    final Color barColor = getProgressColor(progress);

                    // 4. Show the UI
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${cat.budget.toStringAsFixed(0)}', // Removed decimal for space
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          minHeight: 6.0,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        // Text("₹${spent.toStringAsFixed(0)}", style: TextStyle(fontSize: 10)),
                      ],
                    );
                  },
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
    _loadAccounts();
  }

  void _showCategoryOptions(Category category) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Category'),
              onTap: () {
                Navigator.pop(context);
                _showEditCategoryDialog(category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Category'),
              onTap: () async {
                Navigator.pop(context);
                await DatabaseHelper.instance.deleteCategory(category.id!);
                _loadAccounts();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final TextEditingController nameController = TextEditingController(
      text: category.name,
    );
    final TextEditingController budgetController = TextEditingController(
      text: category.budget.toString(),
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    type = category.type;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 21, 21, 21),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
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
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        selectedBackgroundColor: Color.fromARGB(
                          255,
                          247,
                          236,
                          139,
                        ),
                        foregroundColor: Colors.black,
                        selectedForegroundColor: const Color.fromARGB(
                          255,
                          38,
                          36,
                          36,
                        ),
                      ),
                      selected: {type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setDialogState(() {
                          type = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    if (type == 'expense') ...[
                      Text(
                        'Monthly Budget (optional)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: budgetController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 21, 21, 21),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0,
                            ),
                          ),
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                  child: const Text("Update"),
                  onPressed: () async {
                    final updatedCat = Category(
                      id: category.id,
                      name: nameController.text,
                      type: type,
                      iconCode: category.iconCode,

                      budget: double.tryParse(budgetController.text) ?? 0.0,
                    );

                    await DatabaseHelper.instance.updateCategory(
                      updatedCat.toMap(),
                    );
                    _loadAccounts();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController budgetController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    type = 'expense';

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 21, 21, 21),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
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
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Colors.grey, // Unselected background
                        selectedBackgroundColor: Color.fromARGB(
                          255,
                          247,
                          236,
                          139,
                        ), // Selected background
                        foregroundColor: Colors.black, // Unselected text/icon
                        selectedForegroundColor: const Color.fromARGB(
                          255,
                          38,
                          36,
                          36,
                        ), // Selected text/icon
                      ),
                      selected: {type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setDialogState(() {
                          type = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    //const Text('Budget (Optional)'),
                    if (type == 'expense') ...[
                      Text(
                        'Monthly Budget (optional)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: budgetController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 21, 21, 21),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0,
                            ),
                          ),
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                              budget: double.parse(budgetController.text),
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

      setState(() {
        _incomeCategories = loadedinc;
        _expenseCategories = loadedexp;
        _isLoading = false;
      });
    } catch (e) {
      //print("Database Loading Error: $e"); //for debugging purpose :)
      setState(() {
        _isLoading = false;
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 92, 92, 92),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline),
                backgroundColor: const Color.fromARGB(255, 231, 244, 174),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            "\t\t\tIncome",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            height: 10,
          ),
          //Income categories
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _incomeCategories.length,
            itemBuilder: (context, index) {
              return Category_card(
                cat: _incomeCategories[index],
                onLongPress: () =>
                    _showCategoryOptions(_incomeCategories[index]),
              );
            },
          ),

          const SizedBox(height: 25),
          const Text(
            "\t\t\tExpense",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            height: 10,
          ),

          //Expense categories
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _expenseCategories.length,
            itemBuilder: (context, index) {
              return Category_card(
                cat: _expenseCategories[index],
                onLongPress: () =>
                    _showCategoryOptions(_expenseCategories[index]),
              );
            },
          ),

          const SizedBox(height: 30),
          Center(
            child: FloatingActionButton.extended(
              onPressed: () => _showAddCategoryDialog(),
              label: const Text(
                'Add Category',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 92, 92, 92),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              backgroundColor: const Color.fromARGB(255, 231, 244, 174),
            ),
          ),
          const SizedBox(height: 40), // Extra bottom padding for safe scrolling
        ],
      ),
    );
  }
}
