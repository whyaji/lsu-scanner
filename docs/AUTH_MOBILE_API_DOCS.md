# Mobile API — Implementation Guide

API reference for the **mobile app** implementation. Covers auth, single-device session, sync, and upload endpoints. Backend details (schema, services) are in [AUTH_MOBILE_LOGIN_AND_SESSIONS.md](./AUTH_MOBILE_LOGIN_AND_SESSIONS.md).

---

## 1. Base URL & authentication

- **Base URL:** `{API_BASE}/api` (e.g. `https://your-api.example.com/api`).
- **Auth:** After login, send the access token in every protected request:
  - **Header:** `Authorization: Bearer <accessToken>`
  - Store `accessToken` and `refreshToken` in secure storage (e.g. Flutter Secure Storage); **no cookies** are used for mobile.
- **Token expiry:** `expiresIn` is in seconds (e.g. 3600). Use the refresh token flow (e.g. `POST /api/auth/refresh`) when the access token expires.

---

## 2. Mobile login (single-device session)

**One active session per user.** If the user is already logged in on another device, login fails with a specific error. The app must send a stable **device identifier** (`platformId`) and **User-Agent** on login and optionally on sync/upload to refresh session activity.

### `POST /api/auth/mobile-login`

Login for mobile. Tokens are returned in the JSON body; store them securely.

**Request**

- **Content-Type:** `application/json`
- **Body:**

| Field        | Type   | Required | Description                                      |
| ------------ | ------ | -------- | ------------------------------------------------ |
| `username`   | string | Yes      | Username (same as web)                           |
| `password`   | string | Yes      | Password                                         |
| `platformId` | string | Yes      | Device ID (e.g. from `device_info` / Android ID) |
| `userAgent`  | string | Yes      | Client User-Agent string                         |

**Example**

```json
{
  "username": "user@example.com",
  "password": "secret",
  "platformId": "abc123-device-id",
  "userAgent": "LSU-Mobile/1.0 (Android 12)"
}
```

**Success (200)**

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresIn": 3600,
    "user": {
      "id": 1,
      "username": "user@example.com",
      "nama": "Nama User",
      "jabatan": "Jabatan",
      "lokasiKerja": "Lokasi",
      "isAdmin": false,
      "access": ["lsu"]
    }
  }
}
```

**Errors**

- **400** — Validation (e.g. missing `platformId` or `userAgent`). Body includes `issues` array.
- **401** — Invalid credentials, inactive user, or no project access. Message in response.
- **401** — `"Pengguna sudah login di perangkat lain"` — user is already logged in on another device; show this message and optionally offer “Revoke other device” if your app supports it (admin can call `DELETE /api/auth/mobile-sessions/:userId`).
- **500** — Server error.

**Implementation notes**

- Obtain `platformId` from the device (e.g. Flutter `device_info_plus`: Android ID / iOS identifierForVendor) and keep it stable for the app install.
- Send the same `platformId` and a consistent `User-Agent` on login and on sync/upload so the backend can tie activity to one device and refresh `last_activity_at`.

---

## 3. Session refresh (optional on sync & upload)

After login, the backend keeps **one active mobile session** per user. You can refresh that session (update `last_activity_at` and device info) so the server knows the user is still active on this device.

**How:** On the following endpoints, send **both**:

- **Query:** `platformId=<device_id>`
- **Header:** `User-Agent: <your app user-agent>`

If both are present, the server calls `upsertUserMobileSession` before handling the request. You don’t need to call login again.

**Endpoints that support session refresh**

| Method | Endpoint                        | Session refresh      |
| ------ | ------------------------------- | -------------------- |
| GET    | `/api/mobile/sync-sampel-lsu`   | Yes (query + header) |
| GET    | `/api/mobile/sync-sampel-pupuk` | Yes                  |
| POST   | `/api/data-lsu/upload`          | Yes                  |
| POST   | `/api/data-lsu/upload-complete` | Yes                  |
| POST   | `/api/data-sampel-pupuk/upload` | Yes                  |

**Example (sync with session refresh)**

```http
GET /api/mobile/sync-sampel-lsu?regional=1&platformId=abc123-device-id
Authorization: Bearer <accessToken>
User-Agent: LSU-Mobile/1.0 (Android 12)
```

---

## 4. Sync APIs

Both require **auth** (`Authorization: Bearer <accessToken>`). Optional session refresh: add `platformId` in query and `User-Agent` in header.

### `GET /api/mobile/sync-sampel-lsu`

Offline sync data for Master Sampel and Master LSU by regional.

**Query**

| Param        | Type   | Required | Description                     |
| ------------ | ------ | -------- | ------------------------------- |
| `regional`   | number | Yes      | 1–5                             |
| `platformId` | string | No       | Device ID (for session refresh) |

**Headers**

- `Authorization: Bearer <accessToken>`
- `User-Agent` (optional; with `platformId` for session refresh)

**Success (200)**

```json
{
  "success": true,
  "data": {
    "masterSampel": [...],
    "masterLsu": [...],
    "user": { "id": 1, "username": "...", "nama": "...", ... }
  }
}
```

**Errors:** 400 (missing/invalid `regional`), 401 (not authenticated), 500.

---

### `GET /api/mobile/sync-sampel-pupuk`

Same as above but returns Sampel Pupuk sync data.

**Query:** `regional` (required, 1–5), `platformId` (optional).  
**Headers:** Same as sync-sampel-lsu.  
**Success (200):** `{ ...syncData, user }`.

---

## 5. Data upload APIs

All require **auth**. Optional session refresh: `platformId` in query + `User-Agent` in header.

### `POST /api/data-lsu/upload`

Batch upload LSU data.

**Query:** `platformId` (optional, for session refresh).  
**Headers:** `Authorization: Bearer <accessToken>`, `Content-Type: application/json`, `User-Agent` (optional).  
**Body:** JSON validated by backend `uploadDataLsuSchema` (see backend or OpenAPI for exact shape).  
**Success (200):** Result of batch upload.  
**Errors:** 400 (validation), 500.

---

### `POST /api/data-lsu/upload-complete`

Batch mark LSU data as complete (Selesai).

**Query:** `platformId` (optional).  
**Headers:** Same as upload.  
**Body:** JSON validated by `uploadCompleteDataLsuSchema`.  
**Success (200):** Result of upload-complete.  
**Errors:** 400, 500.

---

### `POST /api/data-sampel-pupuk/upload`

Upload Data Sampel Pupuk.

**Query:** `platformId` (optional).  
**Headers:** Same as above.  
**Body:** JSON validated by `uploadDataSampelPupukSchema`.  
**Success (200):** Result of processUpload.  
**Errors:** 400, 500.

---

## 6. Error response format

All error responses follow a common shape:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request body",
    "details": []
  }
}
```

