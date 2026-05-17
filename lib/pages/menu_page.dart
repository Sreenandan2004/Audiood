import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          _buildMenuItem(
            context,
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () {
              // TODO: Navigate to Home
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.library_music_outlined,
            title: 'My Library',
            onTap: () {
              // TODO: Navigate to Library
            },
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.favorite_outline,
            title: 'Favorites',
            onTap: () {
              // TODO: Navigate to Favorites
            },
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              // TODO: Navigate to Settings
            },
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // TODO: Navigate to Help
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
