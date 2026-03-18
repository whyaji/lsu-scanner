# Mobile auth sessions — Flutter implementation

This document describes how the Monitoring POH mobile app implements **single-device mobile sessions**, **token refresh**, **logout**, and **forced navigation to login** when the session is invalid or in conflict.

For backend domain rules (DB schema, admin revoke), see [`AUTH_MOBILE_LOGIN_AND_SESSIONS.md`](./AUTH_MOBILE_LOGIN_AND_SESSIONS.md).

---

## 1. Architecture overview

| Layer                 | Responsibility                                                                                                          |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **`ApiConstants`**    | Paths: `mobile-login`, `mobile-refresh`, `mobile-logout`                                                                |
| **`ApiService`**      | Login, refresh, logout, sync/upload (with device identity)                                                              |
| **`DeviceIdentity`**  | Stable `platformId` + `User-Agent` per device                                                                           |
| **`AuthInterceptor`** | Attach Bearer; **401 → refresh + retry**; **refresh failure → force logout**; **409 `SESSION_CONFLICT` → force logout** |
| **`AuthNotifier`**    | Persist tokens/user; **`forceLogoutFromApi`** clears storage and sets **`shouldNavigateToLogin`**                       |
| **`main.dart`**       | Root **`navigatorKey`** + **`ref.listen(authProvider)`** → **`pushNamedAndRemoveUntil('/login')`**                      |

All authenticated API traffic uses the shared **`ApiClient().dio`** instance so the interceptor always runs.

---

## 2. API endpoints (mobile)

Base URL: `ApiConstants.baseUrl` (e.g. `https://api.example.com/api`). Paths below are appended.

### 2.1 Login

|                   |                                                         |
| ----------------- | ------------------------------------------------------- |
| **Method / path** | `POST /auth/mobile-login`                               |
| **Constant**      | `ApiConstants.login`                                    |
| **Auth header**   | None                                                    |
| **Body (JSON)**   | `username`, `password`, `platformId`, `userAgent`       |
| **Extra header**  | `User-Agent: <same as userAgent in body>` (recommended) |

**Success:** Standard wrapped or unwrapped success with `accessToken`, `refreshToken`, `expiresIn`, `user`.

**Implementation:** `ApiService.login` → `LoginRequest` in `auth_models.dart`.

---

### 2.2 Refresh token

|                   |                                 |
| ----------------- | ------------------------------- |
| **Method / path** | `POST /auth/mobile-refresh`     |
| **Constant**      | `ApiConstants.mobileRefresh`    |
| **Auth header**   | None (do not send access token) |
| **Body (JSON)**   | `refreshToken`, `platformId`    |
| **Extra header**  | `User-Agent` (device string)    |

**Success:** Same shape as login: new `accessToken`, `refreshToken`, `expiresIn`, and typically `user`.

**Used by:**

- **`ApiService.refreshToken`** (explicit call if needed).
- **`AuthInterceptor._refreshToken`** on **401** (automatic, no extra app code).

**Implementation:** `MobileRefreshTokenRequest` in `auth_models.dart`.

---

### 2.3 Logout (end mobile session on server)

|                   |                                       |
| ----------------- | ------------------------------------- |
| **Method / path** | `POST /auth/mobile-logout`            |
| **Constant**      | `ApiConstants.mobileLogout`           |
| **Auth header**   | `Authorization: Bearer <accessToken>` |
| **Body (JSON)**   | `platformId`, `userAgent`             |

Soft-deletes the user’s **active mobile session** on the server so the same account can log in from another device.

**Implementation:** `ApiService.logout` → `MobileLogoutRequest`; **`AuthNotifier.logout`** calls it then clears local storage.

---

## 3. Device identity (`platformId` + `userAgent`)

Defined in **`lib/core/network/device_identity.dart`**.

- **Android:** `platformId` ≈ device id from `device_info_plus`; user agent includes brand, model, OS, id.
- **iOS:** `platformId` ≈ IDFV; user agent includes machine, OS, IDFV.

Used for:

- Login / refresh / logout bodies and headers.
- Pupuk **sync** (`platformId` query + `User-Agent`) and **upload** (query + header).

The server ties the **mobile session** to this `platformId`. If another device logs in, this device gets **409 `SESSION_CONFLICT`** on sync/upload.

---

## 4. `AuthInterceptor` behavior

**File:** `lib/core/network/interceptors/auth_interceptor.dart`

### 4.1 Request phase

- For paths that are **not** “unauthenticated auth” routes, attach **`Authorization: Bearer <accessToken>`**.
- **No Bearer** on: `mobile-login`, `mobile-refresh`, `/auth/refresh` (refresh uses refresh token in body only).

