import 'package:flutter_riverpod/legacy.dart';

/// Increment to trigger LSU home screen to reload pending/uploaded counts.
final homeCountsRefreshProvider = StateProvider<int>((ref) => 0);

/// Increment to trigger Fertilizer/Pupuk home screen to reload pending/uploaded counts.
final fertilizerCountsRefreshProvider = StateProvider<int>((ref) => 0);
