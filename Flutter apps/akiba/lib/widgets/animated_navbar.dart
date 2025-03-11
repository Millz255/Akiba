import 'package:flutter/material.dart';

class AnimatedNavbar extends StatelessWidget {
  final Function(String) onSelect;

  const AnimatedNavbar({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text('Hello, User!'),
            accountEmail: Text('Track your savings'),
            decoration: BoxDecoration(color: Colors.blue),
          ),
          _buildNavItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
          _buildNavItem(context, Icons.swap_vert, 'Transactions', '/transactions'),
          _buildNavItem(context, Icons.savings, 'Savings Goals', '/goals'),
          _buildNavItem(context, Icons.notifications, 'Reminders', '/reminders'),
          _buildNavItem(context, Icons.settings, 'Settings', '/settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pushReplacementNamed(route);
      },
    );
  }
}
