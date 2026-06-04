import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'app_prefs_provider.dart';

/// Persistent app-wide theme mode (light / dark / system).
///
/// Stored in SharedPreferences under [StorageKeys.themeMode] as one of
/// 'light' | 'dark' | 'system'. Defaults to system so first-launch
/// respects the OS preference.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Resolve the persisted choice as soon as prefs are ready. Until
    // then we default to system so the app boots with sensible visuals.
    final async = ref.watch(sharedPreferencesProvider);
    return async.maybeWhen(
      data: (prefs) =>
          _fromStorage(prefs.getString(StorageKeys.themeMode)),
      orElse: () => ThemeMode.system,
    );
  }

  /// Switches the active theme mode and persists it.
  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setString(StorageKeys.themeMode, _toStorage(mode));
    } catch (e, st) {
      appLogger.w(
        'Could not persist theme mode',
        error: e,
        stackTrace: st,
      );
    }
  }

  static ThemeMode _fromStorage(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _toStorage(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
