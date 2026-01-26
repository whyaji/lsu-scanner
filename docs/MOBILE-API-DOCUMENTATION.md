# Mobile API Documentation

This document provides comprehensive API documentation for mobile application development.

## Base URL

```
Production: https://api.example.com/api
Development: http://localhost:3000/api
```

## Authentication

All mobile API endpoints (except sync) require JWT authentication. Include the access token in the Authorization header:

```
Authorization: Bearer <access_token>
```

### Token Management

- **Access Token**: Short-lived (default: 1 hour, configurable), used for API requests
- **Refresh Token**: Long-lived (default: 7 days, configurable), used to obtain new access tokens
- Store tokens securely on the device (e.g., Keychain/Keystore)
- Access tokens expire after the configured time; use refresh token to obtain a new access token

---

## Authentication API

### 1. Login

Authenticate user and obtain access token and refresh token.

#### Endpoint

```
POST /api/auth/login
```

#### Authentication

Not required (public endpoint)

#### Request Body

```json
{
  "username": "john.doe",
  "password": "password123"
}
```

#### Request Fields

| Field      | Type   | Required | Description   |
| ---------- | ------ | -------- | ------------- |
| `username` | string | Yes      | User username |
| `password` | string | Yes      | User password |

#### Response

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 3600,
    "user": {
      "id": 1,
      "username": "john.doe",
      "nama": "John Doe",
      "jabatan": "Field Officer",
      "lokasiKerja": "Regional 1",
      "isAdmin": false
    }
  }
}
```

#### Response Fields

| Field          | Type   | Description                                       |
| -------------- | ------ | ------------------------------------------------- |
| `accessToken`  | string | JWT access token for API authentication           |
| `refreshToken` | string | JWT refresh token for obtaining new access tokens |
| `expiresIn`    | number | Access token expiration time in seconds           |
| `user`         | object | Authenticated user information                    |

#### User Object Fields

| Field         | Type    | Description                   |
| ------------- | ------- | ----------------------------- |
| `id`          | number  | User ID                       |
| `username`    | string  | Username                      |
| `nama`        | string  | Full name                     |
| `jabatan`     | string  | Job position (optional)       |
| `lokasiKerja` | string  | Work location (optional)      |
| `isAdmin`     | boolean | Whether user is administrator |

#### Example Request

```bash
curl -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john.doe",
    "password": "password123"
  }'
```

#### Error Responses

- `400 Bad Request`: Invalid request body or validation errors
- `401 Unauthorized`: Invalid username or password
- `401 Unauthorized`: User account is inactive

#### Error Response Example

```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid username or password",
    "details": {}
  }
}
```

---

### 2. Refresh Access Token

Obtain a new access token using a valid refresh token.

#### Endpoint

```
POST /api/auth/refresh
```

#### Authentication

Not required (public endpoint)

#### Request Body

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Request Fields

| Field          | Type   | Required | Description                    |
| -------------- | ------ | -------- | ------------------------------ |
| `refreshToken` | string | Yes      | Valid refresh token from login |

#### Response

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 3600
  }
}
```

#### Response Fields

| Field         | Type   | Description                             |
| ------------- | ------ | --------------------------------------- |
| `accessToken` | string | New JWT access token                    |
| `expiresIn`   | number | Access token expiration time in seconds |

#### Example Request

```bash
curl -X POST "http://localhost:3000/api/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }'
```

#### Error Responses

- `400 Bad Request`: Invalid request body or validation errors
- `401 Unauthorized`: Refresh token is invalid or expired
- `401 Unauthorized`: User account is inactive

#### Error Response Example

```json
{
  "success": false,
  "error": {
    "code": "TOKEN_EXPIRED",
    "message": "Refresh token is invalid or expired",
    "details": {}
  }
}
```

---

### 3. Logout

Logout the current user. In a stateless JWT system, logout is primarily handled client-side by removing tokens.

#### Endpoint

```
POST /api/auth/logout
```

#### Authentication

Required (Bearer token)

#### Request Body

None

#### Response

```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

#### Example Request

```bash
curl -X POST "http://localhost:3000/api/auth/logout" \
  -H "Authorization: Bearer <access_token>"
