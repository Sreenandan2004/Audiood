import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class PersistenceService {
  static const String _legacyFileName = 'profiles_data.json';
  static Isar? _isar;

  /// Get or initialize the Isar database instance
  static Future<Isar> get isar async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }
    final directory = await getApplicationDocumentsDirectory();
    _isar = Isar.getInstance('audiood_db') ??
        await Isar.open(
          [FriendProfileSchema],
          directory: directory.path,
          name: 'audiood_db',
          inspector: false,
        );
    return _isar!;
  }

  /// Initialize database explicitly (e.g. at app startup)
  static Future<void> init() async {
    await isar;
  }

  /// Load all profiles ordered by sortOrder, resolving relative paths to absolute paths
  static Future<List<FriendProfile>> loadProfiles() async {
    try {
      final db = await isar;
      final directory = await getApplicationDocumentsDirectory();

      List<FriendProfile> profiles = await db.friendProfiles
          .where()
          .sortBySortOrder()
          .findAll();

      // If empty in Isar, check for legacy JSON file to migrate
      if (profiles.isEmpty) {
        profiles = await _migrateFromLegacyJson(db, directory);
      }

      // Convert stored relative paths into current absolute paths
      for (final profile in profiles) {
        _resolveProfilePathsToAbsolute(profile, directory.path);
      }

      return profiles;
    } catch (e) {
      debugPrint("Error loading profiles from Isar: $e");
      return _getDefaultProfiles();
    }
  }

  /// Save or update all profiles, updating sortOrder and persisting relative paths
  static Future<void> saveProfiles(List<FriendProfile> profiles) async {
    try {
      final db = await isar;
      final directory = await getApplicationDocumentsDirectory();

      // Ensure sortOrder reflects current list order
      for (int i = 0; i < profiles.length; i++) {
        profiles[i].sortOrder = i;
      }

      // Create persisted copies with relative paths
      final persistedList = <FriendProfile>[];
      for (final profile in profiles) {
        final persisted = _toPersistedProfile(profile, directory.path);
        persistedList.add(persisted);
      }

      await db.writeTxn(() async {
        // Find existing IDs in DB to remove any deleted profiles
        final existingProfiles = await db.friendProfiles.where().findAll();
        final currentValidIds = persistedList
            .where((p) => p.id != Isar.autoIncrement && p.id != 0)
            .map((p) => p.id)
            .toSet();

        final toDeleteIds = existingProfiles
            .where((p) => !currentValidIds.contains(p.id))
            .map((p) => p.id)
            .toList();

        if (toDeleteIds.isNotEmpty) {
          await db.friendProfiles.deleteAll(toDeleteIds);
        }

        // Put current profiles
        final savedIds = await db.friendProfiles.putAll(persistedList);

        // Sync back generated IDs to in-memory profiles
        for (int i = 0; i < profiles.length; i++) {
          profiles[i].id = savedIds[i];
        }
      });
    } catch (e) {
      debugPrint("Error saving profiles to Isar: $e");
    }
  }

  /// Helper to convert a FriendProfile to an Isar-persistable copy with relative paths
  static FriendProfile _toPersistedProfile(
    FriendProfile profile,
    String basePath,
  ) {
    return FriendProfile(
      name: profile.name,
      imagePath: toRelativePath(profile.imagePath, basePath),
      sortOrder: profile.sortOrder,
      voiceNotes: profile.voiceNotes
          .map(
            (vn) => VoiceNote(
              title: vn.title,
              mood: vn.mood,
              duration: vn.duration,
              filePath: toRelativePath(vn.filePath, basePath),
            ),
          )
          .toList(),
    )..id = profile.id;
  }

  /// Resolve a profile's paths in-place to current absolute paths
  static void _resolveProfilePathsToAbsolute(
    FriendProfile profile,
    String basePath,
  ) {
    profile.imagePath = toAbsolutePath(profile.imagePath, basePath);
    for (final note in profile.voiceNotes) {
      note.filePath = toAbsolutePath(note.filePath, basePath);
    }
  }

  /// Convert an absolute path to a relative path relative to basePath
  static String toRelativePath(String path, String basePath) {
    if (path.isEmpty) return '';
    if (path.startsWith('assets/')) return path;

    final normalizedPath = p.normalize(path).replaceAll(r'\', '/');
    final normalizedBase = p.normalize(basePath).replaceAll(r'\', '/');

    if (normalizedPath.startsWith('$normalizedBase/')) {
      return normalizedPath.substring(normalizedBase.length + 1);
    }

    if (!p.isAbsolute(normalizedPath) && !normalizedPath.contains(':')) {
      return normalizedPath;
    }

    // If outside or container changed, return filename
    return p.basename(normalizedPath);
  }

  /// Convert a stored relative (or old absolute) path to the current absolute path
  static String toAbsolutePath(String storedPath, String basePath) {
    if (storedPath.isEmpty) return '';
    if (storedPath.startsWith('assets/')) return storedPath;

    final normalizedBase = p.normalize(basePath).replaceAll(r'\', '/');
    final normalizedStored = p.normalize(storedPath).replaceAll(r'\', '/');

    if (p.isRelative(normalizedStored) && !normalizedStored.contains(':')) {
      return '$normalizedBase/$normalizedStored';
    }

    // If it's already within current basePath, keep it
    if (normalizedStored.startsWith('$normalizedBase/')) {
      return normalizedStored;
    }

    // If from an older container or different path, re-anchor to current basePath
    return '$normalizedBase/${p.basename(normalizedStored)}';
  }

  /// Migrate legacy JSON file if it exists
  static Future<List<FriendProfile>> _migrateFromLegacyJson(
    Isar db,
    Directory directory,
  ) async {
    try {
      final legacyFile = File('${directory.path}/$_legacyFileName');
      if (!await legacyFile.exists()) return [];

      final contents = await legacyFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      final legacyProfiles =
          jsonList.map((json) => FriendProfile.fromJson(json)).toList();

      if (legacyProfiles.isNotEmpty) {
        await saveProfiles(legacyProfiles);
        // Clean up legacy file to complete migration
        try {
          await legacyFile.delete();
        } catch (_) {}
        return legacyProfiles;
      }
    } catch (e) {
      debugPrint("Error migrating legacy JSON data: $e");
    }
    return [];
  }

  static List<FriendProfile> _getDefaultProfiles() {
    return [];
  }
}
