import 'package:flutter/material.dart';

class SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  Duration? _dragPosition;

  void _handleDragUpdate(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0 || widget.duration.inMilliseconds == 0) return;
    double percent = (localPosition.dx / totalWidth).clamp(0.0, 1.0);
    setState(() {
      _dragPosition = Duration(
        milliseconds: (percent * widget.duration.inMilliseconds).toInt(),
      );
    });
  }

  void _handleDragEnd() {
    if (_dragPosition != null) {
      widget.onSeek(_dragPosition!);
      setState(() {
        _dragPosition = null;
      });
    }
  }

  void _handleTap(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0 || widget.duration.inMilliseconds == 0) return;
    double percent = (localPosition.dx / totalWidth).clamp(0.0, 1.0);
    final targetPosition = Duration(
      milliseconds: (percent * widget.duration.inMilliseconds).toInt(),
    );
    widget.onSeek(targetPosition);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final durationMs = widget.duration.inMilliseconds;
        final activePositionMs =
            _dragPosition?.inMilliseconds ?? widget.position.inMilliseconds;

        double progress =
            durationMs > 0 ? (activePositionMs / durationMs).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTap(details.localPosition, totalWidth),
          onHorizontalDragStart:
              (details) => _handleDragUpdate(details.localPosition, totalWidth),
          onHorizontalDragUpdate:
              (details) => _handleDragUpdate(details.localPosition, totalWidth),
          onHorizontalDragEnd: (details) => _handleDragEnd(),
          onHorizontalDragCancel: () => _handleDragEnd(),
          child: Container(
            height: 30, // Increased tappable area
            alignment: Alignment.centerLeft,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Inactive track
                Container(
                  height: 4,
                  width: totalWidth,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Active track
                Container(
                  height: 4,
                  width: totalWidth * progress,
                  decoration: BoxDecoration(
                    color: Colors.yellow[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Handle/Playhead
                Positioned(
                  left: (totalWidth * progress) - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.yellow[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