### 4.2 Response `409` — `SESSION_CONFLICT`

1. If `error.code == SESSION_CONFLICT` (JSON body).
2. Call configured callback: **`forceLogoutFromApi(message)`**.
3. **Do not** call **`mobile-logout`** here: the active session on the server belongs to the **other** device; invalidating it would log that device out incorrectly.
4. Forward the original error so callers still see failure if needed.

**User-facing message (fallback):**  
_“Akun ini aktif di perangkat lain. Silakan login kembali di perangkat ini.”_

### 4.3 Response `401` — access token expired / invalid

1. **Skip** handling for login, `mobile-login`, `mobile-refresh`, `/auth/refresh` (avoid loops).
2. If this request was **already retried** (`__auth_retry_done__`), treat as terminal → **`_forceLogoutAndForward`**.
3. Otherwise call **`_refreshToken`** (`POST mobile-refresh` with stored refresh token + `platformId`).
4. On success: persist new tokens, **retry original request once** with new access token.
5. On failure (or retry throws): **`_forceLogoutAndForward`**.

### 4.4 After refresh failure (`_forceLogoutAndForward`)

1. **`forceLogoutFromApi`** with: _“Sesi login Anda telah berakhir. Silakan login kembali.”_
2. Replace error with a synthetic **401** response carrying `UNAUTHORIZED` so UI layers parse a consistent shape.

---

## 5. Auth state & navigation to login

**File:** `lib/features/auth/providers/auth_provider.dart`

### 5.1 `forceLogoutFromApi(String message)`

- Clears secure tokens and related preferences (user, location, sync prefs).
- Sets:

  ```dart
  AuthState(error: message, shouldNavigateToLogin: true)
  ```

### 5.2 Global redirect

**File:** `lib/main.dart`

- **`MaterialApp(navigatorKey: appNavigatorKey)`**
- **`ref.listen(authProvider, …)`**: when **`shouldNavigateToLogin`** is true:
  - **`pushNamedAndRemoveUntil('/login', (route) => false)`** (clears stack from any screen: home, upload, settings, …).
  - Retries up to ~30 frames if navigator not ready.
- Then **`acknowledgeSessionTerminatedNavigation()`** clears the flag but **keeps `error`** so **LoginScreen** can show the message.

### 5.3 Normal logout vs forced logout

| Action                  | Calls `mobile-logout`? | `shouldNavigateToLogin` | Typical navigation   |
| ----------------------- | ---------------------- | ----------------------- | -------------------- |
| User taps logout        | Yes                    | No                      | Screen handles route |
| 401 after refresh fails | No                     | Yes                     | App → `/login`       |
| 409 `SESSION_CONFLICT`  | No                     | Yes                     | App → `/login`       |

---

## 6. Session conflict vs sync/upload

When the user opens the app on **device B** while **device A** holds the active mobile session:

- **Device B** may still have old tokens until they expire or refresh fails.
- **Sync** / **upload** enforce `platformId` vs server session → **409** + **`SESSION_CONFLICT`**.
- Interceptor runs **`forceLogoutFromApi`** → user is sent to **login** on device B with an explanatory **`auth.error`**.

---

## 7. Code map (quick reference)

| Topic                            | Location                                                 |
| -------------------------------- | -------------------------------------------------------- |
| Endpoint constants               | `lib/core/constants/api_constants.dart`                  |
| Login / refresh / logout HTTP    | `lib/core/network/api_service.dart`                      |
| Request models                   | `lib/core/network/models/auth_models.dart`               |
| Error helper `isSessionConflict` | `lib/core/network/models/api_response.dart`              |
| Interceptor                      | `lib/core/network/interceptors/auth_interceptor.dart`    |
| Device id / UA                   | `lib/core/network/device_identity.dart`                  |
| Auth + `forceLogoutFromApi`      | `lib/features/auth/providers/auth_provider.dart`         |
| Root navigator + listen          | `lib/main.dart`                                          |
| Sync/upload using same Dio       | `lib/features/pupuk/providers/sync_upload_provider.dart` |

---

## 8. Checklist for backend / API changes

- [ ] **`POST /auth/mobile-refresh`** accepts `{ "refreshToken", "platformId" }` and returns tokens (+ optional `user`).
- [ ] **`POST /auth/mobile-logout`** accepts Bearer + body `{ "platformId", "userAgent" }` (or document if body optional).
- [ ] Sync/upload return **409** with `{ "error": { "code": "SESSION_CONFLICT", "message": "..." } }` when `platformId` ≠ session owner.
- [ ] If refresh path renames (e.g. `mobile-request`), update **`ApiConstants.mobileRefresh`** only.

---

_Last aligned with app implementation in repo; adjust if server contract diverges._
