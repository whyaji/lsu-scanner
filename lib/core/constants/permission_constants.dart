/// RBAC permission slugs — must match backend `permissions.enum.ts`.
abstract final class PermissionConstants {
  static const String dashboard = 'dashboard';

  static const String lsuMobileTerima = 'lsu:mobile-terima';
  static const String lsuMobileSelesai = 'lsu:mobile-selesai';

  static const String pupukMobileKirimEstate = 'pupuk:mobile-kirim-estate';
  static const String pupukMobileKirimLab = 'pupuk:mobile-kirim-lab';
  static const String pupukMobileKirimSertifikat =
      'pupuk:mobile-kirim-sertifikat';
}
