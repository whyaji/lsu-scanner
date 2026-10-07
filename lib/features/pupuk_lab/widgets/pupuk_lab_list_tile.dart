import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/display/app_list_item.dart';
import '../../../widgets/display/app_status_chip.dart';
import '../models/pupuk_lab.dart';
import 'pupuk_lab_status.dart';

/// One Terima Lab receipt in a list of local rows.
class PupukLabListTile extends StatelessWidget {
  const PupukLabListTile({super.key, required this.row, this.onTap});

  final PupukLab row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = pupukLabStatusOf(row);
    final count = row.samples.length;
    final first = row.samples.isEmpty ? '' : row.samples.first.kodeSampel;
    final received = DateTime.tryParse(row.createdAt);
    final subtitle = [
      count == 1 ? first : '$count sampel',
      if (received != null) DateFormat('d MMM y, HH:mm', 'id').format(received),
    ].join(' · ');

    return AppListItem(
      title: 'Terima Lab ${row.noSurat}',
      subtitle: subtitle,
      trailing: AppStatusChip(label: status.text, type: status.type),
      onTap: onTap,
    );
  }
}
