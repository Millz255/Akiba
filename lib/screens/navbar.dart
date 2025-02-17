import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:path_provider/path_provider.dart'; // Import path_provider
import '../models/user_profile.dart';

class NavBar extends StatefulWidget {
  final Function(String) onItemSelected;
  // Removed userName parameter - NavBar will fetch it directly
  const NavBar({super.key, required this.onItemSelected});

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  File? _profileImage;
  late Box<UserProfile> _userProfileBox;
  UserProfile? _userProfile; // Make it nullable initially for loading state
  // Removed local userName variable - using _userProfile?.name

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _openUserProfileBox();
  }

  Future<void> _openUserProfileBox() async {
    _userProfileBox = await Hive.openBox<UserProfile>('settings'); // Changed to 'settings' to match main.dart
    _loadUserProfile(); // Load user profile after opening the box
  }

  Future<void> _loadUserProfile() async {
    if (_userProfileBox.isNotEmpty) {
      setState(() {
        _userProfile = _userProfileBox.getAt(0)!; // Get UserProfile from settingsBox
        if (_userProfile!.profileImagePath != null) {
          _profileImage = File(_userProfile!.profileImagePath!);
        }
      });
    } else {
      // This case should ideally not be reached as UserProfile is created in main.dart and onboarding
      setState(() {
        _userProfile = UserProfile( // Setting a default UserProfile if box is empty (less likely now)
          name: 'User',
          preferredCurrency: 'USD',
          isDarkMode: false,
          biometricEnabled: false,
          language: 'en',
        );
      });
      _userProfileBox.add(_userProfile!); // Add default profile if box was empty
    }
  }


  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final newFile = File('${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await File(pickedFile.path).copy(newFile.path);

        setState(() {
          _profileImage = newFile;
          _userProfile!.profileImagePath = newFile.path; // Use non-nullable _userProfile here
          _userProfileBox.putAt(0, _userProfile!); // Use non-nullable _userProfile here
        });
      } catch (e) {
        print("Error saving image: $e");
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if _userProfile is still null
    if (_userProfile == null) {
      return Drawer(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(),
          _buildNavItem(context, Icons.dashboard, "Dashboard", '/dashboard'),
          _buildNavItem(context, Icons.swap_horiz, "Transactions", '/transactions'),
          _buildNavItem(context, Icons.savings, "Savings Goals", '/savings'),
          _buildNavItem(context, Icons.alarm, "Reminders", '/reminders'),
          _buildNavItem(context, Icons.bar_chart, "Reports", '/reports'),
          _buildNavItem(context, Icons.info, "About", '/about'),
          _buildNavItem(context, Icons.settings, "Settings", '/settings'),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildBottomSheet(),
              );
            },
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + _animationController.value * 0.1,
                  child: Opacity(
                    opacity: 1.0 - _animationController.value * 0.2,
                    child: child,
                  ),
                );
              },
              child: _buildProfilePicture(),
            ),
          ),
          const SizedBox(height: 16),
          Text(' ${_userProfile?.name ?? "User"}', // Display _userProfile.name, default to "User" if null
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
      child: _profileImage == null
          ? Icon(Icons.person, color: Colors.blue.shade700, size: 40)
          : null,
    );
  }

  Widget _buildBottomSheet() {
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take Photo'),
            onTap: () {
              _pickImage(ImageSource.camera);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Choose from Gallery'),
            onTap: () {
              _pickImage(ImageSource.gallery);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route) {
    return InkWell(
      onTap: () {
        widget.onItemSelected(route);

        // Close the drawer only if it's open
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }

        Navigator.pushReplacementNamed(context, route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}