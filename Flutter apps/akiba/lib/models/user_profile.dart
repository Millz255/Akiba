import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 4)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String preferredCurrency;

  @HiveField(2)
  bool biometricEnabled;

  @HiveField(3)
  bool isDarkMode;

  @HiveField(4)
  String language;

  @HiveField(5)
  String? profileImagePath;

  UserProfile({
    required this.name,
    required this.preferredCurrency,
    this.biometricEnabled = false,
    this.isDarkMode = false,
    this.language = 'en',
    this.profileImagePath,
  });
}
