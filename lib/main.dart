import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restrict installed Android phones to portrait; leave tablets free to rotate.
  // iPhone and iPad orientations are configured separately in Info.plist.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final display = WidgetsBinding.instance.platformDispatcher.displays.first;
    final double shortestSide =
        display.size.shortestSide / display.devicePixelRatio;
    await SystemChrome.setPreferredOrientations(
      shortestSide < 600
          ? <DeviceOrientation>[DeviceOrientation.portraitUp]
          : <DeviceOrientation>[],
    );
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      );
      return true;
    };
  }

  final FirebaseAuth auth = FirebaseAuth.instance;

  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  debugPrint('FIREBASE UID: ${auth.currentUser?.uid}');
  debugPrint('ANONYMOUS: ${auth.currentUser?.isAnonymous}');

  runApp(const FirstGuessApp());
}

class FirstGuessApp extends StatelessWidget {
  const FirstGuessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Guess',
      debugShowCheckedModeBanner: false,
      navigatorObservers: <NavigatorObserver>[
        FirebaseAnalyticsObserver(
          analytics: FirebaseAnalytics.instance,
        ),
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}