import 'dart:ffi';
import 'dart:async';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:iamfkit/iamfkit.dart';
import 'dart:io';
import '../models/song.dart';

enum PlayerState { stopped, playing, paused, loading }
enum PlayerRepeatMode { none, one, all }

class PlaybackService extends ChangeNotifier {
  Song? currentSong;
  AudioFormat? currentFormat;
  PlayerState playerState = PlayerState.stopped;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  List<Song> queue = [];
  int queueIndex = -1;
  bool shuffleEnabled = false;
  PlayerRepeatMode repeatMode = PlayerRepeatMode.none;

  // just_audio for Standard / Atmos
  final AudioPlayer _justAudioPlayer = AudioPlayer();
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _justAudioStateSub;

  // IAMF state
  Pointer<IAMF_Decoder> _decoder = nullptr;
  Pointer<Uint8>? _iamfFileBuffer;
  Pointer<Uint32>? _iamfRsize;
  Pointer<Void>? _iamfPcm;
  int _iamfFileSize = 0;
  int _iamfOffset = 0;
  int _iamfSampleRate = 48000;
  int _iamfChannels = 2;
  bool _iamfFeeding = false;
  Timer? _iamfPositionTimer;

  PlaybackService() {
    _positionSub = _justAudioPlayer.positionStream.listen((pos) {
      if (currentFormat != AudioFormat.eclipsa) {
        position = pos;
        notifyListeners();
      }
    });

    _durationSub = _justAudioPlayer.durationStream.listen((dur) {
      if (currentFormat != AudioFormat.eclipsa && dur != null) {
        duration = dur;
        notifyListeners();
      }
    });

    _justAudioStateSub = _justAudioPlayer.playerStateStream.listen((state) {
      if (currentFormat != AudioFormat.eclipsa) {
        if (state.processingState == ProcessingState.completed) {
          _handleSongEnd();
        }
      }
    });
  }

  // ─────────────────────────── Public API ───────────────────────────

  Future<void> playSong(Song song, {AudioFormat? preferredFormat}) async {
    playerState = PlayerState.loading;
    notifyListeners();

    await stop();

    currentSong = song;
    currentFormat = preferredFormat ?? song.bestAvailableFormat;

    if (currentFormat == null) {
      playerState = PlayerState.stopped;
      notifyListeners();
      return;
    }

    try {
      if (currentFormat == AudioFormat.eclipsa) {
        await _playIamf(song.eclipsaPath!);
      } else {
        final path = song.pathForFormat(currentFormat!);
        if (path != null) {
          await _justAudioPlayer.setAudioSource(AudioSource.uri(Uri.file(path)));
          await _justAudioPlayer.play();
          playerState = PlayerState.playing;
        }
      }
    } catch (e) {
      debugPrint('PlaybackService error: $e');
      playerState = PlayerState.stopped;
    }
    notifyListeners();
  }

  Future<void> pause() async {
    if (playerState != PlayerState.playing) return;
    if (currentFormat == AudioFormat.eclipsa) {
      _iamfPositionTimer?.cancel();
      // flutter_pcm_sound doesn't have a pause — we just stop feeding.
      // Mark paused so the feed callback returns early.
    } else {
      await _justAudioPlayer.pause();
    }
    playerState = PlayerState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    if (playerState != PlayerState.paused) return;
    if (currentFormat == AudioFormat.eclipsa) {
      _startIamfPositionTimer();
      // Trigger feed manually to restart pipeline
      await _iamfDecodeAndFeed();
    } else {
      await _justAudioPlayer.play();
    }
    playerState = PlayerState.playing;
    notifyListeners();
  }

  Future<void> stop() async {
    _iamfPositionTimer?.cancel();
    await FlutterPcmSound.release();
    _cleanupIamf();
    await _justAudioPlayer.stop();
    playerState = PlayerState.stopped;
    position = Duration.zero;
    notifyListeners();
  }

  Future<void> seekTo(Duration pos) async {
    if (currentFormat == AudioFormat.eclipsa) {
      // IAMF doesn't support random seek — reset decoder and fast-forward
      // For now, update position display only (future improvement: re-init decoder)
      position = pos;
      notifyListeners();
    } else {
      await _justAudioPlayer.seek(pos);
    }
  }

  Future<void> nextSong() async {
    if (queue.isEmpty) return;
    int nextIndex = queueIndex + 1;
    if (shuffleEnabled) {
      nextIndex = (nextIndex * 7 + 3) % queue.length; // simple pseudo-random
    }
    if (nextIndex >= queue.length) {
      if (repeatMode == PlayerRepeatMode.all) {
        nextIndex = 0;
      } else {
        await stop();
        return;
      }
    }
    queueIndex = nextIndex;
    await playSong(queue[queueIndex]);
  }

