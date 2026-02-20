import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/models.dart';
import 'menu_page.dart';
import 'settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late StreamSubscription _intentDataStreamSubscription;
  int currentPage = 0;

  List<FriendProfile> profiles = [
    FriendProfile(name: "ZONAL", imagePath: "assets/images/Zonal.jpg", voiceNotes: []),
    FriendProfile(name: "ABHAI", imagePath: "assets/images/Abhai.jpg", voiceNotes: []),
    FriendProfile(name: "SURA", imagePath: "assets/images/Sura.jpg", voiceNotes: []),
  ];

  @override
  void initState() {
    super.initState();
    loadData();

    // 1. Listen for sharing while app is in memory (foreground/background)
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // 2. Handle sharing when app is launched from a closed state
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
        // Important: Reset the intent so it doesn't trigger again on Hot Restart
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    for (var file in files) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        // Clean up filename from the path
        final fileName = file.path.split('/').last;
        final newPath = "${appDir.path}/$fileName";

        File sharedFile = File(file.path);
        // Copy to internal app storage so the file persists
        File newFile = await sharedFile.copy(newPath);

        final newNote = VoiceNote(
          title: fileName,
          mood: "Shared",
          duration: "Unknown",
          filePath: newFile.path,
        );

        setState(() {
          profiles[currentPage].voiceNotes.add(newNote);
        });
      } catch (e) {
        debugPrint("Error handling shared file: $e");
      }
    }
    await saveData();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- DATA PERSISTENCE ---

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('profiles');

    if (stored != null && stored.isNotEmpty) {
      setState(() {
        profiles = stored.map((e) => FriendProfile.fromJson(jsonDecode(e))).toList();
      });
    } else {
      debugPrint("No saved data found, using defaults.");
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encodedProfiles = profiles.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('profiles', encodedProfiles);
  }

  // --- AUDIO LOGIC ---

  Future<void> pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      File originalFile = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final newPath = "${appDir.path}/${result.files.single.name}";
      File newFile = await originalFile.copy(newPath);

      final newNote = VoiceNote(
        title: result.files.single.name,
        mood: "Happy",
        duration: "Unknown",
        filePath: newFile.path,
      );

      setState(() {
        profiles[currentPage].voiceNotes.add(newNote);
      });
      await saveData();
    }
  }

  void playVoiceNote(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error playing audio: $e")),
        );
      }
    }
  }

  void deleteNote(int profileIndex, int noteIndex) async {
    final note = profiles[profileIndex].voiceNotes[noteIndex];
    final file = File(note.filePath);
    if (await file.exists()) await file.delete();

    setState(() {
      profiles[profileIndex].voiceNotes.removeAt(noteIndex);
    });
    await saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: pickAudio,
        backgroundColor: Colors.yellow[300],
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => currentPage = index),
            itemCount: profiles.length,
            itemBuilder: (context, profileIndex) {
              final profile = profiles[profileIndex];
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(profile.imagePath, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                            Colors.black,
                          ],
                          stops: const [0.0, 0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        children: [
                          _buildHeader(profile.name),
                          const Spacer(),
                          _buildAudioList(profile, profileIndex),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          _buildBottomNavigationSlider(),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuPage())),
          child: const Icon(Icons.menu, color: Colors.white),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          child: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildAudioList(FriendProfile profile, int profileIndex) {
    return Expanded(
      flex: 2,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20, bottom: 100),
        itemCount: profile.voiceNotes.length,
        itemBuilder: (context, index) {
          final note = profile.voiceNotes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: GestureDetector(
                onTap: () => playVoiceNote(note.filePath),
                child: Container(
                  height: 44, width: 44,
                  decoration: BoxDecoration(color: Colors.yellow[300], borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.play_arrow, color: Colors.black),
                ),
              ),
              title: Text(note.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              subtitle: Text(note.mood, style: const TextStyle(color: Colors.white54)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => deleteNote(profileIndex, index),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationSlider() {
    return Positioned(
      bottom: 40, left: 0, right: 0,
      child: Center(
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              ),
              ...List.generate(profiles.length, (index) {
                bool isActive = currentPage == index;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: isActive ? 28 : 10,
                    height: isActive ? 28 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: isActive ? DecorationImage(image: AssetImage(profiles[index].imagePath), fit: BoxFit.cover) : null,
                      color: isActive ? null : Colors.white38,
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}