import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/theme/app_theme.dart';
import 'package:sampletrack/widgets/buttons/app_button.dart';
import 'package:sampletrack/widgets/display/app_empty_state.dart';
import 'package:sampletrack/widgets/display/app_error_state.dart';
import 'package:sampletrack/widgets/display/app_journey_track.dart';
import 'package:sampletrack/widgets/display/app_key_value_list.dart';
import 'package:sampletrack/widgets/display/app_list_item.dart';
import 'package:sampletrack/widgets/display/app_loading_state.dart';
import 'package:sampletrack/widgets/display/app_photo_thumb.dart';
import 'package:sampletrack/widgets/display/app_stat_card.dart';
import 'package:sampletrack/widgets/display/app_status_chip.dart';
import 'package:sampletrack/widgets/feedback/app_banner.dart';
import 'package:sampletrack/widgets/feedback/app_notice_type.dart';
import 'package:sampletrack/widgets/forms/app_checkbox_group.dart';
import 'package:sampletrack/widgets/forms/app_choice_chips.dart';
import 'package:sampletrack/widgets/forms/app_form_section.dart';
import 'package:sampletrack/widgets/forms/app_repeater_card.dart';
import 'package:sampletrack/widgets/forms/app_select_field.dart';
import 'package:sampletrack/widgets/forms/app_step_header.dart';
import 'package:sampletrack/widgets/forms/app_switch_tile.dart';
import 'package:sampletrack/widgets/forms/app_tag_input.dart';
import 'package:sampletrack/widgets/forms/app_text_field.dart';
import 'package:sampletrack/widgets/layout/app_page.dart';
import 'package:sampletrack/widgets/layout/app_sticky_action_bar.dart';

import '../helpers/test_app.dart';

class _EmptyImage extends ImageProvider<_EmptyImage> {
  @override
  Future<_EmptyImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(_EmptyImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Future.error('no image'));
}

