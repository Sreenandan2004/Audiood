import 'package:flutter/material.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Your updated data
  final List<FriendProfile> profiles = [
    FriendProfile(name: "ZONAL", imagePath: "assets/Zonal.jpg", voiceNotes: []),
    FriendProfile(name: "ABHAI", imagePath: "assets/Abhai.jpg", voiceNotes: []),
    FriendProfile(name: "SURA", voiceNotes: [], imagePath: "assets/Sura.jpg"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];

          return Stack(
            children: [
              // Layer 1: The Background Image
              Positioned.fill(
                child: Image.asset(profile.imagePath, fit: BoxFit.cover),
              ),

              // Layer 2: The Gradient/Overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Layer 3: The Content (Header + List)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      // The Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.menu, color: Colors.white),

                          // The Glassmorphism Name Banner
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          const Icon(Icons.settings, color: Colors.white),
                        ],
                      ),

                      const Spacer(),

                      // The Audio List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 20),
                          itemCount: 5, // Dummy count to test the UI
                          itemBuilder: (context, index) {
                            // We will build our ListTile here!
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),

                              // 1. The Leading Play Button
                              leading: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.play_arrow),
                              ),

                              // 2. The Title & Subtitle
                              title: const Text(
                                "Audio name",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                "happy",
                                style: TextStyle(color: Colors.white54),
                              ),

                              // 3. The Trailing Share/Forward Button
                              trailing: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white70,
                                ),
                                child: Icon(Icons.share),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