```

#### Error Responses

- `401 Unauthorized`: Missing or invalid token

#### Notes

- Logout is primarily handled client-side by removing stored tokens
- The server endpoint is available for future token blacklisting implementation
- After logout, remove both access token and refresh token from device storage

---

### 4. Get Current User

Get information about the currently authenticated user.

#### Endpoint

```
GET /api/auth/me
```

#### Authentication

Required (Bearer token)

#### Request Body

None

#### Response

```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "john.doe",
    "nama": "John Doe",
    "jabatan": "Field Officer",
    "lokasiKerja": "Regional 1",
    "isAdmin": false
  }
}
```

#### Response Fields

| Field         | Type    | Description                   |
| ------------- | ------- | ----------------------------- |
| `id`          | number  | User ID                       |
| `username`    | string  | Username                      |
| `nama`        | string  | Full name                     |
| `jabatan`     | string  | Job position (optional)       |
| `lokasiKerja` | string  | Work location (optional)      |
| `isAdmin`     | boolean | Whether user is administrator |

#### Example Request

```bash
curl -X GET "http://localhost:3000/api/auth/me" \
  -H "Authorization: Bearer <access_token>"
```

#### Error Responses

- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: User not found

---

## API Endpoints

### 1. Mobile Sync (Offline Data)

Get offline data for mobile app synchronization. This endpoint provides all Master Sampel and Master LSU data filtered by regional.

#### Endpoint

```
GET /api/mobile/sync?regional={1-5}
```

#### Parameters

| Parameter  | Type   | Required | Description           |
| ---------- | ------ | -------- | --------------------- |
| `regional` | number | Yes      | Regional number (1-5) |

#### Response

```json
{
  "success": true,
  "data": {
    "masterSampel": [
      {
        "id": 1,
        "nama": "Sampel A"
      },
      {
        "id": 2,
        "nama": "Sampel B"
      }
    ],
    "masterLsu": [
      {
        "id": 1,
        "regional": 1,
        "pt": "PT ABC",
        "statusKebun": "Inti",
        "estate": "NBE",
        "wilayah": 1,
        "afdeling": "Afdeling 1",
        "blok": "Blok A",
        "groupBlok": "Group 1",
        "tahunTanam": 2020,
        "varietas": "Varietas A",
        "jenisTanah": "Mineral",
        "topografi": "Datar",
        "luasHa": "10.5",
        "jmlPokok": 1000,
        "jmlPokokProduktif": 950,
        "sph": "143.5"
      }
    ]
  }
}
```

#### Example Request

```bash
curl -X GET "http://localhost:3000/api/mobile/sync?regional=1"
```

#### Notes

- This endpoint does **not** require authentication
- Master Sampel list is not filtered (returns all)
- Master LSU is filtered by regional
- Use this data for offline mode in mobile app

---

### 2. Batch Upload Data LSU

Upload multiple Data LSU items from mobile app. Updates status from 'Dikirim' to 'Diterima' for valid items.

#### Endpoint

```
POST /api/data-lsu/upload
```

#### Authentication

Required (Bearer token)

#### Request Body

```json
[
  {
    "id": 56,
    "masterLsuId": 3,
    "kode": "NBE 123R",
    "foto": "photoxxxxxxx.jpg",
    "tanggalTerima": "2026-01-03",
    "waktuTerima": "15:34:01"
  },
  {
    "id": 57,
    "masterLsuId": 4,
    "kode": "NBE 124S",
    "foto": "photoxxxxxxx2.jpg",
    "tanggalTerima": "2026-01-04",
    "waktuTerima": "15:35:03"
  }
]
```

#### Request Fields

| Field           | Type   | Required | Description                                                  |
| --------------- | ------ | -------- | ------------------------------------------------------------ |
| `id`            | number | Yes      | Data LSU ID                                                  |
| `masterLsuId`   | number | Yes      | Master LSU ID                                                |
| `kode`          | string | Yes      | Data LSU kode (for validation)                               |
| `foto`          | string | Yes      | Photo filename (will be updated with full path after upload) |
| `tanggalTerima` | string | Yes      | Date received in format YYYY-MM-DD                           |
| `waktuTerima`   | string | Yes      | Time received in format HH:mm:ss                             |

#### Response

```json
{
  "success": true,
  "data": {
    "success": [
      {
        "id": 56,
        "kode": "NBE 123R"
      }
    ],
    "failed": [
      {
        "id": 57,
        "kode": "NBE 124S",
        "error": "Status already processed"
      }
    ]
  }
}
```

#### Validation Rules

Each item is validated:

- Data LSU must exist
- Kode must match
- Master LSU ID must match
- Status must be 'Dikirim' (not already processed)

If valid:

- Status updated to 'Diterima'
- `tanggal_terima` set from request `tanggalTerima`
- `waktu_terima` set from request `waktuTerima`
- `received_by` set to authenticated user ID
- `received_by_nama` set to authenticated user name
- `foto` field updated with filename (will be replaced with full path after photo upload)

#### Example Request

```bash
curl -X POST "http://localhost:3000/api/data-lsu/upload" \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "id": 56,
      "masterLsuId": 3,
      "kode": "NBE 123R",
      "foto": "photoxxxxxxx.jpg",
      "tanggalTerima": "2026-01-03",
      "waktuTerima": "15:34:01"
    }
  ]'
