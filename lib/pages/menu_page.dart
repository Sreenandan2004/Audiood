import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audiood/pages/help_page.dart';
import 'package:audiood/pages/about_page.dart';
import 'package:audiood/services/audio_service.dart';
import 'package:audiood/pages/rearrange_screen.dart';
import '../models/models.dart';

class MenuPage extends StatelessWidget {
  //const MenuPage({super.key});
  final List<dynamic> profiles;
  final List<dynamic> audios;
  final VoidCallback onReordered;

  const MenuPage({
    super.key,
    required this.profiles,
    required this.audios,
    required this.onReordered,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Subtle neutral ambient background glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Quick Action Hero Banner
                      _buildImportHeroCard(context),
                      const SizedBox(height: 28),

                      // Workspace Navigation Section
                      _buildSectionHeader('WORKSPACE'),
                      const SizedBox(height: 10),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildTile(
                              icon: Icons.home,
                              title: 'Profiles View',
                              subtitle: 'Go to Home Page',
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height:10),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildTile(
                              icon: Icons.grid_view_outlined,
                              title: 'Rearrange',
                              subtitle: 'Rearrange Profiles and Audios',
                              onTap: () async {
                                // Pop the menu first if needed, or push directly depending on your navigation structure
                                Navigator.pop(context);

                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RearrangeScreen(
                                      profiles: profiles.cast<FriendProfile>(), // Your main profiles list variable
                                      audios: audios?.cast<VoiceNote>(),     // Your main audios list variable
                                      onReordered: () {
                                        // Call setState or reload page counts/controllers in your home page
                                        // e.g., _initPageVariables();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Preferences Section
                      _buildSectionHeader('PREFERENCES'),
                      const SizedBox(height: 10),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildTile(
                              icon: Icons.help_outline_rounded,
                              title: 'Help & Shortcuts',
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HelpSupportPage(),
                                    ),
                                  ),
                            ),
                            _buildDivider(),
                            _buildTile(
                              icon: Icons.info_outline_rounded,
                              title: 'About Audiood',
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AboutPage(),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Compact Footer
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      'AUDIOOD LOCAL • BUILD 1.0.0',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        'Navigation',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImportHeroCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF161616),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final path = await AudioService.pickAudio();
            if (context.mounted) {
              Navigator.pop(context, path);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_to_photos_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import New Audio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pick from local files directly',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              )
              : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white24,
        size: 22,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 0,
      color: Colors.white.withValues(alpha: 0.04),
    );
  }
}
