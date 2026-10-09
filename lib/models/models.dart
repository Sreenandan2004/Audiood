import 'package:isar/isar.dart';

part 'models.g.dart';

@embedded
class VoiceNote {
  String title;
  String mood;
  String duration;
  String filePath;

  VoiceNote({
    this.title = '',
    this.mood = '',
    this.duration = '',
    this.filePath = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'mood': mood,
        'duration': duration,
        'filePath': filePath,
      };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
        title: json['title'] as String? ?? '',
        mood: json['mood'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        filePath: json['filePath'] as String? ?? '',
      );
}

@collection
class FriendProfile {
  Id id = Isar.autoIncrement;

  String name;
  String imagePath;
  int sortOrder;

  List<VoiceNote> voiceNotes;

  FriendProfile({
    this.name = '',
    this.imagePath = '',
    this.sortOrder = 0,
    List<VoiceNote> voiceNotes = const [],
  }) : voiceNotes = List<VoiceNote>.from(voiceNotes);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'sortOrder': sortOrder,
        'voiceNotes': voiceNotes.map((v) => v.toJson()).toList(),
      };

  factory FriendProfile.fromJson(Map<String, dynamic> json) => FriendProfile(
        name: json['name'] as String? ?? '',
        imagePath: json['imagePath'] as String? ?? '',
        sortOrder: json['sortOrder'] as int? ?? 0,
        voiceNotes: (json['voiceNotes'] as List<dynamic>?)
                ?.map((v) => VoiceNote.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );
}