```

#### Error Responses

- `400 Bad Request`: Invalid request body or validation errors
- `401 Unauthorized`: Missing or invalid token

---

### 3. Upload Photo

Upload photo file for a Data LSU item. Must be called after successful batch upload for each item.

#### Endpoint

```
POST /api/upload/photo
```

#### Authentication

Required (Bearer token)

#### Content Type

```
multipart/form-data
```

#### Form Fields

| Field       | Type   | Required | Description                              |
| ----------- | ------ | -------- | ---------------------------------------- |
| `file`      | File   | Yes      | Photo file (JPG, JPEG, or PNG, max 10MB) |
| `dataLsuId` | number | Yes      | Data LSU ID                              |
| `kode`      | string | Yes      | Data LSU kode (for validation)           |

#### File Requirements

- **Allowed formats**: JPG, JPEG, PNG
- **Max size**: 10MB
- **Filename**: Will be sanitized automatically

#### File Path Structure

Photos are saved to:

```
storage/app/protected/sampel/{year}/{month}/{estate}/{filename}
```

Example:

```
storage/app/protected/sampel/2026/01/NBE/photoxxxxxxx.jpg
```

Where:

- `year`: Current year (4 digits)
- `month`: Current month (2 digits, zero-padded)
- `estate`: Extracted from Master LSU
- `filename`: Sanitized original filename

#### Response

```json
{
  "success": true,
  "data": {
    "filePath": "/protected/sampel/2026/01/NBE/photoxxxxxxx.jpg"
  }
}
```

#### Example Request

```bash
curl -X POST "http://localhost:3000/api/upload/photo" \
  -H "Authorization: Bearer <access_token>" \
  -F "file=@/path/to/photo.jpg" \
  -F "dataLsuId=56" \
  -F "kode=NBE 123R"
