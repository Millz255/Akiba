import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminders_model.dart';
import '../screens/add_reminder_screen.dart'; 
import '../screens/navbar.dart';
import '../models/user_profile.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:google_fonts/google_fonts.dart';

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
  Timer? _randomNotificationTimer;

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
    userProfileBox = Hive.box<UserProfile>('settings');
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _loadUserProfile();

    _scheduleRandomNotifications();
    _scheduleReminderNotifications();
  }

  @override
  void dispose() {
    _randomNotificationTimer?.cancel(); 
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

    
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

     
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
  
    tzdata.initializeTimeZones(); 
    tz.setLocalLocation(tz.getLocation('Africa/Dar_es_Salaam'));
  }

  Future<void> _sendRandomReminderNotification() async {
    final randomMessage = reminderMessages[
        DateTime.now().millisecondsSinceEpoch % reminderMessages.length];

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'encouragement_channel', 
      'Encouragement',       
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      1, 
      'Words of Encouragement!', 
      'Hello $userName, $randomMessage', 
      notificationDetails,
    );
  }

  void _scheduleReminderNotifications() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      final now = tz.TZDateTime.now(tz.local);
      for (var reminder in remindersBox.values) {
        if (reminder.isEnabled) {
          final reminderTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            reminder.time.hour,
            reminder.time.minute,
          );
          if (reminderTime.isBefore(now)) {
            reminderTime.add(Duration(days: 1)); 
          }
          if (reminderTime.difference(now).inMinutes <= 1) {
            _showReminderNotification(reminder);
          }
        }
      }
    });
  }

  void _scheduleRandomNotifications() {
    
    final now = DateTime.now();
    final noonToday = DateTime(now.year, now.month, now.day, 12, 0, 0); 
    DateTime nextNotificationTime;

    if (now.isAfter(noonToday)) {
      
      nextNotificationTime = noonToday.add(Duration(days: 1));
    } else {
      
      nextNotificationTime = noonToday;
    }

    final initialDelay = nextNotificationTime.difference(now);

    _randomNotificationTimer = Timer(initialDelay, () {
      _sendRandomReminderNotification(); 


      _randomNotificationTimer = Timer.periodic(Duration(days: 1), (timer) {
        _sendRandomReminderNotification(); 
      });
    });
  }

  Future<void> _showReminderNotification(ReminderModel reminder) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      reminder.id.hashCode, 
      'Reminder',
      reminder.message,
      notificationDetails,
    );
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
        title: Text("Reminders", style: GoogleFonts.notoSans()),
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
          setState(() {}); 
        },
      ),
      body: ValueListenableBuilder(
        valueListenable: remindersBox.listenable(),
        builder: (context, Box<ReminderModel> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text(
                "No reminders set. Add one!",
                style: GoogleFonts.notoSans(),
              ),
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
                      title: Text(reminder.message, style: GoogleFonts.notoSans()),
                      subtitle: Text(
                        DateFormat.jm().format(reminder.time),
                        style: GoogleFonts.notoSans(),
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
