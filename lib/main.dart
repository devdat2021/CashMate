import 'package:flutter/material.dart';
import 'Pages/accounts_page.dart';
import 'Pages/records_page.dart';
import 'Pages/categories_page.dart';

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

  // List of Widgets for the different screens/tabs
  final List<Widget> _pages = [
    const Accounts(),
    const Records(), //Center(child: Text('Records Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Analysis Page', style: TextStyle(fontSize: 24))),
    const Categories(),
    // const Center(
    //   child: Text('Categories Page', style: TextStyle(fontSize: 24)),
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CashMate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Note: Using a fixed, opaque Color is generally better than Color.fromARGB(199, ...)
        backgroundColor: const Color.fromARGB(
          255,
          17,
          192,
          219,
        ), // A fixed color close to your original
      ),

      //Displays the current page based on currentIndex
      body: _pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 17, 192, 219),

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

        // Optional: Set type to fixed to show all labels consistently
        type: BottomNavigationBarType.fixed,
        // Set colors for better visibility
        selectedItemColor: const Color.fromARGB(255, 116, 115, 115),
        unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }
}
