import 'package:flutter/material.dart';
import 'Pages/accounts_page.dart';
import 'Pages/records_page.dart';
import 'Pages/categories_page.dart';
import 'Pages/transaction_page.dart';

void main() {
  runApp(const MaterialApp(home: BudgetApp()));
}

//Main state
class BudgetApp extends StatefulWidget {
  const BudgetApp({super.key});

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  // 0-Accounts, 1-Records, 2-Analysis, 3-Categories
  int currentIndex = 0;

  // List of Widgets pages for the different screens/tabs
  final List<Widget> _pages = [
    const Accounts(),
    const Records(),
    const Center(child: Text('Analysis Page', style: TextStyle(fontSize: 24))),
    const Categories(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text(
        //   'CashMate',
        //   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        // ),
        title: Image.asset(
          'assets/Topbar_logo.png',
          height: 40, // Adjust height to fit
          fit: BoxFit.contain,
        ),
        backgroundColor: Color.fromARGB(255, 92, 108, 110),
        elevation: 0,
        centerTitle: true,

        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: _pages[currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to Add Page
          final bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
          );

          if (result == true) {
            // Call your load function here, e.g., _loadTransactions();
            // (Make sure _loadTransactions is public or accessible)
          }
        },
        backgroundColor: Color.fromARGB(255, 139, 156, 158),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Keeps the corners rounded
          side: const BorderSide(
            color: Color.fromARGB(255, 247, 236, 139), // <--- YOUR BORDER COLOR
            width: 1.0, // Thickness of the border
          ),
        ),
        child: const Icon(Icons.add, color: Color.fromARGB(255, 249, 206, 89)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 92, 108, 110),

        //currently selected tab
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        //items/tabs
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Records'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color.fromARGB(255, 249, 206, 89),
        unselectedItemColor: const Color.fromARGB(255, 197, 183, 144),
      ),
    );
  }
}
