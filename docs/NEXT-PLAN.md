# Next plan: mobile Terima Lab finish, redesign, cleanup, docs

Status date: 2026-10-06. Each task is small and independent so a cheaper model can run it alone.
Read first for any task: `docs/design-system.md`, `docs/data-layer.md`, `docs/terima-lab.md` (if present), and `sampletrack-mobile/docs/NEXT-PLAN.md` (this file).

## Done (do not redo)
- SmartLab API, SampleTrack backend and web UI, mobile design system (`lib/widgets/{feedback,buttons,layout,forms,display}`), mobile data layer (DAOs, API classes, upload pipeline, Terima Lab models/DAO/upload strategy, DB migrations v3 and v4).
- Terima Lab screens exist in `lib/features/pupuk_lab/screens/`: receive (wizard), scan, photo, detail. `lib/widgets/scanner/qr_scan_view.dart` exists.

## Rules for every task
- Only edit the files listed in the task. No shims, no dead code, no em dash in text.
- New code uses `AppDialog`, `AppBanner`, `AppToast`, `AppButton`, theme colors. Never `SnackBar`, `AppAlerts`, `AppErrorDialog`, `CustomButton`, `AppColors`, raw `FilledButton`.
- UI copy in Indonesian, specific (for example "Simpan penerimaan", not "Submit").
- Finish each task with `flutter analyze --no-pub` (zero new issues in touched files) and `flutter test`. Report pass/fail counts.
- Do not commit.

## Phase A: Terima Lab only (completed)
A1. Done. Focused Terima Lab and database tests pass through the current test run. `flutter analyze --no-pub` reports 27 pre-existing infos and no errors.
A2. Done. Terima Lab is wired into existing pupuk screens:
  - `lib/features/home/screens/fertilizer_home_screen.dart`: tile for `kPupukLab` opens `PupukLabReceiveScreen`; pending count includes pupuk_lab rows.
  - `lib/features/pupuk/screens/sampel_pupuk_list_screen.dart`: show `PupukLabListTile` rows (pending and uploaded) and open `PupukLabDetailScreen`.
  - `lib/features/pupuk/screens/upload_sampel_pupuk_screen.dart`: Terima Lab group with per-row result (`kode_track`, `nomor_lab`, failure reason).
  - `lib/features/pupuk/screens/pupuk_qr_scanner_screen.dart`: pass `pendingPupukLabKodes: ref.watch(reservedPupukLabKodeProvider)`.
  - `lib/features/settings/screens/settings_screen.dart`: hides "Ganti Regional" when `!requiresRegional(user)`.
A3. Done. `docs/terima-lab.md` documents flow, screens, state machine, validation, mapping and failures.
A4. Done. Manual end to end checklist is in `docs/terima-lab.md`. It still needs execution against deployed staging services.

## Phase B: replace SnackBar everywhere (completed)
No `showSnackBar` or `ScaffoldMessenger` calls remain in `lib/`. Feedback now uses dialogs, banners or toasts:
B1. `lib/features/auth`, `lib/features/regional`, `lib/features/notifications`, `lib/core/network/services/fcm_service.dart` (use `AppToast.showGlobal` with action "Lihat").
B2. `lib/features/pupuk/screens/*` (collection, sertifikat form, activity form, confirmation, photo capture, upload).
B3. `lib/features/sample/screens/*` and `lib/widgets/inline_pdf_preview_panel.dart`.
Rule of thumb: needs acknowledgement or destructive = `AppDialog`; form/screen problem = `AppBanner`; light confirmation = `AppToast`.
`main.dart` calls `AppFeedbackHost.register(appNavigatorKey)` once.

## Phase C: screen redesign (one screen group per task)
Use new widgets, one primary action per screen, sticky bottom action bar for forms, loading/empty/error states, tap targets 48dp, text scale 1.3 safe. Keep business rules unchanged. Add a widget smoke test per screen (light and dark, 360x640).
C1. In progress. Login now uses `AppTextField` and `AppButton`, settings update feedback uses `AppToast`, and home screens use `AppCard` plus the new stat card. Remaining shell layout migration is pending.
C2. In progress. Collection flow and activity form now use `AppPage`, `AppCard`, `AppStickyActionBar`, and inline warning feedback. QR scanners and full-screen photo preview use shared dialogs and toasts instead of legacy feedback.
C3. Data Sampel list and detail, Kirim Sertifikat form (split `kirim_sertifikat_form_screen.dart` into sections).
C4. LSU flow: scanner, sample detail, confirmation, received list, upload.
C5. Notifications list and notification sample list.

## Phase D: cleanup (after B and C)
D1. Partial. Unused root widgets are deleted (alert, error dialog, custom button, old empty/loading/error/stat/status/info/action/list-tile cards, image preview, sample card, progress indicator). `AppFooter`, `AppSectionHeader`, `AppSettingsTile` and `AppColors` still have active callers and need a migration pass.
D2. Done. Analyzer deprecations and brace warnings are fixed. `flutter analyze --no-pub` passes with 0 issues.
D3. Clear local pupuk_lab rows and master on logout when a different user logs in.

## Phase E: docs and release
E1. Done. `docs/app-docs.md` documents architecture, folders, roles, screens, offline sync/upload flow, and release checks.
E2. Done. `CHANGELOGS.md` exists in mobile, SampleTrack, and SmartLab.
E3. Done. `README.md` documents setup, run, and verification commands.
E4. Done. Mobile version is `1.1.0+1015`.

## Phase F: production readiness
F1. SampleTrack: run `bun run db:migrate` on staging, `bun run db:seed:rbac:complete`, set `SAMPLE_TRACK_*` envs. Read the rollout notes in `sampletrack/docs/PUPUK-LAB-FLOW.md` first (samples registered in SmartLab before release can create duplicates).
F2. SmartLab: `php artisan migrate --force`, set `SAMPLE_TRACK_API_KEY`, run a queue worker for emails.
F3. Done. Flutter analyzer and full suite pass. SampleTrack tests/typecheck/lint, frontend build/tests, and SmartLab PHP/API tests pass. Deployment migrations and staging click-through remain operational steps.
