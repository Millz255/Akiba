import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'package:intl/intl.dart'; // For date formatting
import 'package:local_auth/local_auth.dart'; // For biometric authentication
import '../screens/transactions_screen.dart';
import '../screens/navbar.dart';
import '../models/transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/user_profile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Box<TransactionModel> _transactionBox;
  late Future<Box<SavingsGoalModel>> _savingsBoxFuture;
  Box<SavingsGoalModel>? _savingsBox; // Make _savingsBox nullable and store the actual box here
  bool _isBalanceVisible = false;
  bool _isSavingsVisible = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  String userName = "";
  String _selectedTimeFrame = "3M";

 @override
  void initState() {
    super.initState();
    _transactionBox = Hive.box<TransactionModel>('transactions');
    _savingsBoxFuture = _openSavingsBox().then((box) {
      setState(() {
        _savingsBox = box; // Assign the box to _savingsBox
      });

      // **TEMPORARY DATA ADDITION FOR TESTING - ADD THIS BLOCK HERE**
      if (box.isEmpty) {
        print("savingsBox is empty, adding temporary data..."); // Optional print for確認
        box.add(SavingsGoalModel(title: "Jan Savings", savedAmount: 50000, dateTime: DateTime(2025, 1, 15), targetAmount: 0, frequency: '', savingAmount: 0));
        box.add(SavingsGoalModel(title: "Feb Savings 1", savedAmount: 75000, dateTime: DateTime(2025, 2, 1), targetAmount: 0, frequency: '', savingAmount: 0));
        box.add(SavingsGoalModel(title: "Feb Savings 2", savedAmount: 85400, dateTime: DateTime(2025, 2, 15), targetAmount: 0, frequency: '', savingAmount: 0));
        print("Temporary data added."); // Optional print for confirmation
      }
      // **END OF TEMPORARY DATA ADDITION**

      return box;
    });
    _checkBiometricSetting();
    Future.delayed(Duration(milliseconds: 500), () { // ADDED DELAY HERE
      _fetchUserName(); // Call _fetchUserName AFTER delay
    });
  }

  Future<Box<SavingsGoalModel>> _openSavingsBox() async {
    try {
      return await Hive.openBox<SavingsGoalModel>('savingsBox');
    } catch (e) {
      print("Error opening savingsBox: $e");
      rethrow;
    }
  }

  void _fetchUserName() async {
    print("_fetchUserName() called");
    try {
      // **CORRECTED BOX NAME (camelCase): 'userProfileBox'**
      var userProfileBox = await Hive.openBox<UserProfile>('userProfileBox');
      print("Hive box 'userProfileBox' opened successfully");
      print("Number of UserProfile objects in box: ${userProfileBox.length}");

      UserProfile? userProfile = await userProfileBox.get('currentUserProfile');

      if (userProfile != null) {
        print("UserProfile found with key 'currentUserProfile': ${userProfile.name}");
        // ... rest of the code ...
      } else {
        print("No UserProfile found with key 'currentUserProfile'.");
      }
    } catch (e) {
        // ... error handling ...
    }
    // ... fallback to "Guest" ...
  }

  void _checkBiometricSetting() async {
    var box = await Hive.openBox('userSettings');
    bool isBiometricEnabled = box.get('biometricEnabled', defaultValue: false);

    if (isBiometricEnabled) {
      bool canAuthenticate = await _localAuth.canCheckBiometrics;
      if (canAuthenticate) {
        setState(() {
          _isBalanceVisible = false; // Hide balance only if the user enabled it
        });
      }
    } else {
      setState(() {
        _isBalanceVisible = true; // Show balance if the feature isn't enabled
      });
    }
  }

  void _authenticateForSavings() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to view your savings',
        options: AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      print('Error during authentication: $e');
    }

    if (authenticated) {
      setState(() {
        _isSavingsVisible = true; // Reveal savings only after successful authentication
      });
    }
  }

  double getBalance() {
    double balance = 0;
    for (var transaction in _transactionBox.values) {
      balance += transaction.amount;
    }
    return balance;
  }

  List<TransactionModel> getTransactions() {
    var transactions = _transactionBox.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date)); // Sort by date
    return transactions;
  }

  List<PieChartSectionData> getPieChartSections() {
    List<PieChartSectionData> sections = [];
    Map<String, double> categoryTotals = {};
    double totalExpenses = 0;

    for (var transaction in _transactionBox.values) {
      if (!transaction.isIncome) {
        String category = transaction.category ?? 'Other';
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + transaction.amount.abs();
        totalExpenses += transaction.amount.abs();
      }
    }

    if (categoryTotals.isNotEmpty && totalExpenses > 0) {
      categoryTotals.forEach((category, total) {
        double percentage = (total / totalExpenses) * 100;
        sections.add(
          PieChartSectionData(
            value: total,
            color: _getRandomColor(),
            title: '$category\n${percentage.toStringAsFixed(1)}%',
            radius: 70,
            titleStyle: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        );
      });
    }

    return sections;
  }

  Color _getRandomColor() {
    return Color(0xFF000000 + Random().nextInt(0xFFFFFF));
  }

  Future<void> _authenticate() async {
    if (_isBalanceVisible) {
      setState(() {
        _isBalanceVisible = false;
      });
      return;
    }

    bool authenticated = false;
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to view your balance',
          options: AuthenticationOptions(
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      } else {
        authenticated = true;
      }
    } catch (e) {
      print('Error during authentication: $e');
      authenticated = true;
    }

    if (authenticated) {
      setState(() {
        _isBalanceVisible = true;
      });
    }
  }

  String _getGreeting() {
  var hour = DateTime.now().hour;

  if (hour >= 5 && hour < 12) { // 05:00 AM to 11:59 AM
    return 'Good Morning ☀️';
  } else if (hour >= 12 && hour < 17) { // 12:00 PM to 4:59 PM
    return 'Good Afternoon 🌤️'; // Or 'Good Noon'
  } else if (hour >= 17 && hour < 22) { // 5:00 PM to 9:59 PM
    return 'Good Evening 🌙';
  } else { // 10:00 PM to 4:59 AM
    return 'It\'s Midnight, Get Some sleep 😴'; // Or 'Good Night'
  }
}

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    List<PieChartSectionData> pieChartSections = getPieChartSections();

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(_getGreeting()),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      drawer: NavBar(
        onItemSelected: (index) {
          print("Selected Item Index: $index");
        },
        userName: userName,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: _buildBalanceCard(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: FutureBuilder<Box<SavingsGoalModel>>(
                        future: _savingsBoxFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text("Error loading savings box: ${snapshot.error}"); // Show error details
                          } else if (snapshot.hasData) {
                            _savingsBox = snapshot.data!; // Assign box data to the nullable variable
                            return _buildSavingsCard(); // Build the savings card
                          } else {
                            return Text("No data available");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildRecentTransactions(),
              const SizedBox(height: 20),
              _buildSpendingPieChart(pieChartSections),
              const SizedBox(height: 20),
              _buildSavingsProgressChart(),
              const SizedBox(height: 20),
              _buildMotivationalMessage(),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildBalanceCard() {
  double balance = getBalance();
  return AnimatedContainer(
    duration: Duration(milliseconds: 300),
    width: MediaQuery.of(context).size.width * 0.45, // Responsive width
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Balance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isBalanceVisible
                    ? AnimatedDefaultTextStyle(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                        duration: Duration(milliseconds: 300),
                        child: Text("Tsh ${balance.toStringAsFixed(2)}"),
                      )
                    : Text(
                        "Tshs ****",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                IconButton(
                  icon: Icon(
                    _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue,
                  ),
                  onPressed: _authenticate,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSavingsCard() {
  double savingsBalance = getSavingsBalance();

  return AnimatedContainer(
    duration: Duration(milliseconds: 300),
    width: MediaQuery.of(context).size.width * 0.45,
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Savings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isSavingsVisible
                    ? AnimatedDefaultTextStyle(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        duration: Duration(milliseconds: 300),
                        child: Text("Tsh ${savingsBalance.toStringAsFixed(2)}"),
                      )
                    : Text(
                        "Tshs ****",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                IconButton(
                  icon: Icon(
                    _isSavingsVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSavingsVisible = !_isSavingsVisible;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


Widget _buildRecentTransactions() {
  List<TransactionModel> transactions = getTransactions();
  // Limit transactions to 5
  List<TransactionModel> recentTransactions = transactions.take(5).toList();

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Transactions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          recentTransactions.isEmpty
              ? Center(
                  child: Text(
                    "No transactions yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: recentTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = recentTransactions[index];
                        String formattedTime = DateFormat('HH:mm').format(transaction.date);
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                              color: transaction.isIncome ? Colors.green : Colors.red,
                            ),
                            title: Text(transaction.category),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('yyyy-MM-dd').format(transaction.date)),
                                Text(formattedTime),
                              ],
                            ),
                            trailing: Text(
                              "Tsh ${transaction.amount.toStringAsFixed(2)}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                    if (transactions.length > 5) // Show "See More" button if there are more than 5 transactions
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 300),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "See More",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
    ),
  );
}

  double getSavingsBalance() {
  final savingsBox = _savingsBox;

  print("Is savingsBox initialized? ${savingsBox != null}"); 

  if (savingsBox == null) {
    print("Savings box is not initialized yet!");
    return 0;
  }

  print("Savings box keys: ${savingsBox.keys}"); 

  double totalSavings = 0;

  for (var savings in savingsBox.values) {
    print("Title: ${savings.title}, Saved Amount: ${savings.savedAmount}");
    totalSavings += savings.savedAmount;
  }

  print("Total Savings: $totalSavings");
  return totalSavings;
}




  Widget _buildSpendingPieChart(List<PieChartSectionData> pieChartSections) {
  int touchedIndex = -1;

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Spending Breakdown", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: pieChartSections.isEmpty
              ? Center(
                  child: Text(
                    "No expenses recorded yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: pieChartSections.asMap().map((index, section) {
                      final isTouched = index == touchedIndex;
                      return MapEntry(
                        index,
                        section.copyWith(
                          radius: isTouched ? 130 : 120,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).values.toList(),
                    borderData: FlBorderData(show: false),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 300),
                  swapAnimationCurve: Curves.easeInOut,
                ),
          ),
        ],
      ),
    ),
  );
}

  // Other methods remain unchanged...

  Widget _buildCategoryLegend() {
    Map<String, double> categoryTotals = {};
    double totalExpenses = 0;

    // Calculate totals
    for (var transaction in _transactionBox.values) {
      if (!transaction.isIncome) {
        String category = transaction.category ?? 'Other';
        categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount.abs();
        totalExpenses += transaction.amount.abs();
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryTotals.entries.map((entry) {
        double percentage = (entry.value / totalExpenses) * 100;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.key}\n${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget bottomTitleWidgetsSavings(double value, TitleMeta meta, List<SavingsGoalModel> savingsData, DateTime? minDate, DateTime? maxDate) {
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12,
    color: Colors.black87,
  );

  print("bottomTitleWidgetsSavings called - value: $value, meta: $meta"); // ADDED PRINT
  print("minDate: $minDate, maxDate: $maxDate, savingsData.length: ${savingsData.length}"); // ADDED PRINT


  if (minDate == null || maxDate == null || savingsData.isEmpty) {
    return Container();
  }

  int index = value.toInt();
  print("bottomTitleWidgetsSavings - index: $index"); // ADDED PRINT
  if (index >= 0 && index < savingsData.length) {
    String text = DateFormat('MMM').format(savingsData[index].dateTime);
    print("bottomTitleWidgetsSavings - text: $text"); // ADDED PRINT
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  return Container();
}


Widget leftTitleWidgetsSavings(double value, TitleMeta meta, double maxY) {
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12,
    color: Colors.black87,
  );
  print("leftTitleWidgetsSavings called - value: $value, meta: $meta, maxY: $maxY"); // ADDED PRINT

  String text;
  if (value == 0) {
    text = '0';
  } else if (value == (maxY * 1 / 3).toInt()) {
    text = '${(maxY * 1 / 3).toInt() / 1000}K';
  } else if (value == (maxY * 2 / 3).toInt()) {
    text = '${(maxY * 2 / 3).toInt() / 1000}K';
  } else if (value == maxY.toInt()) {
    text = '${maxY.toInt() / 1000}K';
  } else {
    return Container();
  }
  print("leftTitleWidgetsSavings - text: $text"); // ADDED PRINT

  return SideTitleWidget(
    meta: meta,
    child: Text(text, style: style, textAlign: TextAlign.left),
  );
}

Widget _buildSavingsProgressChart() {
  print("_buildSavingsProgressChart called (Bar Chart)"); // ADDED PRINT to differentiate

  if (_savingsBox?.isEmpty ?? true) {
    print("Savings box is empty for Bar Chart.");
    return const Center(
        child: Text('No savings data available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
  }

  final savingsData = _savingsBox?.values.toList() ?? [];
  if (savingsData.isEmpty) {
    print("savingsData list is empty for Bar Chart.");
    return const Center(
        child: Text('No savings data to chart',
            style: TextStyle(fontSize: 16, color: Colors.grey)));
  }

  // Sort savings data by dateTime
  savingsData.sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<BarChartGroupData> barChartData = []; // Changed to BarChartGroupData
  double cumulativeSavings = 0;
  DateTime? minDate, maxDate;

  for (int i = 0; i < savingsData.length; i++) {
    cumulativeSavings += savingsData[i].savedAmount;
    barChartData.add(
      BarChartGroupData( // Create BarChartGroupData
        x: i, // X-axis index for each bar
        barRods: [
          BarChartRodData(toY: cumulativeSavings, color: Colors.blue), // Y-value for each bar
        ],
      ),
    );
    if (minDate == null || savingsData[i].dateTime.isBefore(minDate)) {
      minDate = savingsData[i].dateTime;
    }
    if (maxDate == null || savingsData[i].dateTime.isAfter(maxDate)) {
      maxDate = savingsData[i].dateTime;
    }
  }

  double maxY = cumulativeSavings * 1.2; // Set maxY slightly above max savings
  double maxX = savingsData.length.toDouble() - 1; // maxX based on number of data points - 1 for index

  print("savingsData length (Bar Chart): ${savingsData.length}");
  print("barChartData (Bar Chart): $barChartData"); // Print BarChartData
  print("minDate (Bar Chart): $minDate, maxDate: $maxDate");
  print("maxX (Bar Chart): $maxX, maxY (Bar Chart): $maxY");

  return AspectRatio(
    aspectRatio: 1.70,
    child: Padding(
      padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
      child: BarChart( // Changed to BarChart
        BarChartData( // Changed to BarChartData
          alignment: BarChartAlignment.spaceAround, // Adjust bar spacing if needed
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false, // No vertical grid lines for bar chart
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.blue.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: savingsData.length > 0,
                reservedSize: 30,
                getTitlesWidget: (value, meta) =>
                    bottomTitleWidgetsSavings(value, meta, savingsData, minDate, maxDate), // Reusing bottom title widget
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 3,
                reservedSize: 42,
                getTitlesWidget: (value, meta) =>
                    leftTitleWidgetsSavings(value, meta, maxY), // Reusing left title widget
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          barGroups: barChartData, // Use barChartData here
        ),
      ),
    ),
  );
}

Widget _buildAnimatedLegendItem(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      const SizedBox(width: 9),
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blueGrey.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

  Widget _buildTimeFrameSelector() {
    return DropdownButton<String>(
      value: _selectedTimeFrame,
      items: ["1M", "3M", "6M", "1Y"].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedTimeFrame = newValue!;
        });
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  List<FlSpot> _getSavingsSpots() {
  final savingsBox = _savingsBox;
  if (savingsBox?.isEmpty ?? true) {
    print("Savings box is empty or not initialized! in _getSavingsSpots");
    return [FlSpot(0, 0)];
  }

  List<FlSpot> spots = [];
  double cumulativeSavings = 0;

  // Get all savings goals and sort them by date.
  var savingsGoals = savingsBox?.values.toList() ?? [];
  savingsGoals.sort((a, b) => a.dateTime.compareTo(b.dateTime));

  if (savingsGoals.isNotEmpty) {
    print("First savings goal dateTime: ${savingsGoals.first.dateTime}");
    
    final double minX = savingsGoals.first.dateTime.millisecondsSinceEpoch.toDouble();
    print("minX (millisecondsSinceEpoch of first date): $minX");

    double maxXValue = savingsGoals.last.dateTime.millisecondsSinceEpoch.toDouble();

    for (final goal in savingsGoals) {
      print("Goal dateTime: ${goal.dateTime}");
      cumulativeSavings += goal.savedAmount;

      double xValue = (goal.dateTime.millisecondsSinceEpoch.toDouble() - minX) / (maxXValue - minX);
      print("xValue: $xValue");
      spots.add(FlSpot(xValue, cumulativeSavings));
    }
  } else {
    print("savingsGoals is empty after fetching from savingsBox.");
  }

  return spots;
}

  List<TransactionModel> _getSavingsTransactions() {
  var transactions = _transactionBox.values
      .where((transaction) => transaction.category == "Savings")
      .toList();

  if (transactions.isEmpty) {
    // Return an empty list or handle it as needed
    return [];
  }

  transactions.sort((a, b) => a.date.compareTo(b.date));
  return transactions;
}

  List<FlSpot> _getGoalSpots() {
  final savingsBox = _savingsBox;
  print("Is savingsBox in _getGoalSpots initialized? ${savingsBox != null}"); // ADD THIS LINE


  if (savingsBox == null || savingsBox.isEmpty) {
    print("Savings box is empty or not initialized! in _getGoalSpots");
    return [FlSpot(0, 0), FlSpot(1, 0)]; // Default goal line
  }
  print("Savings box keys in _getGoalSpots: ${savingsBox.keys}"); // ADD THIS LINE

  List<FlSpot> spots = [];
  double totalGoal = 0;

  // Sort savings goals by date (oldest first)
  var savingsGoals = savingsBox.values.toList();
  savingsGoals.sort((a, b) => a.dateTime.compareTo(b.dateTime));

  for (int i = 0; i < savingsGoals.length; i++) {
    totalGoal += savingsGoals[i].targetAmount;
    spots.add(FlSpot(i.toDouble(), totalGoal));
  }

  print("Goal Spots: $spots");
  return spots;
}

  String _getMonthLabel(int index) {
  final now = DateTime.now();
  // Ensure the index is within a valid range (0-11 for months)
  final month = now.month - index;
  final year = now.year;
  final adjustedMonth = month <= 0 ? month + 12 : month;
  final adjustedYear = month <= 0 ? year - 1 : year;

  final date = DateTime(adjustedYear, adjustedMonth);
  return DateFormat('MMM').format(date);
}

  Color _getCategoryColor(String category) {
    // Create a consistent color mapping for categories
    final Map<String, Color> colorMap = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Utilities': Colors.green,
      'Entertainment': Colors.purple,
      'Shopping': Colors.red,
      'Other': Colors.grey,
    };
    
    return colorMap[category] ?? Colors.grey;
  }

  Widget _buildMotivationalMessage() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Motivational Message", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              "You're doing great! Keep track of your finances, and you'll reach your goals in no time.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}