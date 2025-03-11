import 'package:hive/hive.dart';

part 'reminders_model.g.dart';

@HiveType(typeId: 2)
class ReminderModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime time;

  @HiveField(2)
  String message;

  @HiveField(3)
  bool isEnabled;

  ReminderModel({
    required this.id,
    required this.time,
    required this.message,
    required this.isEnabled,
  });
}
