import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String notes;

  @HiveField(5)
  bool isIncome;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.notes,
    required this.isIncome,
  });

  Map<String, dynamic> toJson() => { // Add toJson for debugging
    'id': id,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(), // Store date as ISO string
    'notes': notes,
    'isIncome': isIncome,
  };
}