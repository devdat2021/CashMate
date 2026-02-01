import 'package:flutter/material.dart';
import 'Pages/accounts_page.dart';
import 'Pages/records_page.dart';
import 'Pages/analysis_page.dart';
import 'Pages/categories_page.dart';
import 'Pages/transaction_page.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // For File operations
import 'package:path_provider/path_provider.dart'; // To find temp folder
import 'package:share_plus/share_plus.dart'; // To share the file
import 'package:budget/utils/database_helper.dart';
import 'package:intl/intl.dart';

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

  Future<void> _exportData() async {
    try {
      // 1. Fetch all data
      final List<Map<String, dynamic>> data = await DatabaseHelper.instance
          .getAllTransactionsForExport();

      final buffer = StringBuffer();

      // 2. CSV Header
      buffer.writeln("Date,Time,Type,Category,Amount,Account,Note");

      // Helper to escape CSV fields safely
      String csvEscape(dynamic value) {
        if (value == null) return '';
        final str = value.toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }

      // 3. Create rows
      for (final row in data) {
        final dateMillis = row['date'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(dateMillis);

        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final timeStr = DateFormat('HH:mm').format(date);

        final type = csvEscape(row['transaction_type']);
        final category = csvEscape(row['category_name'] ?? 'Uncategorized');
        final account = csvEscape(row['account_name'] ?? 'Unknown');
        final amount = row['amount']; // keep numeric
        final note = csvEscape(row['note']);

        buffer.writeln(
          "$dateStr,$timeStr,$type,$category,$amount,$account,$note",
        );
      }

      // 4. Save file
      final directory = await getTemporaryDirectory();
      final filePath = "${directory.path}/CashMate_Export.csv";
      final file = File(filePath);

      await file.writeAsString(buffer.toString());

      // 5. Share (LATEST API)
      // await SharePlus.instance.share(
      //   [XFile(filePath)],
      //   text: 'Here is my CashMate transaction data',
      //   subject: 'CashMate Export',
      // );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'Here is my CashMate transaction data',
          subject: 'CashMate Export',
        ),
      );
    } catch (e, stack) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error exporting data"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      debugPrint("Export error: $e");
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    // List of Widgets pages for the different screens/tabs
    final List<Widget> _pages = [
      Accounts(key: ValueKey(_refreshKey)),
      Records(key: ValueKey(_refreshKey)),
      AnalysisPage(key: ValueKey(_refreshKey)),
      // const Center(
      //   child: Text('Analysis Page', style: TextStyle(fontSize: 24)),
      // ),
      const Categories(),
    ];
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // A. The Header (Cyan part)
            // const UserAccountsDrawerHeader(
            //   decoration: BoxDecoration(
            //     color: Color.fromARGB(255, 92, 108, 110),
            //   ),
            //   accountName: Text(
            //     "\t\tUser",
            //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            //   ),
            //   accountEmail: Text("Manage your finances"),
            //   currentAccountPicture: CircleAvatar(
            //     backgroundColor: Colors.white,
            //     child: Icon(
            //       Icons.person,
            //       size: 35,
            //       color: Color.fromARGB(255, 92, 108, 110),
            //     ),
            //   ),
            // ),

            // B. The Menu Options
            SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Data (CSV)'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _exportData(); // Call your export function
              },
            ),

            // Placeholder for future options
            // ListTile(
            //   leading: const Icon(Icons.settings),
            //   title: const Text('Settings'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     // Future: Navigator.push(context, MaterialPageRoute(builder: (c) => SettingsPage()));
            //   },
            // ),
            const Divider(), // Visual separator

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: "CashMate",
                  applicationVersion: "1.0.0",
                  children: [
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(text: 'Creator: '),
                          TextSpan(
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            text: 'P Devdat',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(
                                Uri.parse('https://github.com/devdat2021'),
                              ),
                          ),
                          TextSpan(text: '\nSource Code: '),
                          TextSpan(
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            text: 'github.com/devdat2021/CashMate/',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(
                                Uri.parse(
                                  'https://github.com/devdat2021/CashMate',
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                // showAboutDialog(
                //   context: context,
                //   Text.rich(TextSpan()),
                //   applicationName: "CashMate",
                //   applicationVersion: "1.0.0",

                // );
              },
            ),
          ],
        ),
      ),
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
