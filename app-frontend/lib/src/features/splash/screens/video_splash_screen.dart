import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:workmanager/workmanager.dart';
import 'package:al_faruk_app/src/core/services/service_providers.dart';
import 'package:al_faruk_app/src/core/services/notification_service.dart';
import 'package:al_faruk_app/src/features/auth/screens/auth_gate.dart';

const dailyNotificationTask = "scheduleDailyPrayerNotifications";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    try {
      if (task == dailyNotificationTask) {
        await NotificationService.init(isBackground: true);
        await NotificationService.scheduleDailyPrayerNotifications();
      }
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _videoInitialized = false;
  bool _appReady = false;

  @override
  void initState() {
    super.initState();
    _bootApp();
  }

  Future<void> _bootApp() async {
    // 1. Start Video immediately
    _initializeVideo();

    // 2. Start App Setup (Firebase, Settings, etc.)
    _setupAppResources();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/splash.mp4');
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _videoInitialized = true);
        _controller.play();
        _controller.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint("Video Error: $e");
      _appReady = true;
      _navigateToNext();
    }
  }

  void _videoListener() {
    if (_controller.value.position >= _controller.value.duration) {
      if (_appReady) {
        _navigateToNext();
      } else {
        _controller.pause();
      }
    }
  }

  Future<void> _setupAppResources() async {
    try {
      // 1. Initialize Audio Background (Required for your Library audio to play)
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.alfaruk.app.audio',
        androidNotificationChannelName: 'Al-Faruk Audio Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      );

      // 2. Core services (Do not block with permissions yet)
      await Firebase.initializeApp();
      await dotenv.load(fileName: "assets/.env");
      await settingsService.loadSettings();
      await NotificationService.init(isBackground: false);

      // 3. Workmanager init
      if (!kIsWeb) {
        try {
          await Workmanager().initialize(callbackDispatcher);
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _appReady = true);
        // If video already finished, move to AuthGate
        if (_videoInitialized &&
            _controller.value.position >= _controller.value.duration) {
          _navigateToNext();
        }
      }
    } catch (e) {
      debugPrint("Init Error: $e");
      if (mounted) setState(() => _appReady = true);
    }
  }

  void _navigateToNext() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, a, b) => const AuthGate(),
          transitionsBuilder: (context, a, b, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
