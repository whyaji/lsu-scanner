import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_stat_card.dart';
import '../../../widgets/app_section_header.dart';
import '../../../widgets/sync_progress_modal.dart';
import '../providers/home_counts_refresh_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pupuk/constants/pupuk_activity_types.dart';
import '../../pupuk/providers/sync_sampel_pupuk_provider.dart';
import '../../pupuk/screens/pupuk_qr_scanner_screen.dart';
import '../../pupuk/widgets/pupuk_activity_tile.dart';
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
    final t2Pending = await _dbHelper.getPendingKirimDariEstate();
    final t4Pending = await _dbHelper.getPendingKirimLab();
    final t5Pending = await _dbHelper.getPendingKirimSertifikatEstate();
    final t1All = await _dbHelper.getAllKirimDariEstate();
    final t2All = await _dbHelper.getAllKirimLab();
    final t3All = await _dbHelper.getAllKirimSertifikatEstate();
    final pending = t2Pending.length + t4Pending.length + t5Pending.length;
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
    if (mounted) {
      setState(() {
        _pendingCount = pending;
        _uploadedCount = uploaded;
      });
    }
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final regional = ref.read(regionalProvider).selectedRegional ?? 1;
    final syncFuture = ref
        .read(syncSampelPupukProvider.notifier)
        .sync(regional);
    if (!mounted) return;
    showSyncProgressDialog<SyncSampelPupukState>(
      context: context,
      provider: syncSampelPupukProvider,
      isInProgress: (s) => s.isSyncing,
      errorMessage: (s) => s.error,
    );
    await syncFuture;
    if (mounted) _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final hasAccess = user?.hasAnyPupukMobileAccess ?? false;
    final syncState = ref.watch(syncSampelPupukProvider);
    final regionalState = ref.watch(regionalProvider);
    final homeActivities = homePupukActivityTypes(user?.permissions);
    ref.listen<int>(fertilizerCountsRefreshProvider, (prev, next) {
      if (prev != null && next != prev && mounted) _loadCounts();
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
                    'Hubungi admin untuk mendapatkan izin mobile Pupuk (kirim estate/lab/sertifikat).',
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
                if (homeActivities.isNotEmpty) ...[
                  AppSectionHeader(title: 'Aktivitas'),
                  AppSpacing.gapSm,
                  ...homeActivities.map(
                    (type) => PupukActivityTile(
                      label: labelForPupukActivityType(type),
                      icon: Icons.qr_code_scanner,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                PupukQRScannerScreen(activityType: type),
                          ),
                        );
                      },
                    ),
                  ),
                  AppSpacing.gapSm,
                ],
                AppSectionHeader(title: 'Aksi cepat'),
                AppSpacing.gapSm,
                if (user?.hasPupukMobileKirimSertifikat ?? false) ...[
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
        return 'Sinkron Terakhir: ${app_date_utils.DateUtils.formatDateTimeForDisplay(localDt)}';
      } catch (_) {
        return 'Sinkron Terakhir: ${dateTime.toIso8601String()}';
      }
    } else {
      return 'Belum pernah sinkronisasi';
    }
  }
}
