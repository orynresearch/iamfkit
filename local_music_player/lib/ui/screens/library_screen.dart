import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/album.dart';
import '../../core/models/artist.dart';
import '../../core/models/song.dart';
import '../../core/services/database_service.dart';
import '../../core/services/import_service.dart';
import '../../core/services/musicbrainz_service.dart';
import '../../core/services/playback_service.dart';
import '../widgets/shared_widgets.dart';
import 'album_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Artist> _artists = [];
  List<Album> _albums = [];
  List<Song> _songs = [];
  bool _loading = false;
  bool _syncing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() => _loading = true);
    final db = DatabaseService.instance;
    final artists = await db.getArtists();
    final albums = <Album>[];
    for (final artist in artists) {
      final artistAlbums = await db.getAlbumsForArtist(artist.id);
      for (final album in artistAlbums) {
        final tracks = await db.getSongsForAlbum(album.id);
        albums.add(album.copyWith(tracks: tracks));
      }
    }
    final songs = await db.getAllSongs();
    setState(() {
      _artists = artists;
      _albums = albums;
      _songs = songs;
      _loading = false;
    });
  }

  Future<void> _importZip() async {
    final file = await FilePicker.pickFile(
      allowedExtensions: ['zip'],
    );
    if (file == null) return;
    final path = file.path;
    if (path == null) return;

    setState(() {
      _loading = true;
      _statusMessage = 'Extracting archive…';
    });

    final importService = context.read<ImportService>();
    final importResult = await importService.importZip(path);

    setState(() {
      _statusMessage = importResult.errors.isEmpty
          ? 'Imported ${importResult.artistsImported} artists, '
              '${importResult.albumsImported} albums, '
              '${importResult.songsImported} songs'
          : 'Import finished with errors: ${importResult.errors.first}';
    });

    await _loadLibrary();
    await _syncMetadata();
  }

  Future<void> _syncMetadata() async {
    if (_albums.isEmpty) return;
    setState(() {
      _syncing = true;
      _statusMessage = 'Syncing metadata from MusicBrainz…';
    });

    final mbService = MusicbrainzService();
    final db = DatabaseService.instance;

    for (final album in _albums) {
      if (album.musicBrainzReleaseId != null) continue;
      final release =
          await mbService.searchRelease(album.artistName, album.title);
      if (release != null) {
        final artUrl = await mbService.fetchCoverArtUrl(release.releaseId);
        final updated = album.copyWith(
          musicBrainzReleaseId: release.releaseId,
          year: release.year,
          artworkUrl: artUrl,
        );
        await db.updateAlbum(updated);
        // Also update all songs in this album
        for (final song in album.tracks) {
          await db.updateSong(song.copyWith(artworkUrl: artUrl));
        }
      }
    }

    setState(() => _syncing = false);
    await _loadLibrary();
    setState(() => _statusMessage = 'Metadata synced!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0D1F),
                  Color(0xFF0A0A14),
                  Color(0xFF0D1020),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTabBar(),
                if (_statusMessage != null)
                  _buildStatusBanner(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C4DFF),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildArtistsTab(),
                            _buildAlbumsTab(),
                            _buildSongsTab(),
                          ],
                        ),
                ),
                // Space for mini player
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '${_songs.length} songs · ${_albums.length} albums',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_syncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF7C4DFF),
              ),
            ),
          const SizedBox(width: 8),
          _HeaderButton(
            icon: Icons.download_rounded,
            onTap: _importZip,
            tooltip: 'Import ZIP',
          ),
          _HeaderButton(
            icon: Icons.sync_rounded,
            onTap: _syncMetadata,
            tooltip: 'Sync Metadata',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(4),
        borderRadius: 14,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFF7C4DFF).withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelColor: Colors.white54,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Artists'),
            Tab(text: 'Albums'),
            Tab(text: 'Songs'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return AnimatedOpacity(
      opacity: _statusMessage != null ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          borderRadius: 12,
          tint: const Color(0xFF7C4DFF),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF7C4DFF), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _statusMessage = null),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white38, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistsTab() {
    if (_artists.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return _ArtistTile(
          artist: artist,
          onTap: () {
            final artistAlbums =
                _albums.where((a) => a.artistName == artist.name).toList();
            _showArtistAlbums(artist, artistAlbums);
          },
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) return _buildEmptyState();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return _AlbumCard(
          album: album,
          onTap: () => _openAlbum(album),
        );
      },
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return _SongTile(
          song: song,
          onTap: () {
            final playback = context.read<PlaybackService>();
            playback.setQueue(_songs, startIndex: index);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 72,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No music yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap ↓ to import a ZIP archive',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _openAlbum(Album album) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AlbumScreen(album: album)),
    );
  }

  void _showArtistAlbums(Artist artist, List<Album> albums) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => GlassCard(
          borderRadius: 24,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                artist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: albums.length,
                  itemBuilder: (_, i) => _AlbumListTile(
                    album: albums[i],
                    onTap: () {
                      Navigator.pop(context);
                      _openAlbum(albums[i]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderButton(
      {required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistTile({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withOpacity(0.6),
                    const Color(0xFF3D1CB3).withOpacity(0.6),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                artist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AlbumArtWidget(
              album: album,
              size: double.infinity,
              borderRadius: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            album.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumListTile extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumListTile({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AlbumArtWidget(album: album, size: 48, borderRadius: 8),
      title: Text(album.title,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(
        album.year?.toString() ?? album.artistName,
        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
      onTap: onTap,
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _SongTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final isPlaying = playback.currentSong?.id == song.id;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFF7C4DFF).withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPlaying
                ? const Color(0xFF7C4DFF).withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: isPlaying
                  ? WaveformIndicator(
                      isPlaying: playback.playerState == PlayerState.playing,
                      color: const Color(0xFF7C4DFF),
                      barCount: 3,
                    )
                  : Text(
                      '${song.trackNumber}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying
                          ? const Color(0xFFB39DFF)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    song.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildFormatPills(song),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatPills(Song song) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (song.eclipsaPath != null) _pill('E', const Color(0xFF7C4DFF)),
        if (song.atmosPath != null) _pill('A', const Color(0xFF00B4D8)),
        if (song.standardPath != null) _pill('S', const Color(0xFF4CAF50)),
      ],
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 3),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
