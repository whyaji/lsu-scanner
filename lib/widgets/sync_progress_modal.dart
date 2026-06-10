import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

/// Shows a non-dismissible dialog while [isInProgress] is true for [state].
/// When sync finishes, shows success or [errorMessage] with a close button.
void showSyncProgressDialog<T>({
  required BuildContext context,
  required ProviderListenable<T> provider,
  required bool Function(T state) isInProgress,
  required String? Function(T state) errorMessage,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(provider);
          final loading = isInProgress(state);
          final err = errorMessage(state);
          final done = !loading;

          return PopScope(
            canPop: done,
            child: AlertDialog(
              title: Text(
                loading
                    ? 'Menyinkronkan…'
                    : (err != null ? 'Sinkronisasi gagal' : 'Berhasil'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading) ...[
                      const SizedBox(height: 8),
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 20),
                      Text(
                        'Mengunduh dan memperbarui data dari server…',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ] else ...[
                      Icon(
                        err != null
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 56,
                        color: err != null
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        err ?? 'Data berhasil disinkronkan.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (done)
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Tutup'),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
