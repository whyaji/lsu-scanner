import 'package:flutter/material.dart';

import '../../pupuk/constants/data_sampel_pupuk_progress.dart';

class NotificationTypeUi {
  const NotificationTypeUi({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

NotificationTypeUi notificationTypeUiFor(String type) {
  switch (type) {
    case 'dikirim_estate':
      return _fromProgress(DataSampelPupukProgress.dikirimEstate);
    case 'dikirim_lab':
      return _fromProgress(DataSampelPupukProgress.dikirimLab);
    case 'registrasi_lab':
      return _fromProgress(DataSampelPupukProgress.registrasiLab);
    case 'estimasi_kupa':
      return _fromProgress(DataSampelPupukProgress.estimasiKupa);
    case 'sertifikat_lab_rilis':
      return _fromProgress(DataSampelPupukProgress.sertifikatLabRilis);
    case 'sertifikat':
      return _fromProgress(DataSampelPupukProgress.sertifikatTerkirim);
    default:
      return const NotificationTypeUi(
        icon: Icons.notifications_outlined,
        color: Colors.blueGrey,
        label: 'Notifikasi',
      );
  }
}

NotificationTypeUi _fromProgress(DataSampelPupukProgress progress) {
  final tab = tabForProgress(progress);
  return NotificationTypeUi(icon: tab.icon, color: tab.color, label: tab.label);
}
