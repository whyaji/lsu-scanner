import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/photo_capture_helper.dart';
import '../../../widgets/app_alert.dart';

/// Full-screen image preview with details, zoom, share, download, and delete.
/// Use after taking a photo or when viewing an existing received sample.
class FullScreenImagePreviewScreen extends StatelessWidget {
  final String imagePath;
  final String title;
  final Map<String, String> details;
  final bool showDetails;
  final VoidCallback? onDelete;

  const FullScreenImagePreviewScreen({
    super.key,
    required this.imagePath,
    this.title = 'Preview',
    this.details = const {},
    this.showDetails = false,
    this.onDelete,
  });

  Future<void> _sharePhoto(
    BuildContext context,
    String path,
    String shareTitle,
  ) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final file = File(path);
      if (!await file.exists()) {
        if (context.mounted) {
          AppAlerts.error(context, 'File tidak ditemukan untuk dibagikan');
        }
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: shareTitle,
          sharePositionOrigin: box != null
              ? (box.localToGlobal(Offset.zero) & box.size)
              : null,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppAlerts.error(context, 'Gagal membagikan foto: $e');
      }
    }
  }

  Future<void> _downloadPhoto(BuildContext context, String path) async {
    try {
      final isLsu = path.contains('LSU');
      final feature = isLsu ? 'LSU' : 'Pupuk';

      final targetPath = await PhotoCaptureHelper.exportToDownloads(
        path,
        feature: feature,
      );

      if (targetPath != null) {
        if (context.mounted) {
          AppAlerts.success(
            context,
            'Foto berhasil diunduh ke: Download/SampleTrack/$feature/${p.basename(targetPath)}',
          );
        }
      } else {
        if (context.mounted) {
          AppAlerts.error(context, 'Gagal mengunduh foto');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppAlerts.error(context, 'Terjadi kesalahan saat mengunduh: $e');
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus foto ini secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) {
      onDelete!();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final hasDetails = details.isNotEmpty;

    // Check for HD version of the image
    final ext = p.extension(imagePath);
    final hdPath = imagePath.replaceAll(ext, '-HD$ext');
    final hasHd = File(hdPath).existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan',
            onPressed: () => _sharePhoto(context, imagePath, title),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Unduh',
            onPressed: () => _downloadPhoto(context, imagePath),
          ),
          if (hasHd) ...[
            IconButton(
              icon: const Icon(Icons.hd_outlined),
              tooltip: 'Bagikan HD',
              onPressed: () => _sharePhoto(context, hdPath, '$title (HD)'),
            ),
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              tooltip: 'Unduh HD',
              onPressed: () => _downloadPhoto(context, hdPath),
            ),
          ],
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus',
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Full-screen zoomable image
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: file.existsSync()
                      ? Image.file(
                          file,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),
            ),
            // Details panel
            if (showDetails && hasDetails) _buildDetailsPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(
            'Foto tidak ditemukan',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Detail',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: details.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(
                              e.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
