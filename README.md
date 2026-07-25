# Audiood

Audiood is a Flutter app for managing friends/profiles and saving local audio notes per profile. It supports importing audio from the device, choosing a profile target, creating new people, and playing voice notes back using a clean, mobile-first interface.

## Key Features

- Splash screen with branded entry animation
- Profile dashboard with swipe navigation
- Import audio from local files and shared media
- Assign audio files to existing people or create a new person on the fly
- Persistent profile and voice note storage using local JSON persistence
- Audio playback, pause, resume, and file management
- Built with Flutter and modern packages like `audioplayers`, `file_picker`, `share_plus`, and `google_fonts`

## Installation

1. Install Flutter from https://flutter.dev/docs/get-started/install
2. Open the project folder in VS Code or your preferred IDE.
3. Get dependencies:

```bash
flutter pub get
```

4. Run the app on an emulator or device:

```bash
flutter run
```

5. Build a release APK for Android:

```bash
flutter build apk --release
```

## Project Structure

- `lib/main.dart` — app entrypoint and root `MaterialApp`
- `lib/pages/` — UI pages including splash screen, home screen, menu, help, and about pages
- `lib/services/` — core services for audio file handling, persistence, and profile management
- `lib/models/` — data models for friend profiles and voice notes
- `lib/widgets/` — reusable UI components used throughout the app
- `assets/` — app icon, images, and bundled assets

## Dependencies

- `flutter` — Flutter SDK
- `cupertino_icons` — iOS-style icons
- `share_handler` — handle shared media from outside the app
- `share_plus` — share content from within the app
- `path_provider` — access platform-specific storage directories
- `file_picker` — allow users to select audio files
- `audioplayers` — play local audio files
- `google_fonts` — custom font styling
- `path` — path utilities for file operations

## Usage

- Launch the app and wait for the splash screen.
- Swipe between profiles on the home dashboard.
- Use the menu to import audio, view help, or see app information.
- Add a new person when assigning audio to a profile that does not exist yet.
- Audio notes are saved locally and persisted across restarts.

## Notes

- The app currently stores profile metadata in a local JSON file under the application documents directory.
- Default profiles are created automatically if no saved data exists.

## License

This repository is private and not published to pub.dev.
