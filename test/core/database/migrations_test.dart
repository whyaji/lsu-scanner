import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/core/database/migrations/migrations.dart';
import 'package:sampletrack/core/database/migrations/schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/legacy_schema_v2.dart';

Future<Map<String, Object?>> schemaOf(Database db) async {
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  final schema = <String, Object?>{};
  for (final t in tables) {
    final name = t['name'] as String;
    final columns = await db.rawQuery('PRAGMA table_info($name)');
    final foreignKeys = await db.rawQuery('PRAGMA foreign_key_list($name)');
    final indexes = await db.rawQuery('PRAGMA index_list($name)');
    schema[name] = {
      'columns': [
        for (final c in columns)
          '${c['cid']}:${c['name']}:${c['type']}:${c['notnull']}:'
              '${c['dflt_value']}:${c['pk']}',
      ],
      'foreignKeys': [
        for (final f in foreignKeys) '${f['table']}.${f['from']}>${f['to']}',
      ],
      'indexes': [
        for (final i in indexes) '${i['name']}:${i['unique']}:${i['origin']}',
      ],
    };
  }
  return schema;
}

/// Column sets without positions, for upgrades from builds that added a column
/// with ALTER TABLE (it lands at the end of the table).
Map<String, Object?> withoutColumnOrder(Map<String, Object?> schema) {
  return schema.map((table, value) {
    final copy = Map<String, Object?>.from(value! as Map<String, Object?>);
    final columns = [
      for (final c in copy['columns']! as List<String>)
        c.substring(c.indexOf(':') + 1),
    ]..sort();
    copy['columns'] = columns;
    return MapEntry(table, copy);
  });
}

