# Plancito

Aplicación móvil y web construida con Flutter para el descubrimiento de eventos, gestión de comunidades y listado de negocios/mercados. Soporta Android, iOS, Web, Linux y Windows.

## Características

- **Eventos** — Explorar, crear y gestionar eventos con calendario integrado.
- **Comunidades** — Crear y unirse a comunidades de interés.
- **Negocios** — Directorio de negocios y mercados con catálogo de productos (rol `MARKET`).
- **Chat IA** — Asistente de inteligencia artificial integrado.
- **Perfil** — Gestión de cuenta, contraseña, privacidad y notificaciones.
- **Autenticación** — Registro, login y recuperación de contraseña con JWT.

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.8.1` / Dart `^3.8.1`
- Para Android: Android SDK y un dispositivo/emulador configurado.
- Para iOS: Xcode (solo macOS).
- Para Linux: dependencias de escritorio de Flutter (`sudo apt install clang cmake ninja-build libgtk-3-dev`).
- Para Windows: Visual Studio con workload "Desarrollo de escritorio con C++".

## Variables de entorno

Crea un archivo `.env` en la raíz del proyecto antes de ejecutar o compilar:

```env
API_BASE_URL=https://tu-backend.example.com
```

| Variable       | Descripción                                   | Valor por defecto                              |
|----------------|-----------------------------------------------|------------------------------------------------|
| `API_BASE_URL` | URL base del backend REST                     | `https://hackathon-back-theta.vercel.app`      |

> El archivo `.env` debe estar presente en la raíz porque Flutter lo incluye como asset en `pubspec.yaml`. Sin él, la app usa el valor por defecto.

## Instalación y ejecución en desarrollo

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Crear el archivo .env (ver sección anterior)

# 3. Ejecutar en el dispositivo/emulador conectado
flutter run

# Ejecutar en una plataforma específica
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d linux           # Linux desktop
flutter run -d windows         # Windows desktop
```

## Compilar para producción

### Android — APK

```bash
# APK universal (debug, para pruebas rápidas)
flutter build apk --dart-define-from-file=.env

# APK universal release
flutter build apk --release --dart-define-from-file=.env

# APKs separados por arquitectura (más livianos)
flutter build apk --split-per-abi --release --dart-define-from-file=.env
```

Los artefactos se generan en `build/app/outputs/flutter-apk/`.

### Android — App Bundle (para Google Play)

```bash
flutter build appbundle --release --dart-define-from-file=.env
```

Salida: `build/app/outputs/bundle/release/app-release.aab`

### Web

```bash
# Usando el script incluido
bash build.sh

# O manualmente
flutter build web --release --dart-define-from-file=.env
```

Salida: `build/web/` — listo para desplegarse en cualquier hosting estático.

### Linux — Instalable nativo

```bash
flutter build linux --release --dart-define-from-file=.env
```

Salida: `build/linux/x64/release/bundle/` — directorio con el ejecutable y sus dependencias.

Para empaquetar como `.deb` o `.AppImage` se puede usar `flutter_distributor` o `dpkg-deb` sobre el bundle generado.

### Windows — Ejecutable

```bash
flutter build windows --release --dart-define-from-file=.env
```

Salida: `build/windows/x64/runner/Release/` — contiene el `.exe` y las DLLs necesarias.

Para generar un instalador `.msix` o `.exe` empaquetado usa el paquete [`msix`](https://pub.dev/packages/msix) o [Inno Setup](https://jrsoftware.org/isinfo.php) apuntando a esa carpeta.

### iOS (solo macOS)

```bash
flutter build ios --release --dart-define-from-file=.env
```

Requiere firma de código con una cuenta de desarrollador de Apple.

## Estructura del proyecto

```plaintext
lib/
├── main.dart              # Punto de entrada — MaterialApp, verificación de sesión
├── screens/               # Pantallas organizadas por dominio
│   ├── auth/              # Login, registro, intereses, recuperación de contraseña
│   ├── home/              # Pantalla principal con navegación inferior y calendario
│   ├── events/            # Listado, detalle y creación de eventos
│   ├── communities/       # Comunidades y detalle
│   ├── business/          # Negocios, productos (rol MARKET)
│   ├── chatai/            # Chat con IA
│   └── profile/           # Perfil, contraseña, notificaciones, soporte
├── services/              # Capa de API REST (un archivo por dominio)
├── models/                # Clases Dart con fromJson() para deserialización
├── widgets/               # Componentes reutilizables
└── utils/
    └── colors.dart        # Tokens de diseño (colores)
```

### Arquitectura

- **Servicios**: toda comunicación HTTP vive en `lib/services/`. Se instancian directamente desde los widgets; no hay inyección de dependencias. Cada request autenticado incluye el JWT en el header `Authorization: Bearer <token>`.
- **Estado**: Flutter vanilla — `setState()` para estado local, `SharedPreferences` para persistencia del token (`authToken`) y rol de usuario (`userRole`).
- **Modelos**: clases Dart planas con constructores `fromJson()`, sin ORM.
- **Navegación**: `Navigator.push()` entre pantallas; `PageController` + bottom nav bar en `HomeScreen`. El tab de negocios solo aparece si `userRole == 'MARKET'`.

## Linting y análisis

```bash
flutter analyze
```

Reglas configuradas en `analysis_options.yaml` usando `package:flutter_lints/flutter.yaml`.

## Tests

```bash
# Todos los tests
flutter test

# Un archivo específico
flutter test test/ruta/al/archivo_test.dart
```

## Configuración de zona horaria e idioma

La app inicializa el locale en español (`es`) y fija la zona horaria a **America/Caracas (UTC-4)** al arrancar en `main.dart`. Esto afecta el formato de fechas en el calendario y los eventos.
