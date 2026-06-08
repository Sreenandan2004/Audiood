import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';

class TargetPicker {
  static void show({
    required BuildContext context,
    required List<FriendProfile> profiles,
    required Function(FriendProfile) onSelect,
    required Function(String) onAddNewAndSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Align audio to...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile.imagePath.startsWith('assets/')
                            ? AssetImage(profile.imagePath)
                            : FileImage(File(profile.imagePath)) as ImageProvider,
                        onBackgroundImageError: (_, __) {},
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(profile.name, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        onSelect(profile);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.yellow),
                title: const Text("Create New Person & Add", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showNewPersonDialog(context, onAddNewAndSelect);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showNewPersonDialog(BuildContext context, Function(String) onConfirm) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("New Person Name", style: TextStyle(color: Colors.white)),
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
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onConfirm(controller.text.toUpperCase());
                Navigator.pop(context);
              }
            },
            child: const Text("ADD & SAVE"),
          ),
        ],
      ),
    );
  }
}