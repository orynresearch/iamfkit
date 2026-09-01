import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/album.dart';
import '../../core/services/playback_service.dart';
import '../../core/models/song.dart';
import '../widgets/shared_widgets.dart';
import 'now_playing_screen.dart';

class AlbumScreen extends StatelessWidget {
  final Album album;

  const AlbumScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlurredArtBackground(
        album: album,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AlbumArtWidget(
                        album: album,
                        size: 180,
                        borderRadius: 18,
                        showGlow: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        album.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        album.year != null
                            ? '${album.artistName} · ${album.year}'
                            : album.artistName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Play all / Shuffle row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Play All',
                        primary: true,
                        onTap: () {
                          final playback = context.read<PlaybackService>();
                          playback.setQueue(album.tracks, startIndex: 0);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NowPlayingScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.shuffle_rounded,
                        label: 'Shuffle',
                        primary: false,
                        onTap: () {
                          final playback = context.read<PlaybackService>();
                          final shuffled = List.of(album.tracks)..shuffle();
                          playback.setQueue(shuffled, startIndex: 0);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NowPlayingScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Track list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = album.tracks[index];
                  return _TrackTile(
                    song: song,
                    index: index,
                    totalTracks: album.tracks.length,
                    onTap: () {
                      final playback = context.read<PlaybackService>();
                      playback.setQueue(album.tracks, startIndex: index);
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, animation, __) =>
                              const NowPlayingScreen(),
                          transitionsBuilder: (_, animation, __, child) =>
                              SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  );
                },
                childCount: album.tracks.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        borderRadius: 14,
        tint: primary ? const Color(0xFF7C4DFF) : Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color:
                    primary ? const Color(0xFFB39DFF) : Colors.white70,
                size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primary ? const Color(0xFFB39DFF) : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Song song;
  final int index;
  final int totalTracks;
  final VoidCallback onTap;

  const _TrackTile({
    required this.song,
    required this.index,
    required this.totalTracks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final isPlaying = playback.currentSong?.id == song.id;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFF7C4DFF).withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying
                ? const Color(0xFF7C4DFF).withOpacity(0.35)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: isPlaying
                  ? WaveformIndicator(
                      isPlaying: playback.playerState == PlayerState.playing,
                      color: const Color(0xFF7C4DFF),
                    )
                  : Text(
                      '${song.trackNumber}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 14,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isPlaying ? const Color(0xFFB39DFF) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _formatBadges(song),
          ],
        ),
      ),
    );
  }

  Widget _formatBadges(Song song) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (song.eclipsaPath != null)
          _badge('E', const Color(0xFF7C4DFF)),
        if (song.atmosPath != null)
          _badge('A', const Color(0xFF00B4D8)),
        if (song.standardPath != null)
          _badge('S', const Color(0xFF4CAF50)),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
