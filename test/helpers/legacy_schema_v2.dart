/// Frozen copy of the database schema as shipped at version 2 (before
/// AppDatabase). Upgrade tests start from it; do not edit.
const List<String> legacyV2CreateStatements = [
  '''
      CREATE TABLE master_sampel (
        id INTEGER PRIMARY KEY,
        nama TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
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
    ''',
  '''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT
      )
    ''',
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
        updated_at TEXT
      )
    ''',
  '''
      CREATE TABLE terima_dari_gudang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_sampel_pupuk_id INTEGER NOT NULL,
        kode_sampel TEXT NOT NULL,
        tanggal_terima_dari_gudang TEXT NOT NULL,
        foto_terima_dari_gudang TEXT,
        status TEXT NOT NULL DEFAULT 'not_uploaded',
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''',
  '''
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
    ''',
  '''
      CREATE TABLE terima_dari_estate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_sampel_pupuk_id INTEGER NOT NULL,
        kode_sampel TEXT NOT NULL,
        tanggal_terima_dari_estate TEXT NOT NULL,
        foto_terima_dari_estate TEXT,
        status TEXT NOT NULL DEFAULT 'not_uploaded',
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''',
  '''
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
    ''',
  '''
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
    ''',
];
