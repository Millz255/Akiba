import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../models/user_profile.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/navbar.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late Box<TransactionModel> transactionBox;
  late AnimationController _fabAnimationController;

  // State variables for filters
  String? selectedCategory;
  DateTime? startDate;
  DateTime? endDate;
  bool _isFilterExpanded = false; // Controls filter section visibility

  @override
  void initState() {
    super.initState();
    transactionBox = Hive.box<TransactionModel>('transactions');
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var settingsBox = Hive.box<UserProfile>('settings');
    var userProfile = settingsBox.getAt(0) ?? UserProfile(name: 'User', preferredCurrency: 'USD');

    // Get unique categories from transactions
    var categories = transactionBox.values.map((t) => t.category).toSet().toList();
    categories.insert(0, 'All'); // Add 'All' option

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Transactions"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      drawer: NavBar(
        onItemSelected: (index) {
          print("Selected Item Index: $index");
        },
        userName: userProfile.name,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _fabAnimationController.forward();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionScreen()),
          );
          _fabAnimationController.reverse();
          setState(() {}); // Refresh the UI after adding a transaction
        },
        backgroundColor: Colors.blue.shade700,
        elevation: 6,
        child: Icon(Icons.add, size: 30),
      ),
      body: Column(
        children: [
          // Filter Section
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFilterExpanded ? 150 : 0,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 3), // Shadow position
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    hint: Text('Select Category'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                    items: categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Date Range Picker
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTimeRange? picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                              initialDateRange: DateTimeRange(
                                start: startDate ?? DateTime.now(),
                                end: endDate ?? DateTime.now(),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                startDate = picked.start;
                                endDate = picked.end;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  startDate == null || endDate == null
                                      ? "Select Date Range"
                                      : "${DateFormat.yMMMd().format(startDate!)} - ${DateFormat.yMMMd().format(endDate!)}",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Toggle Filter Button
          InkWell(
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFilterExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _isFilterExpanded ? "Hide Filters" : "Show Filters",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          // Transaction List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: transactionBox.listenable(),
              builder: (context, Box<TransactionModel> box, _) {
                if (box.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No transactions yet. Add some!",
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Apply filters
                var filteredTransactions = box.values.toList().where((transaction) {
                  bool categoryMatch = selectedCategory == null || selectedCategory == 'All' || transaction.category == selectedCategory;
                  bool dateMatch = startDate == null || endDate == null || 
                      (transaction.date.isAfter(startDate!) && transaction.date.isBefore(endDate!));
                  return categoryMatch && dateMatch;
                }).toList();

                var reversedTransactions = filteredTransactions.reversed.toList();

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: reversedTransactions.length,
                  itemBuilder: (context, index) {
                    TransactionModel transaction = reversedTransactions[index];
                    return _buildTransactionItem(transaction);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    String formattedTime = DateFormat('h:mm a').format(transaction.date);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTransactionScreen(
              transaction: transaction,
              transactionIndex: transactionBox.values.toList().indexWhere((t) => t.id == transaction.id),
            ),
          ),
        );
        setState(() {});
      },
      child: Card(
        elevation: 5,
        margin: EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 3), // Shadow position
              ),
            ],
          ),
          child: Dismissible(
            key: Key(transaction.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              transactionBox.deleteAt(transactionBox.values.toList().indexWhere((t) => t.id == transaction.id));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transaction deleted")));
            },
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Confirm Delete"),
                    content: Text("Are you sure you want to delete this transaction?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Delete", style: TextStyle(color: Colors.red))),
                    ],
                  );
                },
              );
            },
            child: ListTile(
              leading: Icon(
                transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: transaction.isIncome ? Colors.green : Colors.red,
                size: 30,
              ),
              title: Text(
                transaction.category,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        DateFormat.yMMMd().format(transaction.date),
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    transaction.notes,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: Text(
                'Tsh ${transaction.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: transaction.isIncome ? Colors.green : Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}