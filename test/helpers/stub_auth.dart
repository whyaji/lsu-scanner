import 'package:flutter_riverpod/legacy.dart';
import 'package:sampletrack/core/network/models/auth_models.dart';
import 'package:sampletrack/features/auth/providers/auth_provider.dart';

import 'test_user.dart';

/// Stands in for [AuthNotifier] in widget tests: holds a signed in user and
/// never touches secure storage or the network.
class StubAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  StubAuthNotifier([User? user])
    : super(AuthState(user: user ?? testUser(const []), isCheckingAuth: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
