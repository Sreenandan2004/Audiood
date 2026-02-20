import 'package:flutter/material.dart';

class VoiceNote {
  final String title;
  final String mood;
  final String duration;
  final String filePath; // <--- Add this

  VoiceNote({
    required this.duration,
    required this.mood,
    required this.title,
    required this.filePath, // <--- Add this
  });
}

class FriendProfile {
  final String name;
  final String imagePath;
  final List<VoiceNote> voiceNotes;

  FriendProfile({
    required this.name,
    required this.voiceNotes,
    required this.imagePath,
  });
}