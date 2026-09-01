import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/song.dart';
import '../../core/models/album.dart';

/// A glassmorphism card that displays album artwork.
/// Falls back to [placeholder_art.jpg] if no art is available.
class AlbumArtWidget extends StatelessWidget {
  final Album? album;
  final Song? song;
  final double size;
  final double borderRadius;
  final bool showGlow;

  const AlbumArtWidget({
    super.key,
    this.album,
    this.song,
    this.size = 200,
    this.borderRadius = 16,
    this.showGlow = false,
  });

  String? get _localPath =>
      album?.artworkLocalPath ?? song?.artworkLocalPath;

  String? get _networkUrl =>
      album?.artworkUrl ?? song?.artworkUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (_localPath != null) {
      final file = File(_localPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    if (_networkUrl != null) {
      return CachedNetworkImage(
        imageUrl: _networkUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(),
        errorWidget: (context, url, error) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Image.asset(
      'assets/placeholder_art.jpg',
      fit: BoxFit.cover,
    );
  }
}

/// A blurred, tinted background using album art color.
class BlurredArtBackground extends StatelessWidget {
  final Album? album;
  final Song? song;
  final Widget child;

  const BlurredArtBackground({
    super.key,
    this.album,
    this.song,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: blurred art or gradient
        _buildBlurredBackground(),
        // Dark overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.55),
                const Color(0xFF0A0A14).withOpacity(0.92),
              ],
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }

  Widget _buildBlurredBackground() {
    final localPath = album?.artworkLocalPath ?? song?.artworkLocalPath;
    final networkUrl = album?.artworkUrl ?? song?.artworkUrl;

    ImageProvider? provider;
    if (localPath != null && File(localPath).existsSync()) {
      provider = FileImage(File(localPath));
    } else if (networkUrl != null) {
      provider = NetworkImage(networkUrl);
    }

    return provider != null
        ? ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Image(
              image: provider,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.2),
              colorBlendMode: BlendMode.darken,
            ),
          )
        : Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0A2E),
                  Color(0xFF0A0A1A),
                  Color(0xFF0D1A2E),
                ],
              ),
            ),
          );
  }
}

/// A frosted glass card container.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (tint ?? Colors.white).withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Animated waveform bars used as a now-playing indicator.
class WaveformIndicator extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double barWidth;
  final int barCount;

  const WaveformIndicator({
    super.key,
    required this.isPlaying,
    this.color = Colors.white,
    this.barWidth = 3,
    this.barCount = 4,
  });

  @override
  State<WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<WaveformIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 120),
      );
      if (widget.isPlaying) ctrl.repeat(reverse: true);
      return ctrl;
    });
  }

  @override
  void didUpdateWidget(WaveformIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final ctrl in _controllers) {
      if (widget.isPlaying) {
        if (!ctrl.isAnimating) ctrl.repeat(reverse: true);
      } else {
        ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(widget.barCount, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, _) {
            final heightFraction = widget.isPlaying
                ? 0.3 + (_controllers[i].value * 0.7)
                : 0.3;
            return Container(
              width: widget.barWidth,
              height: 20 * heightFraction,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
