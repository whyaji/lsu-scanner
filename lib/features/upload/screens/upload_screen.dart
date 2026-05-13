import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/upload_provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/received_sample.dart';
import '../../../core/database/models/completed_sample.dart';
import '../../../core/constants/app_constants.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ReceivedSample> _pendingSamples = [];
  List<CompletedSample> _pendingCompleteSamples = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadPendingSamples();
    await _loadPendingCompleteSamples();
  }

  Future<void> _loadPendingSamples() async {
    final samples = await _dbHelper.getPendingUploads();
    if (mounted) setState(() => _pendingSamples = samples);
  }

  Future<void> _loadPendingCompleteSamples() async {
    final samples = await _dbHelper.getPendingCompleteUploads();
    if (mounted) setState(() => _pendingCompleteSamples = samples);
  }

  Future<void> _handleUpload() async {
    await ref.read(uploadProvider.notifier).uploadAll();
    await _loadPendingSamples();

    if (mounted) {
      final uploadState = ref.read(uploadProvider);
      final successCount = uploadState.results.where((r) => r.success).length;
      final failedCount = uploadState.results.where((r) => !r.success).length;

      showDialog(
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
  }

  Future<void> _handleUploadComplete() async {
    await ref.read(uploadCompleteProvider.notifier).uploadAllComplete();
    await _loadPendingCompleteSamples();

    if (mounted) {
      final state = ref.read(uploadCompleteProvider);
      final successCount = state.results.where((r) => r.success).length;
      final failedCount = state.results.where((r) => !r.success).length;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unggah Selesai Sampel Selesai'),
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
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);
    final uploadCompleteState = ref.watch(uploadCompleteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unggah Sampel'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Upload Progress (received)
            if (uploadState.isUploading && uploadState.progress != null)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mengunggah Foto',
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

            // Upload Progress (completed)
            if (uploadCompleteState.isUploading &&
                uploadCompleteState.progress != null)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mengunggah Foto Selesai',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: uploadCompleteState.progress!.percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${uploadCompleteState.progress!.current} / ${uploadCompleteState.progress!.total} (${uploadCompleteState.progress!.percentage}%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mengunggah: ${uploadCompleteState.progress!.currentItem}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Pending Samples List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section: Sampel Diterima
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Sampel Diterima',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _pendingSamples.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
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
                                    'Tidak ada sampel diterima tertunda',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _pendingSamples.length,
                            itemBuilder: (context, index) {
                              final sample = _pendingSamples[index];
                              final isError =
                                  sample.status == AppConstants.statusError;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sample.kode,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (isError)
                                            Icon(
                                              Icons.error_outline,
                                              color: AppColors.error,
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Status: ${sample.status}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isError
                                              ? AppColors.error
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      if (isError &&
                                          sample.errorMessage != null &&
                                          sample.errorMessage!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            sample.errorMessage!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.error,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    if (_pendingSamples.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: uploadState.isUploading
                              ? null
                              : _handleUpload,
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
                                  'Unggah Semua Diterima (${_pendingSamples.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Section: Sampel Selesai
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Sampel Selesai',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _pendingCompleteSamples.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tidak ada sampel selesai tertunda',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _pendingCompleteSamples.length,
                            itemBuilder: (context, index) {
                              final sample = _pendingCompleteSamples[index];
                              final isError =
                                  sample.status == AppConstants.statusError;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sample.kode,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (isError)
                                            Icon(
                                              Icons.error_outline,
                                              color: AppColors.error,
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Status: ${sample.status}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isError
                                              ? AppColors.error
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      if (isError &&
                                          sample.errorMessage != null &&
                                          sample.errorMessage!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            sample.errorMessage!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.error,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    if (_pendingCompleteSamples.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: uploadCompleteState.isUploading
                              ? null
                              : _handleUploadComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: uploadCompleteState.isUploading
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
                                  'Unggah Semua Selesai (${_pendingCompleteSamples.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
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
}
