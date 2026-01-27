import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../scanner/screens/qr_scanner_screen.dart';
import '../../upload/screens/upload_screen.dart';
import '../../sync/providers/sync_provider.dart';
import '../../regional/providers/regional_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../regional/screens/regional_selection_screen.dart';
import '../../sample/screens/received_list_screen.dart';
import '../providers/home_counts_refresh_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int _pendingCount = 0;
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final pending = await _dbHelper.getPendingUploads();
    final all = await _dbHelper.getAllReceivedSamples();
    final uploaded = all
        .where((s) => s.status == AppConstants.statusUploaded)
        .length;

    setState(() {
      _pendingCount = pending.length;
      _uploadedCount = uploaded;
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
        title: Text(AppConstants.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                ref.invalidate(regionalProvider);
                ref.invalidate(syncProvider);
                Navigator.of(context).pushReplacementNamed('/login');
              }
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
                        if (syncState.lastSyncTime != null)
                          Text(
                            'Sinkron terakhir: ${_formatDateTime(syncState.lastSyncTime!)}',
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
                          'Terdunggah',
                          _uploadedCount.toString(),
                          AppColors.success,
                          Icons.cloud_done,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
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
                    'Pindai QR Code',
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegionalSelectionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_on, size: 28),
                  label: const Text(
                    'Ganti Regional',
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
