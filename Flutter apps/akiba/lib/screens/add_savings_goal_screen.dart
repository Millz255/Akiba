import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/savings_goal_model.dart';

class AddSavingsGoalScreen extends StatefulWidget {
  final bool isEdit;
  final SavingsGoalModel? goal;

  const AddSavingsGoalScreen({super.key, this.isEdit = false, this.goal});

  @override
  _AddSavingsGoalScreenState createState() => _AddSavingsGoalScreenState();
}

class _AddSavingsGoalScreenState extends State<AddSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _savingAmountController = TextEditingController();
  String _selectedFrequency = "Weekly";
  late Box<SavingsGoalModel> savingsBox;

  @override
  void initState() {
    super.initState();
    _openHiveBox();

    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _savingAmountController.text = widget.goal!.savingAmount.toString();
      _selectedFrequency = widget.goal!.frequency;
    }
  }

  Future<void> _openHiveBox() async {
    if (!Hive.isBoxOpen('savingsBox')) {
      await Hive.openBox<SavingsGoalModel>('savingsBox');
    }
    savingsBox = Hive.box<SavingsGoalModel>('savingsBox');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _savingAmountController.dispose();
    super.dispose();
  }

  double? _parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final targetAmount = _parseDouble(_targetAmountController.text);
      final savingAmount = _parseDouble(_savingAmountController.text);

      if (targetAmount == null || savingAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter valid numbers")),
        );
        return;
      }

      SavingsGoalModel updatedGoal;

      if (widget.goal == null) {
        // Create a new goal
        updatedGoal = SavingsGoalModel(
          title: _titleController.text,
          targetAmount: targetAmount,
          savedAmount: 0.0,
          frequency: _selectedFrequency,
          savingAmount: savingAmount,
          dateTime: DateTime.now(),
        );
      } else {
        // Update existing goal
        updatedGoal = SavingsGoalModel(
          title: _titleController.text,
          targetAmount: targetAmount,
          savedAmount: widget.goal!.savedAmount, // Preserve savedAmount
          frequency: _selectedFrequency,
          savingAmount: savingAmount,
          dateTime: widget.goal!.dateTime, // Preserve the original date
          savingsEntries: widget.goal!.savingsEntries, // Preserve savingsEntries
        );
      }

      if (widget.goal == null) {
        savingsBox.add(updatedGoal);
      } else {
        savingsBox.put(widget.goal!.key, updatedGoal);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Edit Goal" : "Add Goal"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40), 
                
                Icon(
                  Icons.savings,
                  size: 60.0, 
                  color: Colors.blueAccent,
                ),
                SizedBox(height: 20), 
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextFormField(_titleController, "Goal Title", "Enter a goal title"),
                      _buildTextFormField(_targetAmountController, "Target Amount (Tsh)", "Enter a target amount", keyboardType: TextInputType.number),
                      _buildTextFormField(_savingAmountController, "Saving Amount per Period", "Enter a saving amount", keyboardType: TextInputType.number),
                      _buildDropdown(),
                      SizedBox(height: 40), 
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, String errorText, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return errorText;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: DropdownButtonFormField<String>(
        value: _selectedFrequency,
        decoration: InputDecoration(
          labelText: 'Frequency',
          labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        onChanged: (newValue) {
          setState(() {
            _selectedFrequency = newValue!;
          });
        },
        items: ["Daily", "Weekly", "Monthly", "Yearly"].map((String frequency) {
          return DropdownMenuItem<String>(
            value: frequency,
            child: Text(frequency),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _saveGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 100, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        child: Text(
          widget.isEdit ? "Save Changes" : "Add Goal",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
