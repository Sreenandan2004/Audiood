import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_handler/share_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

// Internal imports
import 'package:audiood/pages/menu_page.dart';
import 'package:audiood/pages/settings_page.dart';
import 'package:audiood/widgets/target_picker.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<FriendProfile> profiles = [
    FriendProfile(name: "ZONAL", imagePath: "assets/images/Zonal.jpg", voiceNotes: []),
    FriendProfile(name: "ABHAI", imagePath: "assets/images/Abhai.jpg", voiceNotes: []),
    FriendProfile(name: "SURA", imagePath: "assets/images/Sura.jpg", voiceNotes: []),
  ];

  @override
  void initState() {
    super.initState();
    initShareHandler();
  }

  // --- LOGIC: HANDLE SHARE & PICK ---

  Future<void> initShareHandler() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final handler = ShareHandler.instance;
    
    try {
      final initialMedia = await handler.getInitialSharedMedia();
      if (initialMedia != null) _handleIncomingMedia(initialMedia);
    } catch (e) {
      debugPrint("Initial Share Error: $e");
    }

    handler.sharedMediaStream.listen((SharedMedia media) {
      _handleIncomingMedia(media);
    });
  }

  void _handleIncomingMedia(SharedMedia media) {
    if (media.attachments != null && media.attachments!.isNotEmpty) {
      final path = media.attachments?.first!.path;
      if (path != null) {
        _triggerTargetSelection(path);
      }
    }
  }

  Future<void> _pickLocalAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        _triggerTargetSelection(result.files.single.path!);
      }
    } catch (e) {
      debugPrint("File Picker Error: $e");
    }
  }

  void _triggerTargetSelection(String audioPath) {
    TargetPicker.show(
      context: context,
      profiles: profiles,
      onSelect: (selectedProfile) {
        _processAndSaveAudio(audioPath, selectedProfile);
      },
      onAddNewAndSelect: (newName) {
        final newProfile = FriendProfile(
          name: newName,
          imagePath: "assets/images/default.jpg",
          voiceNotes: [],
        );
        setState(() {
          profiles.add(newProfile);
        });
        _processAndSaveAudio(audioPath, newProfile);
      },
    );
  }

  Future<void> _processAndSaveAudio(String sourcePath, FriendProfile target) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = p.basename(sourcePath);
    final savedPath = '${directory.path}/$fileName';

    await File(sourcePath).copy(savedPath);

    setState(() {
      target.voiceNotes.add(VoiceNote(
        title: fileName,
        mood: "Saved",
        duration: "0:00",
        filePath: savedPath,
      ));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Audio assigned to ${target.name}!")),
      );
    }
  }
  void _confirmDelete(FriendProfile profile, int index) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Delete Audio?", style: TextStyle(color: Colors.white)),
      content: const Text(
        "This will permanently remove the file from your device.",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
        TextButton(
          onPressed: () async {
            final filePath = profile.voiceNotes[index].filePath;
            Navigator.pop(context); // Close dialog

            try {
              // 1. Delete the physical file from storage
              final file = File(filePath);
              if (await file.exists()) {
                await file.delete();
              }

              // 2. Remove from the UI list
              setState(() {
                profile.voiceNotes.removeAt(index);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Audio deleted")),
              );
            } catch (e) {
              debugPrint("Error deleting file: $e");
            }
          },
          child: const Text("DELETE", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _pickLocalAudio,
        backgroundColor: Colors.yellow[300],
        child: const Icon(Icons.add, color: Colors.black),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => currentPage = index),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      profile.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        color: Colors.black,
                        child: const Icon(Icons.person, size: 100, color: Colors.white12),
                      ),
                    ),
                  ),
                  _buildGradientOverlay(),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        children: [
                          _buildHeader(profile.name),
                          const Spacer(),
                          _buildAudioList(profile),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          _buildBottomSlider(),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.9), Colors.black],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {}),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
      ],
    );
  }

  Widget _buildAudioList(FriendProfile profile) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20, bottom: 80),
        itemCount: profile.voiceNotes.length,
        itemBuilder: (context, index) {
          final vn = profile.voiceNotes[index];
          return GestureDetector(
          // --- LONG PRESS TO DELETE ---
          onLongPress: () => _confirmDelete(profile, index),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            leading: _buildAudioIcon(Icons.play_arrow),
            title: Text(vn.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("${vn.mood} • ${vn.duration}", style: const TextStyle(color: Colors.white54)),
            trailing: GestureDetector(
              onTap: () => Share.shareXFiles([XFile(vn.filePath)]),
              child: _buildAudioIcon(Icons.share),
            ),
          ),);
        },
      ),
    );
  }

  Widget _buildAudioIcon(IconData icon) {
    return Container(
      height: 48, width: 48,
      decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: Colors.black),
    );
  }

  Widget _buildBottomSlider() {
    return Positioned(
      bottom: 40, left: 0, right: 0,
      child: Center(
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              ),
              ...List.generate(profiles.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: index == currentPage
                      ? CircleAvatar(
                          radius: 14, 
                          backgroundImage: AssetImage(profiles[index].imagePath),
                          onBackgroundImageError: (_, __) => const Icon(Icons.person),
                        )
                      : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle)),
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