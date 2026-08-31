import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';

class AutoDownloadSettingsScreen extends StatefulWidget {
  const AutoDownloadSettingsScreen({super.key});

  @override
  State<AutoDownloadSettingsScreen> createState() =>
      _AutoDownloadSettingsScreenState();
}

class _AutoDownloadSettingsScreenState
    extends State<AutoDownloadSettingsScreen> {
  bool _isLoading = true;
  bool _autoDownloadEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _autoDownloadEnabled =
              prefs.getBool('auto_download_enabled') ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppAlerts.error(context, 'Gagal memuat preferensi');
      }
    }
  }

  Future<void> _toggleAutoDownload(bool val) async {
    setState(() => _autoDownloadEnabled = val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_download_enabled', val);
      if (mounted) {
        AppAlerts.success(
          context,
          val
              ? 'Auto download foto diaktifkan'
              : 'Auto download foto dinonaktifkan',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _autoDownloadEnabled = !val); // Revert
        AppAlerts.error(context, 'Gagal menyimpan preferensi');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Auto Download Foto')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.paddingScreenLg,
              children: [
                // Toggle card
                Container(
                  padding: AppSpacing.paddingSm,
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
                  child: SwitchListTile(
                    title: const Text(
                      'Auto Download Foto',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Salin foto hasil capture ke folder publik perangkat setelah berhasil disimpan.',
                    ),
                    value: _autoDownloadEnabled,
                    onChanged: _toggleAutoDownload,
                  ),
                ),
                AppSpacing.gapLg,

                // Informational Card about path
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Lokasi Export File',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapSm,
                      Text(
                        'Ketika diaktifkan, aplikasi akan menduplikasi foto secara otomatis ke lokasi publik berikut agar dapat diakses melalui Galeri atau File Manager bawaan HP:',
                        style: theme.textTheme.bodySmall,
                      ),
                      AppSpacing.gapMd,
                      _buildPathInfo(
                        'Android',
                        Platform.isAndroid
                            ? '/storage/emulated/0/Download/SampleTrack/[Kategori]'
                            : '/Download/SampleTrack/[Kategori]',
                        theme,
                        colorScheme,
                      ),
                      AppSpacing.gapSm,
                      _buildPathInfo(
                        'iOS / Lainnya',
                        'Documents/SampleTrack/[Kategori]',
                        theme,
                        colorScheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPathInfo(
    String platform,
    String path,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          platform,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            path,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        ),
      ],
    );
  }
}
