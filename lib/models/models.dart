class VoiceNote {
  final String title;
  final String mood;
  final String duration;
  final String filePath;

  VoiceNote({
    required this.duration,
    required this.mood,
    required this.title,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'mood': mood,
        'duration': duration,
        'filePath': filePath,
      };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
        title: json['title'] as String,
        mood: json['mood'] as String,
        duration: json['duration'] as String,
        filePath: json['filePath'] as String,
      );
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'imagePath': imagePath,
        'voiceNotes': voiceNotes.map((v) => v.toJson()).toList(),
      };

  factory FriendProfile.fromJson(Map<String, dynamic> json) => FriendProfile(
        name: json['name'] as String,
        imagePath: json['imagePath'] as String,
        voiceNotes: (json['voiceNotes'] as List<dynamic>)
            .map((v) => VoiceNote.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}