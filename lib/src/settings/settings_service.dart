import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';

extension ThemeModeHelper on ThemeMode {
  String toJson() => name;
  static ThemeMode fromJson(String json) => ThemeMode.values.byName(json);
}

/// A service that stores and retrieves user settings.
///
/// By default, this class does not persist user settings. If you'd like to
/// persist the user settings locally, use the shared_preferences package. If
/// you'd like to store settings on a web server, use the http package.
class SettingsService {
  /// Loads the User's preferred ThemeMode from local or remote storage.
  Future<ThemeMode> themeMode() async {
    if (Persistor.userName.isNotEmpty) {
      var userSetting = Persistor.getUserSetting('theme');
      if (userSetting != null) {
        return ThemeModeHelper.fromJson(userSetting);
      }
    }
    return ThemeMode.system;
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    await Persistor.putUserSetting('theme', theme.name);
  }
}
