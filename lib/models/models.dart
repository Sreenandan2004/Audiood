import 'dart:convert';

class VoiceNote {
  final String title;
  final String mood;
  final String duration;
  final String filePath;

  VoiceNote({
    required this.title,
    required this.mood,
    required this.duration,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'mood': mood,
        'duration': duration,
        'filePath': filePath,
      };

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      title: json['title'],
      mood: json['mood'],
      duration: json['duration'],
      filePath: json['filePath'],
    );
  }
}

class FriendProfile {
  final String name;
  final String imagePath;
  List<VoiceNote> voiceNotes;

  FriendProfile({
    required this.name,
    required this.imagePath,
    required this.voiceNotes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'imagePath': imagePath,
        'voiceNotes': voiceNotes.map((v) => v.toJson()).toList(),
      };

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
  return FriendProfile(
    name: json['name'] ?? 'Unknown',
    imagePath: json['imagePath'] ?? '',
    // Safety check: if voiceNotes is null in JSON, return an empty list
    voiceNotes: (json['voiceNotes'] as List?)
            ?.map((v) => VoiceNote.fromJson(v))
            .toList() ?? [],
  );
}
}
