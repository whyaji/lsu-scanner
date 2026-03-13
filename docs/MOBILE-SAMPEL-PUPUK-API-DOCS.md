# Mobile Sampel Pupuk API Documentation

This document describes the APIs used by the mobile app for **Data Sampel Pupuk**: sync, activity upload, and photo upload.

## Base URL

```
Production: https://api.example.com/api
Development: http://localhost:3000/api
```

## Authentication

- **Sync Sampel Pupuk** (`GET /api/mobile/sync-sampel-pupuk`): Authentication is **optional**. If you send a valid Bearer token, the response includes the current **user** profile so the app can update local user data (including `access` for permission checks).
- **Area API** (regional, wilayah, estate), **Upload Pupuk**, and **Upload Photo Pupuk**: Require JWT. Send the token in the header:

```
Authorization: Bearer <access_token>
```

---

## User profile and access

The current user is returned by **GET /auth/me** and, when authenticated, inside the **Sync Data Sampel Pupuk** response as `data.user`. Store this locally to drive UI and permissions (e.g. which activities the user can perform).

### User object

| Field         | Type     | Description                     |
| ------------- | -------- | ------------------------------- |
| `id`          | number   | User ID                         |
| `username`    | string   | Username                        |
| `nama`        | string   | Full name                       |
| `jabatan`     | string?  | Job title (optional)            |
| `lokasiKerja` | string?  | Work location (optional)        |
| `isAdmin`     | boolean  | Whether the user is admin       |
| `access`      | string[] | List of access keys (see below) |

### Access values (`access` array)

Allowed values come from the server (see `USER_ACCESS_VALUES` in schema):

| Value          | Description                                  |
| -------------- | -------------------------------------------- |
| `lsu`          | LSU module access (Data LSU flows)           |
| `pupuk:estate` | Sampel Pupuk – **Estate** role               |
| `pupuk:nt`     | Sampel Pupuk – **NT** (Nasional/Office) role |

### Sampel Pupuk permissions by access

- **`pupuk:estate`**  
  User can: scan QR, fill form, and upload data for:
  - **terimaDariGudang** (receive from gudang)
  - **kirimDariEstate** (send from estate)

- **`pupuk:nt`**  
  User can: scan QR, fill form, and upload data for:
  - **terimaDariEstate** (receive from estate)
  - **kirimLab** (send to lab)

Use the local user’s `access` to show or hide activity types and to validate before calling upload/photo APIs.

---

## 1. Area API (Regional, Wilayah, Estate)

Use these endpoints to load options for **regional**, **wilayah**, and **estate** when filling Data Sampel Pupuk forms (e.g. dropdowns or filters). All require authentication.

### 1.1 Get Regional List

Returns the list of regional IDs (1–5).

#### Endpoint

```
GET /api/area/regional
```

#### Authentication

Required (Bearer token).

#### Response

```json
{
  "success": true,
  "data": [1, 2, 3, 4, 5]
}
```

#### Example Request

```bash
curl -X GET "http://localhost:3000/api/area/regional" \
  -H "Authorization: Bearer <access_token>"
```

---

### 1.2 Get Wilayah List

Returns the list of wilayah IDs (1–9).

#### Endpoint

```
GET /api/area/wilayah
```

#### Authentication

Required (Bearer token).

#### Response

```json
{
  "success": true,
  "data": [1, 2, 3, 4, 5, 6, 7, 8, 9]
}
```

#### Example Request

```bash
curl -X GET "http://localhost:3000/api/area/wilayah" \
  -H "Authorization: Bearer <access_token>"
```

---

### 1.3 Get Estate List

Returns estates from the CMP system. Each estate has `id`, `regional`, `wilayah`, `abbr` (e.g. estate code), and `nama` (full name). Use for estate dropdown; filter by `regional` or `wilayah` on the client if needed.

#### Endpoint

```
GET /api/area/estate
```

#### Authentication

Required (Bearer token).

#### Response

```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 101,
        "regional": 1,
        "wilayah": 1,
        "abbr": "NBE",
        "nama": "Negeri Beku Estate"
      },
      {
        "id": 102,
        "regional": 1,
        "wilayah": 2,
        "abbr": "ABC",
        "nama": "Another Estate"
      }
    ],
    "total": 2
  }
}
```

#### Response Fields (each item in `data.data`)

