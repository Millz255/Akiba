import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class OnboardingScreen extends StatefulWidget {
  final Box<UserProfile> settingsBox;
  final Box onboardingBox;
  const OnboardingScreen({super.key, required this.settingsBox, required this.onboardingBox});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  String _selectedCurrency = 'TZS';
  final List<String> currencies = ['TZS'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
            onPageChanged: (index) => setState(() => isLastPage = index == 2),
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
                  child: const Text("Skip", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: WormEffect(dotHeight: 10, dotWidth: 10, activeDotColor: Colors.blue.shade100),
                ),
                isLastPage
                    ? TextButton(
                        onPressed: saveUserProfile,
                        child: const Text("Start", style: TextStyle(fontSize: 16, color: Colors.white)),
                      )
                    : TextButton(
                        onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                        child: const Text("Next", style: TextStyle(fontSize: 16, color: Colors.white)),
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
        children: [
          Lottie.asset(image, height: 250),
          const SizedBox(height: 30),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade300)),
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
          const Text("Let's Set Up Your Akiba Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          buildTextField(controller: _fullNameController, label: "Full Name"),
          const SizedBox(height: 10),
          buildCurrencyDropdown(),
          const SizedBox(height: 10),
          buildTextField(controller: _jobController, label: "Job / Business (Optional)"),
          const SizedBox(height: 10),
          buildTextField(controller: _incomeController, label: "Another Source of Income (Optional)"),
        ],
      ),
    );
  }

  Widget buildTextField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      onChanged: (newValue) => setState(() => _selectedCurrency = newValue!),
      decoration: InputDecoration(
        labelText: 'Preferred Currency',
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: currencies.map((currency) => DropdownMenuItem(value: currency, child: Text(currency))).toList(),
    );
  }

  Future<void> saveUserProfile() async {
    final userProfile = UserProfile(
      name: _fullNameController.text.trim(), // Keep storing fullName as name for compatibility
      preferredCurrency: _selectedCurrency,
      isDarkMode: false,
      biometricEnabled: false,
      language: 'en',
      profileImagePath: null,
    );

    // **SAVE ONBOARDING DATA TO onboardingBox**
    await widget.onboardingBox.put('fullName', _fullNameController.text.trim()); // Use onboardingBox.put
    await widget.onboardingBox.put('job', _jobController.text.trim());       // Use onboardingBox.put
    await widget.onboardingBox.put('income', _incomeController.text.trim());     // Use onboardingBox.put
    await widget.onboardingBox.put('preferredCurrencyOnboarding', _selectedCurrency); // Use onboardingBox.put


    await widget.settingsBox.put('currentUserProfile', userProfile); // Save UserProfile object to settingsBox
    await widget.onboardingBox.put('hasSeenOnboarding', true);

    Navigator.pushReplacementNamed(context, '/dashboard');
  }
}