import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:eclipsa_iamf_decoder/eclipsa_iamf_decoder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eclipsa IAMF Stream Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const EclipsaPlayerHome(),
    );
  }
}

class EclipsaPlayerHome extends StatefulWidget {
  const EclipsaPlayerHome({super.key});

  @override
  State<EclipsaPlayerHome> createState() => _EclipsaPlayerHomeState();
}

class _EclipsaPlayerHomeState extends State<EclipsaPlayerHome> {
  // Config & File State
  String _fileName = 'test_000003.iamf (Asset)';
  Uint8List? _fileBytes;
  
  // Decoding / Playback State
  bool _isPlaying = false;
  bool _isPaused = false;
  String _status = 'Ready';
  int _totalFrames = 0;
  int _nonZeroSamples = 0;
  int _sampleRate = 0;
  int _channelsCount = 0;

  // Native Pointers
  Pointer<IAMF_Decoder> _decoderHandle = nullptr;
  Pointer<Uint8>? _pBuffer;
  Pointer<Uint32>? _pRsize;
  Pointer<Void>? _pPcm;
  int _decodeOffset = 0;
  int _fileSize = 0;
  bool _isFeeding = false;

  @override
  void dispose() {
    _cleanupDecoder();
    FlutterPcmSound.release();
    super.dispose();
  }

  void _cleanupDecoder() {
    if (_decoderHandle != nullptr) {
      bindings.IAMF_decoder_close(_decoderHandle);
      _decoderHandle = nullptr;
    }
    if (_pBuffer != null) {
      malloc.free(_pBuffer!);
      _pBuffer = null;
    }
    if (_pRsize != null) {
      malloc.free(_pRsize!);
      _pRsize = null;
    }
    if (_pPcm != null) {
      malloc.free(_pPcm!);
      _pPcm = null;
    }
  }