| Field      | Type   | Description              |
| ---------- | ------ | ------------------------ |
| `id`       | number | Estate ID                |
| `regional` | number | Regional (1–5)           |
| `wilayah`  | number | Wilayah (1–9)            |
| `abbr`     | string | Estate abbreviation/code |
| `nama`     | string | Estate full name         |

#### Example Request

```bash
curl -X GET "http://localhost:3000/api/area/estate" \
  -H "Authorization: Bearer <access_token>"
```

#### Notes

- Estate data may be cached on the server.
- For Data Sampel Pupuk forms, use `abbr` or `nama` as the estate value where the field expects an estate label/code.

---

## 2. Sync Data Sampel Pupuk

Download all Data Sampel Pupuk records for a regional for offline use. Use **Area API** (section 1) to get regional/wilayah/estate options for filters or forms. Returns full objects (form sections A–E, activity dates/fotos, metadata). Only records that belong to the given regional, are not deleted, and have no sertifikat yet are returned.

**When the request includes a valid Bearer token**, the response also includes the current **user** profile (`data.user`). The mobile app should store this locally to update the logged-in user (e.g. after login or on pull-to-refresh) and use `user.access` to enforce which activities the user can perform (see **User profile and access** above).

### Endpoint

```
GET /api/mobile/sync-sampel-pupuk
```

### Authentication

Optional. If `Authorization: Bearer <access_token>` is sent and valid, the response includes `user` in `data`.

### Query Parameters

| Parameter  | Type   | Required | Description       |
| ---------- | ------ | -------- | ----------------- |
| `regional` | number | Yes      | Regional ID (1–5) |

### Response (without auth)

```json
{
  "success": true,
  "data": {
    "dataSampelPupuk": [
      {
        "id": 1,
        "kodeSampel": "NBE-2026-001",
        "jenisPupukFull": "II - Pupuk NPK 13-6-27-4 @ 50Kg/Zak",
        "jenisPupuk": "NPK 13",
        "merek": null,
        "noKodeSampel": 1,
        "jumlahSampelZak": 2,
        "noSegel": null,
        "noBaSampelPupuk": null,
        "supplier": "Supplier A",
        "regional": 1,
        "wilayah": 1,
        "estate": "NBE",
        "pt": "PT ABC",
        "noPo": "PO-001",
        "noBpb": null,
        "qtyPartaiPengiriman": 5000,
        "qtyTerima": null,
        "jenisKendaraan": null,
        "tanggalPengambilanSampel": null,
        "tanggalTerimaDariGudang": null,
        "checkLogoPerusahaan": null,
        "checkKondisiKarung": null,
        "checkJahitanKarung": null,
        "checkKontaminan": null,
        "checkJenisKontaminan": null,
        "checkPersentaseKontaminan": null,
        "checkBekasGancu": null,
        "diterimaDeptAgronomiRndNama": null,
        "diperiksaEstateManagerNama": null,
        "diperiksaKtNama": null,
        "disaksikanSupplierNama": null,
        "diambilKepalaGudang": null,
        "fotoTerimaDariGudang": null,
        "terimaDariGudangBy": null,
        "tanggalKirimDariEstate": null,
        "fotoKirimDariEstate": null,
        "kirimDariEstateBy": null,
        "namaPengirim": null,
        "noSurat": null,
        "tanggalTerimaDariEstate": null,
        "fotoTerimaDariEstate": null,
        "terimaDariEstateBy": null,
        "tanggalKirimLab": null,
        "fotoKirimLab": null,
        "kirimLabBy": null,
        "tanggalRegistrasiLab": null,
        "fotoRegistrasiLab": null,
        "tanggalEstimasiKupa": null,
        "kodeTracking": null,
        "noSertifikat": null,
        "tanggalKirimSertifikatEstate": null,
        "rekomendasi": null,
        "createdAt": "2026-01-15T10:00:00.000Z",
        "updatedAt": "2026-01-15T10:00:00.000Z"
      }
    ]
  }
}
```

### Response (with auth)

When the request includes a valid `Authorization: Bearer <access_token>`, the response includes the current user so the app can update local user data:

```json
{
  "success": true,
  "data": {
    "dataSampelPupuk": ["... same as above ..."],
    "user": {
      "id": 1,
      "username": "jane.estate",
      "nama": "Jane Doe",
      "jabatan": "Estate Officer",
      "lokasiKerja": "Regional 1",
      "isAdmin": false,
      "access": ["pupuk:estate"]
    }
  }
}
```

