import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_providers.dart';
import '../data/pupuk_lab_dao.dart';
import '../data/pupuk_lab_master_dao.dart';
import '../data/pupuk_lab_master_repository.dart';

final pupukLabDaoProvider = Provider<PupukLabDao>(
  (ref) => PupukLabDao(ref.watch(appDatabaseProvider)),
);

final pupukLabMasterDaoProvider = Provider<PupukLabMasterDao>(
  (ref) => PupukLabMasterDao(ref.watch(appDatabaseProvider)),
);

final pupukLabMasterRepositoryProvider = Provider<PupukLabMasterRepository>(
  (ref) => PupukLabMasterRepository(ref.watch(pupukLabMasterDaoProvider)),
);

/// The cached master, null before the first successful sync of a lab user.
/// The sync notifier invalidates it after storing a new master.
final pupukLabMasterProvider = FutureProvider<PupukLabMasterSnapshot?>(
  (ref) => ref.watch(pupukLabMasterRepositoryProvider).load(),
);

/// Codes held by local Terima Lab receipts; feeds
/// `allowedPupukActivityTypes(pendingPupukLabKodes: ...)`. Invalidate after
/// saving or deleting a receipt.
final reservedPupukLabKodeProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(pupukLabDaoProvider).getReservedKodeSampel(),
);