  Future<void> _pickFile() async {
    try {
      await _stopPlayback();
      final file = await FilePicker.pickFile();

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _fileName = file.name;
          _fileBytes = bytes;
          _status = 'File loaded. Ready to stream.';
          _totalFrames = 0;
          _nonZeroSamples = 0;
          _sampleRate = 0;
          _channelsCount = 0;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _startDecodingAndStreaming() async {
    setState(() {
      _status = 'Starting stream...';
      _totalFrames = 0;
      _nonZeroSamples = 0;
      _sampleRate = 0;
      _channelsCount = 0;
      _isPaused = false;
    });

    try {
      Uint8List bytes;
      if (_fileBytes != null) {
        bytes = _fileBytes!;
      } else {
        // Fallback to asset
        final data = await rootBundle.load('assets/test_000003.iamf');
        bytes = data.buffer.asUint8List();
      }
      
      _fileSize = bytes.length;
      _decodeOffset = 0;

      // Open decoder
      _decoderHandle = bindings.IAMF_decoder_open();
      if (_decoderHandle == nullptr) {
        throw Exception('Failed to open IAMF Decoder');
      }

      // Set layout (Sound System A = stereo)
      const soundSystem = IAMF_SoundSystem.SOUND_SYSTEM_A;
      var ret = bindings.IAMF_decoder_output_layout_set_sound_system(_decoderHandle, soundSystem);
      if (ret < 0) throw Exception('Failed to set sound system, error: $ret');
      _channelsCount = bindings.IAMF_layout_sound_system_channels_count(soundSystem);

      // Set bit depth (16-bit)
      ret = bindings.IAMF_decoder_set_bit_depth(_decoderHandle, 16);
      if (ret < 0) throw Exception('Failed to set bit depth, error: $ret');

      // Copy bytes to native memory
      _pBuffer = malloc<Uint8>(_fileSize);
      final pBufferList = _pBuffer!.asTypedList(_fileSize);
      pBufferList.setAll(0, bytes);

      // Configure loop
      _pRsize = malloc<Uint32>();
      var configured = false;

      while (_decodeOffset < _fileSize) {
        _pRsize!.value = 0;
        ret = bindings.IAMF_decoder_configure(
          _decoderHandle,
          _pBuffer!.elementAt(_decodeOffset),
          _fileSize - _decodeOffset,
          _pRsize!,
        );
        if (_pRsize!.value == 0) break;
        _decodeOffset += _pRsize!.value;
        if (ret == 0) { // IAMF_OK = 0
          configured = true;
          break;
        }
      }

      if (!configured) {
        _cleanupDecoder();
        throw Exception('Decoder configuration failed');
      }

      // Query stream info/sampling rate
      final info = bindings.IAMF_decoder_get_stream_info(_decoderHandle);
      if (info != nullptr) {
        _sampleRate = info.ref.iamf_stream_info.sampling_rate.value;
      } else {
        _sampleRate = 16000; // fallback
      }

      // Allocate PCM buffer (Stereo, 16-bit, up to 4096 samples per channel)
      final pcmCapacity = _channelsCount * 2 * 4096;
      _pPcm = malloc<Uint8>(pcmCapacity).cast<Void>();

      // Setup FlutterPcmSound player
      await FlutterPcmSound.setup(
        sampleRate: _sampleRate,
        channelCount: _channelsCount,
      );

      FlutterPcmSound.setFeedCallback((int remainingFrames) async {
        await _decodeAndFeedChunk();
      });

      // Feed initial buffer to avoid underruns
      for (var i = 0; i < 4; i++) {
        await _decodeAndFeedChunk();
      }

      // Kickoff playback
      FlutterPcmSound.start();
      
      setState(() {
        _isPlaying = true;
        _status = 'Playing (Streaming)';
      });
    } catch (e) {
      _cleanupDecoder();
      setState(() {
        _isPlaying = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _decodeAndFeedChunk() async {
    if (_isFeeding) return;
    _isFeeding = true;

    try {
      if (_decoderHandle == nullptr || _pBuffer == null || _pRsize == null || _pPcm == null) return;
      
      // If paused, feed silence/nothing to suspend playing
      if (_isPaused) {
        return;
      }

      final accumulatedSamples = <int>[];
      var framesDecodedThisChunk = 0;

      // Decode a cluster of frames (e.g. up to 10 frames or 80ms of audio)
      while (_decodeOffset < _fileSize && framesDecodedThisChunk < 10) {
        _pRsize!.value = 0;
        final ret = bindings.IAMF_decoder_decode(
          _decoderHandle,
          _pBuffer!.elementAt(_decodeOffset),
          _fileSize - _decodeOffset,
          _pRsize!,
          _pPcm!,
        );
        if (_pRsize!.value == 0 && ret <= 0) break;

        if (ret > 0) {
          framesDecodedThisChunk++;
          _totalFrames++;
          final int totalSamples = ret * _channelsCount;
          final Pointer<Int16> pPcm16 = _pPcm!.cast<Int16>();
          
          for (var i = 0; i < totalSamples; i++) {
            final sample = pPcm16[i];
            if (sample != 0) {
              _nonZeroSamples++;
            }
            accumulatedSamples.add(sample);
          }
        }
        _decodeOffset += _pRsize!.value;
      }

      if (accumulatedSamples.isNotEmpty) {
        await FlutterPcmSound.feed(PcmArrayInt16.fromList(accumulatedSamples));
        if (mounted) setState(() {});
      }

      if (_decodeOffset >= _fileSize && framesDecodedThisChunk == 0) {
        // Complete playback when queue drains out
        await _stopPlayback();
        if (mounted) {
          setState(() {
            _status = 'Finished Playback';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Playback Error: $e';
        });
      }
    } finally {
      _isFeeding = false;
    }
  }

  Future<void> _togglePlayPause() async {
    if (_decoderHandle == nullptr) {
      await _startDecodingAndStreaming();
    } else {
      setState(() {
        _isPaused = !_isPaused;
        _isPlaying = !_isPaused;
        _status = _isPaused ? 'Paused' : 'Playing (Streaming)';
      });
      // If resumed, trigger feed manually to start pipeline again
      if (!_isPaused) {
        await _decodeAndFeedChunk();
      }
    }
  }

  Future<void> _stopPlayback() async {
    await FlutterPcmSound.release();
    _cleanupDecoder();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _status = 'Stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eclipsa IAMF Streamer'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.stream, size: 64, color: Colors.deepPurpleAccent),
                      const SizedBox(height: 10),
                      Text(
                        _fileName,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow('Status', _status, color: _status.startsWith('Playing') ? Colors.green : (_status.startsWith('Error') ? Colors.redAccent : null)),
                      _buildInfoRow('Sample Rate', _sampleRate > 0 ? '$_sampleRate Hz' : '-'),
                      _buildInfoRow('Channels', _channelsCount > 0 ? '$_channelsCount' : '-'),
                      _buildInfoRow('Decoded Frames', '$_totalFrames'),
                      _buildInfoRow('Non-zero Samples', '$_nonZeroSamples', color: _nonZeroSamples > 0 ? Colors.greenAccent : null),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Audio Playback Controller Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 64,
                    icon: Icon(
                      _isPlaying 
                        ? Icons.pause_circle_filled 
                        : Icons.play_circle_filled,
                      color: Colors.deepPurpleAccent,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                    onPressed: _stopPlayback,
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isPlaying ? null : _pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose .iamf File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: color,
              )
            ),
          ),
        ],
      ),
    );
  }
}
