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
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextFormField(_titleController, "Goal Title", "Enter a goal title"),
                  _buildTextFormField(_targetAmountController, "Target Amount (Tsh)", "Enter a target amount", keyboardType: TextInputType.number),
                  _buildTextFormField(_savingAmountController, "Saving Amount per Period", "Enter a saving amount", keyboardType: TextInputType.number),
                  _buildDropdown(),
                  SizedBox(height: 30),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, String errorText, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: DropdownButtonFormField<String>(
        value: _selectedFrequency,
        decoration: InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
        onChanged: (newValue) {
          setState(() {
            _selectedFrequency = newValue!;
          });
        },
        items: ["Weekly", "Monthly", "Yearly"].map((String frequency) {
          return DropdownMenuItem<String>(
            value: frequency,
            child: Text(frequency),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _saveGoal,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 80, vertical: 16),
      ),
      child: Text(widget.isEdit ? "Save Changes" : "Add Goal"),
    );
  }
}