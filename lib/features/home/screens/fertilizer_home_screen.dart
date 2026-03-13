import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pupuk/providers/sync_sampel_pupuk_provider.dart';
import '../../pupuk/screens/pupuk_qr_scanner_screen.dart';
import '../../pupuk/screens/sampel_pupuk_list_screen.dart';
import '../../pupuk/screens/upload_sampel_pupuk_screen.dart';
import '../../regional/providers/regional_provider.dart';
import '../../settings/screens/settings_screen.dart';
import 'package:intl/intl.dart';

class FertilizerHomeScreen extends ConsumerStatefulWidget {
  const FertilizerHomeScreen({super.key});

  @override
  ConsumerState<FertilizerHomeScreen> createState() =>
      _FertilizerHomeScreenState();
}

class _FertilizerHomeScreenState extends ConsumerState<FertilizerHomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int _pendingCount = 0;
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    ref.read(syncSampelPupukProvider.notifier).loadLastSyncTime();
  }

  Future<void> _loadCounts() async {
    final t1Pending = await _dbHelper.getPendingTerimaDariGudang();
    final t2Pending = await _dbHelper.getPendingKirimDariEstate();
    final t3Pending = await _dbHelper.getPendingTerimaDariEstate();
    final t4Pending = await _dbHelper.getPendingKirimLab();
    final t1All = await _dbHelper.getAllTerimaDariGudang();
    final t2All = await _dbHelper.getAllKirimDariEstate();
    final t3All = await _dbHelper.getAllTerimaDariEstate();
    final t4All = await _dbHelper.getAllKirimLab();
    final pending =
        t1Pending.length +
        t2Pending.length +
        t3Pending.length +
        t4Pending.length;
    int uploaded = 0;
    for (final row in t1All) {
      if (row.status == AppConstants.statusUploaded) uploaded++;
    }
    for (final row in t2All) {
      if (row.status == AppConstants.statusUploaded) uploaded++;
    }
    for (final row in t3All) {
      if (row.status == AppConstants.statusUploaded) uploaded++;
    }
    for (final row in t4All) {
      if (row.status == AppConstants.statusUploaded) uploaded++;
    }
    if (mounted) {
      setState(() {
        _pendingCount = pending;
        _uploadedCount = uploaded;
      });
    }
  }

  Future<void> _sync() async {
    final regional = ref.read(regionalProvider).selectedRegional ?? 1;
    await ref.read(syncSampelPupukProvider.notifier).sync(regional);
    if (mounted) _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasAccess = authState.user?.hasAnyPupukAccess ?? false;
    final syncState = ref.watch(syncSampelPupukProvider);
    final regionalState = ref.watch(regionalProvider);
    ref.listen<SyncSampelPupukState>(syncSampelPupukProvider, (prev, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Sampel Pupuk'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Anda tidak memiliki akses Sampel Pupuk.',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hubungi admin untuk mendapatkan akses pupuk:estate atau pupuk:nt.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Sampel Pupuk'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _sync();
            await _loadCounts();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang, ${authState.user?.nama ?? "Pengguna"}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (regionalState.selectedRegional != null)
                          Text(
                            'Regional ${regionalState.selectedRegional}',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        if (syncState.lastSyncTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatDateTimeSync(
                                syncState.lastSyncTime != null
                                    ? DateTime.parse(syncState.lastSyncTime!)
                                    : null,
                              ),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Cards — Menunggu / Terunggah
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const SampelPupukListScreen(
                                    isPending: true,
                                  ),
                                ),
                              )
                              .then((_) => _loadCounts());
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: _buildStatCard(
                          'Menunggu',
                          _pendingCount.toString(),
                          AppColors.warning,
                          Icons.pending,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const SampelPupukListScreen(
                                    isPending: false,
                                  ),
                                ),
                              )
                              .then((_) => _loadCounts());
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: _buildStatCard(
                          'Terunggah',
                          _uploadedCount.toString(),
                          AppColors.success,
                          Icons.cloud_done,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sync
                ElevatedButton.icon(
                  onPressed: syncState.isSyncing ? null : _sync,
                  icon: syncState.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    syncState.isSyncing
                        ? 'Menyinkronkan…'
                        : 'Sinkronkan Data Sampel Pupuk',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (syncState.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    syncState.error!,
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),

                // Actions
                const Text(
                  'Aksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PupukQRScannerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 28),
                  label: const Text('Pindai QR Sampel Pupuk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const UploadSampelPupukScreen(),
                          ),
                        )
                        .then((_) => _loadCounts());
                  },
                  icon: const Icon(Icons.cloud_upload, size: 28),
                  label: Text(
                    _pendingCount > 0
                        ? 'Unggah Sampel ($_pendingCount)'
                        : 'Unggah Sampel',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTimeSync(DateTime? dateTime) {
    if (dateTime != null) {
      try {
        final localDt = dateTime.isUtc ? dateTime.toLocal() : dateTime;
        return 'Sinkron Terakhir: ${DateFormat('d MMM yyyy, HH:mm:ss').format(localDt)}';
      } catch (_) {
        return 'Sinkron Terakhir: ${dateTime.toIso8601String()}';
      }
    } else {
      return 'Belum pernah sinkronisasi';
    }
  }
}
