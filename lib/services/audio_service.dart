import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static AudioPlayer get player => _audioPlayer;

  static Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  static Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  static Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  static Duration currentDuration = Duration.zero;
  static bool _listenersInitialized = false;

  static void _ensureListeners() {
    if (!_listenersInitialized) {
      _audioPlayer.onDurationChanged.listen((d) {
        currentDuration = d;
      });
      _listenersInitialized = true;
    }
  }

  static String? currentPlayingPath;

  static Future<void> playLocalFile(String filePath) async {
    _ensureListeners();
    try {
      if (currentPlayingPath == filePath) {
        if (_audioPlayer.state == PlayerState.playing) {
          await _audioPlayer.pause();
        } else if (_audioPlayer.state == PlayerState.paused) {
          await _audioPlayer.resume();
        } else {
          await _audioPlayer.play(DeviceFileSource(filePath));
        }
      } else {
        await _audioPlayer.stop();
        currentPlayingPath = filePath;
        await _audioPlayer.play(DeviceFileSource(filePath));
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  static Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint("Error seeking audio: $e");
    }
  }

  static Future<void> stopAudio() async {
    await _audioPlayer.stop();
    currentPlayingPath = null;
  }

  static Future<String?> pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    return result?.files.single.path;
  }

  static Future<String> saveToPermanentStorage(
    String sourcePath, {
    String? targetName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = p.extension(sourcePath);
    String baseName =
        targetName != null
            ? _sanitizeFileName(p.basenameWithoutExtension(targetName))
            : p.basenameWithoutExtension(sourcePath);

    if (baseName.isEmpty) {
      baseName = "file";
    }

    String fileName = '$baseName$extension';
    String savedPath = '${directory.path}/$fileName';
    int counter = 1;
    while (await File(savedPath).exists()) {
      fileName = '${baseName}_$counter$extension';
      savedPath = '${directory.path}/$fileName';
      counter++;
    }

    await File(sourcePath).copy(savedPath);
    return savedPath;
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  static Future<String> renamePhysicalFile(
    String oldPath,
    String newName,
  ) async {
    final file = File(oldPath);
    if (!await file.exists()) return oldPath;

    final directory = p.dirname(oldPath);
    final extension = p.extension(oldPath);
    final baseName = _sanitizeFileName(p.basenameWithoutExtension(newName));

    if (baseName.isEmpty) {
      return oldPath;
    }

    String fileName = '$baseName$extension';
    String newPath = '$directory/$fileName';
    int counter = 1;
    while (await File(newPath).exists() && newPath != oldPath) {
      fileName = '${baseName}_$counter$extension';
      newPath = '$directory/$fileName';
      counter++;
    }

    if (newPath != oldPath) {
      await file.rename(newPath);
    }
    return newPath;
  }

  static Future<void> deletePhysicalFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
