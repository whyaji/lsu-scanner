/// Single source of truth for the current (latest) table layout.
///
/// A fresh install executes [createStatements]; upgrades execute the versioned
/// migrations, which reuse the same constants for every table or column they
/// add. Both paths therefore end in the same schema (see
/// `test/core/database/migrations_test.dart`).
abstract final class Schema {
  static const String masterSampel = '''
    CREATE TABLE master_sampel (
      id INTEGER PRIMARY KEY,
      nama TEXT NOT NULL,
      created_at TEXT,
      updated_at TEXT
    )
  ''';

  static const String masterLsu = '''
    CREATE TABLE master_lsu (
      id INTEGER PRIMARY KEY,
      regional INTEGER NOT NULL,
      pt TEXT,
      status_kebun TEXT,
      estate TEXT,
      wilayah INTEGER,
      afdeling TEXT,
      blok TEXT,
      group_blok TEXT,
      tahun_tanam INTEGER,
      varietas TEXT,
      jenis_tanah TEXT,
      topografi TEXT,
      luas_ha TEXT,
      jml_pokok INTEGER,
      jml_pokok_produktif INTEGER,
      sph INTEGER,
      created_at TEXT,
      updated_at TEXT
    )
  ''';

  /// `data_lsu_id` is unique to prevent duplicate receives.
  static const String receivedSample = '''
    CREATE TABLE received_sample (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_lsu_id INTEGER NOT NULL UNIQUE,
      master_lsu_id INTEGER NOT NULL,
      kode TEXT NOT NULL,
      tanggal_terima TEXT NOT NULL,
      waktu_terima TEXT NOT NULL,
      foto_path TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'not_uploaded',
      error_message TEXT,
      user_id INTEGER,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (master_lsu_id) REFERENCES master_lsu(id)
    )
  ''';

  static const String completedSample = '''
    CREATE TABLE completed_sample (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_lsu_id INTEGER NOT NULL UNIQUE,
      master_lsu_id INTEGER NOT NULL,
      kode TEXT NOT NULL,
      tanggal_selesai TEXT NOT NULL,
      waktu_selesai TEXT NOT NULL,
      foto_path TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'not_uploaded',
      error_message TEXT,
      user_id INTEGER,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (master_lsu_id) REFERENCES master_lsu(id)
    )
  ''';