Store `data.user` locally and use `user.access` to determine which activities to show (e.g. only terimaDariGudang and kirimDariEstate for `pupuk:estate`, only terimaDariEstate and kirimLab for `pupuk:nt`).

### Response Fields (per item in `dataSampelPupuk`)

| Section                          | Fields                                                                                                                                                       |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **A. Nama dan Jenis Pupuk**      | `kodeSampel`, `jenisPupukFull`, `jenisPupuk`, `merek`, `noKodeSampel`, `jumlahSampelZak`, `noSegel`, `noBaSampelPupuk`                                       |
| **B. Data asal pupuk**           | `supplier`, `regional`, `wilayah`, `estate`, `pt`, `noPo`, `noBpb`, `qtyPartaiPengiriman`, `qtyTerima`                                                       |
| **C. Angkutan Pupuk**            | `jenisKendaraan`, `tanggalPengambilanSampel`, `tanggalTerimaDariGudang`                                                                                      |
| **D. Hasil Pemeriksaan Fisik**   | `checkLogoPerusahaan`, `checkKondisiKarung`, `checkJahitanKarung`, `checkKontaminan`, `checkJenisKontaminan`, `checkPersentaseKontaminan`, `checkBekasGancu` |
| **E. Penerimaan Sampel Pupuk**   | `diterimaDeptAgronomiRndNama`, `diperiksaEstateManagerNama`, `diperiksaKtNama`, `disaksikanSupplierNama`, `diambilKepalaGudang`                              |
| **Activity: Terima dari Gudang** | `fotoTerimaDariGudang`, `terimaDariGudangBy`, `tanggalTerimaDariGudang`                                                                                      |
| **Activity: Kirim dari Estate**  | `tanggalKirimDariEstate`, `fotoKirimDariEstate`, `kirimDariEstateBy`, `namaPengirim`                                                                         |
| **Activity: Terima dari Estate** | `noSurat`, `tanggalTerimaDariEstate`, `fotoTerimaDariEstate`, `terimaDariEstateBy`                                                                           |
| **Activity: Kirim Lab**          | `tanggalKirimLab`, `fotoKirimLab`, `kirimLabBy`                                                                                                              |

#### Date and timestamp fields

All date-related columns are stored and returned as **timestamps** (date + time) in **ISO 8601** format:

- **Sync response**: `tanggalPengambilanSampel`, `tanggalTerimaDariGudang`, `tanggalKirimDariEstate`, `tanggalTerimaDariEstate`, `tanggalKirimLab`, `tanggalRegistrasiLab`, `tanggalEstimasiKupa`, `tanggalKirimSertifikatEstate`, `createdAt`, and `updatedAt` are returned as full ISO datetime strings (e.g. `2026-01-15T10:30:00.000Z`).
- **Upload request**: Date fields **must include time**. Send full ISO 8601 datetime only (e.g. `2026-01-15T10:30:00.000Z` or `2026-01-15T17:30:00`). Date-only `YYYY-MM-DD` is not accepted.

### Example Request

```bash
# Without auth (data only)
curl -X GET "http://localhost:3000/api/mobile/sync-sampel-pupuk?regional=1"

# With auth (data + current user for local storage)
curl -X GET "http://localhost:3000/api/mobile/sync-sampel-pupuk?regional=1" \
  -H "Authorization: Bearer <access_token>"
```

### Error Responses

- `400 Bad Request`: Missing `regional` or invalid value (must be 1–5).

### Notes

- Authentication is optional. Send Bearer token to receive `user` in the response and update local user profile (including `access` for permission checks).
- Use this payload to populate offline lists and forms; use `id` or `kodeSampel` when calling upload/photo APIs.

---

## 3. Upload Data Sampel Pupuk (Activity)

Submit activity data for one or more Data Sampel Pupuk records. Supports four activity types; each type has its own array. Every item must include **id** (local row id from your app), **dataSampelPupukId** (server’s Data Sampel Pupuk ID from sync), and **kodeSampel** (must match the record). The server updates the corresponding date/foto/user fields per type.

### Endpoint

```
POST /api/data-sampel-pupuk/upload
```

### Authentication

Required (Bearer token).

### Request body: common columns (every type)

Each item in every type array must have these three columns:

| Column              | Type   | Required | Description                                                                            |
| ------------------- | ------ | -------- | -------------------------------------------------------------------------------------- |
| `id`                | number | Yes      | Local primary key (your table’s row id). Used in the response to match success/failed. |
| `dataSampelPupukId` | number | Yes      | Server’s Data Sampel Pupuk ID (from sync `dataSampelPupuk[].id`).                      |
| `kodeSampel`        | string | Yes      | No Registrasi Sampel; must match the record identified by `dataSampelPupukId`.         |

