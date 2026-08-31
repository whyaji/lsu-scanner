# Image Storage, Auto-Download, Cleanup, and Preview Guide

This document describes how images are handled in the Smart-MobilePro application. It covers file storage location, automated downloading, storage cleanup mechanisms, and the fullscreen preview feature.

---

## 1. Image File Storage

### Internal Storage Directories

Photos captured by the app are stored in feature-specific directories within the application's document directory. Each feature typically has two versions of a photo:

1. **Compressed/Displayed Version**: Used for standard viewing in forms and lists.
2. **Original/HD Version**: A high-resolution photo, which may include custom watermarks (such as GPS coordinates, date-time, and inspector name).

The storage paths are defined in [app_photo_storage_paths.dart](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/core/services/storage/app_photo_storage_paths.dart). The base folder contains subfolders for each feature:

- **Compressed folders**: `[AppPhotosBasePath]/[FeatureFolder]` (e.g. `MobilePro-InspeksiMutuAncak`, `MobilePro-SidakMutuBuah`).
- **Original folders**: `[AppPhotosBasePath]/[FeatureFolder]-HD`.
- **Legacy Paths**: Support exists for legacy external paths to ensure backward compatibility.

### Watermarking

When a photo is taken (via the [GlobalCameraWidget](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/shared/widgets/global_camera_widget.dart)), if the watermark is enabled in the configuration, a background process adds text overlays at the bottom-right corner containing:

- Feature name (e.g., "Temuan Mutu Ancak")
- Inspector username
- Formatted date-time stamp
- GPS coordinates (latitude and longitude)

---

## 2. Auto-Download Behavior

The app includes an auto-download setting that automatically exports photos to the public storage of the device upon saving inspections.

- **Settings Interface**: Managed in the [PhotoAutoDownloadSettingsPage](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/features/settings/presentation/photo_auto_download_settings_page.dart). Users can toggle auto-download on or off and choose the preferred quality mode per feature based on their user role.
- **Download Quality Modes**:
  - **HD Only**: Automatically exports only the high-resolution watermarked photo.
  - **Compress Only**: Automatically exports only the compressed/standard resolution photo.
  - **All**: Exports both versions.
  - **None**: Disables automatic exporting for that feature.
- **Device Export Destinations**:
  - **Android**: Saves files under `/storage/emulated/0/Download/Smart-MobilePro/[FeatureFolder]`. The service calls `MediaScanner.loadMedia` immediately after saving to make the exported photos instantly visible in the device's Gallery app.
  - **iOS/Others**: Saves files under the application document directory inside a folder named `Smart-MobilePro`.
- **Implementation Details**: The core logic is powered by [DeviceDownloadStorageService](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/core/services/backup/device_download_storage_service.dart).

---

## 3. Storage Cleanup Behavior

To prevent the app from consuming excessive storage space, users can run manual cleanups from the settings menu.

- **Cleanup Settings Page**: Implemented in [AppStorageCleanupPage](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/features/settings/presentation/app_storage_cleanup_page.dart).
- **Retention Threshold**: Users choose a threshold (e.g., minimum 14 days, default 30 days) to scan for old data.
- **Scan & Cleanup Logic**: Handled by [AppStorageCleanupService](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/core/services/storage/app_storage_cleanup_service.dart) and [AppPhotoCleanupHelper](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/core/services/storage/app_photo_cleanup_helper.dart).
  1. **Record Scan**: The service loads local database records older than the cutoff days across all modules (Mutu Ancak, Mutu Transport, Sidak Mutu Buah, Sidak TPH/Mutu Transport, Grading Mill, Inspeksi Gudang, and Absensi QC).
  2. **File Mapping**: It maps all associated file paths, pairing both compressed and original (`-ORI` or `-HD`) photo filenames.
  3. **Orphan File Handling**: The helper scans the physical folders for orphan photos (files that exist on disk but are no longer indexed in the database) older than the cutoff date.
  4. **Deletion**:
     - Files (records-associated + orphans) are physically deleted from storage.
     - Corresponding rows in the SQLite database are removed.
     - A SQLite `VACUUM` command is issued upon cleaning "All Features" to defragment the database file and reclaim disk space.
- **Safety Warn Check**: The UI shows a warning banner (`⚠️ X data belum/gagal upload`) if there are records marked for cleanup that have not yet successfully synced to the backend server.

---

## 4. Image Preview, Share, and Download

For interactive inspection photo previewing, the app uses a dedicated full-page screen.

- **Widget Reference**: [global_photo_preview.dart](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/shared/widgets/global_photo_preview.dart) (`showGlobalPhotoPreview` / `_GlobalPhotoPreviewPage`).
- **Zooming**: Utilizes Flutter's `InteractiveViewer` allowing pinch-to-zoom and panning gestures with scales ranging from `0.5x` to `4.0x`.
- **Download Button**:
  - Saves the currently viewed image to the public Downloads folder of the device.
  - Uses [PhotoDownloadService.savePhotoToDownloads](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/core/services/storage/photo_download_service.dart).
  - Shows a success snackbar displaying the friendly destination path (e.g. `Download/Smart-MobilePro/...`).
- **Share Button**:
  - Leverages `share_plus` to pass the image file to the native OS share sheet (allowing sending to WhatsApp, Email, etc.).
  - Uses [PhotoDownloadService.sharePhoto](file:///c:/Users/wahyu.patriaji/Project/mobile-pro/mobile-pro-app/lib/core/services/storage/photo_download_service.dart).
- **Dual Resolution (HD/Original) Actions**:
  - If an original high-resolution version (`-HD`) of the previewed image exists on the device, the UI dynamically renders secondary **"Share HD"** and **"Download HD"** buttons.
  - Selecting these actions processes/shares the original quality file rather than the compressed preview copy.
- **Delete Action**:
  - If an `onDelete` callback is passed (for example, in forms where photos can be updated), a "Hapus Foto" action button is provided at the bottom of the page.
