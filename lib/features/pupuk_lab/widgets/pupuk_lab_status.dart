import '../../../widgets/feedback/app_notice_type.dart';
import '../models/pupuk_lab.dart';

/// What the user needs to know about a receipt's upload state, in one place so
/// the list, the detail screen and the upload results say the same thing.
class PupukLabStatusLabel {
  const PupukLabStatusLabel(this.text, this.type);

  final String text;
  final AppNoticeType type;
}

PupukLabStatusLabel pupukLabStatusOf(PupukLab row) {
  if (row.isUploaded) {
    return const PupukLabStatusLabel('Terunggah', AppNoticeType.success);
  }
  if (row.needsEdit) {
    return const PupukLabStatusLabel('Perlu diubah', AppNoticeType.error);
  }
  if (row.errorMessage != null) {
    return const PupukLabStatusLabel(
      'Gagal, akan diulang',
      AppNoticeType.warning,
    );
  }
  return const PupukLabStatusLabel('Menunggu unggah', AppNoticeType.info);
}