```

#### Error Responses

- `400 Bad Request`:
  - Invalid file type
  - File size exceeds 10MB
  - Invalid dataLsuId or kode
  - Kode mismatch
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: Data LSU not found

---

## Mobile Workflow

### Authentication Flow

1. **App Launch** → Check for stored tokens
2. **If no tokens or tokens expired**:
   - Show login screen
   - User enters username and password
   - Call `POST /api/auth/login`
   - Store `accessToken` and `refreshToken` securely
   - Store user information
3. **If access token expired but refresh token valid**:
   - Call `POST /api/auth/refresh` with refresh token
   - Update stored access token
   - Retry failed request
4. **If refresh token expired**:
   - Clear stored tokens
   - Redirect to login screen

### Complete Upload Flow

1. **User scans QR code** → Extract Data LSU ID, Master LSU ID, and Kode
2. **Fetch Data LSU details** → `GET /api/data-lsu/kode/{kode}`
3. **User fills form**:
   - `tanggalTerima` (date picker)
   - `waktuTerima` (time picker)
   - `received_by` (current user ID)
   - `received_by_nama` (current user name)
   - `foto` (camera capture)
4. **Save locally as draft** (offline support)
5. **On sync/upload**:
   - **Step 1**: Batch upload → `POST /api/data-lsu/upload`
     - Send array of items with `id`, `masterLsuId`, `kode`, `foto` (filename only), `tanggalTerima`, `waktuTerima`
   - **Step 2**: For each successful item, upload photo → `POST /api/upload/photo`
     - Send actual photo file with `dataLsuId` and `kode`

### Example Mobile Implementation

#### 1. Login

```javascript
// Login function
async function login(username, password) {
  try {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ username, password }),
    });

    const result = await response.json();

    if (result.success) {
      const { accessToken, refreshToken, expiresIn, user } = result.data;

      // Store tokens securely
      await storeToken("accessToken", accessToken);
      await storeToken("refreshToken", refreshToken);
      await storeUser(user);

      // Calculate expiration time
      const expiresAt = Date.now() + expiresIn * 1000;
      await storeToken("accessTokenExpiresAt", expiresAt.toString());

      return { success: true, user };
    } else {
      return { success: false, error: result.error.message };
    }
  } catch (error) {
    return { success: false, error: "Network error occurred" };
  }
}
```

#### 2. Refresh Access Token

```javascript
// Refresh access token function
async function refreshAccessToken() {
  try {
    const refreshToken = await getToken("refreshToken");

    if (!refreshToken) {
      throw new Error("No refresh token available");
    }

    const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ refreshToken }),
    });

    const result = await response.json();

    if (result.success) {
      const { accessToken, expiresIn } = result.data;

      // Update stored access token
      await storeToken("accessToken", accessToken);
      const expiresAt = Date.now() + expiresIn * 1000;
      await storeToken("accessTokenExpiresAt", expiresAt.toString());

      return accessToken;
    } else {
      // Refresh token expired, need to login again
      await clearTokens();
      throw new Error("Refresh token expired");
    }
  } catch (error) {
    await clearTokens();
    throw error;
  }
}
```

#### 3. Authenticated API Request with Auto-Refresh

```javascript
// Make authenticated API request with automatic token refresh
async function authenticatedFetch(url, options = {}) {
  let accessToken = await getToken("accessToken");
  const expiresAt = parseInt((await getToken("accessTokenExpiresAt")) || "0");

  // Check if token is expired or about to expire (within 5 minutes)
  if (!accessToken || Date.now() >= expiresAt - 5 * 60 * 1000) {
    try {
      accessToken = await refreshAccessToken();
    } catch (error) {
      // Redirect to login
      navigateToLogin();
      throw error;
    }
  }

  // Make request with access token
  const response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      Authorization: `Bearer ${accessToken}`,
    },
  });

  // If token expired, try refreshing once more
  if (response.status === 401) {
    try {
      accessToken = await refreshAccessToken();
      // Retry request with new token
      return fetch(url, {
        ...options,
        headers: {
          ...options.headers,
          Authorization: `Bearer ${accessToken}`,
        },
      });
    } catch (error) {
      navigateToLogin();
      throw error;
    }
  }

  return response;
}
```

#### 4. Initial Sync (App Launch)

```javascript
// Fetch offline data
const response = await fetch(`${API_BASE_URL}/mobile/sync?regional=1`);
const { data } = await response.json();

// Store locally
await storeMasterSampel(data.masterSampel);
await storeMasterLsu(data.masterLsu);
```

#### 2. Scan QR Code

Data scan QR code value is like this:

```
"$ID;$MASTER_LSU_ID;$KODE"
Example: "56;3;NBE 123R"
```

#### 3. Save Draft Locally

```javascript
const draft = {
  id: data.id,
  masterLsuId: data.masterLsuId,
  kode: data.kode,
  tanggalTerima: selectedDate,
  waktuTerima: selectedTime,
  foto: photoUri, // Local file path
  timestamp: Date.now(),
};

await saveDraft(draft);
```

#### 4. Batch Upload

```javascript
// Get all drafts
const drafts = await getDrafts();

