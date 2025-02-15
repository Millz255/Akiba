import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../screens/navbar.dart';

// Define the AboutScreen class
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  void _loadUserSettings() async {
    var box = await Hive.openBox('settings');
    setState(() {
      userName = box.get('userName', defaultValue: 'User');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Akiba'),
        backgroundColor: Colors.blue,
      ),
      drawer: NavBar(
        userName: userName,  // Now using Hive-stored username
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/about');
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildHeader(),
            _buildFaqSection(),
            _buildContactInfo(),
            _buildVersionNumber(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Akiba!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
        SizedBox(height: 10),
        Text(
          'Akiba is your personal assistant for managing savings and tracking expenses. Let us help you achieve your financial goals.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ).animate().fadeIn().move(begin: Offset(0, 10), end: Offset(0, 0)),
      ],
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
        ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
        SizedBox(height: 10),
        _buildFaqItem(
          question: 'How do I add savings?',
          answer: 'To add savings, go to the "Savings" tab, enter the amount, and press "Save".',
        ),
        _buildFaqItem(
          question: 'How can I track my expenses?',
          answer: 'Go to "Expenses" in the menu, where you can view and categorize all your transactions.',
        ),
        _buildFaqItem(
          question: 'How can I set financial goals?',
          answer: 'Navigate to "Goals", create a new goal, and set your savings target.',
        ),
      ],
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.help_outline, color: Colors.blue),
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              answer,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ).animate().fadeIn().scale(),
          )
        ],
      ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Contact Us',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
        ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
        SizedBox(height: 10),
        _buildContactItem('Phone', '+255752751416', Icons.phone),
        _buildContactItem('Email', 'mgimwaemily@gmail.com', Icons.email),
      ],
    );
  }

  Widget _buildContactItem(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 14, color: Colors.black54)),
      onTap: () {},
    ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0));
  }

  Widget _buildVersionNumber() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Version',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
        ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
        SizedBox(height: 10),
        Text(
          'Version 1.0.0',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ).animate().fadeIn().move(begin: Offset(0, 10), end: Offset(0, 0)),
      ],
    );
  }
}
