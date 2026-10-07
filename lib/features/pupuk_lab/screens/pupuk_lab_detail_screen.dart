import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/display/app_error_state.dart';
import '../../../widgets/display/app_key_value_list.dart';
import '../../../widgets/display/app_loading_state.dart';
import '../../../widgets/display/app_photo_thumb.dart';
import '../../../widgets/display/app_status_chip.dart';
import '../../../widgets/feedback/app_banner.dart';
import '../../../widgets/feedback/app_dialog.dart';
import '../../../widgets/feedback/app_notice_type.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../../../widgets/forms/app_form_section.dart';
import '../../../widgets/layout/app_page.dart';
import '../../../widgets/layout/app_sticky_action_bar.dart';
import '../../home/providers/home_counts_refresh_provider.dart';
import '../models/pupuk_lab.dart';
import '../models/pupuk_lab_master.dart';
import '../providers/pupuk_lab_providers.dart';
import '../widgets/pupuk_lab_status.dart';
import 'pupuk_lab_receive_screen.dart';

final pupukLabByIdProvider = FutureProvider.autoDispose.family<PupukLab?, int>(
  (ref, id) => ref.watch(pupukLabDaoProvider).getById(id),
);

/// A saved Terima Lab receipt: what was entered, and what SmartLab answered.
class PupukLabDetailScreen extends ConsumerWidget {
  const PupukLabDetailScreen({super.key, required this.id});

  final int id;

