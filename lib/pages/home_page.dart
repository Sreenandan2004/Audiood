import 'package:flutter/material.dart';

import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dummy data for now
  final List<FriendProfile> profiles = [
    FriendProfile(name: "ZONAL", imagePath: "assets/zonal.jpg", voiceNotes: []),
    FriendProfile(name: "ABHAI", imagePath: "assets/abhai.jpg", voiceNotes: []),
    // Add more...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return Stack(
            children: [
              // Layer 1: The Background Image
              // TODO: How do we make this fill the screen?

              // Layer 2: The Gradient/Overlay for readability

              // Layer 3: The Content (Header + List)
            ],
          );
        },
      ),
    );
  }
}
