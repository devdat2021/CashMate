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
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    // List of Widgets pages for the different screens/tabs
    final List<Widget> _pages = [
      Accounts(key: ValueKey(_refreshKey)),
      Records(key: ValueKey(_refreshKey)),
      const Center(
        child: Text('Analysis Page', style: TextStyle(fontSize: 24)),
      ),
      const Categories(),
    ];
    return Scaffold(
      appBar: AppBar(
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
          final bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
          );

          if (result == true) {
            setState(() {
              _refreshKey++; // Change the ID, forcing a reload!
            });
          }
        },
        backgroundColor: Color.fromARGB(255, 139, 156, 158),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color.fromARGB(255, 247, 236, 139),
            width: 1.0,
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
