import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

class PlayGamesService {
  PlayGamesService._();

  static Future<bool> get isSignedIn async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await GameAuth.isSignedIn;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> signIn() async {
    if (kIsWeb) {
      return false;
    }

    try {
      if (await GameAuth.isSignedIn) {
        return true;
      }

      await GameAuth.signIn();
      return await GameAuth.isSignedIn;
    } catch (_) {
      return false;
    }
  }
}