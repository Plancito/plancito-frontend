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
├── main.dart          # Entry point — MaterialApp, session check via FutureBuilder
├── screens/           # UI pages (StatefulWidget / StatelessWidget)
├── services/          # All HTTP/API calls, one file per domain
├── models/            # Dart data classes with fromJson() factory constructors
├── widgets/           # Reusable UI components
└── utils/colors.dart  # Design tokens
```

### Service Layer

All API communication lives in `lib/services/`. Services are instantiated directly (no DI). Each service handles one domain: `auth_service.dart`, `event_service.dart`, `communities_service.dart`, `places_service.dart`, `products_service.dart`, `profile_service.dart`, etc.

- All authenticated requests include `Authorization: Bearer $token` in headers.
- JWT token is stored in `SharedPreferences` under key `authToken`.
- 15-second timeout on all HTTP calls.
- Custom exception classes per domain (e.g., `AuthException`, `EventException`).
- Logging via `dart:developer` with `[ServiceName]` prefix tags.

### State Management

No Provider, Riverpod, BLoC, or GetX — vanilla Flutter only:
- Local widget state: `setState()` in `StatefulWidget`.
- Persistence: `SharedPreferences` for auth token and user role.
- No global state container; services are called directly from widgets.

### Routing & Navigation

- Bottom navigation bar with `PageController` in `HomeScreen`.
- Role-based tab visibility: `MARKET` role shows the business/market tab (read from `SharedPreferences` key `userRole`).
- Screen transitions use `Navigator.push()`.

### Models

Plain Dart classes with `fromJson()` factory constructors mapping directly to REST API JSON. No ORM. Nested relationships are supported (e.g., `Event` has `Place`, `User`, `Community`).

## Design System

- **Primary:** `#4BBAC3` (teal)
- **Secondary:** `#F99B3F` (orange)
- **Background:** `#F5F4EF` (cream)
- Material Design with `AdaptivePlatformDensity` for responsive layout.

## Localization

- Spanish locale active: `initializeDateFormatting('es', null)` in `main.dart`.
- Timezone hardcoded to `America/Caracas` (UTC-4) via the `timezone` package.
- All user-facing error messages are in Spanish.
