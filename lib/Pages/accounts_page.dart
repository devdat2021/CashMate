import 'package:flutter/material.dart';
import 'package:budget/models/account.dart';
import 'package:budget/utils/database_helper.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onLongPress;
  const AccountCard({
    super.key,
    required this.account,
    required this.onLongPress,
  });

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
        leading: account.iconWidget,
        title: Text(account.name, style: const TextStyle(fontSize: 18)),
        trailing: Text(
          '₹${account.balance.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class Accounts extends StatefulWidget {
  const Accounts({super.key});

  @override
  State<Accounts> createState() => _AccountsState();
}

class _AccountsState extends State<Accounts> {
  List<Account> accounts = [];
  bool _isLoading = true; //data loading verification
  Map<String, double> _totals = {'income': 0.0, 'expense': 0.0};

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // Start loading data when the widget is created
    _loadTotals();
  }

  //fetching data from the database
  void _loadAccounts() async {
    try {
      //raw data from the database
      List<Map<String, dynamic>> rawData = await DatabaseHelper.instance
          .getAllAccounts();

      //Convert raw maps into a List of Account objects
      List<Account> loadedAccounts = rawData.map((map) {
        return Account.fromMap(map);
      }).toList();

      // 3. Update the UI state
      setState(() {
        accounts = loadedAccounts;
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

  double _balance() {
    double sum = 0;
    for (var i = 0; i < accounts.length; i++) {
      sum += accounts[i].balance;
    }
    return sum;
  }

  void _loadTotals() async {
    final totals = await DatabaseHelper.instance.getTotals();
    setState(() {
      _totals = totals;
    });
  }

  void _showAddAccountDialog() {
    // Define controllers for the input fields
    final TextEditingController nameController = TextEditingController();
    final TextEditingController initialBalanceController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Account'),
          content: Form(
            //Form for easy validation
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, //To keep the dialog compact
              children: <Widget>[
                // Account Name Input
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Account Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Initial Balance Input
                TextFormField(
                  controller: initialBalanceController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Balance',
                  ),
                  keyboardType: TextInputType.number, // Ensure numeric input
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null) {
                      return 'Please enter a valid number.';
                    }
                    return null;
                  },
                ),
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
                  final double balance = double.parse(
                    initialBalanceController.text,
                  );

                  // 2. Call your database logic (e.g., _saveNewAccount)
                  // _saveNewAccount(name, balance);
                  setState(() {
                    accounts.add(
                      Account(name: name, balance: balance, iconCode: 57408),
                    );
                    DatabaseHelper.instance.insertAccount(
                      accounts.last.toMap(),
                    );
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

  // Show Options (Edit / Delete)
  void _showAccountOptions(Account account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Account'),
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  _showEditAccountDialog(account); // Open Edit Dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Account'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(account.id!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Delete Confirmation
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text(
          "This will delete the account and all its transactions.",
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () async {
              await DatabaseHelper.instance.deleteAccount(id);
              _loadAccounts(); // Refresh list
              _loadTotals(); // Refresh totals
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // Edit Dialog (Pre-filled)
  void _showEditAccountDialog(Account account) {
    final nameController = TextEditingController(text: account.name);
    final balanceController = TextEditingController(
      text: account.balance.toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Account'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Account Name'),
                  validator: (val) => val!.isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Current Balance',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => double.tryParse(val!) == null
                      ? 'Enter valid number'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Create updated object (Keep the SAME ID)
                  final updatedAccount = Account(
                    id: account.id, // Important: Pass the ID!
                    name: nameController.text,
                    balance: double.parse(balanceController.text),
                    iconCode: account.iconCode,
                  );

                  await DatabaseHelper.instance.updateAccount(
                    updatedAccount.toMap(),
                  );
                  _loadAccounts(); // Refresh UI
                  _loadTotals();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (accounts.isEmpty) {
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
              "No accounts added!",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Center(
              child: FloatingActionButton.extended(
                onPressed: () => _showAddAccountDialog(),
                label: const Text(
                  'Add Account',
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
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Makes cards span the width
      children: [
        // Inside the Column's children:
        Card(
          color: const Color.fromARGB(255, 246, 252, 199),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Total Balance
                const Text('Total Net Worth', style: TextStyle(fontSize: 16)),
                Text(
                  '₹${_balance().toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Expense Widget
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Total Expense',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '₹${_totals['expense']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Income Widget
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Total Income',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(200, 58, 58, 58),
                            ),
                          ),
                          Text(
                            '₹${_totals['income']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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
        const SizedBox(height: 20),
        const Text(
          "\t\t\tAccounts",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ), // Spacer
        const SizedBox(height: 16),

        Expanded(
          child: ListView(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  return AccountCard(
                    account: accounts[index],
                    onLongPress: () => _showAccountOptions(accounts[index]),
                  );
                },
              ),
              const SizedBox(height: 15),
              Center(
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddAccountDialog(),
                  label: const Text(
                    'Add Account',
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
        ),
      ],
    );
  }
}