- **code:** e.g. `VALIDATION_ERROR`, `UNAUTHORIZED`, `FORBIDDEN`, `INVALID_CREDENTIALS`, `INTERNAL_SERVER_ERROR`.
- **message:** Human-readable message.
- **details:** Optional (e.g. Zod validation `issues` for 400).

Use `code` and `message` to show the right UI (e.g. “Pengguna sudah login di perangkat lain” for single-device conflict).

---

## 7. Implementation checklist (mobile app)

1. **Config:** Set `API_BASE` and use `/api` prefix for all endpoints.
2. **Login:** Call `POST /api/auth/mobile-login` with `username`, `password`, `platformId`, `userAgent`. Store `accessToken`, `refreshToken`, and `user` in secure storage.
3. **Device ID:** Get a stable `platformId` (e.g. Android ID / iOS identifierForVendor) and use the same value for login and for session refresh on sync/upload.
4. **Requests:** For every protected request, set `Authorization: Bearer <accessToken>`. Optionally add `User-Agent` and query `platformId` on sync and upload endpoints to refresh session.
5. **Token refresh:** When the access token expires (e.g. 401), call `POST /api/auth/refresh` with `{ "refreshToken": "..." }`, then retry the request with the new `accessToken`.
6. **Single-device error:** If mobile-login returns `"Pengguna sudah login di perangkat lain"`, show a clear message; optionally allow the user to contact an admin to revoke the other session (`DELETE /api/auth/mobile-sessions/:userId`).
7. **Sync:** Use `GET /api/mobile/sync-sampel-lsu` and `GET /api/mobile/sync-sampel-pupuk` with `regional=1..5` and optional `platformId` + `User-Agent`.
8. **Upload:** Use `POST /api/data-lsu/upload`, `POST /api/data-lsu/upload-complete`, and `POST /api/data-sampel-pupuk/upload` with the required JSON bodies; add `platformId` and `User-Agent` when you want to refresh the session.

For backend behaviour (single-session rule, schema, services), see [AUTH_MOBILE_LOGIN_AND_SESSIONS.md](./AUTH_MOBILE_LOGIN_AND_SESSIONS.md).
