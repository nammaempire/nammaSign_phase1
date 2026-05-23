import 'package:flutter/material.dart';

/// Convenience getters on [BuildContext] — keeps widget code terse.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
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
