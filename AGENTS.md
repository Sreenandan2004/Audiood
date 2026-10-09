# AGENTS.md — Audiood Project Guide for AI Agents

## 1. Project Overview
- **App Name:** Audiood
- **Framework:** Flutter (Dart SDK >=3.7.0)
- **Purpose:** A mobile application that enables users to organize and store audio voice clips of their friends into custom profiles so they can quickly access and share them during voice chats.
- **Repository Path:** `D:\Development\Audiood`

---

## 2. Core Directives & Golden Rules
1. **Frontend & UI Freeze:**
   - The UI, layouts, styles, themes, and screen interactions are **finalized**.
   - **DO NOT** modify UI design, layout structure, color schemes, or user interactions unless explicitly requested for bug fixes related to persistence state updates.
2. **Persistence Migration Objective:**
   - Migrate local persistence completely from the legacy JSON file storage (`profiles_data.json`) to **Isar Database**.
   - Guarantee that all profiles, profile images, audio clips (voice notes), and their custom ordering persist reliably across app restarts, reboots, and background terminations.
3. **Clarification First:**
   - Do not guess or assume architectural tradeoffs.
   - Always clarify requirements and edge cases with the user before executing changes.

---

## 3. Architecture & File Structure

```
lib/
├── main.dart                  # App entry point, MaterialApp setup
├── models/
│   └── models.dart            # Data models: FriendProfile, VoiceNote
├── pages/
│   ├── splash_screen.dart     # Launch splash screen
│   ├── home_page.dart         # Main profile swipe dashboard & audio list
│   ├── menu_page.dart         # Side/Drawer menu
│   ├── rearrange_screen.dart  # Reorder profiles and voice notes
│   ├── help_page.dart         # Help & FAQ page
│   └── about_page.dart        # About information
├── services/
│   ├── audio_service.dart     # Audio playback, file copying, file management
│   ├── profile_service.dart   # Profile actions (add voice note, change photo, delete)
│   └── persistence_service.dart # Data persistence (Target for Isar implementation)
└── widgets/
    ├── audio_tile.dart        # Audio item tile with play/pause/slider
    ├── seek_bar.dart          # Audio duration seek bar
    └── target_picker.dart     # Modal picker to assign incoming audio to a profile
```

---

## 4. Database & Persistence Architecture (Isar Database)

### 4.1. Confirmed Architectural Decisions
- **Isar Version:** Isar v3 (`isar: 3.1.0+1`, `isar_flutter_libs: 3.1.0+1`, `isar_generator: 3.1.0+1`, `build_runner: ^2.4.9`).
- **Data Schema:** Single collection with embedded objects:
  - `FriendProfile` is annotated with `@collection`, containing `Id id = Isar.autoIncrement`, `late String name`, `late String imagePath`, `late int sortOrder`, and `List<VoiceNote> voiceNotes = []`.
  - `VoiceNote` is annotated with `@embedded`, containing `late String title`, `late String mood`, `late String duration`, `late String filePath`.
- **Order Persistence:** `sortOrder` on `FriendProfile` explicitly saves the custom drag-and-drop order from `rearrange_screen.dart` across app restarts.
- **File Storage Safety:** Audio and image files are stored in `getApplicationDocumentsDirectory()`. Relative paths are persisted in Isar and dynamically resolved to absolute paths on runtime load. This prevents broken file links across app reboots/updates.
- **Initial State:** Empty profiles list on clean install.

### 4.2. File Path Handling Strategy
- Physical audio files and profile images are saved in the permanent Application Documents directory.
- `PersistenceService` stores relative paths (e.g. `audios/voice_1.m4a` or filename) in Isar.
- On loading, `PersistenceService` converts relative paths to current absolute paths so `audioplayers` and file operations work seamlessly.
- On saving/updating, absolute paths are converted back to relative before writing to Isar.

---

## 5. Development Commands
- **Install dependencies:** `flutter pub get`
- **Run code generation (if using Isar generator):** `dart run build_runner build --delete-conflicting-outputs`
- **Run app:** `flutter run`
- **Analyze code:** `flutter analyze`