Plus the type-specific columns below.

### Local database guide (tables and columns per type)

Use this to design your local SQLite/tables. Each type is a separate table; all share the same three required columns and add their own.

#### Table: `terima_dari_gudang` (Type 1)

| Column                    | Type    | Required | Description                                                                        |
| ------------------------- | ------- | -------- | ---------------------------------------------------------------------------------- |
| `id`                      | integer | Yes (PK) | Local row id                                                                       |
| `dataSampelPupukId`       | integer | Yes      | Server Data Sampel Pupuk ID                                                        |
| `kodeSampel`              | text    | Yes      | No Registrasi Sampel                                                               |
| `tanggalTerimaDariGudang` | text    | Yes      | Date and time: ISO 8601 datetime (e.g. `YYYY-MM-DDTHH:mm:ss.sssZ`) — time required |
| `fotoTerimaDariGudang`    | text    | No       | Photo path (from Upload Photo Pupuk)                                               |

#### Table: `kirim_dari_estate` (Type 2)

| Column                   | Type    | Required | Description                                      |
| ------------------------ | ------- | -------- | ------------------------------------------------ |
| `id`                     | integer | Yes (PK) | Local row id                                     |
| `dataSampelPupukId`      | integer | Yes      | Server Data Sampel Pupuk ID                      |
| `kodeSampel`             | text    | Yes      | No Registrasi Sampel                             |
| `tanggalKirimDariEstate` | text    | Yes      | Date and time: ISO 8601 datetime — time required |
| `fotoKirimDariEstate`    | text    | No       | Photo path                                       |
| `namaPengirim`           | text    | No       | Sender name                                      |

#### Table: `terima_dari_estate` (Type 3)

| Column                    | Type    | Required | Description                                      |
| ------------------------- | ------- | -------- | ------------------------------------------------ |
| `id`                      | integer | Yes (PK) | Local row id                                     |
| `dataSampelPupukId`       | integer | Yes      | Server Data Sampel Pupuk ID                      |
| `kodeSampel`              | text    | Yes      | No Registrasi Sampel                             |
| `noSurat`                 | text    | No       | Surat number                                     |
| `tanggalTerimaDariEstate` | text    | Yes      | Date and time: ISO 8601 datetime — time required |
| `fotoTerimaDariEstate`    | text    | No       | Photo path                                       |

#### Table: `kirim_lab` (Type 4)

| Column              | Type    | Required | Description                                      |
| ------------------- | ------- | -------- | ------------------------------------------------ |
| `id`                | integer | Yes (PK) | Local row id                                     |
| `dataSampelPupukId` | integer | Yes      | Server Data Sampel Pupuk ID                      |
| `kodeSampel`        | text    | Yes      | No Registrasi Sampel                             |
| `tanggalKirimLab`   | text    | Yes      | Date and time: ISO 8601 datetime — time required |
| `fotoKirimLab`      | text    | No       | Photo path                                       |

### Full request body example

```json
{
  "terimaDariGudang": [
    {
      "id": 1,
      "dataSampelPupukId": 101,
      "kodeSampel": "NBE-2026-001",
      "tanggalTerimaDariGudang": "2026-01-15T08:00:00.000Z",
      "fotoTerimaDariGudang": "/protected/pupuk/2026/01/NBE/photo.jpg"
    }
  ],
  "kirimDariEstate": [
    {
      "id": 2,
      "dataSampelPupukId": 102,
      "kodeSampel": "NBE-2026-002",
      "tanggalKirimDariEstate": "2026-01-16T09:30:00.000Z",
      "fotoKirimDariEstate": "/protected/pupuk/2026/01/NBE/photo2.jpg",
      "namaPengirim": "John Doe"
    }
  ],
  "terimaDariEstate": [
    {
      "id": 3,
      "dataSampelPupukId": 103,
      "kodeSampel": "NBE-2026-003",
      "noSurat": "SRT-001",
      "tanggalTerimaDariEstate": "2026-01-17T10:00:00.000Z",
      "fotoTerimaDariEstate": "/protected/pupuk/2026/01/NBE/photo3.jpg"
    }
  ],
  "kirimLab": [
    {
      "id": 4,
      "dataSampelPupukId": 104,
      "kodeSampel": "NBE-2026-004",
      "tanggalKirimLab": "2026-01-18T14:00:00.000Z",
      "fotoKirimLab": "/protected/pupuk/2026/01/NBE/photo4.jpg"
    }
  ]
}
```

