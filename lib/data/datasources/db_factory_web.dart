import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// En web usa SQLite/WASM (requiere `web/sqlite3.wasm`, ver README).
/// La variante "NoWebWorker" corre en el hilo principal y guarda los datos
/// en IndexedDB, por lo que persisten entre sesiones y funcionan sin conexión.
Future<void> configurarBaseDeDatos() async {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
