# Kovra Mobile

App móvil (Android + iOS) para cobradores/gestores de campo de Kovra:
consulta de cartera de clientes, detalle de préstamos/cuotas y registro de
pagos en línea.

## Requisitos

- Flutter SDK 3.22+ (Dart >=3.3.0 <4.0.0)
- Backend Kovra API corriendo (ver `C:\Users\acer\OneDrive\Desktop\Kovra_API`)

## Configuración del backend

El base URL de la API se resuelve automáticamente en
`lib/core/network/api_config.dart`:

- Builds de **release** (`flutter build apk/ipa/appbundle`): siempre usan
  `ApiConfig.productionBaseUrl` (HTTPS). Actualiza ese valor con la URL real
  una vez que despliegues `Kovra_API` (ver `Kovra_API/fly.toml`).
- Debug/profile, emulador Android: `http://10.0.2.2:8000`
- Debug/profile, iOS simulator / desktop: `http://localhost:8000`
- Debug/profile, dispositivo físico: pasa la IP LAN de tu backend por
  `--dart-define`, nunca la hardcodees en el código:
  ```bash
  flutter run --dart-define=LAN_OVERRIDE_URL=http://192.168.1.10:8000
  ```

## Primeros pasos

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Si es la primera vez que se abre este proyecto y faltan artefactos nativos
generados por Flutter (Gradle wrapper jar, Xcode `.xcodeproj`, iconos
`mipmap`), ejecuta:

```bash
flutter create . --platforms=android,ios --org com.kovra --project-name kovra_mobile
```

Esto completa el andamiaje nativo estándar sin sobrescribir el código Dart
ya existente en `lib/`.

## Estructura

- `lib/core`: cliente Dio, interceptor de auth, storage seguro, tema, utils.
- `lib/domain/models`: modelos de dominio (Cliente, Prestamo, Factura, Pago...).
- `lib/data/repositories`: repositorios que consumen la API REST.
- `lib/features/{auth,dashboard,clientes,prestamos,pagos,cedula}`: pantallas
  y providers Riverpod por feature.
- `lib/shared/widgets`: componentes reutilizables (ClienteCard, CuotaCard,
  badges, EmptyState/ErrorState, PrimaryButton/SecondaryButton).

## Pantallas (MVP)

1. Login
2. Dashboard (tabs Hoy/Atrasadas)
3. Buscar Cliente
4. Detalle Cliente
5. Detalle Préstamo
6. Registrar Pago
7. Recibo de Pago
8. Registrar Cliente Nuevo
