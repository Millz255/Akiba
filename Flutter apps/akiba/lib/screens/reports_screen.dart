import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
    final endDate = DateTime.now();
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
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(start: result.start, end: result.end);
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
    await Future.wait([_fetchSavingsData(), _fetchTransactionData()]);
  }

  Future<void> _fetchSavingsData() async {
    debugPrint('_fetchSavingsData: Starting');
    try {
      final savingsBox = await Hive.openBox<SavingsGoalModel>('savingsBox');
      final allSavings = savingsBox.values.toList();
      debugPrint('_fetchSavingsData: allSavings.length = ${allSavings.length}'); 
      final filteredSavings = allSavings.where((saving) {
        return saving.dateTime.isAfter(_selectedDateRange.start) &&
            saving.dateTime.isBefore(_selectedDateRange.end);
      }).toList();
      debugPrint('_fetchSavingsData: filteredSavings.length = ${filteredSavings.length}'); 
      debugPrint('_fetchSavingsData: _selectedDateRange = ${_selectedDateRange}');

      if (mounted) {
        setState(() {
          _savings = filteredSavings;
        });
      }
      savingsBox.close();
    } catch (e) {
      debugPrint('Error fetching savings data: $e');
    }
     debugPrint('_fetchSavingsData: Ending');
  }

  Future<void> _fetchTransactionData() async {
    try {

        final transactionsBox = Hive.box<TransactionModel>('transactions'); 
        final allTransactions = transactionsBox.values.toList();
        final filteredTransactions = allTransactions.where((transaction) {
            bool dateFilter = transaction.date.isAfter(_selectedDateRange.start) && transaction.date.isBefore(_selectedDateRange.end);
            bool categoryFilter = _selectedCategoryFilter == null || _selectedCategoryFilter == "All Categories" ||
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
     debugPrint('_generateReport: Starting'); 
    if (mounted) {
      setState(() {
        _isGenerating = true;
        _reportContent = "";
      });
    }

    String reportText = "Financial Report\n";
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
     debugPrint('_generateReport: reportText before setState = \n$reportText'); 

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
     debugPrint('_generateReport: Ending'); 
  }

  String _generateSavingsTable() {
    String table = "";
    table += "--------------------------------------------------------------------\n"; 
    table += "| Goal Title            | Saved Amount    | Target Amount   | Progress      |\n";
    table += "--------------------------------------------------------------------\n"; 
    for (var saving in _savings) {
      double progress = (saving.savedAmount / saving.targetAmount) * 100;
      table += "| ${saving.title.padRight(18)} | Tzs ${saving.savedAmount.toStringAsFixed(2).padLeft(13)} | Tzs ${saving.targetAmount.toStringAsFixed(2).padLeft(13)} | ${progress.toStringAsFixed(2)}%${''.padLeft(5)}|\n";
    }
    table += "--------------------------------------------------------------------\n"; 
    return table;
  }

  String _generateTransactionsTable() {
    String table = "";
    table += "---------------------------------------------------------------------------------------\n"; 
    table += "| Date          | Category      | Notes                       | Amount          |\n";
    table += "---------------------------------------------------------------------------------------\n"; 
    for (var transaction in _transactions) {
      table += "| ${DateFormat.yMMMd().format(transaction.date).padRight(12)} | ${transaction.category.padRight(13)} | ${transaction.notes.padRight(26)} | Tzs ${transaction.amount.toStringAsFixed(2).padLeft(12)} |\n";
    }
    table += "---------------------------------------------------------------------------------------\n"; 
    return table;
  }

  Future<Uint8List> _generatePdfContent(PdfPageFormat format, String reportText) async {
    final pdfDoc = pw.Document();

    pdfDoc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column( 
            crossAxisAlignment: pw.CrossAxisAlignment.start, 
            children: [
              pw.Text('Financial Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), 
              pw.SizedBox(height: 10),
              pw.Text('Date Range: ${DateFormat.yMMMd().format(_selectedDateRange.start)} - ${DateFormat.yMMMd().format(_selectedDateRange.end)}'), // Date range
              pw.SizedBox(height: 20),

              if (_selectedReportType == ReportType.savings && _savings.isNotEmpty) ...[ 
                pw.Text('Savings Goals', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table.fromTextArray( 
                  border: pw.TableBorder.all(),
                  headers: ['Goal Title', 'Saved Amount', 'Target Amount', 'Progress'],
                  data: _savings.map((saving) {
                    double progress = (saving.savedAmount / saving.targetAmount) * 100;
                    return [
                      saving.title,
                      'Tzs ${saving.savedAmount.toStringAsFixed(2)}',
                      'Tzs ${saving.targetAmount.toStringAsFixed(2)}',
                      '${progress.toStringAsFixed(2)}%',
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Total Savings Progress: Tzs ${_calculateTotalSavings().toStringAsFixed(2)}'),
              ],

              if (_selectedReportType == ReportType.transactions && _transactions.isNotEmpty) ...[ 
                pw.Text('Transactions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table.fromTextArray( 
                  border: pw.TableBorder.all(),
                  headers: ['Date', 'Category', 'Notes', 'Amount'],
                  data: _transactions.map((transaction) => [
                    DateFormat.yMMMd().format(transaction.date),
                    transaction.category,
                    transaction.notes,
                    'Tzs ${transaction.amount.toStringAsFixed(2)}',
                  ]).toList(),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Total Income: Tzs ${_calculateTotalIncome().toStringAsFixed(2)}'),
                pw.Text('Total Expenses: Tzs ${_calculateTotalExpenses().toStringAsFixed(2)}'),
              ],
            ],
          );
        },
      ),
    );
    return await pdfDoc.save();
  }

  void _showReportDialog(String content) {
     debugPrint('_showReportDialog: content = \n$content'); 
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: AlertDialog(
            title: Text('Financial Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            content: SingleChildScrollView(
              child: Padding( 
                padding: const EdgeInsets.all(8.0),
                child: Text(content, style: TextStyle(fontSize: 14)), 
              ),
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
        title: const Text('Generate Report'),
        backgroundColor: Colors.blue,
      ),
      body: Center( 
        child: Padding(
          padding: const EdgeInsets.all(24.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: <Widget>[

              Card( 
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _pickDateRange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        ),
                        child: const Text("Select Date Range"),
                      ),
                      Text(
                        "${DateFormat.yMMMd().format(_selectedDateRange.start)} - ${DateFormat.yMMMd().format(_selectedDateRange.end)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card( 
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Report Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                      Row(
                        children: [
                          Radio<ReportType>(
                            value: ReportType.transactions,
                            groupValue: _selectedReportType,
                            onChanged: (value) {
                              setState(() {
                                _selectedReportType = value!;
                                _fetchTransactionData();
                              });
                            },
                          ),
                          const Text('Transactions'),
                          const SizedBox(width: 20),
                          Radio<ReportType>(
                            value: ReportType.savings,
                            groupValue: _selectedReportType,
                            onChanged: (value) {
                              setState(() {
                                _selectedReportType = value!;
                                _fetchSavingsData();
                              });
                            },
                          ),
                          const Text('Savings'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: _selectedReportType == ReportType.transactions,
                        child: Row(
                          children: [
                            const Text("Category:", style: TextStyle(fontWeight: FontWeight.w500)), 
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: _selectedCategoryFilter,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategoryFilter = newValue;
                                });
                                _fetchTransactionData();
                              },
                              items: [
                                'All Categories',
                                ..._transactionCategories,
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _generateReport,
                child: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Generate Report", style: TextStyle(color: Colors.white, fontSize: 16)), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Card( 
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: Colors.grey[50], 
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0), 
                    child: Text(
                      _reportContent,
                      style: const TextStyle(fontSize: 15, fontFamily: 'Roboto', color: Colors.black87), 
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}