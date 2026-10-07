# Changelog

## Unreleased

### Added

- Pupuk Lab role support and offline-first Terima Lab receipt flow.
- SmartLab master-data cache for fertilizer lab forms.
- Reusable dialog, banner, toast, form, layout, and journey-track widgets.
- Versioned SQLite migrations and domain-specific DAOs.
- Domain-specific API classes and strategy-based upload processing.

### Changed

- Fertilizer lab receipts now forward through SampleTrack to SmartLab.
- Feedback uses dialogs, banners, and toasts instead of SnackBar.
- Login and fertilizer home screens use the shared design-system widgets.
- Theme tokens support accessible light and dark semantic colors.

### Fixed

- Pupuk Lab-only users no longer require regional selection.
- Local receipt retries distinguish permanent validation failures from retryable network failures.
- Deprecated Flutter color and form-field APIs were removed.
