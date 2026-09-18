import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tile_shape.dart';
import '../../providers/music_provider.dart';

class MusicTile extends ConsumerWidget {
  final TileShape shape;

  const MusicTile({super.key, required this.shape});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicProvider);
    final theme = Theme.of(context);

    // If it's a chip, just show tiny icon and maybe scrolling text or nothing
    if (shape == TileShape.chip) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            musicState.isPlaying ? Icons.music_note : Icons.music_off,
            size: 16,
            color: musicState.isPlaying ? Colors.white : theme.iconTheme.color,
          ),
          if (musicState.isPlaying) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                musicState.title,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]
        ],
      );
    }

    final isTall = shape == TileShape.tall || shape == TileShape.square;

    final imageWidget = Container(
      width: isTall ? 60 : 50,
      height: isTall ? 60 : 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.dividerColor.withValues(alpha: 0.2),
        image: musicState.albumArt != null
            ? DecorationImage(
                image: MemoryImage(musicState.albumArt!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: musicState.albumArt == null
          ? Icon(Icons.album, color: theme.iconTheme.color?.withValues(alpha: 0.5))
          : null,
    );

    final infoWidget = Column(
      crossAxisAlignment: isTall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          musicState.title.isNotEmpty ? musicState.title : 'No Music',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          musicState.artist.isNotEmpty ? musicState.artist : 'Not Playing',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );

    if (isTall) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              imageWidget,
              const SizedBox(height: 8),
              infoWidget,
              if (musicState.isPlaying) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: _AudioVisualizer(color: theme.colorScheme.primary),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Wide layout
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            imageWidget,
            const SizedBox(width: 16),
            infoWidget,
            if (musicState.isPlaying) ...[
              const SizedBox(width: 16),
              SizedBox(
                width: 24,
                height: 24,
                child: _AudioVisualizer(color: theme.colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple pulsing bars to indicate music playing
class _AudioVisualizer extends StatefulWidget {
  final Color color;
  const _AudioVisualizer({required this.color});

  @override
  State<_AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<_AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(10 + _ctrl.value * 14),
            _bar(14 + (1 - _ctrl.value) * 10),
            _bar(12 + _ctrl.value * 12),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
