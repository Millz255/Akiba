import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Import your models
import '../models/currency_model.dart';
import '../models/user_profile.dart';

// Import your NavBar (Drawer)
import 'navbar.dart';

class SettingsScreen extends StatefulWidget {
  final Box<UserProfile> settingsBox; // Already has settingsBox parameter

  const SettingsScreen({super.key, required this.settingsBox});

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Call the async load function
  }

  Future<void> _loadUserProfile() async {
    var userProfileBox = widget.settingsBox; // Access settingsBox from widget

    // **FETCH ONBOARD USERNAME FIRST**
    var onboardUsernameValue = userProfileBox.get('onboardUsername'); // Get as dynamic

    String? onboardUsername; // Declare onboardUsername as String?

    if (onboardUsernameValue != null && onboardUsernameValue is String) {
      onboardUsername = onboardUsernameValue as String?; // Explicit cast to String? - FIX ERROR 1

      print("Onboard Username fetched from Hive (String): $onboardUsername");

      if (onboardUsername != null && onboardUsername.isNotEmpty) {
        // **IF ONBOARD USERNAME EXISTS, USE IT AS INITIAL NAME**
        _userProfile.name = onboardUsername; // Direct assignment now safe within this block - FIX ERROR 3
        print("Using onboard username as initial username.");
      }
    } else {
      print("No valid onboard username found in Hive or not a String.");
      // **FALLBACK TO EXISTING LOGIC IF ONBOARD USERNAME IS NOT FOUND OR NOT STRING**
      UserProfile? fetchedProfile = userProfileBox.get('currentUserProfile');
      if (fetchedProfile != null) {
        _userProfile = fetchedProfile;
        print("UserProfile loaded from Hive (SettingsScreen): ${_userProfile.name}");
      } else {
        // If no existing profile either, use default profile
        _userProfile = UserProfile(
          name: 'User',
          preferredCurrency: 'TZS',
          isDarkMode: false,
          biometricEnabled: false,
          language: 'en',
        );
        print("No UserProfile found in Hive, using default profile (SettingsScreen)");
      }
    }

    _nameController.text = _userProfile.name; // Set the text controller with the loaded or default name
    _currentCurrency = CurrencyModel(code: _userProfile.preferredCurrency, exchangeRate: 1.0);
    setState(() {
      _isLoading = false; // Set loading to false after profile is loaded
    });
  }

  void _saveSettings() {
    _userProfile.name = _nameController.text;
    _userProfile.preferredCurrency = _currentCurrency.code;

    // **SAVE ONLY WITH KEY - CONSISTENTLY USE KEY-BASED OPERATIONS**
    widget.settingsBox.put('currentUserProfile', _userProfile); // Save using key 'currentUserProfile'

    print('Settings saved (key-based):');
    print('Saved Username in Settings: ${_userProfile.name}');
    print('Preferred Currency: ${_userProfile.preferredCurrency}');

    // **IMMEDIATE BOX INSPECTION - RIGHT AFTER SAVE (KEY-BASED GET)**
    var boxContents = widget.settingsBox.get('currentUserProfile'); // Get using key
    print("Immediately after settings save, box contents (currentUserProfile): $boxContents");
    if (boxContents is UserProfile) {
      print("Box contents (currentUserProfile) Name: ${(boxContents).name}");
    } else {
      print("Box contents (currentUserProfile) is NOT UserProfile type, or null");
    }
    print("Box length immediately after settings save: ${widget.settingsBox.length}");

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
}