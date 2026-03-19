import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_stat_card.dart';
import '../../../widgets/app_section_header.dart';
import '../providers/home_counts_refresh_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pupuk/providers/sync_sampel_pupuk_provider.dart';
import '../../pupuk/screens/pupuk_qr_scanner_screen.dart';
import '../../pupuk/screens/sampel_pupuk_list_screen.dart';
import '../../pupuk/screens/upload_sampel_pupuk_screen.dart';
import '../../pupuk/screens/kirim_sertifikat_form_screen.dart';
import '../../regional/providers/regional_provider.dart';
import '../../settings/screens/settings_screen.dart';

class FertilizerHomeScreen extends ConsumerStatefulWidget {
  const FertilizerHomeScreen({
    super.key,
    this.showBackButton = true,
    this.showSettingsInAppBar = true,
  });

  final bool showBackButton;
  final bool showSettingsInAppBar;

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
    final t5Pending = await _dbHelper.getPendingKirimSertifikatEstate();
    final t1All = await _dbHelper.getAllTerimaDariGudang();
    final t2All = await _dbHelper.getAllKirimDariEstate();
    final t3All = await _dbHelper.getAllTerimaDariEstate();
    final t4All = await _dbHelper.getAllKirimLab();
    final t5All = await _dbHelper.getAllKirimSertifikatEstate();
    final pending =
        t1Pending.length +
        t2Pending.length +
        t3Pending.length +
        t4Pending.length +
        t5Pending.length;
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
    for (final row in t5All) {
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
    ref.listen<int>(fertilizerCountsRefreshProvider, (prev, next) {
      if (prev != null && next != prev && mounted) _loadCounts();
    });
    ref.listen<SyncSampelPupukState>(syncSampelPupukProvider, (prev, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          title: const Text('Sampel Pupuk'),
          actions: [
            if (widget.showSettingsInAppBar)
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
              padding: AppSpacing.paddingXl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.gapLg,
                  Text(
                    'Anda tidak memiliki akses Sampel Pupuk.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Hubungi admin untuk mendapatkan akses pupuk:estate atau pupuk:nt.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Sampel Pupuk'),
        actions: [
          if (widget.showSettingsInAppBar)
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
        child: RefreshIndicator(
          onRefresh: () async {
            await _sync();
            await _loadCounts();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang, ${authState.user?.nama ?? "Pengguna"}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        AppSpacing.gapSm,
                        if (regionalState.selectedRegional != null)
                          Text(
                            'Regional ${regionalState.selectedRegional}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          _formatDateTimeSync(
                            syncState.lastSyncTime != null
                                ? DateTime.parse(syncState.lastSyncTime!)
                                : null,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapMd,

                Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        label: 'Menunggu',
                        value: _pendingCount.toString(),
                        color: colorScheme.tertiary,
                        icon: Icons.pending,
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
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: AppStatCard(
                        label: 'Terunggah',
                        value: _uploadedCount.toString(),
                        color: colorScheme.primary,
                        icon: Icons.cloud_done,
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
                      ),
                    ),
                  ],
                ),
                AppSectionHeader(title: 'Aksi cepat'),
                AppSpacing.gapSm,
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PupukQRScannerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: const Text('Pindai QR Sampel Pupuk'),
                ),
                AppSpacing.gapSm,
                if (authState.user?.hasPupukNtAccess ?? false) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => const KirimSertifikatFormScreen(),
                            ),
                          )
                          .then((_) => _loadCounts());
                    },
                    icon: const Icon(Icons.send, size: 24),
                    label: const Text('Kirim Sertifikat'),
                  ),
                  AppSpacing.gapSm,
                ],
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
                  icon: const Icon(Icons.cloud_upload, size: 24),
                  label: Text(
                    _pendingCount > 0
                        ? 'Unggah Sampel ($_pendingCount)'
                        : 'Unggah Sampel',
                  ),
                ),
                AppSectionHeader(title: 'Sinkronisasi'),
                AppSpacing.gapSm,
                ElevatedButton.icon(
                  onPressed: syncState.isSyncing ? null : _sync,
                  icon: syncState.isSyncing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    syncState.isSyncing
                        ? 'Menyinkronkan…'
                        : 'Sinkronkan Data Sampel Pupuk',
                  ),
                ),
                if (syncState.error != null) ...[
                  AppSpacing.gapSm,
                  Text(
                    syncState.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
