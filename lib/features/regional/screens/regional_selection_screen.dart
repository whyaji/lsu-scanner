import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../sync/providers/sync_provider.dart';
import '../providers/regional_provider.dart';

class RegionalSelectionScreen extends ConsumerStatefulWidget {
  const RegionalSelectionScreen({super.key});

  @override
  ConsumerState<RegionalSelectionScreen> createState() =>
      _RegionalSelectionScreenState();
}

class _RegionalSelectionScreenState
    extends ConsumerState<RegionalSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final regionalState = ref.watch(regionalProvider);
    final syncState = ref.watch(syncProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Regional')),
      body: SafeArea(
        child: regionalState.isLoading || syncState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: AppSpacing.paddingScreen,
                itemCount: AppConstants.regionalOptions.length,
                itemBuilder: (context, index) {
                  final regional = AppConstants.regionalOptions[index];
                  final isSelected = regionalState.selectedRegional == regional;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isSelected ? 4 : 1,
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : colorScheme.surface,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      title: Text(
                        'Regional $regional',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Pilih untuk sinkron data Regional $regional',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: colorScheme.primary,
                              size: 28,
                            )
                          : Icon(
                              Icons.radio_button_unchecked,
                              size: 28,
                              color: colorScheme.onSurfaceVariant,
                            ),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final syncNotifier = ref.read(syncProvider.notifier);

                        // Sync first. Do not call selectRegional yet, or AuthWrapper
                        // will switch to Home and unmount this screen, so sync never runs.
                        final syncSuccess = await syncNotifier.syncData(
                          regional,
                        );

                        if (!mounted) return;

                        if (!syncSuccess) {
                          final errorMsg =
                              ref.read(syncProvider).error ??
                              'Gagal menyinkronkan data';
                          final errorColor = Theme.of(
                            context,
                          ).colorScheme.error;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: errorColor,
                            ),
                          );
                          return;
                        }

                        await ref
                            .read(regionalProvider.notifier)
                            .selectRegional(regional);

                        if (!mounted) return;

                        navigator.pushReplacementNamed('/');
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
