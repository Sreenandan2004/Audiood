import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:audiood/models/models.dart';
import 'package:audiood/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    const isarDllPath =
        r'C:\Users\imsre\AppData\Local\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\windows\isar.dll';
    if (File(isarDllPath).existsSync()) {
      await Isar.initializeIsarCore(libraries: {
        Abi.windowsX64: isarDllPath,
      });
    }

    tempDir = Directory.systemTemp.createTempSync('audiood_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
  });

  tearDownAll(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Isar Database Operations', () {
    test('Persists and loads profiles in order', () async {
      // In-memory profiles
      final p1 = FriendProfile(
        name: 'ALICE',
        imagePath: '',
        sortOrder: 0,
        voiceNotes: [
          VoiceNote(title: 'Note 1', duration: '0:10', mood: 'Saved', filePath: 'audios/1.m4a'),
        ],
      );
      final p2 = FriendProfile(
        name: 'BOB',
        imagePath: '',
        sortOrder: 1,
        voiceNotes: [],
      );

      final list = [p1, p2];
      await PersistenceService.saveProfiles(list);

      // Verify ID was assigned
      expect(p1.id, greaterThan(0));
      expect(p2.id, greaterThan(0));

      final loaded = await PersistenceService.loadProfiles();
      expect(loaded.length, equals(2));
      expect(loaded[0].name, equals('ALICE'));
      expect(loaded[1].name, equals('BOB'));
      expect(loaded[0].voiceNotes.length, equals(1));
      expect(loaded[0].voiceNotes.first.title, equals('Note 1'));

      // Test reordering
      final reordered = [p2, p1];
      await PersistenceService.saveProfiles(reordered);

      final reloaded = await PersistenceService.loadProfiles();
      expect(reloaded[0].name, equals('BOB'));
      expect(reloaded[1].name, equals('ALICE'));
      expect(reloaded[0].sortOrder, equals(0));
      expect(reloaded[1].sortOrder, equals(1));

      // Test delete
      await PersistenceService.saveProfiles([p2]);
      final afterDelete = await PersistenceService.loadProfiles();
      expect(afterDelete.length, equals(1));
      expect(afterDelete.first.name, equals('BOB'));
    });
  });
}
