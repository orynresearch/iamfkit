import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/song.dart';
import '../../core/services/playback_service.dart';
import '../widgets/shared_widgets.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin {
  late AnimationController _discController;
  late AnimationController _fadeInController;

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playback = context.read<PlaybackService>();
    if (playback.playerState == PlayerState.playing) {
      _discController.repeat();
    }
  }

  @override
  void dispose() {
    _discController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final song = playback.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text('Nothing playing')));
    }

    // Sync disc rotation with play state
    if (playback.playerState == PlayerState.playing && !_discController.isAnimating) {
      _discController.repeat();
    } else if (playback.playerState != PlayerState.playing) {
      _discController.stop();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlurredArtBackground(
        song: song,
        child: FadeTransition(
          opacity: _fadeInController,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildSpinningDisc(song),
                        const SizedBox(height: 28),
                        _buildSongInfo(song, playback),
                        const SizedBox(height: 24),
                        _buildFormatPicker(playback, song),
                        const SizedBox(height: 28),
                        _buildSeekBar(playback),
                        const SizedBox(height: 28),
                        _buildControls(playback),
                        const SizedBox(height: 20),
                        _buildSecondaryControls(playback),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          const Spacer(),
          Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildSpinningDisc(Song song) {
    return AnimatedBuilder(
      animation: _discController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _discController.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.45),
              blurRadius: 50,
              spreadRadius: 8,
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AlbumArtWidget(
                song: song,
                size: 240,
                borderRadius: 120,
                showGlow: false,
              ),
              // Center hole
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A0A14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(Song song, PlaybackService playback) {
    return Column(
      children: [
        Text(
          song.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${song.artistName} · ${song.albumTitle}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatPicker(PlaybackService playback, Song song) {
    final formats = AudioFormat.values
        .where((f) => song.hasFormat(f))
        .toList();
    if (formats.length < 2) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(6),
      borderRadius: 14,
      child: Row(
        children: formats.map((format) {
          final isSelected = playback.currentFormat == format;
          final (label, color) = switch (format) {
            AudioFormat.eclipsa  => ('🔮 Eclipsa', const Color(0xFF7C4DFF)),
            AudioFormat.atmos    => ('🌐 Atmos', const Color(0xFF00B4D8)),
            AudioFormat.standard => ('🎵 Standard', const Color(0xFF4CAF50)),
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => playback.switchFormat(format),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color.withOpacity(0.6) : Colors.transparent,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? color : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeekBar(PlaybackService playback) {
    final totalMs = playback.duration.inMilliseconds.toDouble();
    final posMs = playback.position.inMilliseconds
        .toDouble()
        .clamp(0, totalMs > 0 ? totalMs : 1);
    final progress = totalMs > 0 ? posMs / totalMs : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.15),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
          ),
          child: Slider(
            value: progress.toDouble(),
            min: 0,
            max: 1,
            onChanged: (v) {
              if (totalMs > 0) {
                playback.seekTo(Duration(milliseconds: (v * totalMs).toInt()));
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(playback.position),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(playback.duration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(PlaybackService playback) {
    final isPlaying = playback.playerState == PlayerState.playing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          size: 36,
          onTap: () => playback.previousSong(),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () {
            if (isPlaying) {
              playback.pause();
            } else {
              playback.resume();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF9B6DFF), Color(0xFF6A3DE8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 20),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          size: 36,
          onTap: () => playback.nextSong(),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(PlaybackService playback) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SecondaryButton(
          icon: playback.shuffleEnabled
              ? Icons.shuffle_on_rounded
              : Icons.shuffle_rounded,
          active: playback.shuffleEnabled,
          onTap: () => playback.toggleShuffle(),
        ),
        _SecondaryButton(
          icon: switch (playback.repeatMode) {
            PlayerRepeatMode.none => Icons.repeat_rounded,
            PlayerRepeatMode.one  => Icons.repeat_one_rounded,
            PlayerRepeatMode.all  => Icons.repeat_on_rounded,
          },
          active: playback.repeatMode != PlayerRepeatMode.none,
          onTap: () => playback.cycleRepeatMode(),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlButton(
      {required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _SecondaryButton(
      {required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF7C4DFF).withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? const Color(0xFF7C4DFF).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(
          icon,
          color: active ? const Color(0xFFB39DFF) : Colors.white54,
          size: 22,
        ),
      ),
    );
  }
}
