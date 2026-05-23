import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Becomes `true` after the splash animation finishes (3 seconds).
/// The router watches this and holds the user on /splash until then.
final splashCompleteProvider = StateProvider<bool>((_) => false);