All four keys are optional; omit or use empty arrays for types you are not sending.

### Response

```json
{
  "success": true,
  "data": {
    "terimaDariGudang": {
      "success": [{ "id": 1 }],
      "failed": []
    },
    "kirimDariEstate": {
      "success": [{ "id": 2 }],
      "failed": []
    },
    "terimaDariEstate": {
      "success": [{ "id": 3 }],
      "failed": []
    },
    "kirimLab": {
      "success": [{ "id": 4 }],
      "failed": []
    }
  }
}
```

- **success**: array of `{ id: number }` where `id` is the **local** row id from your request; use it to mark that row as synced.
- **failed**: array of `{ id: number, error: string }` where `id` is the local row id; use it to retry or show errors.

### Example Request

```bash
curl -X POST "http://localhost:3000/api/data-sampel-pupuk/upload" \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "terimaDariGudang": [
      {
        "id": 1,
        "dataSampelPupukId": 101,
        "kodeSampel": "NBE-2026-001",
        "tanggalTerimaDariGudang": "2026-01-15T08:00:00.000Z",
        "fotoTerimaDariGudang": "/protected/pupuk/2026/01/NBE/photo.jpg"
      }
    ],
    "kirimDariEstate": [],
    "terimaDariEstate": [],
    "kirimLab": []
  }'
```

### Error Responses

The API can return an error **HTTP status** (4xx/5xx) with a JSON body, or a **200** with some items in the `failed` array (see **Failed data response** below).

#### HTTP error response (4xx / 5xx)

All error responses use this shape:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "details": {}
  }
}
```

| Status                      | Code (typical)                    | When                                                                                                                                               |
| --------------------------- | --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `400 Bad Request`           | `VALIDATION_ERROR`                | Invalid body: missing required fields (`id`, `dataSampelPupukId`, `kodeSampel`, or type-specific fields), invalid types, or Zod validation issues. |
| `401 Unauthorized`          | `UNAUTHORIZED` or `TOKEN_EXPIRED` | Missing `Authorization` header, invalid Bearer token, or token expired.                                                                            |
| `500 Internal Server Error` | `INTERNAL_SERVER_ERROR`           | Server or database error.                                                                                                                          |

**Example – 400 (validation):**

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request body",
    "details": [
      {
        "path": ["terimaDariGudang", 0, "dataSampelPupukId"],
        "message": "Required"
      }
    ]
  }
}
```

