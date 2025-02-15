import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:hive/hive.dart'; // Import Hive
import '../models/user_profile.dart'; // Import UserProfile model

class OnboardingScreen extends StatefulWidget {
  final Box<UserProfile> settingsBox; // ADDED: settingsBox parameter
  const OnboardingScreen({super.key, required this.settingsBox}); // MODIFIED constructor

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  // Controllers for the form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  String _selectedCurrency = 'TZS'; // Default currency

  // Currency options
  final List<String> currencies = ['TZS', 'USD', 'KES', 'UGX', 'ZAR'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Add gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => isLastPage = index == 2);
            },
            children: [
              buildPage(
                image: 'assets/savings.json',
                title: "Save Smartly",
                description: "Track your savings and manage finances with ease.",
              ),
              buildPage(
                image: 'assets/money_growth.json',
                title: "Grow Your Money",
                description: "Set financial goals and see your wealth grow.",
              ),
              buildSetupPage(),
            ],
          ),
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _controller.jumpToPage(2),
                  child: Text("Skip", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: WormEffect(dotHeight: 10, dotWidth: 10, activeDotColor: Colors.blue.shade100),
                ),
                isLastPage
                    ? TextButton(
                        onPressed: () async {
                          // 1. Use the settingsBox passed to the widget
                          final settingsBox = widget.settingsBox; // Access settingsBox using widget.

                          // 2. Create UserProfile object
                          final userProfile = UserProfile(
                            name: _fullNameController.text.trim(),
                            preferredCurrency: _selectedCurrency,
                            isDarkMode: false,
                            biometricEnabled: false,
                            language: 'en',
                            profileImagePath: null,
                          );

                          // 3. Save to widget.settingsBox
                          await settingsBox.clear(); // Clear existing profile in settingsBox if needed (optional)
                          await settingsBox.add(userProfile); // Add to settingsBox

                          print('UserProfile saved to settingsBox from Onboarding:');
                          print('Name: ${userProfile.name}');
                          print('Preferred Currency: ${userProfile.preferredCurrency}');

                          // 4. Navigate to dashboard screen
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        },
                        child: Text("Start", style: TextStyle(fontSize: 16, color: Colors.white)),
                      )
                    : TextButton(
                        onPressed: () => _controller.nextPage(duration: Duration(milliseconds: 500), curve: Curves.easeInOut),
                        child: Text("Next", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage({required String image, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Lottie.asset(image, height: 250),
          SizedBox(height: 30),
          Text(
            title,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }

  Widget buildSetupPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Let's Set Up Your Akiba Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 20),
          buildTextField(controller: _fullNameController, label: "Full Name"),
          SizedBox(height: 10),
          buildCurrencyDropdown(),
          SizedBox(height: 10),
          buildTextField(controller: _jobController, label: "Job / Business (Optional)"),
          SizedBox(height: 10),
          buildTextField(controller: _incomeController, label: "Another Source of Income (Optional)"),
        ],
      ),
    );
  }

  Widget buildTextField({required TextEditingController controller, required String label}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget buildCurrencyDropdown() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCurrency,
        onChanged: (newValue) {
          setState(() {
            _selectedCurrency = newValue!;
          });
        },
        decoration: InputDecoration(
          labelText: 'Preferred Currency',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: currencies.map<DropdownMenuItem<String>>((String currency) {
          return DropdownMenuItem<String>(
            value: currency,
            child: Text(currency),
          );
        }).toList(),
      ),
    );
  }
}