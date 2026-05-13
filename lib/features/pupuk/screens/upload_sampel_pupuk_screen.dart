import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/database/models/kirim_dari_estate.dart';
import '../../../core/database/models/kirim_lab.dart';
import '../../../core/database/models/kirim_sertifikat_estate.dart';
import '../constants/pupuk_activity_types.dart';
import '../providers/upload_sampel_pupuk_provider.dart';
import 'sampel_pupuk_activity_detail_screen.dart';

class UploadSampelPupukScreen extends ConsumerStatefulWidget {
  const UploadSampelPupukScreen({super.key});

  @override
  ConsumerState<UploadSampelPupukScreen> createState() =>
      _UploadSampelPupukScreenState();
}

class _UploadSampelPupukScreenState
    extends ConsumerState<UploadSampelPupukScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<KirimDariEstate> _pendingKirimEstate = [];
  List<KirimLab> _pendingKirimLab = [];
  List<KirimSertifikatEstate> _pendingKirimSertifikat = [];

  Future<void> _loadAll() async {
    final t2 = await _dbHelper.getPendingKirimDariEstate();
    final t4 = await _dbHelper.getPendingKirimLab();
    final t5 = await _dbHelper.getPendingKirimSertifikatEstate();
    if (mounted) {
      setState(() {
        _pendingKirimEstate = t2;
        _pendingKirimLab = t4;
        _pendingKirimSertifikat = t5;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _handleUploadAll() async {
    await ref.read(uploadSampelPupukProvider.notifier).uploadAll();
    await _loadAll();
    if (!mounted) return;
    final state = ref.read(uploadSampelPupukProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
      );
      return;
    }
    // Same as LSU: show result modal with Berhasil / Gagal counts.
    final successCount = state.lastSuccessCount ?? 0;
    final failedCount = state.lastFailedCount ?? 0;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unggah Selesai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Berhasil: $successCount'),
            Text('Gagal: $failedCount'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  int get _totalPending =>
      _pendingKirimEstate.length +
      _pendingKirimLab.length +
      _pendingKirimSertifikat.length;

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadSampelPupukProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unggah Sampel Pupuk'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (uploadState.isUploading && uploadState.progress != null)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mengunggah Sampel Pupuk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: uploadState.progress!.percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${uploadState.progress!.current} / ${uploadState.progress!.total} (${uploadState.progress!.percentage}%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mengunggah: ${uploadState.progress!.currentItem}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSection<KirimDariEstate>(
                      'Kirim dari Estate',
                      kKirimDariEstate,
                      _pendingKirimEstate,
                      (row) => row.id!,
                      (row) => _PendingRow(
                        kodeSampel: row.kodeSampel,
                        dateText: row.tanggalKirimDariEstate,
                        status: row.status,
                        errorMessage: row.errorMessage,
                      ),
                    ),
                    _buildSection<KirimLab>(
                      'Kirim Lab',
                      kKirimLab,
                      _pendingKirimLab,
                      (row) => row.id!,
                      (row) => _PendingRow(
                        kodeSampel: row.kodeSampel,
                        dateText: row.tanggalKirimLab,
                        status: row.status,
                        errorMessage: row.errorMessage,
                        extraLine:
                            row.noSurat != null && row.noSurat!.isNotEmpty
                            ? 'No. Surat: ${row.noSurat}'
                            : null,
                      ),
                    ),
                    _buildSection<KirimSertifikatEstate>(
                      'Kirim Sertifikat',
                      kKirimSertifikatEstate,
                      _pendingKirimSertifikat,
                      (row) => row.id!,
                      (row) => _PendingRow(
                        kodeSampel: row.kodeSampel,
                        dateText: row.tanggalKirimSertifikatEstate,
                        status: row.status,
                        errorMessage: row.errorMessage,
                        extraLine: 'Rekomendasi: ${row.rekomendasi}',
                      ),
                    ),
                    if (_totalPending > 0)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: uploadState.isUploading
                              ? null
                              : _handleUploadAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: uploadState.isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Unggah Semua ($_totalPending)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    if (_totalPending == 0)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada data sampel pupuk tertunda',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection<T>(
    String title,
    String activityType,
    List<T> list,
    int Function(T) getId,
    Widget Function(T) itemBuilder,
  ) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final id = getId(item);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => SampelPupukActivityDetailScreen(
                            activityType: activityType,
                            id: id,
                          ),
                        ),
                      )
                      .then((_) => _loadAll());
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: itemBuilder(item),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  final String kodeSampel;
  final String dateText;
  final String status;
  final String? errorMessage;
  final String? extraLine;

  const _PendingRow({
    required this.kodeSampel,
    required this.dateText,
    required this.status,
    this.errorMessage,
    this.extraLine,
  });

  @override
  Widget build(BuildContext context) {
    final isError = status == AppConstants.statusError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kodeSampel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isError)
              Icon(Icons.error_outline, color: AppColors.error, size: 22),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          app_date_utils.DateUtils.formatDateTimeFromIso(dateText),
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        if (extraLine != null && extraLine!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            extraLine!,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          'Status: ${status == AppConstants.statusUploaded
              ? "Terunggah"
              : status == AppConstants.statusError
              ? "Gagal"
              : "Menunggu"}',
          style: TextStyle(
            fontSize: 14,
            color: isError ? AppColors.error : AppColors.textSecondary,
          ),
        ),
        if (isError && errorMessage != null && errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.error,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
