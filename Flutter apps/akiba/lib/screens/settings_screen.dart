import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Import your models
import '../models/currency_model.dart';
import '../models/user_profile.dart';

// Import your NavBar (Drawer)
import 'navbar.dart';

class SettingsScreen extends StatefulWidget {
  final Box<UserProfile> settingsBox; // Already has settingsBox parameter
  final Box onboardingBox; // Add onboardingBox parameter

  const SettingsScreen({super.key, required this.settingsBox, required this.onboardingBox}); // Receive onboardingBox

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile _userProfile = UserProfile(
    name: 'Username',
    preferredCurrency: 'TZS',
    isDarkMode: false,
    biometricEnabled: false,
    language: 'en',
  );

  late CurrencyModel _currentCurrency;
  final _nameController = TextEditingController();
  final _jobController = TextEditingController(); // New controller for Job
  final _incomeController = TextEditingController(); // New controller for Income
  String _selectedCurrencyDropdown = 'TZS'; // For Currency Dropdown
  final List<String> currencies = ['TZS']; // Currencies list - you might want to populate this dynamically

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Call the async load function
  }

  Future<void> _loadUserProfile() async {
    var userProfileBox = widget.settingsBox; // Access settingsBox from widget
    var onboardBox = widget.onboardingBox; // Access onboardingBox from widget

    // **FETCH ONBOARDING DATA FROM onboardingBox**
    String? fullName = onboardBox.get('fullName');
    String? job = onboardBox.get('job');
    String? income = onboardBox.get('income');
    String? preferredCurrencyOnboarding = onboardBox.get('preferredCurrencyOnboarding');

    // **LOAD EXISTING USERPROFILE FROM settingsBox**
    UserProfile? fetchedProfile = userProfileBox.get('currentUserProfile');

    if (fetchedProfile != null) {
      _userProfile = fetchedProfile;
    }

    // **SET INITIAL VALUES FROM FETCHED DATA OR USERPROFILE OR DEFAULTS**
    _nameController.text = fullName ?? _userProfile.name; // Use fullName from onboarding or existing name or default
    _jobController.text = job ?? ''; // Use job from onboarding or default empty string
    _incomeController.text = income ?? ''; // Use income from onboarding or default empty string
    _selectedCurrencyDropdown = preferredCurrencyOnboarding ?? _userProfile.preferredCurrency; // Use onboarding currency or userProfile or default 'TZS'
    _currentCurrency = CurrencyModel(code: _selectedCurrencyDropdown, exchangeRate: 1.0); // Initialize _currentCurrency

    setState(() {
      _isLoading = false; // Set loading to false after profile is loaded
    });
  }

  void _saveSettings() {
    _userProfile.name = _nameController.text;
    _userProfile.preferredCurrency = _selectedCurrencyDropdown; // Use selected currency from dropdown

    // **SAVE ONBOARDING DATA TO onboardingBox**
    widget.onboardingBox.put('fullName', _nameController.text); // Use onboardingBox.put
    widget.onboardingBox.put('job', _jobController.text);      // Use onboardingBox.put
    widget.onboardingBox.put('income', _incomeController.text);    // Use onboardingBox.put
    widget.onboardingBox.put('preferredCurrencyOnboarding', _selectedCurrencyDropdown); // Use onboardingBox.put

    // **SAVE USERPROFILE OBJECT TO settingsBox**
    widget.settingsBox.put('currentUserProfile', _userProfile); // Keep saving UserProfile to settingsBox

    print('Settings saved (key-based):');
    print('Saved Username in Settings: ${_userProfile.name}');
    print('Preferred Currency: ${_userProfile.preferredCurrency}');
    print('Saved Job: ${_jobController.text}');
    print('Saved Income: ${_incomeController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Show a loading indicator
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
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
            _buildProfileSection(),
            Divider(),
            _buildThemeSection(_userProfile.isDarkMode),
            Divider(),
            _buildBiometricSecuritySection(_userProfile.biometricEnabled),
            Divider(),
            _buildLanguageSection(_userProfile.language),
            Divider(),
            _buildCurrencySection(), // New Currency Section
            Divider(),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: Text("Save Settings"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Management',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person, color: Colors.blue),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _jobController,
          decoration: InputDecoration(
            labelText: 'Job / Business (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work, color: Colors.blue),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _incomeController,
          decoration: InputDecoration(
            labelText: 'Another Source of Income (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection(bool isDarkMode) {
    return ListTile(
      title: Text('Theme Selection'),
      subtitle: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
      leading: Icon(Icons.color_lens, color: Colors.blue),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (bool value) {
          setState(() {
            _userProfile.isDarkMode = value;
          });
        },
      ),
    );
  }

  Widget _buildBiometricSecuritySection(bool isBiometricEnabled) {
    return ListTile(
      title: Text('Biometric Security'),
      subtitle: Text(isBiometricEnabled ? 'Enabled' : 'Disabled'),
      leading: Icon(Icons.fingerprint, color: Colors.blue),
      trailing: Switch(
        value: isBiometricEnabled,
        onChanged: (bool value) {
          setState(() {
            _userProfile.biometricEnabled = value;
          });
        },
      ),
    );
  }

  Widget _buildLanguageSection(String currentLanguage) {
    return ListTile(
      title: Text('Language'),
      subtitle: Text(currentLanguage == 'en' ? 'English' : 'Swahili'),
      leading: Icon(Icons.language, color: Colors.blue),
      trailing: DropdownButton<String>(
        value: currentLanguage,
        onChanged: (String? newValue) {
          setState(() {
            _userProfile.language = newValue ?? 'en';
          });
          // Force a rebuild (NOT ideal for production, just for testing)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context is Element) { // Check if context is still valid
              (context as Element).reassemble();
            }
          });
        },
        items: <String>['en', 'sw'].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value == 'en' ? 'English' : 'Swahili'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrencySection() {
    return ListTile(
      title: Text('Preferred Currency'),
      subtitle: Text(_selectedCurrencyDropdown),
      leading: Icon(Icons.monetization_on, color: Colors.blue),
      trailing: SizedBox( // Wrap DropdownButtonFormField in a SizedBox
        width: 150.0, // Set a maximum width for the dropdown - adjust as needed
        child: DropdownButtonFormField<String>(
          value: _selectedCurrencyDropdown,
          onChanged: (String? newValue) {
            setState(() {
              _selectedCurrencyDropdown = newValue ?? 'TZS';
              _currentCurrency = CurrencyModel(code: _selectedCurrencyDropdown, exchangeRate: 1.0);
            });
          },
          items: currencies.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}