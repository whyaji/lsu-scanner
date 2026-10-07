# Design system SampleTrack Mobile

Code lives in `lib/widgets/{feedback,buttons,layout,forms,display}` and `lib/core/theme`. Every widget is theme driven (`ColorScheme` plus the `AppSemanticColors` extension), works in light and dark, and is tested at text scale 1.3 on a 320dp wide screen.

## Design Read

Reading this as: an internal field operations app for estate, NT and lab staff. They work outdoors, often one-handed, on a spotty network, filling long forms and checking where a sample is in its life. The language is calm and utilitarian. The current blue palette stays as the brand (the owner said the colors are already good), so the light and dark values in `lib/core/theme/app_theme.dart` are untouched.

Dials: ENERGY 1 (nothing competes with the data), RHYTHM 2 (screens share one vertical rhythm: 24 between sections, 16 between fields), MOTION 1 (only 150 to 200 ms fades and slides, none when the system disables animations).

Identity motif, the journey track: small connected stage dots (Gudang Estate, Kirim Estate, Kirim Lab, Terima Lab, Estimasi KUPA, Sertifikat) that show how far a sample has travelled. It appears in list items and in the detail screen via `AppJourneyTrack`. Reason: it is the one thing in this product that is true of every sample, so it gives the UI an identity that no other app would have.

One accent: primary blue, used for the single primary action per screen, the focus ring, selected state and the journey path. No gradients, glow, glass, background grids, decorative shadows, pill-everything or left color stripes. Reason: staff glance at the screen in sunlight, so every extra effect costs legibility.

Elevation only for dialogs, sheets and toasts. Cards are flat with a 1px outline. Reason: depth then means "this is on top of the page and needs your attention".

## Tokens

### Radius (`AppSizes`)

| Token | Value | Used by |
| --- | --- | --- |
| `radiusCard` | 12 | AppCard, banner, toast, list item |
| `radiusField` | 10 | text, select and date fields |
| `radiusButton` | 12 | AppButton |
| `radiusChip` | 8 | status chip, choice chip, tag chip, photo thumb |
| `radiusDialog` / `radiusSheet` | 16 | AppDialog, AppBottomSheet |

### Size

| Token | Value | Reason |
| --- | --- | --- |
| `tapTarget` | 48 | Gloved or one-handed use. Above the 44 minimum of the antislop gate |
| `buttonHeight` / `buttonHeightCompact` | 52 / 48 | Regular for screen actions, compact for dialogs and banners |
| `listItemMinHeight` | 64 | Room for a title, a subtitle and a chip |
| `contentMaxWidth` | 640 | Keeps line length readable on tablets |
| `dialogMaxWidth` / `toastMaxWidth` | 400 / 560 | |
| `dialogStackBreakpoint` | 340 | Dialog inner width below this stacks buttons |

### Spacing (`AppSpacing`, 8pt grid, additive)

| Token | Value | Used for |
| --- | --- | --- |
| `xs / sm / md / lg / xl` | 4 / 8 / 16 / 24 / 32 | existing |
| `sectionGap` | 24 | between titled groups |
| `fieldGap` | 16 | between form fields |
| `labelGap` | 6 | label to control |
| `screenInset(context)` / `screenPaddingOf(context)` | 16 below 600dp, 24 from 600dp | screen padding |

### Semantic colors (`AppSemanticColors`, registered in `AppTheme.light` and `AppTheme.dark`)

`accent` is for icons and for text directly on the page. `onContainer` is for text on `container`. The brand warning color F57C00 is only 2.70:1 on white, so it is not used for text; warning text uses a darker variant. Dark error accent is FF9AA5 because the scheme error CF6679 is 4.23:1 on the dark error container.

Light (page surface FFFFFF, scaffold F5F5F5):

| Type | accent | container | onContainer | onContainer on container | accent on surface | accent on scaffold | accent on container (icon) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| success | 2E7D32 | E8F5E9 | 1B5E20 | 7.00 | 5.13 | 4.70 | 4.56 |
| info | 1565C0 | E3F2FD | 0D47A1 | 7.56 | 5.75 | 5.27 | 5.03 |
| warning | 9A4A00 | FFF3E0 | 6B3400 | 9.05 | 6.26 | 5.74 | 5.71 |
| error | B00020 | FDECEA | 8C0019 | 8.62 | 7.33 | 6.72 | 6.41 |

Dark (page surface 121212, scaffold 1E1E1E):

