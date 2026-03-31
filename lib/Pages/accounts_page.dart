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
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onLongPress: onLongPress,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
          child: account.iconWidget,
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        ),
        trailing: Text(
          '₹${account.balance.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
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
      //print("Database Loading Error: $e");
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
                    color: Colors.white,
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                backgroundColor: const Color(0xFF10B981),
                elevation: 4,
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
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Net Worth',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                    ),
                    Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_balance().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Expense Widget
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF43F5E).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_downward, color: Color(0xFFF43F5E), size: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Expense',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_totals['expense']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Income Widget
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Income',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_totals['income']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                      color: Colors.white,
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  backgroundColor: const Color(0xFF10B981), // Emerald
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}
