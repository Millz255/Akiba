import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../screens/navbar.dart';
import '../models/user_profile.dart'; // Ensure your UserProfile model is imported

class AboutScreen extends StatefulWidget {
  final Box<UserProfile> settingsBox; // Pass the already opened box

  const AboutScreen({super.key, required this.settingsBox});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late Box<UserProfile> _settingsBox;
  String userName = "User";

  @override
  void initState() {
    super.initState();
    // Assign the passed box to a local variable
    _settingsBox = widget.settingsBox;
    // Fetch user information from the passed box
    _loadUserSettings();
  }

  // Fetch user information synchronously using the already opened box
  void _loadUserSettings() {
    final profile = _settingsBox.get('userName');
    setState(() {
      userName = profile?.name ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Akiba', style: TextStyle(fontFamily: 'Noto Sans')),
        backgroundColor: Colors.blue,
      ),
      drawer: NavBar(
        onItemSelected: (index) {
          print("Selected Item Index: $index");
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildHeader(context), // Pass context
            _buildFaqSection(context), // Pass context
            _buildContactInfo(context), // Pass context
            _buildVersionNumber(context), // Pass context
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) { // Take BuildContext
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Akiba',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // Kept blue as intended
            fontFamily: 'Noto Sans',
          ),
        ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
        SizedBox(height: 10),
        Text(
          'Akiba is your personal assistant for managing savings and tracking expenses. Let us help you achieve your financial goals.',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color, // Theme-aware color
            fontFamily: 'Noto Sans',
          ),
        ).animate().fadeIn().move(begin: Offset(0, 10), end: Offset(0, 0)),
      ],
    );
  }

  Widget _buildFaqSection(BuildContext context) { // Take BuildContext
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // Kept blue as intended
            fontFamily: 'Noto Sans',
          ),
        ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
        SizedBox(height: 10),
        _buildFaqItem(
          context: context, // Pass context
          question: 'How do I add savings?',
          answer: 'To add savings, go to the "Savings" tab, enter the amount, and press "Save".',
        ),
        _buildFaqItem(
          context: context, // Pass context
          question: 'How can I track my expenses?',
          answer: 'Go to "Expenses" in the menu, where you can view and categorize all your transactions.',
        ),
        _buildFaqItem(
          context: context, // Pass context
          question: 'How can I set financial goals?',
          answer: 'Navigate to "Goals", create a new goal, and set your savings target.',
        ),
      ],
    );
  }

  Widget _buildFaqItem({required BuildContext context, required String question, required String answer}) { // Take BuildContext
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.bodyLarge, // Theme-aware style, using bodyLarge
        ),
        leading: Icon(Icons.help_outline, color: Colors.blue),
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color, // Theme-aware color
                fontFamily: 'Noto Sans',
              ),
            ).animate().fadeIn().scale(),
          ),
        ],
      ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
    );
  }

  Widget _buildContactInfo(BuildContext context) { // Take BuildContext
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Contact Us',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // Kept blue as intended
            fontFamily: 'Noto Sans',
          ),
        ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
        SizedBox(height: 10),
        _buildContactItem(context, 'Phone', '+255752751416', Icons.phone), // Pass context
        _buildContactItem(context, 'Email', 'mgimwaemily@gmail.com', Icons.email), // Pass context
      ],
    );
  }

  Widget _buildContactItem(BuildContext context, String label, String value, IconData icon) { // Take BuildContext
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge, // Theme-aware style, using bodyLarge
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyMedium?.color, // Theme-aware color
          fontFamily: 'Noto Sans',
        ),
      ),
      onTap: () {},
    ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0));
  }

  Widget _buildVersionNumber(BuildContext context) { // Take BuildContext
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Version',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // Kept blue as intended
            fontFamily: 'Noto Sans',
          ),
        ).animate().fadeIn().move(begin: Offset(0, -10), end: Offset(0, 0)),
        SizedBox(height: 10),
        Text(
          'Version 1.0.0',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color, // Theme-aware color
            fontFamily: 'Noto Sans',
          ),
        ).animate().fadeIn().move(begin: Offset(0, 10), end: Offset(0, 0)),
      ],
    );
  }
}