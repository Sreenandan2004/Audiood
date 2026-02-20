import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_handler/share_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
// Internal imports
import 'package:audiood/pages/menu_page.dart';
import 'package:audiood/pages/settings_page.dart';
import 'package:audiood/services/audio_service.dart';
import 'package:audiood/widgets/target_picker.dart';
import '../models/models.dart';
import 'package:audiood/widgets/audio_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  // Initial Data
  final List<FriendProfile> profiles = [
    FriendProfile(
      name: "ZONAL",
      imagePath: "assets/images/Zonal.jpg",
      voiceNotes: [],
    ),
    FriendProfile(
      name: "ABHAI",
      imagePath: "assets/images/Abhai.jpg",
      voiceNotes: [],
    ),
    FriendProfile(
      name: "SURA",
      imagePath: "assets/images/Sura.jpg",
      voiceNotes: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    initShareHandler();
  }

  // --- LOGIC: EXTERNAL SHARE & LOCAL PICKER ---

  Future<void> initShareHandler() async {
    // Wait for the native channel to stabilize
    await Future.delayed(const Duration(milliseconds: 500));
    final handler = ShareHandler.instance;

    try {
      final initialMedia = await handler.getInitialSharedMedia();
      if (initialMedia != null) _handleIncomingMedia(initialMedia);
    } catch (e) {
      debugPrint("Initial Share Error: $e");
    }

    handler.sharedMediaStream.listen(_handleIncomingMedia);
  }

  void _handleIncomingMedia(SharedMedia media) {
    if (media.attachments != null && media.attachments!.isNotEmpty) {
      final path = media.attachments?.first!.path;
      if (path != null) {
        _triggerTargetSelection(path);
      }
    }
  }

  void _triggerTargetSelection(String audioPath) {
    TargetPicker.show(
      context: context,
      profiles: profiles,
      onSelect: (selectedProfile) {
        _finalizeAudioSave(audioPath, selectedProfile);
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
        _finalizeAudioSave(audioPath, newProfile);
      },
    );
  }

  Future<void> _finalizeAudioSave(
    String sourcePath,
    FriendProfile target,
  ) async {
    try {
      final savedPath = await AudioService.saveToPermanentStorage(sourcePath);
      setState(() {
        target.voiceNotes.add(
          VoiceNote(
            title: p.basename(sourcePath),
            mood: "Saved",
            duration: "0:00",
            filePath: savedPath,
          ),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Audio assigned to ${target.name}!")),
        );
      }
    } catch (e) {
      debugPrint("Error saving audio: $e");
    }
  }

  void _confirmDelete(FriendProfile profile, int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Delete Audio?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "This removes the file permanently.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: () async {
                  await AudioService.deletePhysicalFile(
                    profile.voiceNotes[index].filePath,
                  );
                  setState(() {
                    profile.voiceNotes.removeAt(index);
                  });
                  if (mounted) Navigator.pop(context);
                },
                child: const Text(
                  "DELETE",
                  style: TextStyle(color: Colors.red),
                ),
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
        onPressed: () async {
          final path = await AudioService.pickAudio();
          if (path != null) _triggerTargetSelection(path);
        },
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
                      errorBuilder:
                          (context, _, __) => Container(
                            color: Colors.black,
                            child: const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white12,
                            ),
                          ),
                    ),
                  ),
                  _buildGradientOverlay(),
                  _buildContent(profile),
                ],
              );
            },
          ),
          _buildBottomSlider(),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildContent(FriendProfile profile) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            _buildHeader(profile.name),
            const Spacer(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 20, bottom: 80),
                itemCount: profile.voiceNotes.length,
                itemBuilder: (context, index) {
                  final vn = profile.voiceNotes[index];
                  return StreamBuilder<PlayerState>(
                    stream: AudioService.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      // Check if THIS specific file is the one playing
                      final bool isThisPlaying =
                          state == PlayerState.playing &&
                          AudioService.currentPlayingPath == vn.filePath;

                      return AudioTile(
                        title: vn.title,
                        subtitle: "${vn.mood} • ${vn.duration}",
                        isPlaying:
                            isThisPlaying, // <--- This was the missing argument
                        onPlay: () {
                          // Logic for audioplayers package goes here later
                          AudioService.playLocalFile(vn.filePath);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Playing ${vn.title}..."),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        onShare: () => Share.shareXFiles([XFile(vn.filePath)]),
                        onLongPress: () => _confirmDelete(profile, index),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
              Colors.black.withOpacity(0.9),
              Colors.black,
            ],
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
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuPage()),
              ),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
        ),
      ],
    );
  }

  Widget _buildAudioIcon(IconData icon) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  Widget _buildBottomSlider() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
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
                onPressed:
                    () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
              ),
              ...List.generate(profiles.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child:
                      index == currentPage
                          ? CircleAvatar(
                            radius: 14,
                            backgroundImage: AssetImage(
                              profiles[index].imagePath,
                            ),
                            onBackgroundImageError:
                                (_, __) => const Icon(Icons.person),
                          )
                          : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed:
                    () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