| Type | accent | container | onContainer | onContainer on container | accent on surface | accent on scaffold | accent on container (icon) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| success | 81C784 | 1B3A1F | A5D6A7 | 7.64 | 9.31 | 8.28 | 6.24 |
| info | 90CAF9 | 1E3A5F | D1E4FF | 8.90 | 10.71 | 9.53 | 6.57 |
| warning | FFB74D | 3E2A0A | FFD699 | 9.95 | 10.82 | 9.63 | 7.88 |
| error | FF9AA5 | 3F1A1E | FFB4AB | 8.98 | 9.29 | 8.27 | 7.56 |

Previous brand warning for reference: F57C00 on FFFFFF 2.70 (fail).

### Scheme pairs used by the widgets

| Pair | Light | Dark |
| --- | --- | --- |
| onSurface on surface (body text) | 17.13 | 14.51 |
| onSurfaceVariant on surface (helper, caption) | 9.34 | 10.99 |
| onSurfaceVariant on scaffold | 8.57 | 9.78 |
| onPrimary on primary (primary button) | 5.75 | 4.93 |
| onPrimaryContainer on primaryContainer (tonal button, selected chip) | 6.15 | 8.90 |
| primary on surface (secondary and text buttons, focus ring) | 5.75 | 10.71 |
| primary on scaffold | 5.27 | 9.53 |
| outline on surface (field border, journey pending dot, 3:1 needed) | 4.55 | 5.91 |
| outline on scaffold | 4.18 | 5.26 |
| onError on error (destructive button) | 7.33 | 4.76 |
| error on surface (field error text) | 7.33 | 5.20 |
| error on scaffold | 6.72 | 4.63 |
| onSurface on neutral chip (surfaceContainerHighest) | 13.27 | 10.97 |
| journey done check (onPrimary on primary) | 5.75 | 4.93 |
| journey error mark (surface on error accent) | 7.33 | 9.29 |
| primary text on semantic containers (banner action), success/warning/error/info | 5.11 / 5.24 / 5.02 / 5.03 | 7.18 / 7.79 / 8.71 / 6.57 |
| outline on semantic containers (banner action border, 3:1 needed) | 3.98 to 4.15 | 3.63 to 4.81 |

All ratios were measured with `.agents/skills/antislop-human/contrast-check.py`. `test/core/theme/semantic_colors_contrast_test.dart` fails the build if any semantic pair drops below 4.5:1 (text) or 3:1 (icons, outlines).

Decorative only, not relied on for meaning: card outline (`outlineVariant`, 1.70:1 on white), pending connector line. Meaning is always carried by text or by a second cue (icon shape, check mark, label).

## Feedback: dialog, banner or toast

| Situation | Use | Reason |
| --- | --- | --- |
| Result the user must acknowledge (upload finished with failures, sample rejected, receipt saved with a warning) | `AppDialog.success/info/warning/error` | It interrupts on purpose and returns focus when closed |
| Destructive or irreversible confirmation (delete a draft, discard changes) | `AppDialog.confirm(tone: destructive)` | Cancel gets initial focus so a stray Enter cannot delete |
| A choice with 2 or 3 outcomes | `AppDialog.choice` | One decision, labelled buttons instead of Yes/No |
| Work in progress that must not be interrupted (upload, sync) | `AppDialog.progress` | Not dismissible, controlled through a handle |
| A form or screen level problem that stays until fixed (offline, master data stale, one noSurat per receipt, validation summary) | `AppBanner` | Stays in the layout, announced as a live region, no focus theft |
| Lightweight confirmation that needs no decision (saved, copied, photo removed with undo) | `AppToast` | Auto dismisses, one at a time |
| Anything else | not a SnackBar | `SnackBar` is not used anywhere in the new code |

Rules: never show an error only in a toast (it disappears before it is read). Never stack a toast on a dialog for the same event. A toast with an action stays 7 seconds, a plain one 4.

Toast without a BuildContext (services, providers):

```dart
// main.dart, once, next to appNavigatorKey
AppFeedbackHost.register(appNavigatorKey);

// anywhere
AppToast.showGlobal('Penerimaan disimpan di perangkat');
```

`showGlobal` returns false when no navigator is mounted yet.

## Component catalogue

### feedback/

