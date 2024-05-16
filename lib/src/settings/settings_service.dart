import 'package:ernteliste/src/persistence/persistor.dart';
import 'package:flutter/material.dart';
import 'package:server/tables.dart';

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
      var setting = await Persistor.getUserSetting('theme');
      if (setting != null) {
        return ThemeModeHelper.fromJson(setting);
      }
    }
    return ThemeMode.system;
  }
  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateThemeMode(ThemeMode value) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    await Persistor.putUserSetting('theme', value.name);
  }
  Future<num> anteile() async {
    return await Persistor.getUserSetting(columnAnteile, sys: true);
  }
  Future<void> updateAnteile(num value) async {
    await Persistor.putUserSetting(columnAnteile, value, sys: true);
  }
}
