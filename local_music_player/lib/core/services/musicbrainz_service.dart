import 'dart:convert';
import 'package:http/http.dart' as http;

class MbRelease {
  final String releaseId;
  final String title;
  final String artistName;
  final int? year;

  MbRelease({
    required this.releaseId,
    required this.title,
    required this.artistName,
    this.year,
  });
}

class MusicbrainzService {
  static const String _userAgent = 'LocalMusicPlayer/1.0 (contact@example.com)';
  
  DateTime? _lastCallTime;

  Future<void> _rateLimit() async {
    if (_lastCallTime != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastCallTime!);
      if (diff.inMilliseconds < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - diff.inMilliseconds));
      }
    }
    _lastCallTime = DateTime.now();
  }

  Future<MbRelease?> searchRelease(String artistName, String albumTitle) async {
    await _rateLimit();
    
    // Use the exact query format specified
    final query = 'artist:"$artistName" AND release:"$albumTitle"';
    final url = Uri.parse('https://musicbrainz.org/ws/2/release?query=${Uri.encodeComponent(query)}&fmt=json');

    try {
      final response = await http.get(url, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final releases = data['releases'] as List<dynamic>?;

        if (releases != null && releases.isNotEmpty) {
          final first = releases.first;
          int? year;
          if (first['date'] != null && first['date'].toString().length >= 4) {
            year = int.tryParse(first['date'].toString().substring(0, 4));
          }

          String artist = artistName;
          if (first['artist-credit'] != null && (first['artist-credit'] as List).isNotEmpty) {
             artist = first['artist-credit'][0]['name'] ?? artistName;
          }

          return MbRelease(
            releaseId: first['id'],
            title: first['title'],
            artistName: artist,
            year: year,
          );
        }
      }
    } catch (e) {
      print('MusicBrainz search error: $e');
    }
    
    return null;
  }

  Future<String?> fetchCoverArtUrl(String releaseId) async {
    await _rateLimit();

    final url = Uri.parse('https://coverartarchive.org/release/$releaseId/front-500');
    
    try {
      final response = await http.get(url, headers: {'User-Agent': _userAgent});
      
      if (response.statusCode == 200) {
        // CAA redirects to the actual image URL or returns the image data directly
        return response.request?.url.toString() ?? url.toString();
      }
    } catch (e) {
      print('Cover Art Archive error: $e');
    }
    
    return null;
  }
}
