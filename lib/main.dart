import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'services/home_keyboard_route_observer.dart';
import 'screens/account_deletion_progress_screen.dart';
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check is required by the account deletion callable. A provider
  // initialisation error must not leave the entire website on a blank screen:
  // the callable itself still rejects requests without a valid App Check token.
  try {
    if (kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: kDebugMode
            ? WebDebugProvider()
            : ReCaptchaEnterpriseProvider(
                '6Ldcju0tAAAAAJiW0WcKHgQ_TbLjKYX66QnxUpLb',
              ),
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase App Check activation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Analytics and Performance should not prevent the app from rendering
  // if a web plugin fails during startup.
  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (error) {
    debugPrint('Firebase Analytics initialisation failed: $error');
  }
  try {
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  } catch (error) {
    debugPrint('Firebase Performance initialisation failed: $error');
  }

  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

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
        homeKeyboardRouteObserver,
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
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
      home: const AccountDeletionStartupGate(),
    );
  }
}
