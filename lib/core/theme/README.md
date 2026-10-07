# SampleTrack Design System

## Theme System

- **Light / Dark / System**: User can choose in **Settings → Tampilan**.
- **Persistence**: Theme choice is stored via `SharedPreferences` and applied on next launch.
- **Central config**: `lib/core/theme/app_theme.dart` defines `AppTheme.light` and `AppTheme.dark` using Material 3 `ColorScheme`.

## Design Tokens

- **Spacing (8pt grid)**: `lib/core/theme/app_spacing.dart`  
  Use `AppSpacing.md`, `AppSpacing.paddingScreen`, `AppSpacing.gapMd`, etc.
- **Typography**: Prefer `Theme.of(context).textTheme` and `AppTypography` helpers in `lib/core/theme/app_typography.dart` when needed.
- **Sizes and radii**: `lib/core/theme/app_sizes.dart` (tap target 48, card 12, field 10, button 12, chip 8, dialog 16).
- **Semantic colors**: `AppSemanticColors` (`app_semantic_colors.dart`, registered in both themes) for success, info, warning and error. Resolve through `AppNoticeType.resolve(context)`.
- **New widget set and rules**: `docs/design-system.md` (feedback, buttons, layout, forms, display under `lib/widgets/<group>/`).

## Reusable UI Components

| Widget                    | Path                                  | Use                                                 |
| ------------------------- | ------------------------------------- | --------------------------------------------------- |
| `AppEmptyState`           | `lib/widgets/display/app_empty_state.dart`    | Empty lists with icon + title (+ optional message)  |
| `AppLoadingState`         | `lib/widgets/display/app_loading_state.dart`  | Shimmer list placeholder while loading              |
| `AppErrorState`           | `lib/widgets/display/app_error_state.dart`    | Error message + optional retry                      |
| `AppStatCard`             | `lib/widgets/display/app_stat_card.dart`      | Dashboard stat tiles (e.g. Menunggu / Terunggah)    |
| `AppSettingsTile`         | `lib/widgets/app_settings_tile.dart`          | Settings row with icon, title, subtitle, tap        |
| `AppButton`               | `lib/widgets/buttons/app_button.dart`         | Primary button with optional icon/loading           |

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
  widgets/         # Shared UI grouped by buttons, display, feedback, forms, layout, scanner
```

## Redesigned Screens (examples)

- **Settings**: Theme selector (Terang / Gelap / Sistem), profile card, regional tile, logout; uses `AppSettingsTile` and theme colors.
- **Home**: Welcome text and sample type cards using `AppSpacing` and `colorScheme`.
- **LSU Home / Fertilizer Home**: Welcome card, `AppStatCard` for Menunggu/Terunggah, themed buttons.
- **Login**: Themed form, primary button, and snackbar.
- **Received list / Sampel Pupuk list**: `AppLoadingState` (shimmer), `AppEmptyState`, and list cards using theme and `AppSpacing`.

All other screens should be migrated to use `Theme.of(context).colorScheme` and `textTheme` instead of `AppColors` and hardcoded styles for full light/dark support.
