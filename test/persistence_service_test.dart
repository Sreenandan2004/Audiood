import 'package:flutter_test/flutter_test.dart';
import 'package:audiood/services/persistence_service.dart';
import 'package:audiood/models/models.dart';

void main() {
  group('PersistenceService Path Handling', () {
    const basePath = '/app/documents/directory';

    test('converts absolute child path to relative path', () {
      final childPath = '/app/documents/directory/audios/clip1.m4a';
      final rel = PersistenceService.toRelativePath(childPath, basePath);
      expect(rel, equals('audios/clip1.m4a'));
    });

    test('preserves asset paths untouched', () {
      const asset = 'assets/icon/app_icon.png';
      expect(PersistenceService.toRelativePath(asset, basePath), equals(asset));
      expect(PersistenceService.toAbsolutePath(asset, basePath), equals(asset));
    });

    test('resolves relative path back to current absolute basePath', () {
      const rel = 'audios/clip1.m4a';
      final abs = PersistenceService.toAbsolutePath(rel, basePath);
      expect(abs, equals('/app/documents/directory/audios/clip1.m4a'));
    });

    test('re-anchors path from changed sandbox container', () {
      const oldContainerPath = '/old/sandbox/container/clip1.m4a';
      final reanchored = PersistenceService.toAbsolutePath(oldContainerPath, basePath);
      expect(reanchored, equals('/app/documents/directory/clip1.m4a'));
    });
  });

  group('Model Serialization with Sort Order', () {
    test('FriendProfile retains sortOrder and voiceNotes in order', () {
      final profile = FriendProfile(
        name: 'TEST USER',
        imagePath: 'img.jpg',
        sortOrder: 3,
        voiceNotes: [
          VoiceNote(title: 'Note 1', duration: '0:15', mood: 'Saved', filePath: 'a.m4a'),
          VoiceNote(title: 'Note 2', duration: '0:30', mood: 'Saved', filePath: 'b.m4a'),
        ],
      );

      final json = profile.toJson();
      expect(json['sortOrder'], equals(3));
      expect(json['name'], equals('TEST USER'));
      expect((json['voiceNotes'] as List).length, equals(2));

      final restored = FriendProfile.fromJson(json);
      expect(restored.sortOrder, equals(3));
      expect(restored.voiceNotes.first.title, equals('Note 1'));
      expect(restored.voiceNotes.last.title, equals('Note 2'));
    });
  });
}