  Future<void> previousSong() async {
    if (queue.isEmpty) return;
    // If >3s into song, restart; otherwise go to previous
    if (position.inSeconds > 3) {
      await seekTo(Duration.zero);
    } else {
      queueIndex = (queueIndex - 1).clamp(0, queue.length - 1);
      await playSong(queue[queueIndex]);
    }
  }

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    queue = songs;
    queueIndex = startIndex;
    if (queue.isNotEmpty) {
      await playSong(queue[queueIndex]);
    }
  }

  void toggleShuffle() {
    shuffleEnabled = !shuffleEnabled;
    notifyListeners();
  }

  void cycleRepeatMode() {
    repeatMode = switch (repeatMode) {
      PlayerRepeatMode.none => PlayerRepeatMode.one,
      PlayerRepeatMode.one => PlayerRepeatMode.all,
      PlayerRepeatMode.all => PlayerRepeatMode.none,
    };
    notifyListeners();
  }

  Future<void> switchFormat(AudioFormat format) async {
    if (currentSong == null || !currentSong!.hasFormat(format)) return;
    final savedPosition = position;
    await playSong(currentSong!, preferredFormat: format);
    if (format != AudioFormat.eclipsa) {
      await seekTo(savedPosition);
    }
  }

  // ─────────────────────────── IAMF Pipeline ───────────────────────────

  Future<void> _playIamf(String filePath) async {
    _cleanupIamf();

    // Read file bytes
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    _iamfFileSize = bytes.length;
    _iamfOffset = 0;

    // Open decoder
    _decoder = bindings.iamfkit_decoder_open();
    if (_decoder == nullptr) throw Exception('Failed to open IAMF decoder');

    // Configure layout: stereo (Sound System 0)
    bindings.iamfkit_decoder_set_sound_system(_decoder, 0);
    _iamfChannels = 2;
    bindings.iamfkit_decoder_set_bit_depth(_decoder, 16);

    // Copy file to native memory
    _iamfFileBuffer = malloc<Uint8>(_iamfFileSize);
    _iamfFileBuffer!.asTypedList(_iamfFileSize).setAll(0, bytes);

    // Configure decoder (consume header packets)
    _iamfRsize = malloc<Uint32>();
    final isConfiguredPtr = malloc<Int32>();
    var configured = false;
    while (_iamfOffset < _iamfFileSize) {
      _iamfRsize!.value = 0;
      isConfiguredPtr.value = 0;
      bindings.iamfkit_decoder_configure(
        _decoder,
        _iamfFileBuffer!.elementAt(_iamfOffset),
        _iamfFileSize - _iamfOffset,
        _iamfRsize!,
        isConfiguredPtr,
      );
      if (_iamfRsize!.value == 0) break;
      _iamfOffset += _iamfRsize!.value;
      if (isConfiguredPtr.value == 1) { configured = true; break; }
    }
    malloc.free(isConfiguredPtr);
    if (!configured) throw Exception('IAMF decoder configuration failed');

    // Query sample rate via unified info struct
    final infoPtr = malloc<IamfKitStreamInfoNative>();
    if (bindings.iamfkit_decoder_get_info(_decoder, infoPtr) == 0) {
      _iamfSampleRate = infoPtr.ref.sampleRate;
    }
    malloc.free(infoPtr);

    // Set duration estimate from file (rough: will be refined later)
    // Allocate PCM output buffer
    _iamfPcm = malloc<Uint8>(_iamfChannels * 2 * 4096).cast<Void>();

    // Setup FlutterPcmSound
    await FlutterPcmSound.setup(
      sampleRate: _iamfSampleRate,
      channelCount: _iamfChannels,
    );
    FlutterPcmSound.setFeedCallback((remainingFrames) async {
      if (playerState == PlayerState.paused) return;
      await _iamfDecodeAndFeed();
    });

    // Pre-fill buffer to avoid startup underrun
    for (var i = 0; i < 4; i++) {
      await _iamfDecodeAndFeed();
    }
    FlutterPcmSound.start();

    playerState = PlayerState.playing;
    _startIamfPositionTimer();
  }

  Future<void> _iamfDecodeAndFeed() async {
    if (_iamfFeeding || _decoder == nullptr || _iamfFileBuffer == null) return;
    _iamfFeeding = true;

    try {
      final samples = <int>[];
      var framesDecoded = 0;

      while (_iamfOffset < _iamfFileSize && framesDecoded < 10) {
        _iamfRsize!.value = 0;
        final ret = bindings.iamfkit_decoder_decode(
          _decoder,
          _iamfFileBuffer!.elementAt(_iamfOffset),
          _iamfFileSize - _iamfOffset,
          _iamfRsize!,
          _iamfPcm!,
        );
        if (_iamfRsize!.value == 0 && ret <= 0) break;
        if (ret > 0) {
          framesDecoded += ret;
          final byteLength = ret * _iamfChannels * 2;
          final pcmBytes = _iamfPcm!.cast<Uint8>().asTypedList(byteLength);
          samples.addAll(pcmBytes);
        }
        _iamfOffset += _iamfRsize!.value;
      }

      if (samples.isNotEmpty) {
        await FlutterPcmSound.feed(Uint8List.fromList(samples));
      }

      if (_iamfOffset >= _iamfFileSize) {
        _iamfPositionTimer?.cancel();
        await Future.delayed(const Duration(milliseconds: 500));
        _handleSongEnd();
      }
    } finally {
      _iamfFeeding = false;
    }
  }

  void _startIamfPositionTimer() {
    _iamfPositionTimer?.cancel();
    _iamfPositionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (playerState == PlayerState.playing) {
        position += const Duration(milliseconds: 200);
        notifyListeners();
      }
    });
  }

  void _cleanupIamf() {
    _iamfPositionTimer?.cancel();
    if (_decoder != nullptr) {
      bindings.iamfkit_decoder_close(_decoder);
      _decoder = nullptr;
    }
    if (_iamfFileBuffer != null) {
      malloc.free(_iamfFileBuffer!);
      _iamfFileBuffer = null;
    }
    if (_iamfRsize != null) {
      malloc.free(_iamfRsize!);
      _iamfRsize = null;
    }
    if (_iamfPcm != null) {
      malloc.free(_iamfPcm!);
      _iamfPcm = null;
    }
    _iamfOffset = 0;
    _iamfFileSize = 0;
  }

  void _handleSongEnd() {
    if (repeatMode == PlayerRepeatMode.one && currentSong != null) {
      playSong(currentSong!);
    } else {
      nextSong();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _justAudioStateSub?.cancel();
    _iamfPositionTimer?.cancel();
    FlutterPcmSound.release();
    _cleanupIamf();
    _justAudioPlayer.dispose();
    super.dispose();
  }
}
