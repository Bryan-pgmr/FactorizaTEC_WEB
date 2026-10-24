// Selecciona la fábrica de bases de datos según la plataforma.
//  - Android / iOS: sqflite nativo (no hace falta configurar nada).
//  - Web (PWA): SQLite compilado a WebAssembly, persistido en IndexedDB.
export 'db_factory_stub.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';
