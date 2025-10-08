import 'package:flutter/material.dart';
import 'package:budget/models/account.dart';
import 'package:budget/utils/database_helper.dart';

class AccountCard extends StatelessWidget {
  final Account account;

  const AccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
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

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // Start loading data when the widget is created
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
        // Inside the Column's children:
        Card(
          color: const Color.fromARGB(255, 204, 236, 233),
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
                        children: const [
                          Text(
                            'Total Expense',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '-₹980.50',
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
                        children: const [
                          Text(
                            'Total Income',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(200, 58, 58, 58),
                            ),
                          ),
                          Text(
                            '+₹1,200.00',
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
                  return AccountCard(account: accounts[index]);
                },
              ),
              const SizedBox(height: 15),
              Center(
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddAccountDialog(),
                  label: const Text(
                    'Add Account',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  backgroundColor: const Color.fromARGB(255, 91, 246, 189),
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
