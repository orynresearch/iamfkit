import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:local_music_player/main.dart';
import 'package:local_music_player/core/services/playback_service.dart';
import 'package:local_music_player/core/services/import_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlaybackService()),
          Provider(create: (_) => ImportService()),
        ],
        child: const LocalMusicPlayerApp(),
      ),
    );
    // The library screen should render
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
