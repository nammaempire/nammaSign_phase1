import 'package:flutter/material.dart';

/// Convenience getters on [BuildContext] — keeps widget code terse.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;

  /// NOTE: the `colors` getter that returned [ColorScheme] used to live
  /// here. It collided with `AppPaletteX.colors` after the theme refactor,
  /// so callers should reach Material's ColorScheme via `theme.colorScheme`
  /// directly, and use the semantic `context.colors` from AppPaletteX for
  /// the app palette (bg / card / textPrimary / …).

  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => mq.size;
  EdgeInsets get safeInsets => mq.padding;
  bool get isKeyboardOpen => mq.viewInsets.bottom > 0;

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showErrorSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
      ));
  }
}