  static const String userPreferences = '''
    CREATE TABLE user_preferences (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  /// Columns appended to `data_sampel_pupuk` by migration v3. They sit after
  /// `updated_at` in [dataSampelPupuk] so an `ALTER TABLE ADD COLUMN` upgrade
  /// produces the same column order as a fresh install.
  static const Map<String, String> dataSampelPupukV3Columns = {
    'registrasi_lab_by': 'INTEGER',
    'pupuk_lab_terima_id': 'INTEGER',
  };

  static String get dataSampelPupuk =>
      '''
    CREATE TABLE data_sampel_pupuk (
      id INTEGER PRIMARY KEY,
      kode_sampel TEXT,
      jenis_pupuk_full TEXT,
      jenis_pupuk TEXT,
      merek TEXT,
      no_kode_sampel INTEGER,
      jumlah_sampel_zak INTEGER,
      no_segel TEXT,
      no_ba_sampel_pupuk TEXT,
      supplier TEXT,
      regional INTEGER,
      wilayah INTEGER,
      estate TEXT,
      pt TEXT,
      no_po TEXT,
      no_bpb TEXT,
      qty_partai_pengiriman INTEGER,
      qty_terima INTEGER,
      jenis_kendaraan TEXT,
      tanggal_pengambilan_sampel TEXT,
      check_logo_perusahaan TEXT,
      check_kondisi_karung TEXT,
      check_jahitan_karung TEXT,
      check_kontaminan TEXT,
      check_jenis_kontaminan TEXT,
      check_persentase_kontaminan TEXT,
      check_bekas_gancu TEXT,
      diperiksa_estate_manager_nama TEXT,
      diperiksa_ktu_nama TEXT,
      disaksikan_supplier_nama TEXT,
      diambil_kepala_gudang TEXT,
      tanggal_terima_dari_gudang TEXT,
      foto_terima_dari_gudang TEXT,
      tanggal_kirim_dari_estate TEXT,
      foto_kirim_dari_estate TEXT,
      tanggal_terima_dari_estate TEXT,
      foto_terima_dari_estate TEXT,
      nama_pengirim TEXT,
      no_surat TEXT,
      tanggal_kirim_lab TEXT,
      foto_kirim_lab TEXT,
      tanggal_registrasi_lab TEXT,
      foto_registrasi_lab TEXT,
      tanggal_estimasi_kupa TEXT,
      kode_tracking TEXT,
      no_sertifikat TEXT,
      tanggal_kirim_sertifikat_estate TEXT,
      rekomendasi TEXT,
      tracking_sampel_pupuk TEXT,
      created_at TEXT,
      updated_at TEXT,
      ${dataSampelPupukV3Columns.entries.map((e) => '${e.key} ${e.value}').join(',\n      ')}
    )
  ''';

  static const String kirimDariEstate = '''
    CREATE TABLE kirim_dari_estate (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_sampel_pupuk_id INTEGER NOT NULL,
      kode_sampel TEXT NOT NULL,
      tanggal_kirim_dari_estate TEXT NOT NULL,
      foto_kirim_dari_estate TEXT,
      nama_pengirim TEXT,
      status TEXT NOT NULL DEFAULT 'not_uploaded',
      error_message TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  static const String kirimLab = '''
    CREATE TABLE kirim_lab (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_sampel_pupuk_id INTEGER NOT NULL,
      kode_sampel TEXT NOT NULL,
      no_surat TEXT,
      tanggal_kirim_lab TEXT NOT NULL,
      foto_kirim_lab TEXT,
      status TEXT NOT NULL DEFAULT 'not_uploaded',
      error_message TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  static const String kirimSertifikatEstate = '''
    CREATE TABLE kirim_sertifikat_estate (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_sampel_pupuk_id INTEGER NOT NULL,
      kode_sampel TEXT NOT NULL,
      tanggal_kirim_sertifikat_estate TEXT NOT NULL,
      rekomendasi TEXT,
      file_sertifikat TEXT,
      status TEXT NOT NULL DEFAULT 'not_uploaded',
      error_message TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  /// Offline Terima Lab receipt. `samples_json`, `form_json` and
  /// `foto_paths_json` hold the camelCase upload shapes (see `PupukLab`).
  static const String pupukLab = '''
    CREATE TABLE pupuk_lab (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      client_uuid TEXT NOT NULL UNIQUE,
      no_surat TEXT NOT NULL,
      samples_json TEXT NOT NULL,
      form_json TEXT NOT NULL,
      foto_paths_json TEXT,
      status TEXT NOT NULL DEFAULT 'not_uploaded',
      error_message TEXT,
      kode_track TEXT,
      nomor_lab TEXT,
      nomor_kupa INTEGER,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      error_retryable INTEGER NOT NULL DEFAULT 1
    )
  ''';

  /// Added to `pupuk_lab` in v4. 0 marks a permanent SmartLab rejection that
  /// only an edit can fix, so uploads skip the row until then.
  static const Map<String, String> pupukLabV4Columns = {
    'error_retryable': 'INTEGER NOT NULL DEFAULT 1',
  };

  /// Cached SmartLab master data; a single row with key `master`.
  static const String pupukLabMaster = '''
    CREATE TABLE pupuk_lab_master (
      key TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      version TEXT,
      synced_at TEXT NOT NULL
    )
  ''';

  /// Reusable values shown in email and WhatsApp form suggestions.
  /// Uniqueness is based on the normalized value, while `value` preserves the
  /// display value used by the user.
  static const String formCompletionSuggestions = '''
    CREATE TABLE form_completion_suggestions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL CHECK (type IN ('email', 'whatsapp')),
      value TEXT NOT NULL,
      normalized_value TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE (type, normalized_value)
    )
  ''';

  /// Tables dropped in v3 (never read or written by any code).
  static const List<String> legacyTablesDroppedInV3 = [
    'terima_dari_gudang',
    'terima_dari_estate',
  ];

  static List<String> get createStatements => [
    masterSampel,
    masterLsu,
    receivedSample,
    completedSample,
    userPreferences,
    dataSampelPupuk,
    kirimDariEstate,
    kirimLab,
    kirimSertifikatEstate,
    pupukLab,
    pupukLabMaster,
    formCompletionSuggestions,
  ];
}
