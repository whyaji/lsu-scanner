# SampleTrack Design System

## Theme System

- **Light / Dark / System**: User can choose in **Settings → Tampilan**.
- **Persistence**: Theme choice is stored via `SharedPreferences` and applied on next launch.
- **Central config**: `lib/core/theme/app_theme.dart` defines `AppTheme.light` and `AppTheme.dark` using Material 3 `ColorScheme`.

## Design Tokens

- **Spacing (8pt grid)**: `lib/core/theme/app_spacing.dart`  
  Use `AppSpacing.md`, `AppSpacing.paddingScreen`, `AppSpacing.gapMd`, etc.
- **Typography**: Prefer `Theme.of(context).textTheme` and `AppTypography` helpers in `lib/core/theme/app_typography.dart` when needed.

## Reusable UI Components

| Widget                    | Path                                  | Use                                                 |
| ------------------------- | ------------------------------------- | --------------------------------------------------- |
| `AppEmptyState`           | `lib/widgets/app_empty_state.dart`    | Empty lists with icon + title (+ optional subtitle) |
| `AppLoadingState`         | `lib/widgets/app_loading_state.dart`  | Shimmer list placeholder while loading              |
| `AppErrorState`           | `lib/widgets/app_error_state.dart`    | Error message + optional retry                      |
| `AppStatCard`             | `lib/widgets/app_stat_card.dart`      | Dashboard stat tiles (e.g. Menunggu / Terunggah)    |
| `AppSettingsTile`         | `lib/widgets/app_settings_tile.dart`  | Settings row with icon, title, subtitle, tap        |
| `CustomButton`            | `lib/widgets/custom_button.dart`      | Primary button with optional icon/loading           |
| `SampleCard`              | `lib/widgets/sample_card.dart`        | Sample list card using theme colors                 |
| `CustomProgressIndicator` | `lib/widgets/progress_indicator.dart` | Upload progress card                                |

## Using the Theme in Screens

- Use `Theme.of(context).colorScheme` for colors (e.g. `colorScheme.primary`, `colorScheme.onSurface`, `colorScheme.error`).
- Use `Theme.of(context).textTheme` for text styles.
- Use `AppSpacing` for padding and gaps instead of magic numbers.
- Avoid hardcoded `AppColors` for background/surface/text; reserve for legacy or semantic status where needed.

## Folder Structure (relevant to UI)

```
lib/
  core/
    constants/     # AppConstants, AppColors (legacy)
    theme/         # app_theme.dart, app_spacing.dart, app_typography.dart
  features/
    settings/
      providers/   # theme_provider.dart
      screens/     # settings_screen.dart (theme selector)
  widgets/         # Shared UI: app_empty_state, app_loading_state, app_stat_card, etc.
```

## Redesigned Screens (examples)

- **Settings**: Theme selector (Terang / Gelap / Sistem), profile card, regional tile, logout; uses `AppSettingsTile` and theme colors.
- **Home**: Welcome text and sample type cards using `AppSpacing` and `colorScheme`.
- **LSU Home / Fertilizer Home**: Welcome card, `AppStatCard` for Menunggu/Terunggah, themed buttons.
- **Login**: Themed form, primary button, and snackbar.
- **Received list / Sampel Pupuk list**: `AppLoadingState` (shimmer), `AppEmptyState`, and list cards using theme and `AppSpacing`.

All other screens should be migrated to use `Theme.of(context).colorScheme` and `textTheme` instead of `AppColors` and hardcoded styles for full light/dark support.