```dart
final ok = await AppDialog.confirm(
  context,
  title: 'Hapus penerimaan ini?',
  message: 'Data yang belum diunggah akan hilang.',
  confirmLabel: 'Hapus penerimaan',
  tone: AppDialogTone.destructive,
);

await AppDialog.error(
  context,
  title: 'Unggah gagal',
  message: 'Jaringan terputus. Data tetap tersimpan di perangkat.',
  onRetry: upload,
);

final handle = AppDialog.progress(context, message: 'Mengunggah 3 data');
handle.update(message: 'Mengunggah foto', value: 0.4);
handle.close();

final picked = await AppDialog.choice<String>(
  context,
  title: 'Tambah foto',
  choices: const [
    AppDialogChoice(label: 'Ambil foto', value: 'camera'),
    AppDialogChoice(label: 'Pilih dari galeri', value: 'gallery'),
    AppDialogChoice(label: 'Lewati', value: 'skip'),
  ],
);

AppBanner(
  type: AppNoticeType.warning,
  title: 'Master data belum diperbarui',
  message: 'Memakai data terakhir dari 5 Oktober.',
  actionLabel: 'Sinkronkan',
  onAction: sync,
  onDismiss: hide,
);

AppToast.show(context, 'Foto dihapus', type: AppNoticeType.info, actionLabel: 'Urungkan', onAction: undo);

final value = await AppBottomSheet.show<int>(context, title: 'Pilih jenis', builder: (_) => ...);
```

Dialog behavior: Back, Escape and the scrim close every dialog except progress (`confirm` then returns false, `choice` returns null). Buttons stack vertically with the primary on top below 340dp inner width (every phone), when there are 3 actions, and sit in a row only on wider screens. Every button is 48 high. Focus stays inside the dialog (route focus scope), the title is the route name for screen readers, and the tone icon carries a spoken label (Berhasil, Informasi, Peringatan, Kesalahan).

`AppNoticeType.resolve(context)` returns `AppNoticeStyle(accent, container, onContainer, icon)`. Use it for any new notice-like widget instead of picking colors.

### buttons/

```dart
AppButton(label: 'Simpan penerimaan', onPressed: save, loading: saving, fullWidth: true);
AppButton(label: 'Pindai label', variant: AppButtonVariant.secondary, icon: Icons.qr_code_scanner, onPressed: scan);
AppIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Hapus foto', onPressed: remove);
```

Variants: primary (one per screen), secondary (outlined), tonal, text, destructive. Sizes: regular 52, compact 48. `loading` swaps the label for a spinner without changing width and announces "sedang diproses". `AppButton` sets all colors itself, so the app wide `filledButtonTheme` (which paints every FilledButton red) does not leak into it. `AppIconButton` requires a tooltip, which is also its screen reader label.

### layout/

```dart
AppPage(
  title: 'Terima Lab',
  onRefresh: reload,
  bottomBar: AppStickyActionBar(primaryLabel: 'Lanjut', onPrimary: next, secondaryLabel: 'Kembali', onSecondary: back),
  body: Column(children: [...]),
);
AppSection(title: 'Sampel', children: [...]);
AppCard(onTap: open, child: ...);
```

`AppPage` caps content at 640, pads 16 or 24, dismisses the keyboard on drag and puts the sticky bar inside the body column so it rides above the keyboard. `AppStickyActionBar` handles the gesture bar through `SafeArea` and stacks its two buttons at large text or narrow width. `AppSection` is a plain column by default so cards are not nested in cards.

### forms/

```dart
AppFormSection(title: 'Informasi Sampel', description: 'Isi sesuai label kemasan.', children: [
  AppSelectField<int>(label: 'Jenis Pupuk', options: opts, value: id, onChanged: setId, required: true,
      disabledReason: komoditas == null ? 'Pilih Jenis Komoditas dulu.' : null),
  AppDateField(label: 'Tanggal Terima', value: tgl, onChanged: setTgl, minDate: memo),
  AppTagInput(label: 'Email penerima', values: emails, onChanged: setEmails, itemValidator: validateEmail),
]);
AppStepHeader(currentStep: 2, stepLabels: labels, onStepTap: goToStep);
```

Fields: `AppTextField` (label above, helper or error, clear, password toggle), `AppSelectField<T>` (bottom sheet, search above 7 options), `AppDateField`, `AppDateTimeField` (Material pickers in id locale, min/max, 24 hour), `AppChoiceChips<T>`, `AppCheckboxGroup<T>`, `AppSwitchTile`, `AppTagInput` (Enter, comma, semicolon or leaving the field commits; invalid text stays and shows the message), `AppRepeaterCard`, `AppFormSection`, `AppStepHeader`. Custom fields extend `AppFormValueField<T>` so `Form.validate()` covers them. A non-null `disabledReason` disables a picker and prints the reason in place of the helper text.

### display/

