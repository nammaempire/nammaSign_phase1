import 'package:logger/logger.dart';

/// App-wide logger. Use this instead of `print` or `debugPrint`.
///
/// In release builds the logger is configured to drop debug logs so secrets
/// and verbose state don't leak.
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
