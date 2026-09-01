import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/services/playback_service.dart';
import 'core/services/import_service.dart';
import 'ui/screens/library_screen.dart';
import 'ui/widgets/mini_player.dart';

// ─── FEATURE TOGGLE ────────────────────────────────────────────────────────────
/// Set to [true] to show one merged entry per song with a quality picker.
/// Set to [false] to show separate entries for each format.
/// Hot-reload safe.
const bool kMergeFormats = true;
// ──────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaybackService()),
        Provider(create: (_) => ImportService()),
      ],
      child: const LocalMusicPlayerApp(),
    ),
  );
}

class LocalMusicPlayerApp extends StatelessWidget {
  const LocalMusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Music Player',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const AppShell(),
    );
  }

  ThemeData _buildTheme() {
    const seedColor = Color(0xFF7C4DFF);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF0A0A14),
        surfaceContainer: const Color(0xFF13131F),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A14),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      iconTheme: const IconThemeData(color: Colors.white70),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LibraryScreen(),
          // Mini player anchored above safe area bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer<PlaybackService>(
              builder: (context, playback, _) {
                if (playback.currentSong == null) return const SizedBox.shrink();
                return const MiniPlayer();
              },
            ),
          ),
        ],
      ),
    );
  }
}
