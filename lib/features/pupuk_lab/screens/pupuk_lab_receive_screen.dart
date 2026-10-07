import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/display/app_error_state.dart';
import '../../../widgets/display/app_loading_state.dart';
import '../../../widgets/feedback/app_banner.dart';
import '../../../widgets/feedback/app_dialog.dart';
import '../../../widgets/feedback/app_notice_type.dart';
import '../../../widgets/forms/app_step_header.dart';
import '../../../widgets/layout/app_page.dart';
import '../../../widgets/layout/app_sticky_action_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pupuk/screens/upload_sampel_pupuk_screen.dart';
import '../data/pupuk_lab_master_repository.dart';
import '../models/pupuk_lab.dart';
import '../models/pupuk_lab_draft.dart';
import '../models/pupuk_lab_master.dart';
import '../providers/pupuk_lab_draft_notifier.dart';
import '../providers/pupuk_lab_providers.dart';
import '../utils/pupuk_lab_sync.dart';
import '../widgets/steps/pupuk_lab_contact_step.dart';
import '../widgets/steps/pupuk_lab_info_step.dart';
import '../widgets/steps/pupuk_lab_parameters_step.dart';
import '../widgets/steps/pupuk_lab_review_step.dart';
import '../widgets/steps/pupuk_lab_samples_step.dart';

/// Terima Lab: scan the samples, fill the SmartLab form in five steps, save on
/// the device. Nothing here needs a network; the receipt goes up with the next
/// upload. Pass [editing] to change a receipt that is not uploaded yet.
class PupukLabReceiveScreen extends ConsumerStatefulWidget {
  const PupukLabReceiveScreen({super.key, this.editing});

  final PupukLab? editing;

  @override
  ConsumerState<PupukLabReceiveScreen> createState() =>
      _PupukLabReceiveScreenState();
}

class _PupukLabReceiveScreenState extends ConsumerState<PupukLabReceiveScreen> {
  PupukLabStep _step = PupukLabStep.samples;

