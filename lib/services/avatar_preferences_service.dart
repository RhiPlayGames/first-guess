import 'package:shared_preferences/shared_preferences.dart';

class AvatarPreferencesService {
  static const String _selectedAvatarKey = 'selected_avatar_path';

  static Future<String?> loadSelectedAvatarPath() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    return preferences.getString(_selectedAvatarKey);
  }

  static Future<void> saveSelectedAvatarPath(String avatarPath) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _selectedAvatarKey,
      avatarPath,
    );
  }
}
