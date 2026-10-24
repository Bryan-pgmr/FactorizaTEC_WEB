# App Educativa de Factorización Algebraica
TecNM · Instituto Tecnológico de Minatitlán · 2025–2026


## PWA (versión web instalable)

La app ahora corre también como **PWA** (Flutter Web): se instala desde el
navegador, funciona sin conexión y guarda el progreso en el propio dispositivo
(SQLite/WASM sobre IndexedDB).

### Cambios respecto a la versión móvil
- `web/` nuevo: `index.html`, `manifest.json` e iconos (normales y *maskable*).
- `lib/data/datasources/db_factory*.dart`: en web usa `sqflite_common_ffi_web`;
  en Android/iOS sigue usando sqflite nativo sin cambios.
- `lib/main.dart`: inicializa la fábrica de BD y, solo en web, centra la UI en
  una columna de 640 px máx. para que no se estire en pantallas grandes.
- `pubspec.yaml`: dependencia `sqflite_common_ffi_web`, SDK mínimo Dart 3.3.
- Todo el resto (BLoC, repositorios, pantallas, generador de ejercicios,
  esquema SQL) queda igual.

### Compilar y probar (una sola vez, requiere Flutter ≥ 3.22)
```bash
flutter pub get
dart run sqflite_common_ffi_web:setup   # genera web/sqlite3.wasm y web/sqflite_sw.js
flutter run -d chrome                   # desarrollo
flutter build web --release             # salida en build/web/
```
Si `flutter create` pide completar plataformas, ejecuta
`flutter create . --platforms=web,android` (no sobrescribe `lib/` ni `web/`).

### Publicar
Sube el contenido de `build/web/` a cualquier hosting estático **con HTTPS**
(GitHub Pages, Firebase Hosting, Netlify, Railway…). Si lo sirves desde una
subcarpeta, compila con `--base-href /subcarpeta/`.
Después, en Chrome/Edge aparece "Instalar app"; en iOS: Compartir →
"Añadir a pantalla de inicio".

### Notas
- Los datos viven en el navegador: borrar datos del sitio borra el progreso.
- Cada navegador/dispositivo tiene su propio `device_install_id`, igual que
  cada instalación móvil, así que la semilla de ejercicios sigue siendo única.
- Tras publicar una versión nueva, el service worker la descarga en segundo
  plano y se activa al cerrar y reabrir la app.
