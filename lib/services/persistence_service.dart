import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class PersistenceService {
  static const String _fileName = 'profiles_data.json';

  static Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<List<FriendProfile>> loadProfiles() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return _getDefaultProfiles();
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => FriendProfile.fromJson(json)).toList();
    } catch (e) {
      return _getDefaultProfiles();
    }
  }

  static Future<void> saveProfiles(List<FriendProfile> profiles) async {
    try {
      final file = await _getLocalFile();
      final jsonList = profiles.map((p) => p.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      // Silently catch or log errors
    }
  }

  static List<FriendProfile> _getDefaultProfiles() {
    return [];
  }
}
