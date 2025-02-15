import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/currency_model.dart';
import 'models/reminders_model.dart';
import 'models/savings_goal_model.dart';
import 'models/transaction_model.dart';
import 'models/user_profile.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/settings_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/savings_goals_screen.dart'; // Ensure this is correctly imported
import 'screens/onboard_screen.dart';
import 'screens/navbar.dart';
import 'screens/reminders_screen.dart';
import 'screens/reports_screen.dart'; // Ensure this is correctly imported and ONLY from reports_screen.dart
import 'screens/about_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Ensure Flutter is initialized

  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(CurrencyModelAdapter());
  Hive.registerAdapter(ReminderModelAdapter());
  Hive.registerAdapter(SavingsGoalModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  // Open boxes (only once)
  await Hive.openBox<CurrencyModel>('currency');
  await Hive.openBox<ReminderModel>('reminders');
  await Hive.openBox<SavingsGoalModel>('savingsGoal');
  await Hive.openBox<TransactionModel>('transactions');
  var settingsBox = await Hive.openBox<UserProfile>('settings');
  var onboardingBox = await Hive.openBox('onboarding');
  var reportSettingsBox = await Hive.openBox('report_settings'); // Add this line to open report_settings box

  // Initialize default profile if needed
  if (settingsBox.isEmpty) {
    settingsBox.add(UserProfile(name: 'User', preferredCurrency: 'USD', isDarkMode: false, language: 'en'));
  }

  // Check if the user has seen the onboarding screen before
  bool hasSeenOnboarding = onboardingBox.get('hasSeenOnboarding', defaultValue: false);

  runApp(MyApp(settingsBox: settingsBox, hasSeenOnboarding: hasSeenOnboarding, reportSettingsBox: reportSettingsBox));
}

class MyApp extends StatelessWidget {
  final Box<UserProfile> settingsBox;
  final bool hasSeenOnboarding;
  final Box reportSettingsBox;  // Add this to your constructor

  const MyApp({super.key, required this.settingsBox, required this.hasSeenOnboarding, required this.reportSettingsBox});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box<UserProfile> settings, _) {
        var userProfile = settings.getAt(0) ?? UserProfile(name: 'User', preferredCurrency: 'TZS');
        bool isDarkMode = userProfile.isDarkMode;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Akiba App',
          theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
          locale: Locale(userProfile.language),
          supportedLocales: [
            Locale('en', 'US'),
            Locale('sw', 'TZ'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          initialRoute: hasSeenOnboarding ? '/dashboard' : '/onboarding',
          routes: {
            '/onboarding': (context) => OnboardingScreen(settingsBox: settingsBox),
            '/dashboard': (context) => DashboardScreen(),
            '/transactions': (context) => TransactionsScreen(),
            '/savings': (context) => SavingsGoalsScreen(), // Ensure SavingsGoalsScreen is correctly referenced
            '/settings': (context) => SettingsScreen(settingsBox: settingsBox),
            '/navbar': (context) => NavBar(onItemSelected: (route) {}, userName: userProfile.name),
            '/about': (context) => AboutScreen(),
            '/reminders': (context) => RemindersScreen(),
            '/reports': (context) => ReportsExportScreen(reportSettingsBox: reportSettingsBox),  // Pass the box here, Ensure ReportsExportScreen is correctly referenced
          },
        );
      },
    );
  }
}