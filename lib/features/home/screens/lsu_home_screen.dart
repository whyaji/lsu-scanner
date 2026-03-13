import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../scanner/screens/qr_scanner_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../upload/screens/upload_screen.dart';
import '../../sync/providers/sync_provider.dart';
import '../../regional/providers/regional_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sample/screens/received_list_screen.dart';
import '../providers/home_counts_refresh_provider.dart';

class LsuHomeScreen extends ConsumerStatefulWidget {
  const LsuHomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final regionalState = ref.watch(regionalProvider);
    final syncState = ref.watch(syncProvider);
    ref.listen<int>(homeCountsRefreshProvider, (prev, next) {
      if (prev != null && next != prev && mounted) _loadCounts();
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Sampel LSU'),
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
            if (regionalState.selectedRegional != null) {
              await ref
                  .read(syncProvider.notifier)
                  .syncData(regionalState.selectedRegional!);
            }
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
                        Text(
                          _formatDateTimeSync(syncState.lastSyncTime),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
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
                                  builder: (_) => const ReceivedListScreen(
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

                // Action Buttons — Pindai QR Terima only for non-admin
                if (authState.user?.isAdmin != true)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text(
                      'Pindai QR Terima',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (authState.user?.isAdmin != true) const SizedBox(height: 12),
                // Pindai QR Selesai only for admin
                if (authState.user?.isAdmin == true)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const QRScannerScreen(isCompleteSample: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text(
                      'Pindai QR Selesai',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (authState.user?.isAdmin == true) const SizedBox(height: 12),
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
                  icon: const Icon(Icons.cloud_upload, size: 28),
                  label: const Text(
                    'Unggah Sampel',
                    style: TextStyle(fontSize: 18),
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
