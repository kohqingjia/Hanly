import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'theme_preference';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initial) : super(initial);

  void setFromProfile(String preference) {
    final mode = preference == 'dark' ? ThemeMode.dark : ThemeMode.light;
    state = mode;
    _persist(preference);
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persist(state == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> _persist(String preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, preference);
  }

  static Future<ThemeMode> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final pref = prefs.getString(_themeKey);
    if (pref == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ThemeMode.light);
});
