import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/app_prefs_provider.dart';
import '../../domain/account_type.dart';

/// User's chosen account type. Defaults to corporate to match the design's
/// pre-selected state. Persisted to SharedPreferences on "Continue".
final selectedAccountTypeProvider =
    StateProvider<AccountType>((_) => AccountType.corporate);

/// Reads the persisted account type from SharedPreferences (null if not set).
final persistedAccountTypeProvider = Provider<AccountType?>((ref) {
  return ref.watch(sharedPreferencesProvider).maybeWhen(
        data: (prefs) =>
            AccountType.fromStorage(prefs.getString(StorageKeys.accountType)),
        orElse: () => null,
      );
});