```dart
AppListItem(
  title: 'NPK 16-16-16',
  subtitle: 'Supplier A',
  trailing: AppStatusChip(label: 'Menunggu unggah', type: AppNoticeType.warning),
  journey: AppJourneyTrack.sample(completed: 3),
  onTap: open,
);
AppJourneyTrack.sample(completed: 4, showLabels: true, hasError: false);
```

`AppJourneyTrack` has a compact mode (dots plus one caption line, for lists) and a labelled mode (every stage name, scrolls sideways when names do not fit at large text). Each stage is done (filled with check), current (ring with center dot), pending (hollow) or error (filled with mark), so state survives grayscale. Screen readers get one sentence, for example "Perjalanan sampel. Kirim Lab (3 dari 6). Gudang Estate selesai, Kirim Estate selesai, Kirim Lab sedang berjalan, ...". Build custom stage lists with `AppJourneyTrack(stages: [...])`.

Also: `AppStatusChip` (neutral or semantic, icon repeats the meaning), `AppStatCard` (null value renders a dash, never a made up number), `AppEmptyState`, `AppErrorState` (retry), `AppLoadingState` (skeleton shaped like a list item, shimmer blended from onSurface so it works in dark, still when animations are disabled), `AppKeyValueList` (label above value, selectable), `AppPhotoThumb` (any `ImageProvider`, optional 48dp remove target).

## Accessibility rules

1. Text 4.5:1 and icons or outlines 3:1 against their actual background, in both themes (measured above, enforced by test).
2. Every tappable thing is 48dp or more, including icon buttons, step segments, list rows, checkbox rows and the photo remove control.
3. Meaning never depends on color alone: notice icons differ by shape, selected chips show a check, journey stages differ by shape.
4. Text scales to 1.3 without clipping: titles wrap to two lines, rows use `Expanded`, wide content scrolls instead of overflowing.
5. Banners and toasts are live regions. Dialogs name the route, focus stays inside, Back and Escape close.
6. Every icon-only control has a tooltip that doubles as its label.
7. Disabled controls say why (`disabledReason`), they are not just dimmed.
8. Every list or section has loading (`AppLoadingState`), empty (`AppEmptyState`) and error (`AppErrorState`) states.
9. Motion: 150 to 200 ms fades, off when `disableAnimations` is true.

## Decisions and reasons

| Decision | Reason |
| --- | --- |
| Semantic colors in a `ThemeExtension` instead of constants on `AppTheme` | Light and dark values travel with the theme, widgets cannot pick the wrong one |
| Separate `accent` and `onContainer` | Text on a pastel container needs a darker shade than the icon, and the page needs a different one again |
| Warning text is 9A4A00, not the brand F57C00 | Brand orange is 2.70:1 on white, unreadable outdoors |
| Banner for persistent problems, toast only for confirmations | A toast disappears in 4 seconds, an error must outlive that |
| Dialog buttons stack on phones with primary on top | The thumb reaches the top button first, and long Indonesian labels do not get truncated |
| Destructive confirm focuses Cancel | A stray Enter or a keyboard double tap must not delete data |
| Labels above fields, not floating labels | Long forms stay readable at 1.3x text and the label never shrinks into a hint |
| "(wajib)" instead of an asterisk | Screen readers and new staff read it without a legend |
| Select opens a bottom sheet, search from 8 options | A native dropdown cannot be searched and is hard to hit with a thumb |
| Tag input commits on blur | Pressing Save with an email still in the field must not lose it |
| Cards are outlined, not shadowed | Elevation is kept for overlays so stacking order stays obvious |
| `AppButton` overrides every state color | The app theme paints every `FilledButton` red, so relying on the theme would make primary buttons destructive |
| Journey track in lists and detail | One motif for the one fact true of every sample |
| Toast reachable through a registered navigator key | Providers and services show feedback without holding a BuildContext |

## Migration notes

The old widgets in `lib/widgets/*.dart` (`AppStatusChip`, `AppStatCard`, `AppEmptyState`, `AppErrorState`, `AppLoadingState`, `CustomButton`, `AppAlert`, `AppErrorDialog`, SnackBar calls) are replaced by the new ones above. Class names `AppStatusChip`, `AppStatCard`, `AppEmptyState`, `AppErrorState` and `AppLoadingState` exist in both places until the cleanup pass deletes the old files, so a screen must import only one of them. `AppStatusChip(color:)` becomes `AppStatusChip(type:)`.

main.dart needs one line after the navigator key declaration: `AppFeedbackHost.register(appNavigatorKey);` (call it at the top of `main()` or in `MyApp.build`).
