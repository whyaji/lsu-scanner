import '../models/pupuk_lab_master.dart';
import 'pupuk_lab_master_dao.dart';

/// What the form needs to know about the cached master data.
class PupukLabMasterSnapshot {
  const PupukLabMasterSnapshot({
    required this.master,
    required this.syncedAt,
    required this.isStale,
  });

  final PupukLabMaster master;
  final DateTime syncedAt;

  /// The data may be outdated: the backend served an old snapshot, the last
  /// sync could not refresh it, or it is older than
  /// [PupukLabMasterRepository.staleAfter].
  final bool isStale;
}

/// Loads the master from SQLite once and keeps it in memory afterwards.
class PupukLabMasterRepository {
  PupukLabMasterRepository(
    this._dao, {
    this.staleAfter = const Duration(hours: 24),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PupukLabMasterDao _dao;
  final Duration staleAfter;
  final DateTime Function() _clock;

  StoredPupukLabMaster? _stored;
  bool _loaded = false;
  bool _serverStale = false;

  Future<PupukLabMasterSnapshot?> load() async {
    if (!_loaded) {
      _stored = await _dao.load();
      _loaded = true;
    }
    final stored = _stored;
    if (stored == null) return null;
    return PupukLabMasterSnapshot(
      master: stored.master,
      syncedAt: stored.syncedAt,
      isStale:
          _serverStale || stored.master.isOlderThan(staleAfter, now: _clock()),
    );
  }

  Future<bool> get hasMaster async => (await load()) != null;

  /// Replaces the cached master. [serverStale] is the backend's flag that
  /// SmartLab was unreachable and this is an older snapshot.
  Future<void> store(PupukLabMaster master, {bool serverStale = false}) async {
    final syncedAt = _clock();
    await _dao.save(master, syncedAt: syncedAt);
    _stored = StoredPupukLabMaster(master: master, syncedAt: syncedAt);
    _loaded = true;
    _serverStale = serverStale;
  }

  /// A sync could not refresh the master; keep the old one but flag it.
  void markStale() => _serverStale = true;

  Future<void> clear() async {
    await _dao.clear();
    _stored = null;
    _loaded = true;
    _serverStale = false;
  }
}
