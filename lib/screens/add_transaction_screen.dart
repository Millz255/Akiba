import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final int? transactionIndex;

  const AddTransactionScreen({super.key, this.transaction, this.transactionIndex});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = "Food";
  DateTime _selectedDate = DateTime.now();
  bool _isIncome = false;
  late Box<TransactionModel> transactionBox;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    transactionBox = Hive.box<TransactionModel>('transactions');
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.abs().toString();
      _notesController.text = widget.transaction!.notes;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
      _isIncome = widget.transaction!.isIncome;
    }

    _animationController.forward();
  }

  double _getTotalBalance() {
    double balance = 0;
    for (var transaction in transactionBox.values) {
      balance += transaction.amount;
    }
    return balance;
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_isIncome && !_isValidIncomeCategory()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Income can only be from 'Income', 'Business Income', or 'Other Income'")),
        );
        return;
      }

      if (_selectedDate.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot add transactions in the future.")),
        );
        return;
      }

      double amount = double.parse(_amountController.text);

      // Adjust amount sign based on transaction type
      if (!_isIncome) {
        amount = -amount.abs(); // Ensure negative for expenses
      } else {
        amount = amount.abs(); // Ensure positive for income
      }

      // Check if the user is trying to add a spending transaction
      if (!_isIncome) {
        double currentBalance = _getTotalBalance();
        if (currentBalance <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("You cannot add a spending transaction without first adding an income.")),
          );
          return;
        }
      }

      if (widget.transaction != null && widget.transactionIndex != null) {
        // Update existing transaction
        TransactionModel updatedTransaction = TransactionModel(
          id: widget.transaction!.id, // Keep the same ID
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          notes: _notesController.text,
          isIncome: _isIncome,
        );

        // Update at the correct index
        transactionBox.putAt(widget.transactionIndex!, updatedTransaction);
      } else {
        // Add new transaction
        transactionBox.add(
          TransactionModel(
            id: Uuid().v4(),
            amount: amount,
            category: _selectedCategory,
            date: _selectedDate,
            notes: _notesController.text,
            isIncome: _isIncome,
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  bool _isValidIncomeCategory() {
    List<String> validIncomeCategories = ["Income", "Business Income", "Other Income"];
    return validIncomeCategories.contains(_selectedCategory);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double balance = _getTotalBalance();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? "Add Transaction" : "Edit Transaction"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - _animationController.value) * 100),
                child: Opacity(
                  opacity: _animationController.value,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Current Balance: Tsh ${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        _buildAmountField(),
                        _buildCategoryDropdown(),
                        _buildDatePicker(),
                        _buildNotesField(),
                        _buildIncomeSwitch(),
                        SizedBox(height: 30),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: "Amount (Tsh)",
        labelStyle: TextStyle(color: Colors.blueAccent),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        fillColor: Colors.blueAccent.withOpacity(0.1),
        filled: true,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter an amount";
        }
        final num? amount = num.tryParse(value);
        if (amount == null) {
          return "Enter a valid number";
        }
        if (amount <= 0) {
          return "Amount must be greater than 0";
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    List<String> categories = [
      "Food",
      "Transport",
      "Entertainment",
      "Bills",
      "House Expenses",
      "Drinks",
      "Clothes shopping",
      "Other",
      "Income",
      "Salary",
      "Business Income",
      "Other Income",
      "Miscellaneous Income"
    ];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: DropdownButtonFormField(
        value: _selectedCategory,
        items: categories
            .map((category) => DropdownMenuItem(value: category, child: Text(category)))
            .toList(),
        onChanged: (value) => setState(() => _selectedCategory = value as String),
        decoration: InputDecoration(
          labelText: "Category",
          labelStyle: TextStyle(color: Colors.blueAccent),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.blueAccent.withOpacity(0.1),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text("Date: ${DateFormat.yMMMd().format(_selectedDate)}"),
      trailing: Icon(Icons.calendar_today, color: Colors.blueAccent),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) setState(() => _selectedDate = pickedDate);
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: "Notes",
        labelStyle: TextStyle(color: Colors.blueAccent),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        fillColor: Colors.blueAccent.withOpacity(0.1),
        filled: true,
      ),
    );
  }

  Widget _buildIncomeSwitch() {
    return SwitchListTile(
      value: _isIncome,
      onChanged: (val) => setState(() => _isIncome = val),
      title: Text("Is Income?", style: TextStyle(color: Colors.blueAccent)),
      activeColor: Colors.blueAccent,
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveTransaction,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            widget.transaction == null ? "Save Transaction" : "Update Transaction",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}