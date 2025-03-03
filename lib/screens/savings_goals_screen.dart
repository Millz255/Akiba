import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/adapters.dart';
import 'add_savings_goal_screen.dart';
import 'navbar.dart';
import '../models/savings_goal_model.dart';
import '../models/user_profile.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  _SavingsGoalsScreenState createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> with SingleTickerProviderStateMixin {
  late Box<SavingsGoalModel> savingsBox;
  String userName = "User"; // Replace with actual user data

  @override
  void initState() {
    super.initState();
  }

  Future<Box<SavingsGoalModel>> _initializeSavingsBox() async {
    savingsBox = await Hive.openBox<SavingsGoalModel>('savingsBox');
    return savingsBox;
  }

  void _showAddSavingsDialog(BuildContext context, SavingsGoalModel goal) {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Savings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter amount (TZS)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("Save"),
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  setState(() {
                    goal.savedAmount += amount;
                    goal.savingsEntries.add({
                      "amount": amount,
                      "date": DateTime.now().toString(),
                    });
                    savingsBox.put(goal.key, goal);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Savings Goal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text("Are you sure you want to delete this savings goal?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete"),
              onPressed: () {
                savingsBox.delete(goal.key); // Delete the goal
                setState(() {});
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var settingsBox = Hive.box<UserProfile>('settings');
    var userProfile = settingsBox.getAt(0) ?? UserProfile(name: 'User', preferredCurrency: 'USD');
    return FutureBuilder<Box<SavingsGoalModel>>(
      future: _initializeSavingsBox(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text("Savings Goals", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.blue),
            drawer: NavBar(
              onItemSelected: (index) {
                print("Selected Item Index: $index");
              },
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          savingsBox = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text("Savings Goals", style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue,
              elevation: 0,
            ),
            drawer: NavBar(
              onItemSelected: (index) {
                print("Selected Item Index: $index");
              },
            ),
            body: ValueListenableBuilder(
              valueListenable: savingsBox.listenable(),
              builder: (context, Box<SavingsGoalModel> box, _) {
                var savingsList = box.values.toList().reversed.toList();

                if (savingsList.isEmpty) {
                  return Center(
                    child: Text("No savings added yet!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: savingsList.length,
                  itemBuilder: (context, index) {
                    var saving = savingsList[index];
                    double progress = (saving.savedAmount / saving.targetAmount).clamp(0.0, 1.0) * 100;

                    return Card(
                      elevation: 6,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      shadowColor: Colors.black.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(saving.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                            SizedBox(height: 5),
                            Text("Target: ${saving.targetAmount} TZS", style: TextStyle(fontSize: 16, color: Colors.blue)),
                            Text("Saved: ${saving.savedAmount} TZS", style: TextStyle(fontSize: 14, color: Colors.green)),
                            Text("Saving Amount: ${saving.savingAmount} TZS", style: TextStyle(fontSize: 14, color: Colors.blue)),
                            Text("Frequency: ${saving.frequency}", style: TextStyle(fontSize: 14, color: Colors.orange)),
                            SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            SizedBox(height: 5),
                            Text("Progress: ${progress.toStringAsFixed(2)}%", style: TextStyle(fontSize: 14, color: Colors.purple)),
                            SizedBox(height: 15),

                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(icon: Icon(Icons.add, color: Colors.green), onPressed: () => _showAddSavingsDialog(context, saving)),
                                IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddSavingsGoalScreen(isEdit: true, goal: saving)));
                                }),
                                IconButton(icon: Icon(Icons.delete, color: Colors.redAccent), onPressed: () {
                                  _confirmDelete(context, saving);
                                }),
                              ],
                            ),

                            // Displaying all saved amounts with date/time
                            Text("Recent Savings:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),

                            // Use Dismissible to handle swipe-to-delete
                            ...saving.savingsEntries.reversed.map((entry) {
                              return Dismissible(
                                key: ValueKey(entry),
                                direction: DismissDirection.startToEnd,
                                onDismissed: (direction) {
                                  setState(() {
                                    saving.savingsEntries.remove(entry);
                                    // Recalculate the total saved amount after removing an entry
                                    double totalSaved = 0;
                                    for (var e in saving.savingsEntries) {
                                      totalSaved += e['amount'];
                                    }
                                    saving.savedAmount = totalSaved;
                                    savingsBox.put(saving.key, saving); // Save the changes
                                  });
                                },
                                background: Container(color: Colors.red),
                                child: GestureDetector(
                                  onTap: () {
                                    // Open dialog to edit saving entry
                                    _showEditSavingDialog(context, saving, entry);
                                  },
                                  child: ListTile(
                                    leading: Icon(Icons.monetization_on, color: Colors.green),
                                    title: Text("+${entry['amount']} TZS", style: TextStyle(color: Colors.green, fontSize: 16)),
                                    subtitle: Text("${entry['date']}", style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ).animate().scale();
                  },
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddSavingsGoalScreen(isEdit: false)));
              },
              backgroundColor: Colors.blue,
              child: Icon(Icons.add),
            ),
          );
        }
      },
    );
  }

  void _showEditSavingDialog(BuildContext context, SavingsGoalModel goal, Map<String, dynamic> entry) {
    TextEditingController amountController = TextEditingController(text: entry['amount'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Savings Entry", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Edit amount (TZS)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("Save"),
              onPressed: () {
                double newAmount = double.tryParse(amountController.text) ?? 0;
                if (newAmount > 0) {
                  setState(() {
                    // Update the entry amount
                    entry['amount'] = newAmount;

                    // Recalculate the total saved amount
                    double totalSaved = 0;
                    for (var entry in goal.savingsEntries) {
                      totalSaved += entry['amount'];
                    }
                    goal.savedAmount = totalSaved;

                    // Save the updated goal
                    savingsBox.put(goal.key, goal); // Save the changes to the box
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
