import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_handler/share_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
// Internal imports
import 'package:audiood/pages/menu_page.dart';
import 'package:audiood/pages/settings_page.dart';
import 'package:audiood/services/audio_service.dart';
import 'package:audiood/services/persistence_service.dart';
import 'package:audiood/services/profile_service.dart';
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
  List<FriendProfile> profiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    initShareHandler();
  }

  Future<void> _loadSavedData() async {
    final loaded = await PersistenceService.loadProfiles();
    setState(() {
      profiles = loaded;
      isLoading = false;
    });
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
      onAddNewAndSelect: (newName) async {
        final newProfile = await ProfileService.createNewPerson(
          name: newName,
          profiles: profiles,
        );
        setState(() {});
        _finalizeAudioSave(audioPath, newProfile);
      },
    );
  }

  void _showFabActionsBottomSheet() {
    final currentProfile = profiles.isEmpty ? null : profiles[currentPage];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Action",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (currentProfile != null)
                ListTile(
                  leading: const Icon(Icons.audio_file, color: Colors.yellow),
                  title: Text(
                    "Add Voice for ${currentProfile.name}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final path = await AudioService.pickAudio();
                    if (path != null) {
                      _finalizeAudioSave(path, currentProfile);
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.yellow),
                title: const Text(
                  "Create New Person",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPersonDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPersonDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Create New Person", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter name",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ProfileService.createNewPerson(
                  name: controller.text,
                  profiles: profiles,
                );
                setState(() {});
                if (context.mounted) Navigator.pop(context);

                // Slide the page controller to the newly created user card
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      profiles.length - 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              }
            },
            child: const Text("CREATE"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePhoto(FriendProfile profile) async {
    final updated = await ProfileService.updateProfilePhoto(
      profile: profile,
      profiles: profiles,
    );
    if (updated != null) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile photo updated for ${profile.name}!")),
        );
      }
    }
  }

  Future<void> _finalizeAudioSave(
    String sourcePath,
    FriendProfile target,
  ) async {
    final updated = await ProfileService.addVoiceNote(
      sourcePath: sourcePath,
      target: target,
      profiles: profiles,
    );
    if (updated != null) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Audio assigned to ${target.name}!")),
        );
      }
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
                  await ProfileService.deleteVoiceNote(
                    profile: profile,
                    index: index,
                    profiles: profiles,
                  );
                  setState(() {});
                  if (context.mounted) Navigator.pop(context);
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.yellow),
        ),
      );
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showFabActionsBottomSheet,
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
                    child: profile.imagePath.startsWith('assets/')
                        ? Image.asset(
                            profile.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => _buildFallbackBackground(),
                          )
                        : Image.file(
                            File(profile.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => _buildFallbackBackground(),
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

  Widget _buildFallbackBackground() {
    return Container(
      color: Colors.black,
      child: const Icon(
        Icons.person,
        size: 100,
        color: Colors.white12,
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
            _buildHeader(profile),
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
                        isPlaying: isThisPlaying,
                        onPlay: () {
                          AudioService.playLocalFile(vn.filePath);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isThisPlaying ? "Paused" : "Playing ${vn.title}..."),
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
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.9),
              Colors.black,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FriendProfile profile) {
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
        GestureDetector(
          onTap: () => _updateProfilePhoto(profile),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.photo_camera, color: Colors.white70, size: 16),
              ],
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
            color: Colors.white.withValues(alpha: 0.2),
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
                final imagePath = profiles[index].imagePath;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child:
                      index == currentPage
                          ? CircleAvatar(
                            radius: 14,
                            backgroundImage: imagePath.startsWith('assets/')
                                ? AssetImage(imagePath)
                                : FileImage(File(imagePath)) as ImageProvider,
                            onBackgroundImageError: (_, __) {},
                            child: const Icon(Icons.person, size: 14, color: Colors.white),
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
