import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/currency_model.dart';
import 'models/reminders_model.dart';
import 'models/savings_goal_model.dart';
import 'models/transaction_model.dart';
import 'models/user_profile.dart';
import 'screens/settings_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/savings_goals_screen.dart';
import 'screens/onboard_screen.dart';
import 'screens/navbar.dart';
import 'screens/reminders_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/about_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData _buildThemeData(bool isDarkMode) {
  return isDarkMode
      ? ThemeData.dark().copyWith(
          textTheme: TextTheme(
            bodyLarge: GoogleFonts.roboto(fontSize: 16, color: Colors.white), 
            bodyMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.white), 
            headlineLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white), 
            headlineMedium: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), 
            bodySmall: TextStyle(fontFamily: 'NotoSansSymbols', fontSize: 12, color: Colors.white), 
            titleMedium: TextStyle(fontFamily: 'NotoColorEmoji', fontSize: 18, color: Colors.white), 
          ),
        )
      : ThemeData.light().copyWith(
          textTheme: TextTheme(
            bodyLarge: GoogleFonts.roboto(fontSize: 16, color: Colors.black), 
            bodyMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.black), 
            headlineLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black), 
            headlineMedium: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black), 
            bodySmall: TextStyle(fontFamily: 'NotoSansSymbols', fontSize: 12, color: Colors.black), 
            titleMedium: TextStyle(fontFamily: 'NotoColorEmoji', fontSize: 18, color: Colors.black), 
          ),
        );
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();

    Hive.registerAdapter(CurrencyModelAdapter());
    Hive.registerAdapter(ReminderModelAdapter());
    Hive.registerAdapter(SavingsGoalModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(UserProfileAdapter());

    try {
      await Hive.openBox<CurrencyModel>('currency');
      print('Currency box opened successfully');
    } catch (e) {
      print('Error opening currency box: $e');
    }
    try {
      await Hive.openBox<ReminderModel>('reminders');
      print('Reminders box opened successfully');
    } catch (e) {
      print('Error opening reminders box: $e');
    }
    try {
      await Hive.openBox<SavingsGoalModel>('savingsGoal');
      print('SavingsGoal box opened successfully');
    } catch (e) {
      print('Error opening savingsGoal box: $e');
    }
    try {
      await Hive.openBox<TransactionModel>('transactions');
      print('Transactions box opened successfully');
    } catch (e) {
      print('Error opening transactions box: $e');
    }
    try {
      await Hive.openBox('userSettings');
      print('userSettings box opened successfully');
    } catch (e) {
      print('Error opening userSettings box: $e');
    }
    late Box<UserProfile> settingsBox; // Declare settingsBox outside try to use later
    try {
      settingsBox = await Hive.openBox<UserProfile>('settings');
      print('Settings box opened successfully');
    } catch (e) {
      print('Error opening settings box: $e');
      return; // Importantly return if settingsBox fails to open, don't runApp
    }
    try {
      await Hive.openBox('onboarding');
      print('Onboarding box opened successfully');
    } catch (e) {
      print('Error opening onboarding box: $e');
    }
    try {
      await Hive.openBox('report_settings');
      print('Report settings box opened successfully');
    } catch (e) {
      print('Error opening report_settings box: $e');
    }

    var onboardingBox = await Hive.openBox('onboarding');
    var reportSettingsBox = await Hive.openBox('report_settings');


    bool hasSeenOnboarding = onboardingBox.get('hasSeenOnboarding', defaultValue: false);


    UserProfile? existingProfile = settingsBox.get('currentUserProfile');
    if (existingProfile == null) {
      try {
        await settingsBox.put(
          'currentUserProfile',
          UserProfile(name: 'Username', preferredCurrency: 'TZS', isDarkMode: false, language: 'en'),
        );
      } catch (e) {
        print('Error adding default user profile during onboarding: $e');
      }
    }

    runApp(MyApp(
      settingsBox: settingsBox, // Now settingsBox is guaranteed to be initialized (or main() would have returned)
      hasSeenOnboarding: hasSeenOnboarding,
      reportSettingsBox: reportSettingsBox,
      onboardingBox: onboardingBox,
    ));
  } catch (e) {
    print('General error during Hive initialization or box opening: $e');
  }
}

class MyApp extends StatelessWidget {
  final Box<UserProfile> settingsBox;
  final bool hasSeenOnboarding;
  final Box reportSettingsBox;
  final Box onboardingBox;

  const MyApp({
    super.key,
    required this.settingsBox,
    required this.hasSeenOnboarding,
    required this.reportSettingsBox,
    required this.onboardingBox,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<UserProfile>>(
      valueListenable: settingsBox.listenable(keys: ['currentUserProfile']),
      builder: (context, Box<UserProfile> settings, _) {
        final userProfile = settings.get('currentUserProfile');
        final isDarkMode = userProfile?.isDarkMode ?? false;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Akiba',
          theme: _buildThemeData(false),
          darkTheme: _buildThemeData(true),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          locale: Locale(userProfile?.language ?? 'en'),
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('sw', 'TZ'),
          ],
          localizationsDelegates: [
            ...GlobalMaterialLocalizations.delegates,
            GlobalWidgetsLocalizations.delegate,
          ],
          initialRoute: hasSeenOnboarding ? '/dashboard' : '/onboarding',
          routes: {
            '/onboarding': (context) => OnboardingScreen(settingsBox: settingsBox, onboardingBox: onboardingBox),
            '/dashboard': (context) => DashboardScreen(),
            '/transactions': (context) => TransactionsScreen(),
            '/savings': (context) => SavingsGoalsScreen(),
            '/settings': (context) => SettingsScreen(settingsBox: settingsBox, onboardingBox: onboardingBox),
            '/navbar': (context) => NavBar(onItemSelected: (route) {}),
            '/about': (context) => AboutScreen(settingsBox: settingsBox),
            '/reminders': (context) => RemindersScreen(),
            '/reports': (context) => ReportsExportScreen(reportSettingsBox: reportSettingsBox),
          },
        );
      },
    );
  }
}
