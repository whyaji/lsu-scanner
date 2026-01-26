import 'package:flutter_riverpod/legacy.dart';

/// Increment to trigger home screen to reload pending/uploaded counts.
final homeCountsRefreshProvider = StateProvider<int>((ref) => 0);
