import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/upload_provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/received_sample.dart';
import '../../../core/constants/app_constants.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ReceivedSample> _pendingSamples = [];

  @override
  void initState() {
    super.initState();
    _loadPendingSamples();
  }

  Future<void> _loadPendingSamples() async {
    final samples = await _dbHelper.getPendingUploads();
    setState(() {
      _pendingSamples = samples;
    });
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

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unggah Sampel'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingSamples,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Upload Progress
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

            // Pending Samples List
            Expanded(
              child: _pendingSamples.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_done,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada unggahan tertunda',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: AppColors.error.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
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
            ),

            // Upload Button
            if (_pendingSamples.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: uploadState.isUploading ? null : _handleUpload,
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
                          'Unggah Semua (${_pendingSamples.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
