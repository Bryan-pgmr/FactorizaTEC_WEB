import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'seed_data.dart';
import 'ejercicio_generator.dart';
import 'device_id_helper.dart';

/// Singleton que gestiona la conexión SQLite.
/// Uso: `final db = await DatabaseHelper.instance.database;`
class DatabaseHelper {
  static const _dbName = 'factorizacion.db';
  static const _dbVersion = 4; // v4: pasos trinomio fácil simplificados + niveles XP corregidos

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ─── Inicialización ──────────────────────────────────────────────────────

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _crearTablas(db);
    await SeedData.insertar(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Estrategia simple para versión académica: recrear todo
    // En producción se usarían migraciones incrementales
    if (oldVersion < newVersion) {
      await _eliminarTablas(db);
      await _crearTablas(db);
      await SeedData.insertar(db);
    }
  }

  Future<void> _crearTablas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tema (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre  TEXT    NOT NULL,
        metodo  TEXT    NOT NULL,
        orden   INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ejercicio (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        tema_id     INTEGER NOT NULL REFERENCES tema(id),
        expresion   TEXT    NOT NULL,
        dificultad  TEXT    NOT NULL,
        es_generado INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS paso_esperado (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        ejercicio_id      INTEGER NOT NULL REFERENCES ejercicio(id),
        orden             INTEGER NOT NULL,
        expresion_paso    TEXT    NOT NULL,
        descripcion       TEXT    NOT NULL,
        explicacion_error TEXT    NOT NULL,
        pista             TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS alumno (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre         TEXT NOT NULL,
        fecha_registro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS progreso (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        alumno_id     INTEGER NOT NULL UNIQUE REFERENCES alumno(id),
        xp_total      INTEGER NOT NULL DEFAULT 0,
        nivel         INTEGER NOT NULL DEFAULT 1,
        racha_dias    INTEGER NOT NULL DEFAULT 0,
        ultima_sesion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS intento (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        alumno_id    INTEGER NOT NULL REFERENCES alumno(id),
        ejercicio_id INTEGER NOT NULL REFERENCES ejercicio(id),
        fecha        TEXT    NOT NULL,
        completado   INTEGER NOT NULL DEFAULT 0,
        xp_obtenido  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS paso_resuelto (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        intento_id       INTEGER NOT NULL REFERENCES intento(id),
        paso_orden       INTEGER NOT NULL,
        respuesta_alumno TEXT    NOT NULL,
        es_correcto      INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ejercicio_tema    ON ejercicio(tema_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_paso_ejercicio    ON paso_esperado(ejercicio_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_intento_alumno    ON intento(alumno_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_paso_resuelto_int ON paso_resuelto(intento_id)');
  }

  Future<void> _eliminarTablas(Database db) async {
    const tablas = [
      'paso_resuelto', 'intento', 'progreso', 'alumno',
      'paso_esperado', 'ejercicio', 'tema',
    ];
    for (final t in tablas) {
      await db.execute('DROP TABLE IF EXISTS $t');
    }
  }

  // ─── CRUD: Alumno ────────────────────────────────────────────────────────

  Future<int> insertarAlumno(String nombre) async {
    final db = await database;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final id = await db.insert('alumno', {'nombre': nombre, 'fecha_registro': hoy});
    // Crear fila de progreso inicial
    await db.insert('progreso', {'alumno_id': id});
    return id;
  }

  Future<Map<String, dynamic>?> obtenerAlumno(int id) async {
    final db = await database;
    final rows = await db.query('alumno', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  // ─── CRUD: Progreso ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> obtenerProgreso(int alumnoId) async {
    final db = await database;
    final rows = await db.query(
      'progreso',
      where: 'alumno_id = ?',
      whereArgs: [alumnoId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> actualizarProgreso({
    required int alumnoId,
    required int xpNuevo,
    required int nivelNuevo,
    required int rachaNueva,
  }) async {
    final db = await database;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    await db.update(
      'progreso',
      {
        'xp_total': xpNuevo,
        'nivel': nivelNuevo,
        'racha_dias': rachaNueva,
        'ultima_sesion': hoy,
      },
      where: 'alumno_id = ?',
      whereArgs: [alumnoId],
    );
  }

  // ─── CRUD: Temas y ejercicios ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> obtenerTemas() async {
    final db = await database;
    return db.query('tema', orderBy: 'orden ASC');
  }

  Future<List<Map<String, dynamic>>> obtenerEjerciciosPorTema(int temaId) async {
    final db = await database;
    return db.query(
      'ejercicio',
      where: 'tema_id = ?',
      whereArgs: [temaId],
      orderBy: "CASE dificultad WHEN 'facil' THEN 1 WHEN 'medio' THEN 2 ELSE 3 END",
    );
  }

  Future<List<Map<String, dynamic>>> obtenerPasos(int ejercicioId) async {
    final db = await database;
    return db.query(
      'paso_esperado',
      where: 'ejercicio_id = ?',
      whereArgs: [ejercicioId],
      orderBy: 'orden ASC',
    );
  }

  // ─── CRUD: Intentos ──────────────────────────────────────────────────────

  /// Para ejercicios generados (id < 0) los inserta en la BD y devuelve
  /// su nuevo ID real, evitando la violación de FK en `intento`.
  Future<int> resolverEjercicioId({
    required int ejercicioId,
    required int temaId,
    required String expresion,
    required String dificultad,
  }) async {
    if (ejercicioId > 0) return ejercicioId;
    final db = await database;
    // Verificar si ya fue insertado antes (misma expresión y tema)
    final existing = await db.query(
      'ejercicio',
      columns: ['id'],
      where: 'tema_id = ? AND expresion = ? AND dificultad = ?',
      whereArgs: [temaId, expresion, dificultad],
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return db.insert('ejercicio', {
      'tema_id': temaId,
      'expresion': expresion,
      'dificultad': dificultad,
      'es_generado': 1,   // marca para excluirlo de la lista del seed
    });
  }

  Future<int> crearIntento({
    required int alumnoId,
    required int ejercicioId,
  }) async {
    final db = await database;
    return db.insert('intento', {
      'alumno_id': alumnoId,
      'ejercicio_id': ejercicioId,
      'fecha': DateTime.now().toIso8601String(),
      'completado': 0,
      'xp_obtenido': 0,
    });
  }

  Future<void> completarIntento({
    required int intentoId,
    required int xpObtenido,
  }) async {
    final db = await database;
    await db.update(
      'intento',
      {'completado': 1, 'xp_obtenido': xpObtenido},
      where: 'id = ?',
      whereArgs: [intentoId],
    );
  }

  Future<void> insertarPasoResuelto({
    required int intentoId,
    required int pasoOrden,
    required String respuestaAlumno,
    required bool esCorrecta,
  }) async {
    final db = await database;
    await db.insert('paso_resuelto', {
      'intento_id': intentoId,
      'paso_orden': pasoOrden,
      'respuesta_alumno': respuestaAlumno,
      'es_correcto': esCorrecta ? 1 : 0,
    });
  }

  // ─── Racha: lógica de días de semana ────────────────────────────────────

  /// Devuelve la nueva racha dado la última sesión guardada.
  /// Solo cuenta días de semana (lun–vie). Sábado y domingo no rompen ni suman.
  int calcularRacha({
    required int rachaActual,
    required String? ultimaSesion,
  }) {
    final hoy = DateTime.now();

    // Fin de semana: no hace nada
    if (hoy.weekday == DateTime.saturday || hoy.weekday == DateTime.sunday) {
      return rachaActual;
    }

    if (ultimaSesion == null) return 1;

    final ultima = DateTime.parse(ultimaSesion);
    final diff = _diasHabilesEntre(ultima, hoy);

    if (diff == 0) return rachaActual;      // ya jugó hoy
    if (diff == 1) return rachaActual + 1;  // día hábil consecutivo
    return 1;                               // rompió la racha
  }

  /// Cuenta cuántos días hábiles (lun–vie) hay entre dos fechas (sin contar la inicial).
  int _diasHabilesEntre(DateTime desde, DateTime hasta) {
    int count = 0;
    DateTime cursor = desde.add(const Duration(days: 1));
    while (!cursor.isAfter(hasta)) {
      if (cursor.weekday != DateTime.saturday &&
          cursor.weekday != DateTime.sunday) {
        count++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  /// Devuelve los 3 ejercicios base + 4 ejercicios generados por dificultad.
  /// La semilla combina alumnoId + temaId + deviceId para que cada dispositivo
  /// (instalación) obtenga ejercicios únicos aunque el alumnoId coincida.
  Future<List<Map<String, dynamic>>> obtenerEjerciciosConGenerados({
    required int temaId,
    required int alumnoId,
  }) async {
    final db = await database;
    final temas = await db.query('tema', where: 'id = ?', whereArgs: [temaId]);
    if (temas.isEmpty) return [];
    final metodo = temas.first['metodo'] as String;

    final base = await db.query(
      'ejercicio',
      where: 'tema_id = ? AND es_generado = 0',
      whereArgs: [temaId],
      orderBy: "CASE dificultad WHEN 'facil' THEN 1 WHEN 'medio' THEN 2 ELSE 3 END",
    );

    // Incluir el ID de instalación para que dispositivos distintos
    // generen ejercicios distintos aunque el alumnoId sea igual.
    final deviceId = await DeviceIdHelper.obtener();
    final semilla = alumnoId * 1000000 + temaId * 1000 + (deviceId % 1000);
    final generados = <Map<String, dynamic>>[];
    int idVirtual = -1;

    for (final dif in ['facil', 'medio', 'dificil']) {
      // Pasar las expresiones del seed para que el generador no las repita
      final expresionesSeed = base
          .where((e) => e['dificultad'] == dif)
          .map((e) => e['expresion'] as String)
          .toSet();
      final extras = EjercicioGenerator.generar(
        metodo: metodo,
        dificultad: dif,
        cantidad: 4,
        semilla: semilla + dif.hashCode,
        expresionesExistentes: expresionesSeed,
      );
      for (final e in extras) {
        // Si este ejercicio generado ya fue completado antes, habrá sido
        // insertado en la tabla ejercicio con es_generado=1. Buscarlo por
        // expresión para usar su ID real (positivo) y que _completados lo detecte.
        final existente = await db.query(
          'ejercicio',
          columns: ['id'],
          where: 'tema_id = ? AND expresion = ? AND dificultad = ? AND es_generado = 1',
          whereArgs: [temaId, e.expresion, e.dificultad],
        );
        final idReal = existente.isNotEmpty
            ? existente.first['id'] as int
            : idVirtual;
        generados.add({
          'id': idReal,
          'tema_id': temaId,
          'expresion': e.expresion,
          'dificultad': e.dificultad,
          '_pasos_generados': e.pasos,
        });
        if (existente.isEmpty) idVirtual--;
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final dif in ['facil', 'medio', 'dificil']) {
      result.addAll(base.where((e) => e['dificultad'] == dif));
      result.addAll(generados.where((e) => e['dificultad'] == dif));
    }
    return result;
  }

  /// Devuelve el conjunto de ejercicio_id que el alumno ya completó al menos una vez.
  Future<Set<int>> obtenerEjerciciosCompletados(int alumnoId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT ejercicio_id FROM intento WHERE alumno_id = ? AND completado = 1',
      [alumnoId],
    );
    return rows.map((r) => r['ejercicio_id'] as int).toSet();
  }

  /// Devuelve los pasos de un ejercicio generado (id negativo) sin tocar la DB.
  List<Map<String, dynamic>> obtenerPasosGenerados(Map<String, dynamic> row) {
    final pasos = row['_pasos_generados'];
    if (pasos == null) return [];
    return (pasos as List).asMap().entries.map((entry) {
      final p = entry.value as Map<String, String>;
      return {
        'id': -(entry.key + 1),
        'ejercicio_id': row['id'],
        'orden': entry.key + 1,
        'expresion_paso': p['expresion']!,
        'descripcion': p['descripcion']!,
        'explicacion_error': p['explicacion_error']!,
        'pista': p['pista']!,
      };
    }).toList();
  }

}