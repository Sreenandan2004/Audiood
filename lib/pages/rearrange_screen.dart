import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audiood/pages/help_page.dart';
import 'package:audiood/pages/about_page.dart';
import 'package:audiood/services/audio_service.dart';
import 'package:audiood/pages/menu_page.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';

class RearrangeScreen extends StatefulWidget {
  final List<FriendProfile> profiles;
  final List<VoiceNote>? audios;
  final VoidCallback onReordered;

  const RearrangeScreen({
    super.key,
    required this.profiles,
    this.audios,
    required this.onReordered,
  });

  @override
  State<RearrangeScreen> createState() => _RearrangeScreenState();
}

class _RearrangeScreenState extends State<RearrangeScreen> {
  late List<FriendProfile> _localProfiles;
  FriendProfile? _selectedProfileForAudios;

  @override
  void initState() {
    super.initState();
    _localProfiles = widget.profiles;
  }

  // --- REORDER PROFILES ---
  void _onReorderProfiles(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _localProfiles.removeAt(oldIndex);
      _localProfiles.insert(newIndex, item);
    });
    widget.onReordered();
  }

  // --- REORDER AUDIOS FOR SELECTED PROFILE ---
  void _onReorderAudios(int oldIndex, int newIndex) {
    if (_selectedProfileForAudios == null) return;

    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final voiceNotes = _selectedProfileForAudios!.voiceNotes;
      final item = voiceNotes.removeAt(oldIndex);
      voiceNotes.insert(newIndex, item);
    });
    widget.onReordered();
  }

  void _openAudioReorder(FriendProfile profile) {
    if (profile.voiceNotes.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No audios to Rearrange",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _selectedProfileForAudios = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAudioMode = _selectedProfileForAudios != null;

    return PopScope(
      canPop: !isAudioMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isAudioMode) {
          setState(() {
            _selectedProfileForAudios = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (isAudioMode) {
                setState(() {
                  _selectedProfileForAudios = null;
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            isAudioMode
                ? "Rearrange ${_selectedProfileForAudios!.name}'s Audios"
                : "Rearrange Profiles",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: isAudioMode ? _buildAudioListView() : _buildProfileListView(),
      ),
    );
  }

  // --- VIEW 1: REORDER PROFILES ---
  Widget _buildProfileListView() {
    if (_localProfiles.isEmpty) {
      return const Center(
        child: Text(
          "No profiles available",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.yellow, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Drag handle to reorder • Tap profile to reorder audios",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: _localProfiles.length,
            onReorder: _onReorderProfiles,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                shadowColor: Colors.black54,
                elevation: 8,
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final profile = _localProfiles[index];
              return Container(
                key: ValueKey("profile_${profile.name}_$index"),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onTap: () => _openAudioReorder(profile),
                  leading: _buildProfileAvatar(profile.imagePath),
                  title: Text(
                    profile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "${profile.voiceNotes.length} Voice Note${profile.voiceNotes.length == 1 ? '' : 's'}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.drag_handle,
                            color: Colors.yellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- VIEW 2: REORDER AUDIOS ---
  Widget _buildAudioListView() {
    final voiceNotes = _selectedProfileForAudios!.voiceNotes;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.yellow, size: 16),
              SizedBox(width: 8),
              Text(
                "Drag handles to reorder audio files",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: voiceNotes.length,
            onReorder: _onReorderAudios,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                shadowColor: Colors.black54,
                elevation: 8,
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final vn = voiceNotes[index];
              return Container(
                key: ValueKey("audio_${vn.filePath}_$index"),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.audiotrack,
                      color: Colors.yellow,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    vn.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    "${vn.mood} • ${vn.duration}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.drag_handle,
                        color: Colors.yellow,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(String imagePath) {
    ImageProvider? imageProvider;
    if (imagePath.startsWith('assets/')) {
      imageProvider = AssetImage(imagePath);
    } else if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      imageProvider = FileImage(File(imagePath));
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.yellow.withValues(alpha: 0.5),
          width: 1.5,
        ),
        color: Colors.grey[800],
      ),
      child: ClipOval(
        child: imageProvider != null
            ? Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person,
            color: Colors.white54,
          ),
        )
            : const Icon(
          Icons.person,
          color: Colors.white54,
        ),
      ),
    );
  }
}