void main() {
  late Directory tempDir;
  late String dbPath;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('sampletrack_migration_');
    dbPath = p.join(tempDir.path, 'test.db');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> createLegacy({
    required int version,
    List<String> statements = legacyV2CreateStatements,
    Future<void> Function(Database db)? seed,
  }) async {
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, _) async {
          for (final statement in statements) {
            await db.execute(statement);
          }
          await seed?.call(db);
        },
      ),
    );
    await db.close();
  }

  Future<Database> upgraded() async {
    final appDb = AppDatabase(factory: databaseFactoryFfi, path: dbPath);
    return appDb.database;
  }

  Future<Database> fresh() {
    final path = p.join(tempDir.path, 'fresh.db');
    return AppDatabase(factory: databaseFactoryFfi, path: path).database;
  }

  test('migrations are contiguous from 2 and end at the database version', () {
    expect(kMigrations.first.version, 2);
    for (var i = 1; i < kMigrations.length; i++) {
      expect(kMigrations[i].version, kMigrations[i - 1].version + 1);
    }
    expect(kDatabaseVersion, kMigrations.last.version);
    expect(kDatabaseVersion, 5);
  });

  test('fresh install creates v5 tables and no legacy tables', () async {
    final db = await fresh();
    final schema = await schemaOf(db);

    expect(await db.getVersion(), 5);
    expect(
      schema.keys,
      containsAll([
        'pupuk_lab',
        'pupuk_lab_master',
        'form_completion_suggestions',
      ]),
    );
    for (final legacy in Schema.legacyTablesDroppedInV3) {
      expect(schema.keys, isNot(contains(legacy)));
    }
    await db.close();
  });

  test(
    'upgrade v2 to v5 produces the same schema as a fresh install',
    () async {
      await createLegacy(version: 2);
      final upgradedDb = await upgraded();
      final upgradedSchema = await schemaOf(upgradedDb);
      expect(await upgradedDb.getVersion(), 5);
      await upgradedDb.close();

      final freshDb = await fresh();
      final freshSchema = await schemaOf(freshDb);
      await freshDb.close();

      expect(upgradedSchema, freshSchema);
    },
  );

  test(
    'upgrade v3 to v5 keeps receipts retryable and matches a fresh install',
    () async {
      final v3Path = p.join(tempDir.path, 'v3.db');
      final v3 = await databaseFactoryFfi.openDatabase(
        v3Path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, _) async {
            for (final statement in legacyV2CreateStatements) {
              await db.execute(statement);
            }
            await upgradeDatabase(db, 2, 3);
            await db.insert('pupuk_lab', {
              'client_uuid': 'u-v3',
              'no_surat': 'S/3',
              'samples_json': '[]',
              'form_json': '{}',
              'status': 'error',
              'error_message': 'lama',
              'created_at': '2026-10-05T10:00:00',
            });
          },
        ),
      );
      await v3.close();

      final upgradedDb = await AppDatabase(
        factory: databaseFactoryFfi,
        path: v3Path,
      ).database;
      final row = (await upgradedDb.query('pupuk_lab')).single;
      expect(await upgradedDb.getVersion(), 5);
      expect(row['error_retryable'], 1);
      expect(row['error_message'], 'lama');
      final upgradedSchema = await schemaOf(upgradedDb);
      await upgradedDb.close();

      final freshDb = await fresh();
      final freshSchema = await schemaOf(freshDb);
      await freshDb.close();

      expect(upgradedSchema, freshSchema);
    },
  );

  test(
    'upgrade from v1 (no tracking column) matches modulo column order',
    () async {
      final v1 = [
        for (final s in legacyV2CreateStatements)
          s.replaceFirst('tracking_sampel_pupuk TEXT,', ''),
      ];
      await createLegacy(version: 1, statements: v1);
      final upgradedDb = await upgraded();
      final upgradedSchema = await schemaOf(upgradedDb);
      await upgradedDb.close();

      final freshDb = await fresh();
      final freshSchema = await schemaOf(freshDb);
      await freshDb.close();

      expect(
        withoutColumnOrder(upgradedSchema),
        withoutColumnOrder(freshSchema),
      );
    },
  );

  test(
    'upgrade keeps existing rows and defaults the new columns to null',
    () async {
      await createLegacy(
        version: 2,
        seed: (db) async {
          await db.insert('data_sampel_pupuk', {
            'id': 7,
            'kode_sampel': 'W-007',
            'tracking_sampel_pupuk': '[["W-007","S/1",null,null]]',
          });
          await db.insert('kirim_lab', {
            'data_sampel_pupuk_id': 7,
            'kode_sampel': 'W-007',
            'tanggal_kirim_lab': '2026-10-01',
            'created_at': '2026-10-01T08:00:00',
          });
          await db.insert('user_preferences', {'key': 'k', 'value': 'v'});
          await db.insert('terima_dari_gudang', {
            'data_sampel_pupuk_id': 7,
            'kode_sampel': 'W-007',
            'tanggal_terima_dari_gudang': '2026-10-01',
            'created_at': '2026-10-01T08:00:00',
          });
        },
      );

      final db = await upgraded();
      final sample = (await db.query('data_sampel_pupuk')).single;
      expect(sample['kode_sampel'], 'W-007');
      expect(sample['tracking_sampel_pupuk'], '[["W-007","S/1",null,null]]');
      expect(sample['registrasi_lab_by'], isNull);
      expect(sample['pupuk_lab_terima_id'], isNull);
      expect(await db.query('kirim_lab'), hasLength(1));
      expect(await db.query('user_preferences'), hasLength(1));

      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      )).map((r) => r['name']);
      expect(tables, isNot(contains('terima_dari_gudang')));
      expect(tables, isNot(contains('terima_dari_estate')));
      await db.close();
    },
  );

  test('upgrade tolerates a column that already exists', () async {
    final withColumns = [
      for (final s in legacyV2CreateStatements)
        s.contains('CREATE TABLE data_sampel_pupuk')
            ? s.replaceFirst(
                RegExp(r'updated_at TEXT\s*\)'),
                'updated_at TEXT, registrasi_lab_by INTEGER)',
              )
            : s,
    ];
    await createLegacy(version: 2, statements: withColumns);

    final db = await upgraded();
    final columns = (await db.rawQuery(
      'PRAGMA table_info(data_sampel_pupuk)',
    )).map((c) => c['name']).toList();

    expect(columns.where((c) => c == 'registrasi_lab_by'), hasLength(1));
    expect(columns, contains('pupuk_lab_terima_id'));
    await db.close();
  });

  test('pupuk_lab enforces unique client_uuid and defaults status', () async {
    final db = await fresh();
    final row = {
      'client_uuid': 'u-1',
      'no_surat': 'S/1',
      'samples_json': '[]',
      'form_json': '{}',
      'created_at': '2026-10-06T10:00:00',
    };
    await db.insert('pupuk_lab', row);
    expect(
      () => db.insert('pupuk_lab', row),
      throwsA(isA<DatabaseException>()),
    );
    expect((await db.query('pupuk_lab')).single['status'], 'not_uploaded');
    await db.close();
  });
}