**Example – 401 (unauthorized):**

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Missing or invalid authorization header",
    "details": {}
  }
}
```

#### Failed data response (200 with partial failure)

When the request is valid and the server processes the payload, the response is **200** and `data` contains both `success` and `failed` per type. Items in `failed` were not updated; the `id` is your **local** row id and `error` explains why.

**Example – mixed success and failed:**

```json
{
  "success": true,
  "data": {
    "terimaDariGudang": {
      "success": [{ "id": 1 }],
      "failed": [
        { "id": 2, "error": "Record not found or kodeSampel mismatch" }
      ]
    },
    "kirimDariEstate": {
      "success": [],
      "failed": [
        { "id": 10, "error": "Record not found or kodeSampel mismatch" }
      ]
    },
    "terimaDariEstate": { "success": [], "failed": [] },
    "kirimLab": { "success": [], "failed": [] }
  }
}
```

**Possible `error` values in `failed`:**

| Error message                             | Meaning                                                                                                                               |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `Record not found or kodeSampel mismatch` | No Data Sampel Pupuk with that `dataSampelPupukId`, or its `kodeSampel` does not match the request. Re-sync and check ids/kodeSampel. |
| `Unknown error`                           | Unexpected server/database error while updating that item. Retry later.                                                               |

The app should: mark `success[].id` as synced; keep `failed[].id` as pending and show `failed[].error` (e.g. toast or list of failed rows) and optionally retry after re-sync.

---

## 4. Upload Photo Pupuk

Upload a single photo file for a Data Sampel Pupuk activity. The photo is stored and the corresponding `foto*` column on the record is set to the returned path. Use this path in the Upload Data Sampel Pupuk request for the same activity type.

### Endpoint

```
POST /api/upload/photo-pupuk
```

### Authentication

Required (Bearer token).

### Content Type

```
multipart/form-data
```

### Form Fields

| Field               | Type   | Required | Description                                                                             |
| ------------------- | ------ | -------- | --------------------------------------------------------------------------------------- |
| `file`              | File   | Yes      | Photo file (JPG, JPEG, or PNG; max 10MB)                                                |
| `dataSampelPupukId` | number | Yes      | Data Sampel Pupuk ID                                                                    |
| `kodeSampel`        | string | Yes      | No Registrasi Sampel (must match the record)                                            |
| `type`              | string | Yes      | Activity type: `terimaDariGudang`, `kirimDariEstate`, `terimaDariEstate`, or `kirimLab` |

### Allowed `type` Values

| type               | Updated field on record |
| ------------------ | ----------------------- |
| `terimaDariGudang` | `fotoTerimaDariGudang`  |
| `kirimDariEstate`  | `fotoKirimDariEstate`   |
| `terimaDariEstate` | `fotoTerimaDariEstate`  |
| `kirimLab`         | `fotoKirimLab`          |

### File Requirements

- **Formats**: JPG, JPEG, PNG
- **Max size**: 10 MB
- Filename is sanitized by the server.

### File Path Structure

Photos are saved under:

```
storage/app/protected/pupuk/{year}/{month}/{estate_or_kodeSampel}/{filename}
```

Example:

```
/protected/pupuk/2026/01/NBE/photo.jpg
```

The path segment after `month` is derived from the record’s `estate` or, if missing, `kodeSampel` (sanitized).

### Response

```json
{
  "success": true,
  "data": {
    "filePath": "/protected/pupuk/2026/01/NBE/photo.jpg",
    "type": "terimaDariGudang"
  }
}
```

Use `data.filePath` as the foto value for that activity type in `POST /api/data-sampel-pupuk/upload`.

### Example Request

```bash
curl -X POST "http://localhost:3000/api/upload/photo-pupuk" \
  -H "Authorization: Bearer <access_token>" \
  -F "file=@/path/to/photo.jpg" \
  -F "dataSampelPupukId=1" \
  -F "kodeSampel=NBE-2026-001" \
  -F "type=terimaDariGudang"
```

### Error Responses

- `400 Bad Request`:
  - Missing file, `dataSampelPupukId`, `kodeSampel`, or `type`
  - Invalid `type` (not one of: terimaDariGudang, kirimDariEstate, terimaDariEstate, kirimLab)
  - Invalid `dataSampelPupukId`
  - Invalid file type or size > 10MB
  - Kode Sampel mismatch
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: Data Sampel Pupuk not found

---

## Mobile Workflow (Sampel Pupuk)

### Recommended flow

1. **Load area options**  
   Call `GET /api/area/regional`, `GET /api/area/wilayah`, and `GET /api/area/estate` (with auth) to fill dropdowns for **regional**, **wilayah**, and **estate** in create/edit forms or filters.

2. **Sync**
   Call `GET /api/mobile/sync-sampel-pupuk?regional={regional}` **with** `Authorization: Bearer <access_token>` so the response includes `dataSampelPupuk` and `user`. Store both locally; use `user.access` to show only the activities the user is allowed to perform (e.g. `pupuk:estate` → terimaDariGudang, kirimDariEstate; `pupuk:nt` → terimaDariEstate, kirimLab).

3. **User fills an activity** (e.g. Terima dari Gudang)
   - Select record by `id` or `kodeSampel` from synced data.
   - Only show activity types that match the user’s `access`.
   - Enter date and time (ISO 8601 datetime; time is required — see **Date and timestamp fields** in Sync section).
   - Capture or select photo.

4. **Upload photo first (when online)**  
   For each photo:  
   `POST /api/upload/photo-pupuk` with `file`, `dataSampelPupukId`, `kodeSampel`, `type`.  
   Save returned `filePath` for that item and activity type.

5. **Upload activity data**  
   `POST /api/data-sampel-pupuk/upload` with the relevant activity array(s). For each item, use the `filePath` from step 3 in the corresponding `foto*` field.  
   Handle `success` and `failed` per type to update UI or retry.

### Order of calls

- You can upload the photo first, then send the activity payload with the returned path; or upload activity with a placeholder and update later (if your backend supports it). The documented flow is: **photo first**, then **activity with path**.
- Use the same `id` or `kodeSampel` in both photo and activity requests so the server links the photo to the correct record and activity type.
