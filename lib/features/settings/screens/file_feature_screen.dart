import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/photo_capture_helper.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_alert.dart';
import '../../sample/screens/full_screen_image_preview_screen.dart';

class LocalFileItem {
  final File file;
  final String path;
  final int sizeBytes;
  final DateTime modified;
  final bool isLsu;

  LocalFileItem({
    required this.file,
    required this.path,
    required this.sizeBytes,
    required this.modified,
    required this.isLsu,
  });
}

class FileFeatureScreen extends ConsumerStatefulWidget {
  const FileFeatureScreen({super.key});

  @override
  ConsumerState<FileFeatureScreen> createState() => _FileFeatureScreenState();
}

class _FileFeatureScreenState extends ConsumerState<FileFeatureScreen> {
  bool _isLoading = true;
  List<LocalFileItem> _files = [];
  String _selectedCategory = 'Semua'; // 'Semua', 'LSU', 'Pupuk'
  int _retentionDays = 30; // 7, 14, 30, 0 (All)

  // Stats
  int _totalFiles = 0;
  int _totalBytes = 0;
  int _lsuFiles = 0;
  int _lsuBytes = 0;
  int _pupukFiles = 0;
  int _pupukBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final List<LocalFileItem> loadedFiles = [];

      // 1. Load LSU files safely
      try {
        final lsuPath = await PhotoCaptureHelper.getAppPicturesDirectory(
          feature: 'LSU',
        );
        final lsuDir = Directory(lsuPath);
        if (await lsuDir.exists()) {
          final lsuEntities = await lsuDir.list().toList();
          for (final entity in lsuEntities) {
            if (entity is File && _isImageFile(entity.path)) {
              try {
                final stat = await entity.stat();
                loadedFiles.add(
                  LocalFileItem(
                    file: entity,
                    path: entity.path,
                    sizeBytes: stat.size,
                    modified: stat.modified,
                    isLsu: true,
                  ),
                );
              } catch (_) {
                // Ignore stat errors for single files
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading LSU directory: $e');
      }

      // 2. Load Pupuk files safely
      try {
        final pupukPath = await PhotoCaptureHelper.getAppPicturesDirectory(
          feature: 'Pupuk',
        );
        final pupukDir = Directory(pupukPath);
        if (await pupukDir.exists()) {
          final pupukEntities = await pupukDir.list().toList();
          for (final entity in pupukEntities) {
            if (entity is File && _isImageFile(entity.path)) {
              try {
                final stat = await entity.stat();
                loadedFiles.add(
                  LocalFileItem(
                    file: entity,
                    path: entity.path,
                    sizeBytes: stat.size,
                    modified: stat.modified,
                    isLsu: false,
                  ),
                );
              } catch (_) {
                // Ignore stat errors for single files
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading Pupuk directory: $e');
      }

      // Sort files by modified date descending
      loadedFiles.sort((a, b) => b.modified.compareTo(a.modified));

      // Calculate stats
      int lsuCount = 0;
      int lsuSize = 0;
      int pupukCount = 0;
      int pupukSize = 0;
      int totalSize = 0;

      for (final item in loadedFiles) {
        totalSize += item.sizeBytes;
        if (item.isLsu) {
          lsuCount++;
          lsuSize += item.sizeBytes;
        } else {
          pupukCount++;
          pupukSize += item.sizeBytes;
        }
      }

      if (mounted) {
        setState(() {
          _files = loadedFiles;
          _totalFiles = loadedFiles.length;
          _totalBytes = totalSize;
          _lsuFiles = lsuCount;
          _lsuBytes = lsuSize;
          _pupukFiles = pupukCount;
          _pupukBytes = pupukSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading files: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppAlerts.error(context, 'Gagal memuat file lokal: $e');
          }
        });
      }
    }
  }

  bool _isImageFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.jpg' || ext == '.jpeg' || ext == '.png';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteFile(LocalFileItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus foto ini secara permanen dari perangkat?',
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

    if (confirmed == true && mounted) {
      try {
        if (await item.file.exists()) {
          await item.file.delete();
        }
        if (mounted) {
          AppAlerts.success(context, 'Foto berhasil dihapus');
        }
        _loadFiles();
      } catch (e) {
        if (mounted) {
          AppAlerts.error(context, 'Gagal menghapus file: $e');
        }
      }
    }
  }

  Future<void> _runCleanup() async {
    if (_retentionDays == 0) {
      // Delete all
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Semua Foto'),
          content: const Text(
            'Tindakan ini akan menghapus semua file foto (LSU & Pupuk) yang disimpan secara lokal di aplikasi.\n\nApakah Anda yakin?',
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
              child: const Text('Ya, Hapus Semua'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      int deletedCount = 0;
      final now = DateTime.now();

      for (final item in _files) {
        bool shouldDelete = false;
        if (_retentionDays == 0) {
          shouldDelete = true;
        } else {
          final cutoff = now.subtract(Duration(days: _retentionDays));
          if (item.modified.isBefore(cutoff)) {
            shouldDelete = true;
          }
        }

        if (shouldDelete) {
          if (await item.file.exists()) {
            await item.file.delete();
            deletedCount++;
          }
        }
      }

      if (mounted) {
        AppAlerts.success(
          context,
          deletedCount > 0
              ? 'Berhasil membersihkan $deletedCount file lama'
              : 'Tidak ada file lama yang perlu dibersihkan',
        );
        _loadFiles();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppAlerts.error(context, 'Gagal melakukan pembersihan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filtered list
    final filteredFiles = _files.where((item) {
      if (_selectedCategory == 'Semua') return true;
      if (_selectedCategory == 'LSU') return item.isLsu;
      return !item.isLsu; // Pupuk
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penyimpanan & Pembersihan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // 1. Stats and Cleanup options section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatsCard(colorScheme, theme),
                        AppSpacing.gapMd,
                        _buildCleanupCard(colorScheme, theme),
                        AppSpacing.gapMd,
                        // Category chips header
                        Text(
                          'Daftar File Foto',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.gapSm,
                        Row(
                          children: [
                            _buildCategoryChip('Semua'),
                            const SizedBox(width: AppSpacing.xs),
                            _buildCategoryChip('LSU'),
                            const SizedBox(width: AppSpacing.xs),
                            _buildCategoryChip('Pupuk'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Grid items or empty state
                filteredFiles.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppEmptyState(
                          title: 'Tidak ada foto',
                          subtitle: _selectedCategory == 'Semua'
                              ? 'Belum ada foto yang diambil oleh aplikasi ini.'
                              : 'Tidak ada foto di kategori $_selectedCategory.',
                          icon: Icons.photo_library_outlined,
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: AppSpacing.sm,
                                mainAxisSpacing: AppSpacing.sm,
                                childAspectRatio: 0.8,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = filteredFiles[index];
                            return _buildGridTile(
                              context,
                              item,
                              colorScheme,
                              theme,
                            );
                          }, childCount: filteredFiles.length),
                        ),
                      ),

                // Bottom spacer
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard(ColorScheme colorScheme, ThemeData theme) {
    // Calculate proportional shares between 1 and 100 to prevent RenderFlex layout overflow
    int lsuShare = 0;
    int pupukShare = 0;
    if (_totalBytes > 0) {
      lsuShare = ((_lsuBytes / _totalBytes) * 100).round();
      pupukShare = ((_pupukBytes / _totalBytes) * 100).round();
      if (_lsuBytes > 0 && lsuShare == 0) lsuShare = 1;
      if (_pupukBytes > 0 && pupukShare == 0) pupukShare = 1;
    }

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Penyimpanan Lokal',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatBytes(_totalBytes),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_totalFiles File',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          // Custom Storage Distribution Line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (_lsuBytes > 0)
                    Expanded(
                      flex: lsuShare,
                      child: Container(color: Colors.blue),
                    ),
                  if (_pupukBytes > 0)
                    Expanded(
                      flex: pupukShare,
                      child: Container(color: Colors.green),
                    ),
                  if (_totalBytes == 0)
                    Expanded(child: Container(color: colorScheme.outline)),
                ],
              ),
            ),
          ),
          AppSpacing.gapSm,
          // Storage Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(
                'LSU',
                Colors.blue,
                '$_lsuFiles file (${_formatBytes(_lsuBytes)})',
                theme,
              ),
              _buildLegendItem(
                'Pupuk',
                Colors.green,
                '$_pupukFiles file (${_formatBytes(_pupukBytes)})',
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    String desc,
    ThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              desc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCleanupCard(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manajemen Pembersihan',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Foto lama yang sudah ter-upload disarankan untuk dibersihkan agar menghemat ruang penyimpanan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _retentionDays,
                  decoration: const InputDecoration(
                    labelText: 'Ambang Batas',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 Hari')),
                    DropdownMenuItem(value: 14, child: Text('14 Hari')),
                    DropdownMenuItem(value: 30, child: Text('30 Hari')),
                    DropdownMenuItem(value: 0, child: Text('Semua Foto')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _retentionDays = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(
                  _retentionDays == 0
                      ? Icons.delete_forever
                      : Icons.cleaning_services,
                  size: 18,
                ),
                label: Text(_retentionDays == 0 ? 'Hapus' : 'Bersihkan'),
                onPressed: _runCleanup,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: _retentionDays == 0
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  foregroundColor: _retentionDays == 0
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = label);
        }
      },
      selectedColor: colorScheme.primaryContainer,
    );
  }

  Widget _buildGridTile(
    BuildContext context,
    LocalFileItem item,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullScreenImagePreviewScreen(
              imagePath: item.path,
              title: item.isLsu ? 'LSU Sample' : 'Pupuk Sample',
              showDetails: true,
              details: {
                'Kategori': item.isLsu ? 'LSU (Sample)' : 'Pupuk (Fertilizer)',
                'Nama File': p.basename(item.path),
                'Ukuran File': _formatBytes(item.sizeBytes),
                'Dibuat': du.DateUtils.formatDateTimeForDisplay(item.modified),
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
            width: 1,
          ),
          color: colorScheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail Image
            Image.file(
              item.file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.error,
                  size: 28,
                ),
              ),
            ),

            // Top-left category tag indicator
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (item.isLsu ? Colors.blue : Colors.green).withOpacity(
                    0.85,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.isLsu ? 'LSU' : 'Pupuk',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Delete action button
            Positioned(
              top: 2,
              right: 2,
              child: InkWell(
                onTap: () => _deleteFile(item),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),

            // Bottom overlay with file size/date
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatBytes(item.sizeBytes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      p.basenameWithoutExtension(item.path).split('_').first,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
