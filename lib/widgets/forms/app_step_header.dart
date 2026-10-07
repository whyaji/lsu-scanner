import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';

/// Step name plus the segmented progress bar.
/// currentStep is 1-based. Finished segments are tappable and call onStepTap with their 1-based number.
/// Use [AppStepTrack] alone when the bar should stay pinned and the name should scroll.
class AppStepHeader extends StatelessWidget {
  const AppStepHeader({
    super.key,
    required this.currentStep,
    required this.stepLabels,
    this.onStepTap,
  });

  final int currentStep;
  final List<String> stepLabels;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = stepLabels[currentStep - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AppStepTrack(
          currentStep: currentStep,
          stepLabels: stepLabels,
          onStepTap: onStepTap,
        ),
      ],
    );
  }
}

/// Segmented progress bar only. currentStep is 1-based.
class AppStepTrack extends StatelessWidget {
  const AppStepTrack({
    super.key,
    required this.currentStep,
    required this.stepLabels,
    this.onStepTap,
    this.height = AppSizes.tapTarget,
  });

  final int currentStep;
  final List<String> stepLabels;
  final ValueChanged<int>? onStepTap;
  final double height;

  int get totalSteps => stepLabels.length;

  @override
  Widget build(BuildContext context) {
    assert(currentStep >= 1 && currentStep <= totalSteps);

    return Row(
      children: [
        for (var i = 1; i <= totalSteps; i++) ...[
          if (i > 1) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _Segment(step: i, track: this),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.step, required this.track});

  final int step;
  final AppStepTrack track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = step < track.currentStep;
    final current = step == track.currentStep;
    final tappable = done && track.onStepTap != null;

    final bar = Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: current ? 6 : 4,
        decoration: BoxDecoration(
          color: done || current
              ? scheme.primary
              : scheme.outline.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );

    final box = SizedBox(height: track.height, child: bar);
    if (!tappable) {
      return ExcludeSemantics(child: box);
    }
    return Semantics(
      button: true,
      label: 'Kembali ke langkah $step: ${track.stepLabels[step - 1]}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
        onTap: () => track.onStepTap!(step),
        child: box,
      ),
    );
  }
}
