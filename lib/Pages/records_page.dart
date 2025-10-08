import 'package:flutter/material.dart';
import 'package:budget/models/transaction.dart';
//import 'package:budget/utils/database_helper.dart';

class Records extends StatefulWidget {
  const Records({super.key});

  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records> {
  List<Transaction> transactions = [];
  @override
  Widget build(BuildContext context) {
    // Use a Column as the root container for the whole page
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Ensures card takes full width
      children: [
        Padding(
          // Padding only needed on the outside edges
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Current Month Records Summary",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Expense Widget
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "Expense",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹500',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Vertical Divider
                      const SizedBox(
                        height: 40,
                        child: VerticalDivider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),

                      // Income Widget
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "Income",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹1000',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
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
        ),
        // END STATIC HEADER CARD

        // 2. SCROLLING TRANSACTION LIST
        // MUST use Expanded to tell the list to take the remaining height
        Expanded(
          child: ListView.builder(
            // itemCount will eventually be based on your transaction list size
            itemCount: 5,
            itemBuilder: (context, index) {
              // This is where your date headers and transaction cards will go
              return const ListTile(
                title: Text(
                  'Fuck bitches',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
