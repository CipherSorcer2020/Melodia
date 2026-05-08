import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'providers/library_provider.dart';
import 'screens/home_screen.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  // Keep the native splash on screen while we boot
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const MelodiaApp());
}

class MelodiaApp extends StatefulWidget {
  const MelodiaApp({super.key});

  @override
  State<MelodiaApp> createState() => _MelodiaAppState();
}

class _MelodiaAppState extends State<MelodiaApp> {
  MelodiaAudioHandler? _handler;

  @override
  void initState() {
    super.initState();
    _bootAudioService();
  }

  Future<void> _bootAudioService() async {
    // Notification permission — required on Android 13+ for any notification
    await Permission.notification.request();

    // Battery optimization exemption — ColorOS/OPPO aggressively kills services
    // without this, killing the foreground audio service when the app backgrounds
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    MelodiaAudioHandler handler;
    try {
      handler = await AudioService.init(
        builder: () => MelodiaAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.melodia.channel.audio',
          androidNotificationChannelName: 'Melodia Audio Playback',
          androidStopForegroundOnPause: false,
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('AudioService.init timed out — using handler directly');
          return MelodiaAudioHandler();
        },
      );
    } catch (e) {
      debugPrint('AudioService init error: $e');
      handler = MelodiaAudioHandler();
    }

    if (mounted) {
      setState(() => _handler = handler);
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = _handler;

    // While AudioService is booting, show nothing — the native splash covers it
    if (handler == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        darkTheme: _darkTheme(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(backgroundColor: Color(0xFF0D0B1A)),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AudioProvider(handler)),
      ],
      child: MaterialApp(
        title: 'Melodia',
        debugShowCheckedModeBanner: false,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        themeMode: ThemeMode.dark,
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _darkTheme() {
    const primary = Color(0xFF8B5CF6);
    const secondary = Color(0xFFEC4899);
    const bg = Color(0xFF0D0B1A);
    const surface = Color(0xFF12101F);
    const card = Color(0xFF1A1630);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: Colors.white,
        primaryContainer: Color(0xFF3B1F7A),
        onPrimaryContainer: Colors.white,
        secondaryContainer: Color(0xFF7C1A4A),
        onSecondaryContainer: Colors.white,
        surfaceContainerHighest: card,
        error: Color(0xFFFC8181),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: Colors.white10,
      typography: Typography.material2021(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.2),
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 4,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.light,
      ),
      typography: Typography.material2021(),
    );
  }
}
