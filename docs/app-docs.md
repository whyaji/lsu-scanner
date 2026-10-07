# SampleTrack Mobile application guide

## Purpose

SampleTrack Mobile supports LSU and fertilizer sample operations for estate, NT, and laboratory staff. Fertilizer lab receiving is offline-first: the device stores a receipt locally and forwards it when connectivity returns.

## Architecture

```text
Flutter screens
    -> Riverpod providers
    -> domain models and upload strategies
    -> API classes and Dio
    -> SampleTrack API
    -> SmartLab API
```

Local SQLite stores operational records, upload queues, master data, and user preferences. `AppDatabase` owns schema versions and migrations. DAOs own table access. Providers coordinate sync and upload state.

## Main folders

| Folder | Responsibility |
| --- | --- |
| `lib/core/constants` | API paths and app constants |
| `lib/core/database` | SQLite database, migrations, DAOs |
| `lib/core/network` | Dio client, API classes, response models |
| `lib/core/theme` | Light and dark Material 3 theme |
| `lib/features/auth` | Login and session state |
| `lib/features/home` | Permission-based home and navigation |
| `lib/features/pupuk` | Fertilizer sample activities |
| `lib/features/pupuk_lab` | Offline Terima Lab receipt workflow |
| `lib/features/sample` | LSU sample workflow |
| `lib/widgets` | Shared layout, form, feedback, and display widgets |

## Roles and permissions

| Role | Permission | Main access |
| --- | --- | --- |
| LSU Main Station | `lsu:mobile-selesai` | Complete LSU samples |
| LSU Sub Station | `lsu:mobile-terima` | Receive LSU samples |
| Pupuk Estate | `pupuk:mobile-kirim-estate` | Send fertilizer samples from estate |
| Pupuk NT | `pupuk:mobile-kirim-lab`, `pupuk:mobile-kirim-sertifikat` | Send samples to lab and send certificates |
| Pupuk Lab | `pupuk:mobile-pupuk-lab` | Receive fertilizer samples at lab |

The app derives visible destinations from permissions returned by login. A Pupuk Lab-only account does not require a regional selection.

## Terima Lab flow

1. Sync fertilizer data and SmartLab master data.
2. Scan system QR labels or enter manual sample codes.
3. Keep one no. surat per receipt. The first system sample sets the default.
4. Complete the five form steps.
5. Save one receipt to SQLite.
6. Upload photos, then send the receipt through SampleTrack to SmartLab.
7. SampleTrack updates tracking tuple index 4 for system samples.

The full field mapping and failure matrix is in `docs/terima-lab.md`.

## Feedback policy

- Use `AppDialog` for confirmation, errors requiring acknowledgement, and destructive actions.
- Use `AppBanner` for screen-level problems or stale data.
- Use `AppToast` for short, non-blocking results.
- Do not use `SnackBar`, dead buttons, or color-only status indicators.

## Theme and layout

The existing blue palette remains the brand palette. Light and dark themes are supported. Shared widgets use theme `ColorScheme` values and semantic colors. Tap targets are at least 48 dp. Forms use sticky actions so the primary action remains reachable above the keyboard.

Design Read: internal field-operations app for estate, NT, and laboratory staff, with calm utilitarian visual language, dial ENERGY 1 / RHYTHM 2 / MOTION 1. The repeated identity motif is a journey track that shows sample stage progress.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Use `.envexample` as the environment template. Do not commit production credentials.

## Release checklist

- Verify API base URL and Firebase configuration.
- Run migrations through the application startup path.
- Test login for every role.
- Test offline save and later upload.
- Test SmartLab validation failure and retryable network failure.
- Test light and dark themes.
- Test at narrow width and text scale 1.3.
- Build the target platform and inspect logs for runtime errors.
