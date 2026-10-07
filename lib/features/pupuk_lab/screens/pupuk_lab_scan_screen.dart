import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/feedback/app_dialog.dart';
import '../../../widgets/feedback/app_notice_type.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../../../widgets/scanner/qr_scan_view.dart';
import '../data/pupuk_lab_scan_resolver.dart';
import '../providers/pupuk_lab_draft_notifier.dart';
import '../providers/pupuk_lab_providers.dart';
import '../utils/pupuk_lab_sync.dart';

/// Full screen scanner for one sample. The camera closes as soon as a label is
/// accepted; `Pindai label` opens it again for the next sample. A rejected
/// label keeps the camera open so the user can try another one.
class PupukLabScanScreen extends ConsumerStatefulWidget {
  const PupukLabScanScreen({super.key});

  @override
  ConsumerState<PupukLabScanScreen> createState() => _PupukLabScanScreenState();
}

class _PupukLabScanScreenState extends ConsumerState<PupukLabScanScreen> {
  bool _busy = false;

  Future<void> _onCode(String raw) async {
    if (_busy) return;
    setState(() => _busy = true);
    var accepted = false;
    try {
      accepted = await _handle(raw);
    } finally {
      if (accepted) {
        if (mounted) Navigator.of(context).pop();
      } else if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Returns true when the label was added to the receipt.
  Future<bool> _handle(String raw) async {
    final draft = ref.read(pupukLabDraftProvider);
    final reserved = await ref
        .read(pupukLabDaoProvider)
        .getReservedKodeSampel(excludingId: draft.editingId);
    final result = await ref
        .read(pupukLabScanResolverProvider)
        .resolve(
          raw,
          existingKodes: draft.kodes.toSet(),
          noSurat: draft.noSurat,
          reservedKodes: reserved,
        );
    if (!mounted) return false;

    switch (result) {
      case PupukLabScanAccepted(:final sample, :final noSurat):
        ref
            .read(pupukLabDraftProvider.notifier)
            .addScanned(sample, noSurat: noSurat);
        final count = ref.read(pupukLabDraftProvider).samples.length;
        AppToast.show(context, '${sample.kode} ditambahkan ($count sampel)');
        return true;
      case PupukLabScanRejected(:final problem, :final title, :final message):
        await _reject(problem, title, message);
        return false;
    }
  }

  Future<void> _reject(
    PupukLabScanProblem problem,
    String title,
    String message,
  ) async {
    switch (problem) {
      case PupukLabScanProblem.duplicate:
        AppToast.show(context, message, type: AppNoticeType.info);
      case PupukLabScanProblem.notFound:
        final sync = await AppDialog.confirm(
          context,
          title: title,
          message: message,
          confirmLabel: 'Sinkronkan sekarang',
          cancelLabel: 'Tutup',
        );
        if (sync && mounted) await _sync();
      case PupukLabScanProblem.invalidQr:
      case PupukLabScanProblem.notSentToLab:
      case PupukLabScanProblem.alreadyReceived:
      case PupukLabScanProblem.reservedLocally:
      case PupukLabScanProblem.noSuratMismatch:
        await AppDialog.warning(context, title: title, message: message);
    }
  }

  Future<void> _sync() async {
    final error = await syncPupukData(context, ref);
    if (!mounted) return;
    if (error == null) {
      AppToast.show(context, 'Data tersinkron. Pindai label sekali lagi.');
    } else {
      await AppDialog.error(
        context,
        title: 'Sinkronisasi gagal',
        message: '$error\nPeriksa jaringan, lalu coba lagi.',
        onRetry: _sync,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai label sampel')),
      body: SafeArea(
        child: QrScanView(
          paused: _busy,
          hint: 'Arahkan kamera ke QR di label satu sampel',
          onCode: _onCode,
        ),
      ),
    );
  }
}
