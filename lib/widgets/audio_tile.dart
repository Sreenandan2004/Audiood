import 'package:flutter/material.dart';

class AudioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isPlaying;
  final Stream<Duration>? positionStream;
  final Stream<Duration>? durationStream;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onLongPress;

  const AudioTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isPlaying,
    this.positionStream,
    this.durationStream,
    this.onSeek,
    required this.onPlay,
    required this.onShare,
    required this.onLongPress,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            leading: GestureDetector(
              onTap: onPlay,
              child: _buildIcon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: GestureDetector(
              onTap: onShare,
              child: _buildIcon(Icons.share),
            ),
          ),
          if (isPlaying) _buildProgressBar(context),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: positionStream,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final double progress =
                duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                      0.0,
                      1.0,
                    )
                    : 0.0;
            return Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: Colors.yellow[300],
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.yellow[300],
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (val) {
                          if (onSeek != null && duration.inMilliseconds > 0) {
                            final newPosition = Duration(
                              milliseconds:
                                  (val * duration.inMilliseconds).toInt(),
                            );
                            onSeek!(newPosition);
                          }
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
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
