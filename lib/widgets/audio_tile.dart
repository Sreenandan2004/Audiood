import 'package:flutter/material.dart';

class AudioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onLongPress;

  const AudioTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isPlaying,
    required this.onPlay,
    required this.onShare,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        // Wrapped the leading icon in a GestureDetector for play functionality
        leading: GestureDetector(
          onTap: onPlay,
          child: _buildIcon(isPlaying ? Icons.stop : Icons.play_arrow),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: GestureDetector(
          onTap: onShare,
          child: _buildIcon(Icons.share),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon) {
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
}
