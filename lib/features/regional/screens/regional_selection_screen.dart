import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/regional_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../sync/providers/sync_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Regional'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: regionalState.isLoading || syncState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: AppConstants.regionalOptions.length,
                itemBuilder: (context, index) {
                  final regional = AppConstants.regionalOptions[index];
                  final isSelected = regionalState.selectedRegional == regional;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isSelected ? 4 : 1,
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surface,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        'Regional $regional',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Select to sync data for Regional $regional',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 28,
                            )
                          : const Icon(Icons.radio_button_unchecked, size: 28),
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
                              'Failed to sync data';
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        await ref
                            .read(regionalProvider.notifier)
                            .selectRegional(regional);

                        if (!mounted) return;

                        navigator.pushReplacementNamed('/home');
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
