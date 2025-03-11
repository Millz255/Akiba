import 'package:hive/hive.dart';

part 'currency_model.g.dart';  // This is correct for generating the TypeAdapter

@HiveType(typeId: 5)
class CurrencyModel {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final double exchangeRate;

  CurrencyModel({required this.code, required this.exchangeRate});
}