// Prepare upload payload
const uploadItems = drafts.map((draft) => ({
  id: draft.id,
  masterLsuId: draft.masterLsuId,
  kode: draft.kode,
  foto: extractFilename(draft.foto), // e.g., "photoxxxxxxx.jpg"
  tanggalTerima: draft.tanggalTerima, // Format: YYYY-MM-DD
  waktuTerima: draft.waktuTerima, // Format: HH:mm:ss
}));

// Upload batch
const response = await fetch(`${API_BASE_URL}/data-lsu/upload`, {
  method: "POST",
  headers: {
    Authorization: `Bearer ${accessToken}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify(uploadItems),
});

const { data } = await response.json();

// Process results
for (const successItem of data.success) {
  const draft = drafts.find((d) => d.id === successItem.id);

  // Upload photo
  const formData = new FormData();
  formData.append("file", {
    uri: draft.foto,
    type: "image/jpeg",
    name: extractFilename(draft.foto),
  });
  formData.append("dataLsuId", successItem.id);
  formData.append("kode", successItem.kode);

  await fetch(`${API_BASE_URL}/upload/photo`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
    body: formData,
  });

  // Remove from drafts
  await removeDraft(successItem.id);
}
```

---

## Error Handling

### Standard Error Response

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Common Error Codes

| Code                    | HTTP Status | Description                             |
| ----------------------- | ----------- | --------------------------------------- |
| `UNAUTHORIZED`          | 401         | Missing or invalid authentication token |
| `TOKEN_EXPIRED`         | 401         | Access token has expired                |
| `FORBIDDEN`             | 403         | Insufficient permissions                |
| `VALIDATION_ERROR`      | 400         | Request validation failed               |
| `NOT_FOUND`             | 404         | Resource not found                      |
| `INTERNAL_SERVER_ERROR` | 500         | Server error                            |

### Handling Token Expiration

When receiving `401 Unauthorized` or `TOKEN_EXPIRED`:

1. Use refresh token to get new access token
2. Retry the failed request with new token
3. If refresh fails, redirect to login

---

## Best Practices

### 1. Offline Support

- Store Master LSU and Master Sampel data locally after sync
- Save drafts locally before upload
- Implement retry logic for failed uploads
- Show sync status to user

### 2. Photo Handling

- Compress photos before upload to reduce size
- Validate file type and size before upload
- Show upload progress for large files
- Handle upload failures gracefully

### 3. Error Handling

- Implement retry logic with exponential backoff
- Show user-friendly error messages
- Log errors for debugging
- Handle network timeouts

### 4. Security

- Store tokens securely (Keychain/Keystore)
- Never log tokens or sensitive data
- Validate QR code data before processing
- Implement certificate pinning for production

### 5. Performance

- Batch uploads when possible
- Compress images before upload
- Use background sync for uploads
- Cache Master data locally

---

## Testing

### Test Endpoints

Use the following test data for development:

**Master LSU (Regional 1)**:

- ID: 1, Estate: "NBE", Afdeling: "Afdeling 1"

**Master Sampel**:

- ID: 1, Nama: "Sampel A"

**Data LSU**:

- ID: 1, Kode: "NBE 1A", Status: "Dikirim"

### Example Test Flow

1. **Login**: `POST /api/auth/login` with test credentials
   ```json
   {
     "username": "testuser",
     "password": "testpassword"
   }
   ```
2. **Get Current User**: `GET /api/auth/me` with access token
3. **Sync**: `GET /api/mobile/sync?regional=1`
4. **Scan QR**: `GET /api/data-lsu/kode/NBE%201A` with access token
5. **Upload**: `POST /api/data-lsu/upload` with test data and access token
6. **Upload Photo**: `POST /api/upload/photo` with test image and access token
7. **Refresh Token**: `POST /api/auth/refresh` with refresh token

---

## Changelog

### Version 1.1.0 (2026-01-XX)

- Added authentication API documentation
- Login endpoint
- Refresh token endpoint
- Logout endpoint
- Get current user endpoint
- Authentication flow examples
- Token management best practices

### Version 1.0.0 (2026-01-XX)

- Initial mobile API documentation
- Mobile sync endpoint
- Batch upload endpoint
- Photo upload endpoint
- QR code scanning support
