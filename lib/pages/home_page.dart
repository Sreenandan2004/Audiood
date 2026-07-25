import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_handler/share_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;

// Internal imports
import 'package:audiood/pages/menu_page.dart';
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
    // Wait for native channels to stabilize
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
              if (currentProfile != null) ...[
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
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    "Delete ${currentProfile.name}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteProfile(currentProfile, currentPage);
                  },
                ),
              ],
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
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Create New Person",
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter name",
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await ProfileService.createNewPerson(
                      name: controller.text,
                      profiles: profiles,
                    );
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);

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
    final defaultName = p.basenameWithoutExtension(sourcePath);
    final nameController = TextEditingController(text: defaultName);

    final String? chosenName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Name your Audio File",
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter a descriptive name",
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = nameController.text.trim();
                  Navigator.pop(context, text.isNotEmpty ? text : defaultName);
                },
                child: const Text("SAVE"),
              ),
            ],
          ),
    );

    if (chosenName == null) return;

    final updated = await ProfileService.addVoiceNote(
      sourcePath: sourcePath,
      target: target,
      profiles: profiles,
      title: chosenName,
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
                  // If deleting the actively playing file, stop playing first
                  if (AudioService.currentPlayingPath ==
                      profile.voiceNotes[index].filePath) {
                    await AudioService.stopAudio();
                  }

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

  void _confirmDeleteProfile(FriendProfile profile, int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Delete Profile?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Deleting this profile will remove the profile and all its saved audio files.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: () async {
                  if (AudioService.currentPlayingPath != null &&
                      profile.voiceNotes.any(
                        (note) =>
                            note.filePath == AudioService.currentPlayingPath,
                      )) {
                    await AudioService.stopAudio();
                  }

                  await ProfileService.deleteProfile(
                    profile: profile,
                    profiles: profiles,
                  );

                  if (profiles.isEmpty) {
                    currentPage = 0;
                  } else if (currentPage >= profiles.length) {
                    currentPage = profiles.length - 1;
                  }

                  setState(() {});
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (_pageController.hasClients) {
                      _pageController.animateToPage(
                        currentPage,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
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

  void _showAudioOptions(FriendProfile profile, int index) {
    final voiceNote = profile.voiceNotes[index];
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  voiceNote.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.yellow),
                title: const Text(
                  "Rename Audio File",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(profile, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Delete Audio File",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(profile, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(FriendProfile profile, int index) {
    final voiceNote = profile.voiceNotes[index];
    final extension = p.extension(voiceNote.filePath);
    String displayName = voiceNote.title;
    if (extension.isNotEmpty &&
        displayName.toLowerCase().endsWith(extension.toLowerCase())) {
      displayName = displayName.substring(
        0,
        displayName.length - extension.length,
      );
    }

    final TextEditingController controller = TextEditingController(
      text: displayName,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Rename Audio File",
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter new name",
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    await ProfileService.renameVoiceNote(
                      profile: profile,
                      index: index,
                      newName: text,
                      profiles: profiles,
                    );
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text("RENAME"),
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
        body: Center(child: CircularProgressIndicator(color: Colors.yellow)),
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
            onPageChanged: (index) {
              // Automatically stop audio playing when swiping cards
              AudioService.stopAudio();
              setState(() => currentPage = index);
            },
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child:
                        profile.imagePath.startsWith('assets/')
                            ? Image.asset(
                              profile.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, _, __) =>
                                      _buildFallbackBackground(),
                            )
                            : Image.file(
                              File(profile.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, _, __) =>
                                      _buildFallbackBackground(),
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
      child: const Icon(Icons.person, size: 100, color: Colors.white12),
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

                      // Identify active track playing
                      final bool isThisPlaying =
                          state == PlayerState.playing &&
                          AudioService.currentPlayingPath == vn.filePath;

                      return AudioTile(
                        title: vn.title,
                        subtitle: "${vn.mood} • ${vn.duration}",
                        isPlaying: isThisPlaying,
                        // Stream bindings passed down for seeking & tracking
                        positionStream: AudioService.positionStream,
                        durationStream: AudioService.durationStream,
                        onSeek: (position) => AudioService.seek(position),
                        onPlay: () {
                          AudioService.playLocalFile(vn.filePath);
                        },
                        onShare: () => Share.shareXFiles([XFile(vn.filePath)]),
                        onLongPress: () => _showAudioOptions(profile, index),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuPage()),
                ),
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
          // Limit max width so it stays clean on larger screens
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left Chevron
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed:
                    () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
              ),

              // Scrollable Indicators Section
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(profiles.length, (index) {
                      final imagePath = profiles[index].imagePath;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child:
                            index == currentPage
                                ? CircleAvatar(
                                  radius: 14,
                                  backgroundImage:
                                      imagePath.startsWith('assets/')
                                          ? AssetImage(imagePath)
                                          : FileImage(File(imagePath))
                                              as ImageProvider,
                                  onBackgroundImageError: (_, __) {},
                                  child: const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.white,
                                  ),
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
                  ),
                ),
              ),

              // Right Chevron
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
