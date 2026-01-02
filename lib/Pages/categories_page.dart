import 'package:budget/models/category.dart';
import 'package:flutter/material.dart';
import 'package:budget/utils/database_helper.dart';

// class AddCategoryDialog extends StatefulWidget {
//   const AddCategoryDialog({super.key});

//   @override
//   State<AddCategoryDialog> createState() => _AddCategoryDialogState();
// }

// class _AddCategoryDialogState extends State<AddCategoryDialog> {
//   String type = 'expense';
//   // Define controllers for the input fields
//   final TextEditingController nameController = TextEditingController();
//   // final TextEditingController initialBalanceController =TextEditingController();
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add New Category'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           TextFormField(
//             controller: nameController,
//             decoration: const InputDecoration(labelText: 'Category Name'),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter a name.';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           const Text('Type'),
//           const SizedBox(height: 5),
//           SegmentedButton<String>(
//             segments: const [
//               ButtonSegment(value: 'expense', label: Text('Expense')),
//               ButtonSegment(value: 'income', label: Text('Income')),
//             ],
//             selected: {type},
//             onSelectionChanged: (newSelection) {
//               setState(() {
//                 type = newSelection.first;
//               });
//             },
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.pop(context, type); // return selected type
//           },
//           child: const Text('Save'),
//         ),
//       ],
//     );
//   }
// }

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

  // void _showAddCategoryDialog() async {
  //   final selectedType = await showDialog<String>(
  //     context: context,
  //     builder: (_) => const AddCategoryDialog(),
  //   );

  //   if (selectedType != null) {
  //     setState(() {
  //       type = selectedType;
  //     });
  //   }
  // }

  void _showAddCategoryDialog() {
    // Define controllers for the input fields
    final TextEditingController nameController = TextEditingController();
    // final TextEditingController initialBalanceController =TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: Form(
            //Form for easy validation
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, //To keep the dialog compact
              children: <Widget>[
                // Account Name Input
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Type'), const SizedBox(height: 5),
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment(value: 'expense', label: Text('Expense')),
                    ButtonSegment(value: 'income', label: Text('Income')),
                  ],
                  selected: {type},
                  // onSelectionChanged: (newSelection) {
                  //   dialogSetState(() {
                  //     // ✅ THIS rebuilds the dialog
                  //     type = newSelection.first;
                  //   });
                  // },
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      type = newSelection.first;
                    });
                  },
                ),
                // Initial Balance Input
                // TextFormField(
                //   controller: initialBalanceController,
                //   decoration: const InputDecoration(
                //     labelText: 'Initial Balance',
                //   ),
                //   keyboardType: TextInputType.number, // Ensure numeric input
                //   validator: (value) {
                //     if (value == null || double.tryParse(value) == null) {
                //       return 'Please enter a valid number.';
                //     }
                //     return null;
                //   },
                // ),
              ],
            ),
          ),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            // Save Button
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // 1. Get validated values
                  final String name = nameController.text;
                  final String Cat_type = type;
                  // final double balance = double.parse(
                  //   initialBalanceController.text,
                  // );

                  // 2. Call your database logic (e.g., _saveNewAccount)
                  // _saveNewAccount(name, balance);
                  setState(() {
                    if (type == "expense") {
                      _expenseCategories.add(
                        Category(
                          name: name,
                          iconCode: Icons.monetization_on_rounded.codePoint,
                          type: Cat_type,
                        ),
                      );
                      DatabaseHelper.instance.insertAccount(
                        _expenseCategories.last.toMap(),
                      );
                    }
                    if (type == "income") {
                      _expenseCategories.add(
                        Category(
                          name: name,
                          iconCode: Icons.monetization_on_rounded.codePoint,
                          type: Cat_type,
                        ),
                      );
                      DatabaseHelper.instance.insertAccount(
                        _expenseCategories.last.toMap(),
                      );
                    }
                  });

                  // 3. Close the dialog
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
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

    return Column();
  }
}
