# App Development Guide

This document provides comprehensive development guidelines for the SampleTrack application.

## Table of Contents

1. [Overview](#overview)
2. [App Flow](#app-flow)
3. [Core Features](#core-features)
4. [Database Schema](#database-schema)
5. [Recommended Libraries](#recommended-libraries)
6. [Implementation Guidelines](#implementation-guidelines)
7. [UI/UX Guidelines](#uiux-guidelines)
8. [API Integration](#api-integration)
9. [Testing Guidelines](#testing-guidelines)

---

## Overview

The SampleTrack application is a Flutter-based mobile app designed for field officers to:

- Scan QR codes to receive sample data
- Capture photos of samples
- Store data locally for offline functionality
- Upload data and photos to the server with progress tracking

### Key Requirements

- **Regional Selection**: After login, users select regional (1-5)
- **Data Sync**: Sync `masterSampel` and `masterLsu` from API
- **Local Storage**: Store all master data and received samples locally
- **QR Code Scanning**: Scan QR codes with format `"$ID;$MASTER_LSU_ID;$KODE"`
- **Photo Capture**: Take photos of samples
- **Offline Support**: Work offline and sync when online
- **Upload with Progress**: Upload data and photos with progress tracking

---

## App Flow

### 1. Authentication Flow

```
App Launch
    ↓
Check Stored Tokens
    ↓
[No Tokens/Expired] → Login Screen
    ↓
[Valid Tokens] → Check Regional Selection
    ↓
[No Regional] → Regional Selection Screen
    ↓
[Regional Selected] → Home/Dashboard
```

### 2. Post-Login Flow

```
Login Success
    ↓
Regional Selection Screen (1-5)
    ↓
User Selects Regional
    ↓
Sync Data (masterSampel + masterLsu)
    ↓
Store to Local Database
    ↓
Navigate to Home/Dashboard
```

### 3. QR Code Scanning Flow

```
Home Screen
    ↓
Tap "Scan QR Code"
    ↓
QR Scanner Opens
    ↓
Scan QR Code: "56;3;NBE 123R"
    ↓
Parse: ID=56, MASTER_LSU_ID=3, KODE="NBE 123R"
    ↓
Fetch Master Data from Local DB
    ↓
Display Sample Detail Screen
    ↓
Tap "Take Photo"
    ↓
Camera Opens
    ↓
Capture Photo
    ↓
Confirmation Screen (with all details)
    ↓
Tap "Save"
    ↓
Store to Local DB (received_sample table)
    Status: "not_uploaded"
```

### 4. Upload Flow

```
Home Screen / Upload Screen
    ↓
Tap "Upload"
    ↓
Fetch all samples with status: "not_uploaded" or "error"
    ↓
Step 1: Batch Upload Data
    POST /api/data-lsu/upload
    ↓
Get Response: { success: [...], failed: [...] }
    ↓
Step 2: Upload Photos (for success items only)
    For each success item:
        POST /api/upload/photo
        Show Progress Bar & Percentage
    ↓
Update Local DB:
    - Success items: status = "uploaded"
    - Failed items: status = "error", error_message = "..."
    ↓
Show Upload Summary
```

### 5. Regional Change Flow

```
Settings / Profile Screen
    ↓
Tap "Change Regional"
    ↓
Regional Selection Screen
    ↓
User Selects New Regional
    ↓
Clear Existing Master Data
    ↓
Sync New Regional Data
    ↓
Store to Local Database
    ↓
Update User Preference
```

---

## Core Features

### 1. Regional Selection

**Screen**: `RegionalSelectionScreen`

**Functionality**:

- Display 5 regional options (1-5)
- Allow user to select one regional
- After selection, automatically trigger data sync
- Show loading indicator during sync
- Store selected regional in local preferences

**UI Elements**:

- Card-based selection (modern, clean design)
- Regional number and description
- Selected state indicator
- Sync progress indicator

### 2. Data Sync

**Functionality**:

- Call API: `GET /api/mobile/sync?regional={selected}`
- Receive: `masterSampel[]` and `masterLsu[]`
- Store to local database tables:
  - `master_sampel` table
  - `master_lsu` table
- Replace existing data (not append)
- Show sync status and last sync time

**Sync Triggers**:

- After regional selection
- Manual sync from settings
- Pull-to-refresh on home screen

### 3. QR Code Scanning

**Screen**: `QRScannerScreen`

**Functionality**:

- Open camera for QR scanning
- Parse QR code format: `"$ID;$MASTER_LSU_ID;$KODE"`
- Example: `"56;3;NBE 123R"`
- Validate QR code format
- Extract: `id`, `masterLsuId`, `kode`
- Fetch master data from local database using `masterLsuId`
- Navigate to sample detail screen

**Error Handling**:

- Invalid QR format → Show error message
- Master LSU not found → Show error message
- Network error → Use local data only

### 4. Sample Detail Screen

**Screen**: `SampleDetailScreen`

**Displays**:

- Master LSU information:
  - PT, Estate, Wilayah, Afdeling
  - Blok, Group Blok
  - Tahun Tanam, Varietas
  - Jenis Tanah, Topografi
  - Luas Ha, Jumlah Pokok
- Sample ID and Kode
- "Take Photo" button

### 5. Photo Capture

**Functionality**:

- Open device camera
- Allow user to capture photo
- Show preview of captured photo
- Allow retake if needed
- Compress image if needed (max 10MB)
- Store photo path locally

### 6. Confirmation Screen

**Screen**: `ConfirmationScreen`

**Displays**:

- All sample details (from master LSU)
- Captured photo preview
- Date and time (auto-filled, editable)
- "Save" button
- "Cancel" button

**On Save**:

- Create record in `received_sample` table
- Fields:
  - `id` (from QR code)
  - `master_lsu_id`
  - `kode`
  - `tanggal_terima` (current date)
  - `waktu_terima` (current time)
  - `foto_path` (local file path)
  - `status` = "not_uploaded"
  - `created_at` (timestamp)
  - `user_id` (from auth)

### 7. Upload Feature

**Screen**: `UploadScreen`

**Functionality**:

- Fetch all samples with `status IN ('not_uploaded', 'error')`
- Display list of pending uploads
- "Upload All" button
- Progress indicator:
  - Overall progress bar
  - Percentage (e.g., "3/10 uploaded - 30%")
  - Current item being uploaded
  - Success/failed count

**Upload Process**:

**Step 1: Batch Upload Data**

```
POST /api/data-lsu/upload
Body: [
  {
    "id": 56,
    "masterLsuId": 3,
    "kode": "NBE 123R",
    "foto": "photoxxxxxxx.jpg",
    "tanggalTerima": "2026-01-23",
    "waktuTerima": "15:34:01"
  },
  ...
]
```

**Step 2: Upload Photos (for success items)**

```
For each item in success list:
  POST /api/upload/photo
  FormData:
    - file: [photo file]
    - dataLsuId: 56
    - kode: "NBE 123R"

  Show progress:
    - Photo 1/5 uploading... (20%)
    - Photo 2/5 uploading... (40%)
    ...
```

**After Upload**:

- Update local database:
  - Success items: `status = "uploaded"`
  - Failed items: `status = "error"`, `error_message = "..."`
- Show summary:
  - Total uploaded
  - Total failed
  - List of failed items with error messages

---

## Database Schema

### Local Database Tables

#### 1. `master_sampel`

```sql
CREATE TABLE master_sampel (
  id INTEGER PRIMARY KEY,
  nama TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
);
```

#### 2. `master_lsu`

```sql
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
  sph TEXT,
  created_at TEXT,
  updated_at TEXT
);
```

#### 3. `received_sample`

```sql
CREATE TABLE received_sample (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  data_lsu_id INTEGER NOT NULL,
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
);
```

#### 4. `user_preferences`

```sql
CREATE TABLE user_preferences (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT
);
```

**Stored Keys**:

- `selected_regional`: "1", "2", "3", "4", or "5"
- `last_sync_time`: ISO timestamp
- `access_token`: JWT token
- `refresh_token`: JWT refresh token
- `user_id`: Current user ID
- `user_data`: JSON string of user object

---

## Recommended Libraries

### Core Dependencies

```yaml
dependencies:
  cached_network_image: ^3.4.1
  dio: ^5.9.0
  flutter:
    sdk: flutter
  flutter_form_builder: ^10.2.0
  flutter_image_compress: ^2.4.0
  flutter_riverpod: ^3.2.0
  flutter_secure_storage: ^10.0.0
  flutter_slidable: ^4.0.3
  flutter_spinkit: ^5.2.2
  flutter_svg: ^2.2.3
  form_builder_validators: ^11.2.0
  image: ^4.7.2
  image_picker: ^1.2.1
  intl: ^0.20.2
  mobile_scanner: ^7.1.4
  path: ^1.9.1
  path_provider: ^2.1.5
  permission_handler: ^12.0.1
  pretty_dio_logger: ^1.4.0
  riverpod: ^3.2.0
  shared_preferences: ^2.5.4
  shimmer: ^3.0.0
  sqflite: ^2.4.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### Library Recommendations by Feature

#### State Management

- **Riverpod** provide excellent state management and dependency injection

#### Local Database

- **sqflite**: SQLite database for Flutter
- **path**: Path manipulation utilities

#### HTTP Client

- **dio**: Powerful HTTP client with interceptors, error handling
- **pretty_dio_logger**: Beautiful API request/response logging

#### Storage

- **shared_preferences**: Simple key-value storage
- **flutter_secure_storage**: Secure storage for tokens (uses Keychain/Keystore)

#### QR Code

- **mobile_scanner**: Modern, maintained QR scanner

#### Camera & Images

- **image_picker**: Camera and gallery access
- **image**: Image processing and watermarking
- **flutter_image_compress**: Image compression

#### UI Enhancements

- **shimmer**: Loading placeholders
- **cached_network_image**: Efficient image caching
- **flutter_spinkit**: Beautiful loading indicators

#### Permissions

- **permission_handler**: Request camera, storage permissions

---

## Implementation Guidelines

### 1. Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── database/
│   │   ├── database_helper.dart
│   │   └── models/
│   │       ├── master_sampel.dart
│   │       ├── master_lsu.dart
│   │       └── received_sample.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_service.dart
│   │   └── interceptors/
│   │       └── auth_interceptor.dart
│   └── utils/
│       ├── date_utils.dart
│       └── image_utils.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   └── login_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   ├── regional/
│   │   ├── screens/
│   │   │   └── regional_selection_screen.dart
│   │   └── providers/
│   │       └── regional_provider.dart
│   ├── sync/
│   │   ├── screens/
│   │   │   └── sync_screen.dart
│   │   └── providers/
│   │       └── sync_provider.dart
│   ├── scanner/
│   │   ├── screens/
│   │   │   └── qr_scanner_screen.dart
│   │   └── providers/
│   │       └── scanner_provider.dart
│   ├── sample/
│   │   ├── screens/
│   │   │   ├── sample_detail_screen.dart
│   │   │   ├── photo_capture_screen.dart
│   │   │   └── confirmation_screen.dart
│   │   └── providers/
│   │       └── sample_provider.dart
│   └── upload/
│       ├── screens/
│       │   └── upload_screen.dart
│       └── providers/
│           └── upload_provider.dart
└── widgets/
    ├── custom_button.dart
    ├── progress_indicator.dart
    └── sample_card.dart
```

### 2. Database Helper Implementation

```dart
// lib/core/database/database_helper.dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sampletrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Create tables
    await db.execute('''
      CREATE TABLE master_sampel (
        id INTEGER PRIMARY KEY,
        nama TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
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
        sph TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE received_sample (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_lsu_id INTEGER NOT NULL,
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
    ''');

    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  // Master Sampel methods
  Future<int> insertMasterSampel(MasterSampel sampel) async {
    final db = await database;
    return await db.insert('master_sampel', sampel.toJson());
  }

  Future<List<MasterSampel>> getAllMasterSampel() async {
    final db = await database;
    final result = await db.query('master_sampel');
    return result.map((json) => MasterSampel.fromJson(json)).toList();
  }

  Future<int> clearMasterSampel() async {
    final db = await database;
    return await db.delete('master_sampel');
  }

  // Master LSU methods
  Future<int> insertMasterLsu(MasterLsu lsu) async {
    final db = await database;
    return await db.insert('master_lsu', lsu.toJson());
  }

  Future<MasterLsu?> getMasterLsuById(int id) async {
    final db = await database;
    final result = await db.query(
      'master_lsu',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return MasterLsu.fromJson(result.first);
  }

  Future<int> clearMasterLsu() async {
    final db = await database;
    return await db.delete('master_lsu');
  }

  // Received Sample methods
  Future<int> insertReceivedSample(ReceivedSample sample) async {
    final db = await database;
    return await db.insert('received_sample', sample.toJson());
  }

  Future<List<ReceivedSample>> getPendingUploads() async {
    final db = await database;
    final result = await db.query(
      'received_sample',
      where: 'status IN (?, ?)',
      whereArgs: ['not_uploaded', 'error'],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => ReceivedSample.fromJson(json)).toList();
  }

  Future<int> updateReceivedSampleStatus(
    int id,
    String status, {
    String? errorMessage,
  }) async {
    final db = await database;
    return await db.update(
      'received_sample',
      {
        'status': status,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User Preferences methods
  Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_preferences',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreference(String key) async {
    final db = await database;
    final result = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }
}
```

### 3. API Service Implementation

```dart
// lib/core/network/api_service.dart
class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService(this._dio, this.baseUrl);

  // Sync data
  Future<SyncResponse> syncData(int regional) async {
    final response = await _dio.get(
      '/mobile/sync',
      queryParameters: {'regional': regional},
    );
    return SyncResponse.fromJson(response.data);
  }

  // Batch upload
  Future<UploadResponse> batchUpload(List<UploadItem> items) async {
    final response = await _dio.post(
      '/data-lsu/upload',
      data: items.map((e) => e.toJson()).toList(),
    );
    return UploadResponse.fromJson(response.data);
  }

  // Upload photo
  Future<PhotoUploadResponse> uploadPhoto({
    required String filePath,
    required int dataLsuId,
    required String kode,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'dataLsuId': dataLsuId,
      'kode': kode,
    });

    final response = await _dio.post(
      '/upload/photo',
      data: formData,
      onSendProgress: onSendProgress,
    );
    return PhotoUploadResponse.fromJson(response.data);
  }
}
```

### 4. QR Code Parsing

```dart
// lib/features/scanner/utils/qr_parser.dart
class QRParser {
  static QRData? parse(String qrCode) {
    try {
      final parts = qrCode.split(';');
      if (parts.length != 3) {
        return null;
      }

      final id = int.tryParse(parts[0]);
      final masterLsuId = int.tryParse(parts[1]);
      final kode = parts[2].trim();

      if (id == null || masterLsuId == null || kode.isEmpty) {
        return null;
      }

      return QRData(
        id: id,
        masterLsuId: masterLsuId,
        kode: kode,
      );
    } catch (e) {
      return null;
    }
  }
}

class QRData {
  final int id;
  final int masterLsuId;
  final String kode;

  QRData({
    required this.id,
    required this.masterLsuId,
    required this.kode,
  });
}
```

### 5. Upload with Progress

```dart
// lib/features/upload/providers/upload_provider.dart
class UploadProvider extends ChangeNotifier {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper;

  UploadProgress? _progress;
  bool _isUploading = false;
  List<UploadResult> _results = [];

  UploadProvider(this._apiService, this._dbHelper);

  UploadProgress? get progress => _progress;
  bool get isUploading => _isUploading;
  List<UploadResult> get results => _results;

  Future<void> uploadAll() async {
    _isUploading = true;
    _results.clear();
    notifyListeners();

    try {
      // Get pending samples
      final samples = await _dbHelper.getPendingUploads();
      if (samples.isEmpty) {
        _isUploading = false;
        notifyListeners();
        return;
      }

      // Step 1: Batch upload data
      final uploadItems = samples.map((s) => UploadItem.fromSample(s)).toList();
      final batchResponse = await _apiService.batchUpload(uploadItems);

      // Step 2: Upload photos for success items
      final successItems = batchResponse.success;
      final totalPhotos = successItems.length;
      int uploadedPhotos = 0;

      for (final item in successItems) {
        final sample = samples.firstWhere((s) => s.dataLsuId == item.id);

        // Update progress
        _progress = UploadProgress(
          total: totalPhotos,
          current: uploadedPhotos + 1,
          percentage: ((uploadedPhotos + 1) / totalPhotos * 100).round(),
          currentItem: sample.kode,
        );
        notifyListeners();

        try {
          // Upload photo
          await _apiService.uploadPhoto(
            filePath: sample.fotoPath,
            dataLsuId: item.id,
            kode: item.kode,
            onSendProgress: (sent, total) {
              // Photo upload progress
            },
          );

          // Update status to uploaded
          await _dbHelper.updateReceivedSampleStatus(
            sample.id!,
            'uploaded',
          );

          _results.add(UploadResult(
            sample: sample,
            success: true,
          ));
        } catch (e) {
          // Update status to error
          await _dbHelper.updateReceivedSampleStatus(
            sample.id!,
            'error',
            errorMessage: e.toString(),
          );

          _results.add(UploadResult(
            sample: sample,
            success: false,
            error: e.toString(),
          ));
        }

        uploadedPhotos++;
      }

      // Handle failed items
      for (final item in batchResponse.failed) {
        final sample = samples.firstWhere((s) => s.dataLsuId == item.id);
        await _dbHelper.updateReceivedSampleStatus(
          sample.id!,
          'error',
          errorMessage: item.error,
        );

        _results.add(UploadResult(
          sample: sample,
          success: false,
          error: item.error,
        ));
      }
    } catch (e) {
      // Handle error
    } finally {
      _isUploading = false;
      _progress = null;
      notifyListeners();
    }
  }
}

class UploadProgress {
  final int total;
  final int current;
  final int percentage;
  final String currentItem;

  UploadProgress({
    required this.total,
    required this.current,
    required this.percentage,
    required this.currentItem,
  });
}
```

---

## UI/UX Guidelines

### Design Principles

1. **Modern & Clean**: Use Material Design 3 principles
2. **Intuitive Navigation**: Clear navigation flow
3. **Visual Feedback**: Loading states, success/error messages
4. **Offline First**: Show offline indicators when needed
5. **Accessibility**: Support for screen readers, proper contrast

### Color Scheme

```dart
class AppColors {
  static const primary = Color(0xFF2196F3);
  static const primaryDark = Color(0xFF1976D2);
  static const secondary = Color(0xFF03DAC6);
  static const error = Color(0xFFB00020);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}
```

### Screen Examples

#### Regional Selection Screen

```dart
class RegionalSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Regional'),
        elevation: 0,
      ),
      body: Consumer<RegionalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) {
              final regional = index + 1;
              final isSelected = provider.selectedRegional == regional;

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                child: ListTile(
                  title: Text(
                    'Regional $regional',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.primary)
                      : Icon(Icons.radio_button_unchecked),
                  onTap: () => provider.selectRegional(regional),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

#### Upload Progress Screen

```dart
class UploadProgressWidget extends StatelessWidget {
  final UploadProgress progress;

  const UploadProgressWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Uploading Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 8),
            Text(
              '${progress.current} / ${progress.total} (${progress.percentage}%)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Uploading: ${progress.currentItem}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## API Integration

### Base Configuration

```dart
// lib/core/network/api_client.dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com/api',
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
));

// Add interceptors
dio.interceptors.add(AuthInterceptor());
dio.interceptors.add(PrettyDioLogger(
  requestHeader: true,
  requestBody: true,
  responseBody: true,
  responseHeader: false,
  error: true,
));
```

### Authentication Interceptor

```dart
// lib/core/network/interceptors/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  final SecureStorage _storage = SecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add token to requests (except sync endpoint)
    if (!options.path.contains('/mobile/sync')) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 - refresh token
    if (err.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry request
        final opts = err.requestOptions;
        final token = await _storage.getAccessToken();
        opts.headers['Authorization'] = 'Bearer $token';
        final response = await dio.fetch(opts);
        handler.resolve(response);
        return;
      }
    }
    handler.next(err);
  }
}
```

---

## Testing Guidelines

### Unit Tests

- Test QR code parsing
- Test database operations
- Test API service methods
- Test data models

### Widget Tests

- Test UI components
- Test user interactions
- Test navigation flows

### Integration Tests

- Test complete upload flow
- Test sync flow
- Test offline functionality

### Test Data

Use mock data for:

- Master Sampel
- Master LSU
- API responses
- QR codes

---

## Additional Notes

### Image Compression

Before uploading, compress images to reduce size:

```dart
Future<String> compressImage(String imagePath) async {
  final image = decodeImage(File(imagePath).readAsBytesSync());
  if (image == null) throw Exception('Invalid image');

  // Resize if needed
  final resized = copyResize(image, width: 1920);

  // Save compressed
  final compressedPath = '${imagePath}_compressed.jpg';
  File(compressedPath).writeAsBytesSync(
    encodeJpg(resized, quality: 85),
  );

  return compressedPath;
}
```

### Permissions

Request permissions on app start:

```dart
Future<void> requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
    Permission.photos,
  ].request();
}
```

### Error Handling

- Show user-friendly error messages
- Log errors for debugging
- Retry failed operations
- Handle network timeouts

---

## Version History

### Version 1.0.0 (2026-01-23)

- Initial app development guide
- Complete feature specifications
- Database schema design
- Library recommendations
- Implementation guidelines
