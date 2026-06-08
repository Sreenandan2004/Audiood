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
  }) async {
    try {
      final savedPath = await AudioService.saveToPermanentStorage(sourcePath);

      // Resolve actual duration
      String durationStr = "0:00";
      try {
        final tempPlayer = AudioPlayer();
        await tempPlayer.setSource(DeviceFileSource(savedPath));
        final duration = await tempPlayer.getDuration();
        if (duration != null) {
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
          durationStr = "$minutes:$seconds";
        }
        await tempPlayer.dispose();
      } catch (e) {
        debugPrint("Error getting duration on save: $e");
      }

      final updatedVoiceNote = VoiceNote(
        title: p.basename(sourcePath),
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

  // 4. Create new person
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
}
