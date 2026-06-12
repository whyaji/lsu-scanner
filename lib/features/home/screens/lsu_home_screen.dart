import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_footer.dart';
import '../../../widgets/app_stat_card.dart';
import '../../../widgets/app_section_header.dart';
import '../../../widgets/sync_progress_modal.dart';
import '../../scanner/screens/qr_scanner_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../upload/screens/upload_screen.dart';
import '../../sync/providers/sync_provider.dart';
import '../../regional/providers/regional_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sample/screens/received_list_screen.dart';
import '../providers/home_counts_refresh_provider.dart';

import '../../notifications/providers/notification_provider.dart';

class LsuHomeScreen extends ConsumerStatefulWidget {
  const LsuHomeScreen({
    super.key,
    this.showBackButton = true,
    this.showSettingsInAppBar = true,
  });

  final bool showBackButton;
  final bool showSettingsInAppBar;

  @override
  ConsumerState<LsuHomeScreen> createState() => _LsuHomeScreenState();
}

class _LsuHomeScreenState extends ConsumerState<LsuHomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int _pendingCount = 0;
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final pendingReceived = await _dbHelper.getPendingUploads();
    final pendingComplete = await _dbHelper.getPendingCompleteUploads();
    final allReceived = await _dbHelper.getAllReceivedSamples();
    final allCompleted = await _dbHelper.getAllCompletedSamples();
    final uploadedReceived = allReceived
        .where((s) => s.status == AppConstants.statusUploaded)
        .length;
    final uploadedComplete = allCompleted
        .where((s) => s.status == AppConstants.statusUploaded)
        .length;

    setState(() {
      _pendingCount = pendingReceived.length + pendingComplete.length;
      _uploadedCount = uploadedReceived + uploadedComplete;
    });
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final regional = ref.read(regionalProvider).selectedRegional ?? 1;
    final syncFuture = ref.read(syncProvider.notifier).syncData(regional);
    if (!mounted) return;
    showSyncProgressDialog<SyncState>(
      context: context,
      provider: syncProvider,
      isInProgress: (s) => s.isLoading,
      errorMessage: (s) => s.error,
    );
    await syncFuture;
    if (mounted) _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;
    final user = authState.user;
    final hasAccess = user?.hasAnyLsuMobileAccess ?? false;
    final canTerima = user?.hasLsuMobileTerima ?? false;
    final canSelesai = user?.hasLsuMobileSelesai ?? false;
    final regionalState = ref.watch(regionalProvider);
    final syncState = ref.watch(syncProvider);
    ref.listen<int>(homeCountsRefreshProvider, (prev, next) {
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
          title: const Text('Sampel LSU'),
          actions: [
            if (widget.showSettingsInAppBar) ...[
              IconButton(
                icon: Badge(
                  label: unreadCount > 0 ? Text('$unreadCount') : null,
                  isLabelVisible: unreadCount > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/notifications');
                },
              ),
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
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: AppSpacing.paddingXl,
                    child: Text(
                      'Anda tidak memiliki izin mobile LSU (terima/selesai). Hubungi admin.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: AppFooter(),
              ),
            ],
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
        title: const Text('Sampel LSU'),
        actions: [
          if (widget.showSettingsInAppBar) ...[
            IconButton(
              icon: Badge(
                label: unreadCount > 0 ? Text('$unreadCount') : null,
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
            ),
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
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _sync();
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (regionalState.selectedRegional != null)
                                    Text(
                                      'Regional ${regionalState.selectedRegional}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  Text(
                                    _formatDateTimeSync(syncState.lastSyncTime),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TextButton.icon(
                              onPressed: syncState.isLoading ? null : _sync,
                              style: TextButton.styleFrom(
                                backgroundColor: !syncState.isLoading
                                    ? colorScheme.primary
                                    : colorScheme.surface,
                                foregroundColor: !syncState.isLoading
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                              ),
                              icon: syncState.isLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  : const Icon(Icons.sync, size: 18),
                              label: const Text('Sync'),
                            ),
                          ],
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
                                  builder: (_) =>
                                      const ReceivedListScreen(isPending: true),
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
                                  builder: (_) => const ReceivedListScreen(
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
                if (canTerima)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 24),
                    label: const Text('Pindai QR Terima'),
                  ),
                if (canTerima && canSelesai) AppSpacing.gapSm,
                if (canSelesai)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const QRScannerScreen(isCompleteSample: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 24),
                    label: const Text('Pindai QR Selesai'),
                  ),
                if (canTerima || canSelesai) AppSpacing.gapSm,
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => const UploadScreen(),
                          ),
                        )
                        .then((_) => _loadCounts());
                  },
                  icon: const Icon(Icons.cloud_upload, size: 24),
                  label: const Text('Unggah Sampel'),
                ),
                AppSpacing.gapLg,
                const Center(child: AppFooter()),
                AppSpacing.gapMd,
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
