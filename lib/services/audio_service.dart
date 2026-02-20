import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

class AudioService {
  // Logic for picking a local file from storage
  static Future<String?> pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    return result?.files.single.path;
  }

  // Logic for moving file from temporary cache to permanent app storage
  static Future<String> saveToPermanentStorage(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = p.basename(sourcePath);
    final savedPath = '${directory.path}/$fileName';
    await File(sourcePath).copy(savedPath);
    return savedPath;
  }

  // Logic for physical deletion to avoid storage leaks
  static Future<void> deletePhysicalFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}