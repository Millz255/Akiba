import 'package:hive/hive.dart';

part 'savings_goal_model.g.dart'; // This links to the generated file

@HiveType(typeId: 3)
class SavingsGoalModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double targetAmount;

  @HiveField(2)
  double savedAmount;

  @HiveField(3)
  String frequency;

  @HiveField(4)
  double savingAmount;

  @HiveField(5)
  DateTime dateTime;

  @HiveField(6)
  List<Map<String, dynamic>> savingsEntries;

  // Private constructor
  SavingsGoalModel._({
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.frequency,
    required this.savingAmount,
    required this.dateTime,
    required this.savingsEntries,
  });

  // Factory constructor
  factory SavingsGoalModel({
    required String title,
    required double targetAmount,
    required double savedAmount,
    required String frequency,
    required double savingAmount,
    required DateTime dateTime,
    List<Map<String, dynamic>>? savingsEntries,
  }) {
    return SavingsGoalModel._(
      title: title,
      targetAmount: targetAmount,
      savedAmount: savedAmount,
      frequency: frequency,
      savingAmount: savingAmount,
      dateTime: dateTime,
      savingsEntries: savingsEntries ?? [], // Initialize with a modifiable list
    );
  }

  double get progress => targetAmount == 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);
}