  Future<void> _edit(BuildContext context, WidgetRef ref, PupukLab row) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PupukLabReceiveScreen(editing: row),
      ),
    );
    ref.invalidate(pupukLabByIdProvider(id));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PupukLab row,
  ) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Hapus penerimaan ${row.noSurat}?',
      message:
          'Data di perangkat ini hilang dan tidak pernah dikirim ke SmartLab. Sampelnya bisa diterima ulang.',
      confirmLabel: 'Hapus penerimaan',
      tone: AppDialogTone.destructive,
    );
    if (!ok || !context.mounted) return;
    await ref.read(pupukLabDaoProvider).delete(id);
    ref.invalidate(reservedPupukLabKodeProvider);
    ref.read(fertilizerCountsRefreshProvider.notifier).state++;
    if (!context.mounted) return;
    AppToast.show(context, 'Penerimaan dihapus', type: AppNoticeType.info);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowAsync = ref.watch(pupukLabByIdProvider(id));
    final master = ref.watch(pupukLabMasterProvider).value?.master;

    return rowAsync.when(
      loading: () => const AppPage(
        title: 'Penerimaan lab',
        scroll: false,
        body: AppLoadingState(itemCount: 4),
      ),
      error: (error, _) => AppPage(
        title: 'Penerimaan lab',
        scroll: false,
        body: AppErrorState(
          title: 'Penerimaan tidak terbaca',
          message: '$error',
          onRetry: () => ref.invalidate(pupukLabByIdProvider(id)),
        ),
      ),
      data: (row) {
        if (row == null) {
          return const AppPage(
            title: 'Penerimaan lab',
            scroll: false,
            body: AppErrorState(
              title: 'Penerimaan tidak ditemukan',
              message: 'Data ini sudah dihapus dari perangkat.',
            ),
          );
        }
        return AppPage(
          title: 'Penerimaan lab',
          bottomBar: row.isUploaded
              ? null
              : AppStickyActionBar(
                  primaryLabel: 'Ubah penerimaan',
                  onPrimary: () => _edit(context, ref, row),
                  secondaryLabel: 'Hapus penerimaan',
                  onSecondary: () => _delete(context, ref, row),
                ),
          body: _Body(row: row, master: master),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.row, required this.master});

  final PupukLab row;
  final PupukLabMaster? master;

  @override
  Widget build(BuildContext context) {
    final form = row.form;
    final date = DateFormat('d MMMM y', 'id');
    final terima = DateTime.tryParse(form.tanggalTerima);
    final estimasi = DateTime.tryParse(form.estimasiKupa);
    final jenis = master?.jenisById(form.jenisSampelId)?.nama;
    final status = master
        ?.progressOptionsFor(form.jenisSampelId)
        .where((p) => p.id == form.statusPengerjaan)
        .firstOrNull
        ?.nama;

    String parameterName(int id) =>
        master?.parameterById(id)?.namaParameter ?? 'Parameter #$id';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBanner(row: row),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Penerimaan',
          children: [
            AppKeyValueList(
              items: [
                AppKeyValue(label: 'No. surat', value: row.noSurat),
                AppKeyValue(
                  label: 'Tanggal terima',
                  value: terima == null
                      ? form.tanggalTerima
                      : date.format(terima),
                ),
                AppKeyValue(
                  label: 'Estimasi KUPA',
                  value: estimasi == null
                      ? form.estimasiKupa
                      : date.format(estimasi),
                ),
                AppKeyValue(label: 'Penerima', value: form.penerimaSampel),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Sampel (${row.samples.length})',
          children: [
            for (final sample in row.samples)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sample.kodeSampel,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (sample.isManual)
                    const AppStatusChip(
                      label: 'Manual',
                      type: AppNoticeType.info,
                      icon: Icons.edit_note_rounded,
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Informasi sampel',
          children: [
            AppKeyValueList(
              items: [
                AppKeyValue(label: 'Jenis komoditas', value: jenis ?? '-'),
                AppKeyValue(label: 'Jenis pupuk', value: form.jenisPupuk),
                AppKeyValue(label: 'Status pengerjaan', value: status ?? '-'),
                AppKeyValue(label: 'Asal sampel', value: form.asalSampel),
                AppKeyValue(label: 'Kemasan', value: form.kemasanSampel),
                AppKeyValue(label: 'Kondisi', value: form.kondisiSampel),
                AppKeyValue(label: 'Tujuan', value: form.tujuan),
                AppKeyValue(label: 'Prioritas', value: form.skalaPrioritas),
                AppKeyValue(
                  label: 'Peralatan',
                  value: form.peralatan.isEmpty
                      ? '-'
                      : form.peralatan.join(', '),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Pengirim dan kontak',
          children: [
            AppKeyValueList(
              items: [
                AppKeyValue(label: 'Nama pengirim', value: form.namaPengirim),
                AppKeyValue(label: 'Departemen', value: form.departemen),
                AppKeyValue(
                  label: 'Email tujuan',
                  value: form.emailTo.join(', '),
                ),
                AppKeyValue(
                  label: 'Email CC',
                  value: form.emailCc.isEmpty ? '-' : form.emailCc.join(', '),
                ),
                AppKeyValue(
                  label: 'WhatsApp',
                  value: form.noHp.isEmpty ? '-' : form.noHp.join(', '),
                ),
                AppKeyValue(
                  label: 'Diskon',
                  value: form.diskon == null ? '-' : '${form.diskon}%',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Parameter uji',
          children: [
            for (final p in form.parameters)
              AppKeyValueList(
                items: [
                  AppKeyValue(
                    label: parameterName(p.parameterId),
                    value: '${p.totalSample}x pada ${p.kodeSampel.join(', ')}',
                  ),
                ],
              ),
          ],
        ),
        if (row.fotoPaths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          AppFormSection(
            title: 'Foto (${row.fotoPaths.length})',
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < row.fotoPaths.length; i++)
                    AppPhotoThumb(
                      image: FileImage(File(row.fotoPaths[i])),
                      semanticLabel: 'Foto ${i + 1}',
                    ),
                ],
              ),
            ],
          ),
        ],
        if ((form.catatan ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          AppFormSection(title: 'Catatan', children: [Text(form.catatan!)]),
        ],
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.row});

  final PupukLab row;

  @override
  Widget build(BuildContext context) {
    final status = pupukLabStatusOf(row);
    if (row.isUploaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBanner(
            type: AppNoticeType.success,
            title: 'Sudah masuk SmartLab',
            message: 'Nomor di bawah ditetapkan SmartLab saat data diunggah.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppKeyValueList(
            items: [
              AppKeyValue(label: 'Kode track', value: row.kodeTrack ?? '-'),
              AppKeyValue(label: 'Nomor lab', value: _nomorLab(row.nomorLab)),
              AppKeyValue(
                label: 'Nomor kupa',
                value: row.nomorKupa?.toString() ?? '-',
              ),
            ],
          ),
        ],
      );
    }
    if (row.needsEdit) {
      return AppBanner(
        type: AppNoticeType.error,
        title: 'SmartLab menolak data ini',
        message:
            '${row.errorMessage ?? 'Data tidak lolos pemeriksaan.'}\nUbah penerimaan, lalu unggah lagi. Mengunggah ulang tanpa perubahan akan ditolak lagi.',
      );
    }
    if (row.errorMessage != null) {
      return AppBanner(
        type: AppNoticeType.warning,
        title: 'Belum terkirim',
        message:
            '${row.errorMessage}\nDicoba lagi otomatis pada unggahan berikutnya.',
      );
    }
    return AppBanner(
      type: status.type,
      title: 'Belum diunggah',
      message: 'Data tersimpan di perangkat. Unggah saat jaringan tersedia.',
    );
  }

  /// SmartLab stores `kiri$kanan`; a single sample has `-` on the right.
  String _nomorLab(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parts = raw.split(r'$');
    if (parts.length == 2 && (parts[1] == '-' || parts[1] == parts[0])) {
      return parts[0];
    }
    return parts.join(' sampai ');
  }
}
