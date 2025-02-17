import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:typed_data';
import '../models/transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../screens/navbar.dart';

enum ReportType { transactions, savings }

class ReportsExportScreen extends StatefulWidget {
  final Box reportSettingsBox;
  const ReportsExportScreen({super.key, required this.reportSettingsBox});

  @override
  _ReportsExportScreenState createState() => _ReportsExportScreenState();
}

class _ReportsExportScreenState extends State<ReportsExportScreen>
    with SingleTickerProviderStateMixin {
  late DateTimeRange _selectedDateRange;
  late Box _settingsBox;
  bool _isGenerating = false;
  List<TransactionModel> _transactions = [];
  List<SavingsGoalModel> _savings = [];
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _selectedCategoryFilter;
  final List<String> _transactionCategories = [
    "Food", "Transport", "Entertainment", "Bills", "House Expenses", "Drinks",
    "Clothes shopping", "Other", "Income", "Salary", "Business Income",
    "Other Income", "Miscellaneous Income"
  ];
  ReportType _selectedReportType = ReportType.transactions;
  String _reportContent = "";

  @override
  void initState() {
    super.initState();
    _settingsBox = widget.reportSettingsBox;

    final startDate = DateTime.fromMillisecondsSinceEpoch(
        _settingsBox.get('startDate') ?? DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch);
    final endDate = DateTime.fromMillisecondsSinceEpoch(
        _settingsBox.get('endDate') ?? DateTime.now().millisecondsSinceEpoch);
    _selectedDateRange = DateTimeRange(start: startDate, end: endDate);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _fetchInitialData();
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange initialRange = _selectedDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: result.start,
          end: now,
        );
      });

      await _settingsBox.put('startDate', _selectedDateRange.start.millisecondsSinceEpoch);
      await _settingsBox.put('endDate', _selectedDateRange.end.millisecondsSinceEpoch);

      await _fetchInitialData();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchSavingsData(),
      _fetchTransactionData(),
    ]);
  }

  Future<void> _fetchSavingsData() async {
    try {
      final savingsBox = await Hive.openBox<SavingsGoalModel>('savingsBox');
      final allSavings = savingsBox.values.toList();
      final filteredSavings = allSavings.where((saving) {
        final createdDate = saving.dateTime;
        return !createdDate.isBefore(_selectedDateRange.start) && !createdDate.isAfter(_selectedDateRange.end);
      }).toList();

      if (mounted) {
        setState(() {
          _savings = filteredSavings;
        });
      }
    } catch (e) {
      debugPrint('Error fetching savings data: $e');
    }
  }

  Future<void> _fetchTransactionData() async {
    try {
      final transactionsBox = await Hive.openBox<TransactionModel>('transactions');
      final allTransactions = transactionsBox.values.toList();
      final filteredTransactions = allTransactions.where((transaction) {
        bool dateFilter = !transaction.date.isBefore(_selectedDateRange.start) && !transaction.date.isAfter(_selectedDateRange.end);
        bool categoryFilter = _selectedCategoryFilter == null ||
            _selectedCategoryFilter == "All Categories" ||
            transaction.category == _selectedCategoryFilter;
        return dateFilter && categoryFilter;
      }).toList();

      if (mounted) {
        setState(() {
          _transactions = filteredTransactions;
        });
      }
    } catch (e) {
      debugPrint('Error fetching transaction data: $e');
    }
  }

  Future<void> _generateReport() async {
  if (mounted) {
    setState(() {
      _isGenerating = true;
      _reportContent = "";
    });
  }

  String reportText = "";

  reportText += "Financial Report\n";
  reportText += "Date Range: ${DateFormat.yMMMd().format(_selectedDateRange.start)} - ${DateFormat.yMMMd().format(_selectedDateRange.end)}\n\n";

  if (_selectedReportType == ReportType.savings) {
    reportText += "Savings Goals\n";
    reportText += _generateSavingsTable();
    reportText += "\n";
    reportText += "Total Savings Progress: Tzs ${_calculateTotalSavings().toStringAsFixed(2)}\n";
  }

  if (_selectedReportType == ReportType.transactions) {
    reportText += "Transactions\n";
    reportText += _generateTransactionsTable();
    reportText += "\n";
    reportText += "Total Income: Tzs ${_calculateTotalIncome().toStringAsFixed(2)}\n";
    reportText += "Total Expenses: Tzs ${_calculateTotalExpenses().toStringAsFixed(2)}\n";
  }

  if (mounted) {
    setState(() {
      _isGenerating = false;
      _reportContent = reportText;
    });

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => _generatePdfContent(format, reportText),
    );

    _showReportDialog(reportText);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report sent to printer!')),
    );
  }
}

String _generateSavingsTable() {
  var table = "| Title            | Saved Amount   | Target Amount  | Progress       |\n";
  table += "|------------------|----------------|----------------|----------------|\n";
  for (var saving in _savings) {
    double progress = (saving.savedAmount / saving.targetAmount) * 100;
    table += "| ${saving.title.padRight(16)} | Tzs ${saving.savedAmount.toStringAsFixed(2).padLeft(12)} | Tzs ${saving.targetAmount.toStringAsFixed(2).padLeft(12)} | ${progress.toStringAsFixed(2)}%       |\n";
  }
  return table;
}

String _generateTransactionsTable() {
  var table = "| Date       | Category    | Notes                | Amount        |\n";
  table += "|------------|-------------|----------------------|---------------|\n";
  for (var transaction in _transactions) {
    table += "| ${DateFormat.yMMMd().format(transaction.date)} | ${transaction.category.padRight(11)} | ${transaction.notes.padRight(20)} | Tzs ${transaction.amount.toStringAsFixed(2).padLeft(12)} |\n";
  }
  return table;
}

Future<Uint8List> _generatePdfContent(PdfPageFormat format, String reportText) async {
  final pdfDoc = pw.Document();
  pdfDoc.addPage(
    pw.Page(
      pageFormat: format,
      build: (pw.Context context) {
        return pw.Text(reportText);
      },
    ),
  );
  return await pdfDoc.save();
}

  void _showReportDialog(String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: AlertDialog(
            title: Text('Financial Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            content: SingleChildScrollView(
              child: Text(content),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Close', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateTotalSavings() => _savings.fold(0, (sum, saving) => sum + saving.savedAmount);
  double _calculateTotalIncome() => _transactions.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
  double _calculateTotalExpenses() => _transactions.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(
        onItemSelected: (index) {
          print("Selected Item Index: $index");
        },
      ),
      appBar: AppBar(
        title: const Text('Generate Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Radio<ReportType>(
                      value: ReportType.transactions,
                      groupValue: _selectedReportType,
                      onChanged: (ReportType? value) {
                        setState(() {
                          _selectedReportType = value!;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    Text('Transactions', style: TextStyle(color: Colors.blue)),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Radio<ReportType>(
                      value: ReportType.savings,
                      groupValue: _selectedReportType,
                      onChanged: (ReportType? value) {
                        setState(() {
                          _selectedReportType = value!;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    Text('Savings', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickDateRange,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'Select Date Range: ${DateFormat.yMMMd().format(_selectedDateRange.start)} - ${DateFormat.yMMMd().format(_selectedDateRange.end)}',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedReportType == ReportType.transactions)
              SizedBox(
                height: 60, // Explicitly set a height
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoryFilter,
                  items: ["All Categories", ..._transactionCategories]
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryFilter = value;
                      _fetchTransactionData();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Filter by Category (Transactions)',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.blue),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _isGenerating
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _generateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Generate Report', style: TextStyle(color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}