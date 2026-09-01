import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/playback_service.dart';
import '../../core/models/song.dart';
import 'shared_widgets.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final song = playback.currentSong;
    if (song == null) return const SizedBox.shrink();

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const NowPlayingScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + bottomPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Album art thumbnail
                AlbumArtWidget(
                  song: song,
                  size: 44,
                  borderRadius: 8,
                  showGlow: false,
                ),
                const SizedBox(width: 12),
                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Format badge
                _FormatBadge(format: playback.currentFormat),
                const SizedBox(width: 8),
                // Previous
                _MiniButton(
                  icon: Icons.skip_previous_rounded,
                  onTap: () => playback.previousSong(),
                ),
                // Play/Pause
                _MiniButton(
                  icon: playback.playerState == PlayerState.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 30,
                  onTap: () {
                    if (playback.playerState == PlayerState.playing) {
                      playback.pause();
                    } else {
                      playback.resume();
                    }
                  },
                ),
                // Next
                _MiniButton(
                  icon: Icons.skip_next_rounded,
                  onTap: () => playback.nextSong(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.onTap,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final AudioFormat? format;

  const _FormatBadge({this.format});

  @override
  Widget build(BuildContext context) {
    if (format == null) return const SizedBox.shrink();
    final (label, color) = switch (format!) {
      AudioFormat.eclipsa => ('ECLIPSA', const Color(0xFF7C4DFF)),
      AudioFormat.atmos   => ('ATMOS', const Color(0xFF00B4D8)),
      AudioFormat.standard => ('STD', const Color(0xFF4CAF50)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
