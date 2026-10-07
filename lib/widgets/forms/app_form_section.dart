import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../layout/app_section.dart';

/// Titled group of form fields with the standard 16 gap between fields.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppSection(
      title: title,
      description: description,
      gap: AppSpacing.fieldGap,
      children: children,
    );
  }
}
