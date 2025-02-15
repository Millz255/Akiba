import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminders_model.dart'; // Import your ReminderModel
import '../screens/add_reminder_screen.dart'; // Import your AddReminderScreen
import '../screens/navbar.dart'; // Import your NavBar
import '../models/user_profile.dart'; // Import User Profile Model

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
    
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); // Initialize first!
    
    _initializeNotifications().then((_) {
      setState(() {}); // Ensure UI updates after initialization
    });

    remindersBox = Hive.box<ReminderModel>('reminders');
    userProfileBox = Hive.box<UserProfile>('userProfile');
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _loadUserProfile();
  }


  Future<void> _initializeNotifications() async {
  try {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    bool? initialized = await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print("Notifications Initialized: $initialized");
  } catch (e) {
    print("Error initializing notifications: $e");
  }
}


  Future<void> _sendRandomReminderNotification() async {
  final randomMessage = reminderMessages[
      DateTime.now().millisecondsSinceEpoch % reminderMessages.length];

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
    0,
    'Reminder to Save!',
    randomMessage,
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Reminders"),
        backgroundColor: Colors.blue,
      ),
      drawer: NavBar(
        onItemSelected: (route) { // Corrected parameter name
          // Handle navigation based on route
          Navigator.pushNamed(context, route);
        },
        userName: userName,
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
                          if (value) {
                            _sendRandomReminderNotification();
                          }
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