Widget _page() {
  return AppPage(
    title: 'Terima Lab',
    onRefresh: () async {},
    bottomBar: AppStickyActionBar(
      primaryLabel: 'Simpan penerimaan',
      onPrimary: () {},
      secondaryLabel: 'Kembali',
      onSecondary: () {},
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppStepHeader(
          currentStep: 2,
          stepLabels: const ['Sampel', 'Informasi Sampel', 'Pengirim dan Kontak'],
          onStepTap: (_) {},
        ),
        const SizedBox(height: 16),
        const AppBanner(
          type: AppNoticeType.warning,
          title: 'Surat berbeda',
          message: 'Sampel ini memakai nomor surat lain dari penerimaan ini.',
        ),
        const SizedBox(height: 16),
        AppFormSection(
          title: 'Informasi Sampel',
          description: 'Isi sesuai label pada kemasan.',
          children: [
            const AppTextField(
              label: 'Kemasan Sampel',
              hint: 'Contoh: karung 50 kg',
              required: true,
              clearable: true,
            ),
            const AppTextField(label: 'Sandi', obscureText: true),
            AppSelectField<int>(
              label: 'Jenis Pupuk',
              options: const [AppSelectOption(value: 1, label: 'NPK')],
              value: null,
              disabledReason: 'Pilih Jenis Komoditas dulu.',
              onChanged: (_) {},
            ),
            AppChoiceChips<String>(
              label: 'Kondisi Sampel',
              options: const [
                AppChoiceOption(value: 'n', label: 'Normal'),
                AppChoiceOption(value: 'a', label: 'Abnormal'),
              ],
              value: 'n',
              onChanged: (_) {},
            ),
            AppCheckboxGroup<String>(
              label: 'Peralatan',
              options: const [
                AppCheckboxOption(value: 'p', label: 'Personel'),
                AppCheckboxOption(value: 'a', label: 'Alat'),
              ],
              values: const ['p'],
              onChanged: (_) {},
            ),
            AppSwitchTile(
              title: 'Konfirmasi pelanggan',
              subtitle: 'Kirim email konfirmasi ke penerima.',
              value: true,
              onChanged: (_) {},
            ),
            AppTagInput(
              label: 'Email penerima',
              values: const ['ani@lab.co.id', 'budi.santoso@citraborneo.co.id'],
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppRepeaterCard(
          title: 'Parameter 1',
          onRemove: () {},
          children: const [AppTextField(label: 'Total sampel')],
        ),
        const SizedBox(height: 16),
        AppListItem(
          title: 'NPK 16-16-16',
          subtitle: 'Supplier A',
          trailing: const AppStatusChip(
            label: 'Gagal',
            type: AppNoticeType.error,
          ),
          journey: AppJourneyTrack.sample(completed: 3),
          onTap: () {},
        ),
        const SizedBox(height: 16),
        const AppStatCard(label: 'Menunggu unggah', value: '4'),
        const SizedBox(height: 16),
        const AppStatCard(label: 'Terunggah', value: null),
        const SizedBox(height: 16),
        AppJourneyTrack.sample(completed: 4, showLabels: true),
        const SizedBox(height: 16),
        const AppKeyValueList(
          items: [
            AppKeyValue(label: 'Nomor surat', value: 'SJ/2026/10/0042'),
            AppKeyValue(label: 'Catatan'),
          ],
        ),
        const SizedBox(height: 16),
        AppPhotoThumb(
          image: _EmptyImage(),
          semanticLabel: 'Foto kemasan',
          onRemove: () {},
        ),
        const SizedBox(height: 16),
        const AppButton(label: 'Tonal', onPressed: null, variant: AppButtonVariant.tonal),
        AppButton(label: 'Hapus', onPressed: () {}, variant: AppButtonVariant.destructive, fullWidth: true),
        AppButton(label: 'Teks', onPressed: () {}, variant: AppButtonVariant.text),
      ],
    ),
  );
}

void main() {
  for (final theme in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('page with every form and display widget fits 320dp, ${theme.key}, x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          testApp(_page(), theme: theme.value, textScale: scale, scaffold: false),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('state widgets render, ${theme.key}', (tester) async {
      await tester.pumpWidget(
        testApp(
          ListView(
            children: [
              SizedBox(
                height: 220,
                child: AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Belum ada penerimaan',
                  message: 'Pindai label sampel untuk memulai.',
                  actionLabel: 'Pindai label',
                  onAction: () {},
                ),
              ),
              SizedBox(
                height: 260,
                child: AppErrorState(
                  title: 'Data gagal dimuat',
                  message: 'Periksa koneksi lalu coba lagi.',
                  onRetry: () {},
                ),
              ),
              const SizedBox(height: 300, child: AppLoadingState(itemCount: 2)),
            ],
          ),
          theme: theme.value,
          textScale: 1.3,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.text('Pindai label'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  }

  testWidgets('sticky bar stacks buttons at large text and keeps 48dp targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        AppPage(
          title: 'Ringkasan',
          body: const SizedBox(height: 20),
          bottomBar: AppStickyActionBar(
            primaryLabel: 'Simpan penerimaan',
            onPrimary: () {},
            secondaryLabel: 'Kembali',
            onSecondary: () {},
          ),
        ),
        textScale: 1.3,
        scaffold: false,
      ),
    );
    final primary = tester.getTopLeft(find.text('Simpan penerimaan'));
    final secondary = tester.getTopLeft(find.text('Kembali'));
    expect(primary.dy, lessThan(secondary.dy));
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Simpan penerimaan')).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('text field toggles obscure text and clears', (tester) async {
    final controller = TextEditingController(text: 'rahasia');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      testApp(
        Column(
          children: [
            AppTextField(label: 'Kata sandi', controller: controller, obscureText: true),
            AppTextField(label: 'Catatan', controller: controller, clearable: true),
          ],
        ),
      ),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText).first).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Tampilkan Kata sandi'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).first).obscureText,
      isFalse,
    );

    await tester.tap(find.byTooltip('Hapus isi Catatan'));
    await tester.pump();
    expect(controller.text, isEmpty);
  });
}
