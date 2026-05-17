# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Plancito is a Flutter multi-platform app (iOS, Android, Web) for event discovery, community management, and business listings. Package name: `hackathon_frontend`.

## Common Commands

```bash
# Install Flutter and set up environment
bash install.sh

# Run in development
flutter run

# Analyze code (linting)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Build for web (production)
bash build.sh
# or manually:
flutter build web --release --dart-define-from-file=.env
```

## Environment Configuration

API base URL and secrets are injected via a `.env` file at build time using `flutter_dotenv`. The `install.sh` script handles setup and `.env` injection. The key variable is `API_BASE_URL` (defaults to `https://hackathon-back-theta.vercel.app`).

## Architecture

### Layer Structure

```
lib/
├── main.dart              # Entry point — MaterialApp + navigatorKey + onSessionExpired wiring
├── screens/               # UI pages (StatefulWidget / StatelessWidget)
├── services/              # All HTTP/API calls; all extend BaseApiService
│   └── base_api_service.dart  # Shared baseUrl, authHeaders(), handleUnauthorized()
├── models/                # Dart data classes with fromJson() factory constructors
├── widgets/               # Reusable UI components
└── utils/
    ├── colors.dart        # Design tokens (kPrimaryColor, etc.)
    ├── storage_keys.dart  # StorageKeys constants (token, userId, userRole)
    └── app_navigator.dart # appNavigatorKey — GlobalKey<NavigatorState> for service-layer navigation
```

### Service Layer

All services extend `BaseApiService` (`lib/services/base_api_service.dart`). Never instantiate services as `const`.

- `baseUrl` getter reads `API_BASE_URL` from `.env` via `flutter_dotenv`.
- `authHeaders()` returns `{'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}`.
- `handleUnauthorized()` clears SharedPreferences (token, userId, userRole) and fires `BaseApiService.onSessionExpired` (wired in `main.dart` to navigate to LoginScreen).
- Every method that calls the API must check `response.statusCode == 401` and call `await handleUnauthorized()` before throwing the session-expired exception.
- 15-second timeout on all HTTP calls.
- Custom exception classes per domain (e.g., `AuthException`, `EventException`).
- Logging via `dart:developer` with `[ServiceName]` prefix tags.

### Token Expiry & Session Redirect

`BaseApiService.onSessionExpired` is a static `VoidCallback?` set in `main.dart`:

```dart
BaseApiService.onSessionExpired = () {
  appNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (_) => false,
  );
};
```

`appNavigatorKey` is a `GlobalKey<NavigatorState>` defined in `lib/utils/app_navigator.dart` and passed as `navigatorKey` to `MaterialApp`. This lets services redirect to login without importing any screen.

### Storage Keys

Use `StorageKeys` from `lib/utils/storage_keys.dart` everywhere. Do NOT use hardcoded string literals or the deprecated `LoginStorageKeys` typedef (removed).

```dart
StorageKeys.token    // 'authToken'
StorageKeys.userId   // 'userId'
StorageKeys.userRole // 'userRole'
```

### State Management

No Provider, Riverpod, BLoC, or GetX — vanilla Flutter only:
- Local widget state: `setState()` in `StatefulWidget`.
- Persistence: `SharedPreferences` via `StorageKeys` constants.
- No global state container; services are called directly from widgets.

### Routing & Navigation

- Bottom navigation bar with `PageController` in `HomeScreen`.
- Role-based tab visibility: `MARKET` role shows the business/market tab (read from `SharedPreferences` key `StorageKeys.userRole`).
- Screen transitions use `Navigator.push()` / `Navigator.pushAndRemoveUntil()`.
- Use `MaterialPageRoute<void>(...)` (explicit type) to satisfy `very_good_analysis`.

### Models

Plain Dart classes with `fromJson()` factory constructors mapping directly to REST API JSON. No ORM. The canonical user model is `User` in `lib/models/user_model.dart` — it includes `role` and `membership` fields (previously in a separate `AuthUser` class, now removed).

## Linting

Uses `very_good_analysis` (not `flutter_lints`). Noisy stylistic rules are disabled in `analysis_options.yaml`. The goal is **0 warnings, 0 errors** from `flutter analyze`.

Key rules enforced:
- `unawaited_futures` — wrap fire-and-forget with `unawaited()` (import `dart:async`).
- `inference_failure_on_instance_creation` — always provide type args: `MaterialPageRoute<void>`, `showModalBottomSheet<void>`.
- `prefer_final_locals` — local variables that aren't reassigned must be `final`.
- `avoid_void_async` — async functions must return `Future<void>`, not `void`.

## Design System

- **Primary:** `#4BBAC3` (teal)
- **Secondary:** `#F99B3F` (orange)
- **Background:** `#F5F4EF` (cream)
- Material Design with `AdaptivePlatformDensity` for responsive layout.

## Localization

- Spanish locale active: `initializeDateFormatting('es', null)` in `main.dart`.
- Timezone hardcoded to `America/Caracas` (UTC-4) via the `timezone` package.
- All user-facing error messages are in Spanish.
