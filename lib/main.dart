import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'providers/library_provider.dart';
import 'screens/home_screen.dart';
import 'services/audio_handler.dart';

late MelodiaAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  _audioHandler = await AudioService.init(
    builder: () => MelodiaAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.melodia.channel.audio',
      androidNotificationChannelName: 'Melodia Audio Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(const MelodiaApp());
}

class MelodiaApp extends StatelessWidget {
  const MelodiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AudioProvider(_audioHandler)),
      ],
      child: MaterialApp(
        title: 'Melodia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          typography: Typography.material2021(),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          typography: Typography.material2021(),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
