import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminders_model.dart'; // Import your ReminderModel
import '../screens/add_reminder_screen.dart'; // Import your AddReminderScreen
import '../screens/navbar.dart'; // Import your NavBar
import '../models/user_profile.dart'; // Import User Profile Model
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async'; // Import dart:async for Timer


class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late Box<ReminderModel> remindersBox;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late Box<UserProfile> userProfileBox;
  String userName = "User";
  late AnimationController _animationController;
  Timer? _randomNotificationTimer; // Timer for random notifications

  final List<String> reminderMessages = [
    "Save a little, smile a lot! 😊",
    "Money saved today is happiness tomorrow! 💸",
    "Every penny counts, don’t forget to save! 💪",
    "A penny saved is a penny earned! 🏦",
    "Budget now, enjoy later! 🥳",
    "Save smart, live happy! 🏖️",
    "Your future self will thank you for saving! 🌟",
    "Don’t spend it all! Think before you spend! 🤔",
    "Saving today is investing in tomorrow! 💰",
    "Be wise, save the prize! 🏆"
  ];

  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications().then((_) {
      setState(() {});
    });

    remindersBox = Hive.box<ReminderModel>('reminders');
    print("Is remindersBox open in RemindersScreen initState?: ${remindersBox.isOpen}");

    userProfileBox = Hive.box<UserProfile>('settings');
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _loadUserProfile();

    _scheduleRandomNotifications(); // Schedule random notifications on init
  }

  @override
  void dispose() {
    _randomNotificationTimer?.cancel(); // Cancel timer when screen is disposed
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> checkNotificationPermission() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted = await androidImplementation?.areNotificationsEnabled();
    return granted ?? false;
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
          InitializationSettings(android: androidInitializationSettings);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Get Android SDK version
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      // Request permission for notifications (Android 13+)
      if (androidInfo.version.sdkInt >= 33) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      print("Notifications Initialized Successfully");
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }

  Future<void> _sendRandomReminderNotification() async {
    final randomMessage = reminderMessages[
        DateTime.now().millisecondsSinceEpoch % reminderMessages.length];

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'encouragement_channel', // Changed channel ID
      'Encouragement',        // Changed channel Name
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // Changed notification ID to avoid conflict with reminder notifications if you have any in future
      'Words of Encouragement!', // Changed title
      'Hello $userName, $randomMessage', // Added username to the message
      notificationDetails,
    );
  }

  void _scheduleRandomNotifications() {
    // Set the interval for random notifications (e.g., daily at noon)
    final now = DateTime.now();
    final noonToday = DateTime(now.year, now.month, now.day, 12, 0, 0); // Noon today
    DateTime nextNotificationTime;

    if (now.isAfter(noonToday)) {
      // If it's already past noon, schedule for noon tomorrow
      nextNotificationTime = noonToday.add(Duration(days: 1));
    } else {
      // Otherwise, schedule for noon today
      nextNotificationTime = noonToday;
    }

    final initialDelay = nextNotificationTime.difference(now);

    _randomNotificationTimer = Timer(initialDelay, () {
      _sendRandomReminderNotification(); // Send notification at the scheduled time

      // Schedule the next notification for the next day
      _randomNotificationTimer = Timer.periodic(Duration(days: 1), (timer) {
        _sendRandomReminderNotification(); // Send notification daily
      });
    });
  }


  void _loadUserProfile() {
    if (userProfileBox.isNotEmpty) {
      setState(() {
        userName = userProfileBox.getAt(0)?.name ?? "User";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Is remindersBox open BEFORE ValueListenableBuilder?: ${remindersBox.isOpen}");
    return Scaffold(
      appBar: AppBar(
        title: Text("Reminders"),
        backgroundColor: Colors.blue,
      ),
      drawer: NavBar(
        onItemSelected: (index) {
          print("Selected Item Index: $index");
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddReminderScreen()),
          );
          setState(() {}); // Refresh the list after adding a reminder
        },
      ),
      body: ValueListenableBuilder(
        valueListenable: remindersBox.listenable(),
        builder: (context, Box<ReminderModel> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text("No reminders set. Add one!"),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final ReminderModel reminder = box.getAt(index)!;

              return Dismissible(
                key: Key(reminder.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  reminder.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Reminder deleted")),
                  );
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddReminderScreen(reminder: reminder),
                      ),
                    );
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(Icons.alarm, color: Colors.blue, size: 32),
                      title: Text(
                        DateFormat.jm().format(reminder.time),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(reminder.message),
                      trailing: Switch(
                        value: reminder.isEnabled,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            reminder.isEnabled = value;
                            reminder.save();
                          });
                          // Removed the call to _sendRandomReminderNotification() from here
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}