import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/services/app_update_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_settings_tile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../regional/providers/regional_provider.dart';
import '../../regional/screens/regional_selection_screen.dart';
import '../../sync/providers/sync_provider.dart';
import '../providers/theme_provider.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_footer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isCheckingUpdate = false;

  Future<void> _onManualUpdateCheck() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    try {
      final outcome = await AppUpdateService.manualCheckForUpdate();
      if (!mounted) return;
      switch (outcome) {
        case ManualUpdateOutcome.platformNotSupported:
          AppAlerts.info(
            context,
            'Pembaruan dalam aplikasi hanya tersedia di perangkat Android.',
          );
          break;
        case ManualUpdateOutcome.debugBuild:
          AppAlerts.info(
            context,
            'Pemeriksaan pembaruan tidak dijalankan pada build pengembangan (debug).',
          );
          break;
        case ManualUpdateOutcome.noUpdateAvailable:
          AppAlerts.success(
            context,
            'Aplikasi sudah menggunakan versi terbaru.',
          );
          break;
        case ManualUpdateOutcome.updateFlowStarted:
          AppAlerts.info(
            context,
            'Ikuti langkah di layar untuk menyelesaikan pembaruan.',
          );
          break;
        case ManualUpdateOutcome.error:
          AppAlerts.error(
            context,
            'Gagal memeriksa pembaruan. Periksa koneksi atau coba lagi nanti.',
          );
          break;
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final regionalState = ref.watch(regionalProvider);
    final user = authState.user;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreenLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        _initials(user?.nama ?? 'U'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Text(
                      user?.nama ?? 'Pengguna',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (user?.email.isNotEmpty ?? false) ...[
                      AppSpacing.gapXs,
                      Text(
                        user!.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (user != null && user.jabatan.isNotEmpty) ...[
                      AppSpacing.gapSm,
                      _InfoChip(
                        icon: Icons.badge_outlined,
                        label: user.jabatan,
                      ),
                    ],
                    if (user?.lokasiKerja != null &&
                        (user?.lokasiKerja ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _InfoChip(
                        icon: Icons.place_outlined,
                        label: user?.lokasiKerja ?? '',
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapLg,

              // Theme section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
                child: Text(
                  'Tampilan',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _ThemeSelector(
                currentMode: themeMode,
                onChanged: (mode) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                },
              ),
              AppSpacing.gapLg,

              // Regional section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
                child: Text(
                  'Regional',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AppSettingsTile(
                icon: Icons.location_on_outlined,
                title: 'Ganti Regional',
                subtitle: regionalState.selectedRegional != null
                    ? 'Regional ${regionalState.selectedRegional}'
                    : 'Belum dipilih',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegionalSelectionScreen(),
                    ),
                  );
                },
              ),
              AppSpacing.gapLg,

              // App section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
                child: Text(
                  'Aplikasi',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AppSettingsTile(
                icon: Icons.system_update_outlined,
                title: 'Periksa Pembaruan',
                subtitle: AppConstants.appVersion.isNotEmpty
                    ? 'Versi ${AppConstants.appVersion}'
                    : 'Periksa versi terbaru di Play Store',
                onTap: _onManualUpdateCheck,
                trailing: _isCheckingUpdate
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              AppSpacing.gapLg,

              // Logout
              AppSettingsTile(
                icon: Icons.logout,
                iconColor: colorScheme.error,
                title: 'Keluar',
                subtitle: 'Keluar dari akun ini',
                onTap: () => _showLogoutConfirmation(context, ref),
                isDestructive: true,
              ),
              AppSpacing.gapLg,
              const Center(child: AppFooter()),
              AppSpacing.gapMd,
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.isEmpty
          ? '?'
          : s.length >= 2
          ? s.substring(0, 2).toUpperCase()
          : s.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        ref.invalidate(regionalProvider);
        ref.invalidate(syncProvider);
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.currentMode, required this.onChanged});

  final AppThemeMode currentMode;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _ThemeOption(
            mode: AppThemeMode.light,
            icon: Icons.light_mode_outlined,
            label: AppThemeMode.light.displayName,
            isSelected: currentMode == AppThemeMode.light,
            onTap: () => onChanged(AppThemeMode.light),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          _ThemeOption(
            mode: AppThemeMode.dark,
            icon: Icons.dark_mode_outlined,
            label: AppThemeMode.dark.displayName,
            isSelected: currentMode == AppThemeMode.dark,
            onTap: () => onChanged(AppThemeMode.dark),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          _ThemeOption(
            mode: AppThemeMode.system,
            icon: Icons.brightness_auto_outlined,
            label: AppThemeMode.system.displayName,
            isSelected: currentMode == AppThemeMode.system,
            onTap: () => onChanged(AppThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, size: 22, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
