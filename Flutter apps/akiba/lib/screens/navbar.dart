import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';

class NavBar extends StatefulWidget {
  final Function(String) onItemSelected;
  const NavBar({super.key, required this.onItemSelected});

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  File? _profileImage;
  late Box<UserProfile> _userProfileBox;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _openUserProfileBox();
  }

  Future<void> _openUserProfileBox() async {
    _userProfileBox = await Hive.openBox<UserProfile>('settings');
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_userProfileBox.isNotEmpty) {
      setState(() {
        _userProfile = _userProfileBox.getAt(0)!;
        if (_userProfile!.profileImagePath != null) {
          _profileImage = File(_userProfile!.profileImagePath!);
        }
      });
    } else {
      setState(() {
        _userProfile = UserProfile(
          name: 'User',
          preferredCurrency: 'USD',
          isDarkMode: false,
          biometricEnabled: false,
          language: 'en',
        );
      });
      _userProfileBox.add(_userProfile!);
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
          _userProfile!.profileImagePath = newFile.path;
          _userProfileBox.putAt(0, _userProfile!);
        });
      } catch (e) {
        debugPrint("Error saving image: $e");
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
    if (_userProfile == null) {
      return const Drawer(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(),
          _buildNavItem(Icons.dashboard, "Dashboard", '/dashboard'),
          _buildNavItem(Icons.swap_horiz, "Transactions", '/transactions'),
          _buildNavItem(Icons.savings, "Savings Goals", '/savings'),
          _buildNavItem(Icons.alarm, "Reminders", '/reminders'),
          _buildNavItem(Icons.bar_chart, "Reports", '/reports'),
          _buildNavItem(Icons.info, "About", '/about'),
          _buildNavItem(Icons.settings, "Settings", '/settings'),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: Colors.blue.shade700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (context) => _buildBottomSheet(),
            ),
            child: _buildProfilePicture(),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.name ?? "User",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoEmoji',
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
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              _pickImage(ImageSource.camera);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Choose from Gallery'),
            onTap: () {
              _pickImage(ImageSource.gallery);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'NotoEmoji',
        ),
      ),
      onTap: () {
        widget.onItemSelected(route);
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}
