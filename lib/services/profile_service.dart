import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import 'audio_service.dart';
import 'persistence_service.dart';

class ProfileService {
  // 1. Add a voice note to a profile
  static Future<FriendProfile?> addVoiceNote({
    required String sourcePath,
    required FriendProfile target,
    required List<FriendProfile> profiles,
    String? title,
  }) async {
    try {
      final savedPath = await AudioService.saveToPermanentStorage(
        sourcePath,
        targetName: title,
      );

      // Resolve actual duration
      String durationStr = "0:00";
      try {
        final tempPlayer = AudioPlayer();
        await tempPlayer.setSource(DeviceFileSource(savedPath));
        final duration = await tempPlayer.getDuration();
        if (duration != null) {
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds
              .remainder(60)
              .toString()
              .padLeft(2, '0');
          durationStr = "$minutes:$seconds";
        }
        await tempPlayer.dispose();
      } catch (e) {
        debugPrint("Error getting duration on save: $e");
      }

      final updatedVoiceNote = VoiceNote(
        title: title ?? p.basename(sourcePath),
        mood: "Saved",
        duration: durationStr,
        filePath: savedPath,
      );

      // Mutate or update profile
      target.voiceNotes.add(updatedVoiceNote);
      await PersistenceService.saveProfiles(profiles);
      return target;
    } catch (e) {
      debugPrint("Error in addVoiceNote: $e");
      return null;
    }
  }

  // 2. Update a profile's photo
  static Future<FriendProfile?> updateProfilePhoto({
    required FriendProfile profile,
    required List<FriendProfile> profiles,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final savedImagePath = await AudioService.saveToPermanentStorage(path);

        final updatedProfile = FriendProfile(
          name: profile.name,
          imagePath: savedImagePath,
          voiceNotes: profile.voiceNotes,
        );

        final index = profiles.indexOf(profile);
        if (index != -1) {
          profiles[index] = updatedProfile;
        }
        await PersistenceService.saveProfiles(profiles);
        return updatedProfile;
      }
    } catch (e) {
      debugPrint("Error in updateProfilePhoto: $e");
    }
    return null;
  }

  // 3. Delete a voice note physically and from list
  static Future<void> deleteVoiceNote({
    required FriendProfile profile,
    required int index,
    required List<FriendProfile> profiles,
  }) async {
    try {
      final voiceNote = profile.voiceNotes[index];
      await AudioService.deletePhysicalFile(voiceNote.filePath);
      profile.voiceNotes.removeAt(index);
      await PersistenceService.saveProfiles(profiles);
    } catch (e) {
      debugPrint("Error in deleteVoiceNote: $e");
    }
  }

  // 4. Delete a profile and all its audio files
  static Future<void> deleteProfile({
    required FriendProfile profile,
    required List<FriendProfile> profiles,
  }) async {
    try {
      for (final note in profile.voiceNotes) {
        try {
          await AudioService.deletePhysicalFile(note.filePath);
        } catch (innerError) {
          debugPrint("Error deleting voice note file: $innerError");
        }
      }

      if (!profile.imagePath.startsWith('assets/')) {
        try {
          await AudioService.deletePhysicalFile(profile.imagePath);
        } catch (innerError) {
          debugPrint("Error deleting profile image file: $innerError");
        }
      }

      profiles.remove(profile);
      await PersistenceService.saveProfiles(profiles);
    } catch (e) {
      debugPrint("Error in deleteProfile: $e");
    }
  }

  // 5. Create new person
  static Future<FriendProfile> createNewPerson({
    required String name,
    required List<FriendProfile> profiles,
  }) async {
    final newProfile = FriendProfile(
      name: name.toUpperCase(),
      imagePath: "assets/images/default.jpg",
      voiceNotes: [],
    );
    profiles.add(newProfile);
    await PersistenceService.saveProfiles(profiles);
    return newProfile;
  }

  // 5. Rename an existing voice note and its physical file
  static Future<void> renameVoiceNote({
    required FriendProfile profile,
    required int index,
    required String newName,
    required List<FriendProfile> profiles,
  }) async {
    try {
      final voiceNote = profile.voiceNotes[index];

      // Stop the audio player if it's currently playing this file
      if (AudioService.currentPlayingPath == voiceNote.filePath) {
        await AudioService.stopAudio();
      }

      final extension = p.extension(voiceNote.filePath);
      String baseName = p.basenameWithoutExtension(newName);
      if (baseName.isEmpty) {
        baseName = "audio";
      }
      final newTitle = '$baseName$extension';

      // Rename physical file
      final newPath = await AudioService.renamePhysicalFile(
        voiceNote.filePath,
        baseName,
      );

      // Create updated voice note
      final updatedVoiceNote = VoiceNote(
        title: newTitle,
        mood: voiceNote.mood,
        duration: voiceNote.duration,
        filePath: newPath,
      );

      // Update in profile list
      profile.voiceNotes[index] = updatedVoiceNote;
      await PersistenceService.saveProfiles(profiles);
    } catch (e) {
      debugPrint("Error in renameVoiceNote: $e");
    }
  }
}