  /// Steps where the user already tried to continue, so their errors show.
  final Set<PupukLabStep> _showErrors = {};
  bool _saving = false;
  bool _allowPop = false;
  Object? _startError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      final snapshot = await ref.read(pupukLabMasterProvider.future);
      if (!mounted) return;
      if (snapshot == null) return;
      final user = ref.read(authProvider).user;
      final editing = widget.editing;
      final PupukLabDraft initial;
      if (editing != null) {
        final samples = await ref
            .read(pupukLabScanResolverProvider)
            .describeSamples(editing.samples);
        initial = PupukLabDraft.fromReceipt(receipt: editing, samples: samples);
      } else {
        initial = PupukLabDraft.create(
          master: snapshot.master,
          penerima: user?.namaLengkap ?? '',
        );
      }
      if (!mounted) return;
      ref.read(pupukLabDraftProvider.notifier).start(initial);
    } catch (e) {
      if (mounted) setState(() => _startError = e);
    }
  }

  Future<void> _syncNow() async {
    final error = await syncPupukData(context, ref);
    if (!mounted) return;
    if (error != null) {
      await AppDialog.error(
        context,
        title: 'Sinkronisasi gagal',
        message: '$error\nPeriksa jaringan, lalu coba lagi.',
        onRetry: _syncNow,
      );
      return;
    }
    ref.invalidate(pupukLabMasterProvider);
    await _start();
  }

  void _goTo(PupukLabStep step) {
    setState(() => _step = step);
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller != null && controller.hasClients) controller.jumpTo(0);
  }

  Future<void> _next(PupukLabMaster master) async {
    final draft = ref.read(pupukLabDraftProvider);
    final errors = draft.errorsOf(_step, master);
    if (errors.isNotEmpty) {
      setState(() => _showErrors.add(_step));
      final controller = PrimaryScrollController.maybeOf(context);
      if (controller != null && controller.hasClients) controller.jumpTo(0);
      return;
    }
    _goTo(PupukLabStep.values[_step.index + 1]);
  }

  /// Steps before the last one that still have errors.
  List<PupukLabStep> _problemSteps(
    PupukLabDraft draft,
    PupukLabMaster master,
  ) => [
    for (final step in PupukLabStep.values)
      if (step != PupukLabStep.review &&
          draft.errorsOf(step, master).isNotEmpty)
        step,
  ];

  Future<void> _save(PupukLabMaster master) async {
    final draft = ref.read(pupukLabDraftProvider);
    final problems = _problemSteps(draft, master);
    final reviewErrors = draft.errorsOf(PupukLabStep.review, master);
    if (problems.isNotEmpty || reviewErrors.isNotEmpty) {
      setState(() => _showErrors.addAll([...problems, PupukLabStep.review]));
      _goTo(problems.isNotEmpty ? problems.first : PupukLabStep.review);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(pupukLabDraftProvider.notifier).save(master);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await AppDialog.error(
        context,
        title: 'Penerimaan belum tersimpan',
        message: 'Data tidak dapat ditulis ke perangkat: $e',
      );
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);

    final uploadNow = await AppDialog.choice<bool>(
      context,
      title: 'Penerimaan tersimpan',
      message:
          'Data ada di perangkat ini dan belum terkirim ke SmartLab. Unggah saat jaringan tersedia.',
      choices: const [
        AppDialogChoice(label: 'Unggah sekarang', value: true),
        AppDialogChoice(label: 'Nanti saja', value: false),
      ],
    );
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (uploadNow == true) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const UploadSampelPupukScreen(),
        ),
        (route) => route.isFirst,
      );
    } else {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await AppDialog.confirm(
      context,
      title: 'Buang isian ini?',
      message: 'Isian yang belum disimpan akan hilang.',
      confirmLabel: 'Buang isian',
      cancelLabel: 'Lanjut mengisi',
      tone: AppDialogTone.destructive,
    );
    if (!leave || !mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.editing == null ? 'Terima Lab' : 'Ubah penerimaan';
    final masterAsync = ref.watch(pupukLabMasterProvider);
    final draft = ref.watch(pupukLabDraftProvider);

    if (_startError != null) {
      return AppPage(
        title: title,
        scroll: false,
        body: AppErrorState(
          title: 'Penerimaan tidak dapat dibuka',
          message: '$_startError',
          onRetry: () {
            setState(() => _startError = null);
            _start();
          },
        ),
      );
    }

    return masterAsync.when(
      loading: () => AppPage(
        title: title,
        scroll: false,
        body: const AppLoadingState(itemCount: 4),
      ),
      error: (error, _) => AppPage(
        title: title,
        scroll: false,
        body: AppErrorState(
          title: 'Data master tidak terbaca',
          message: '$error',
          onRetry: () => ref.invalidate(pupukLabMasterProvider),
        ),
      ),
      data: (snapshot) {
        if (snapshot == null || !snapshot.master.isUsable) {
          return AppPage(
            title: title,
            scroll: false,
            body: AppErrorState(
              title: snapshot == null
                  ? 'Data master SmartLab belum ada'
                  : 'Data master SmartLab kosong',
              message:
                  'Form ini memakai daftar komoditas dan parameter dari SmartLab. Sinkronkan saat ada jaringan.',
              retryLabel: 'Sinkronkan sekarang',
              onRetry: _syncNow,
            ),
          );
        }
        if (!draft.started) {
          return AppPage(
            title: title,
            scroll: false,
            body: const AppLoadingState(itemCount: 4),
          );
        }
        return _buildWizard(title, snapshot, draft);
      },
    );
  }

  Widget _buildWizard(
    String title,
    PupukLabMasterSnapshot snapshot,
    PupukLabDraft draft,
  ) {
    final master = snapshot.master;
    final errors = _showErrors.contains(_step)
        ? draft.errorsOf(_step, master)
        : const <String, String>{};
    final isLast = _step == PupukLabStep.review;
    final problemSteps = isLast && _showErrors.contains(PupukLabStep.review)
        ? _problemSteps(draft, master)
        : const <PupukLabStep>[];

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inset = AppSpacing.screenInset(context);
    final labels = [for (final s in PupukLabStep.values) s.label];

    return PopScope(
      canPop: _allowPop || !draft.dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: AppPage(
        title: title,
        scroll: false,
        leading: const BackButton(),
        bottomBar: AppStickyActionBar(
          horizontal: true,
          primaryLabel: isLast ? 'Simpan penerimaan' : 'Lanjut',
          primaryLoading: _saving,
          onPrimary: _saving
              ? null
              : () => isLast ? _save(master) : _next(master),
          secondaryLabel: _step == PupukLabStep.samples || _saving
              ? null
              : 'Kembali',
          onSecondary: _step == PupukLabStep.samples || _saving
              ? null
              : () => _goTo(PupukLabStep.values[_step.index - 1]),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                child: AppStepTrack(
                  currentStep: _step.index + 1,
                  stepLabels: labels,
                  height: 32,
                  onStepTap: (n) => _goTo(PupukLabStep.values[n - 1]),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                primary: true,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  inset,
                  AppSpacing.md,
                  inset,
                  inset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _step.label,
                      key: const Key('pupukLabStepTitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (snapshot.isStale) ...[
                      AppBanner(
                        type: AppNoticeType.warning,
                        title: 'Data master belum diperbarui',
                        message:
                            'Memakai data SmartLab dari ${DateFormat('d MMMM y, HH:mm', 'id').format(snapshot.syncedAt)}. Sinkronkan saat ada jaringan.',
                        actionLabel: 'Sinkronkan',
                        onAction: _syncNow,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (errors.isNotEmpty && !isLast) ...[
                      AppBanner(
                        type: AppNoticeType.error,
                        title: errors.length == 1
                            ? '1 isian perlu diperbaiki'
                            : '${errors.length} isian perlu diperbaiki',
                        message: errors.values.first,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _stepBody(master, errors, problemSteps),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(
    PupukLabMaster master,
    Map<String, String> errors,
    List<PupukLabStep> problemSteps,
  ) {
    return switch (_step) {
      PupukLabStep.samples => PupukLabSamplesStep(errors: errors),
      PupukLabStep.info => PupukLabInfoStep(master: master, errors: errors),
      PupukLabStep.contact => PupukLabContactStep(
        master: master,
        errors: errors,
      ),
      PupukLabStep.parameters => PupukLabParametersStep(
        master: master,
        errors: errors,
        onGoToInfo: () => _goTo(PupukLabStep.info),
      ),
      PupukLabStep.review => PupukLabReviewStep(
        master: master,
        errors: errors,
        problemSteps: problemSteps,
        onGoToStep: _goTo,
      ),
    };
  }
}
