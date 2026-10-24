-- ─────────────────────────────────────────────────────────────────────────────
-- SCHEMA — App educativa de factorización
-- Motor: SQLite (sqflite en Flutter)
-- Convención: snake_case, ids enteros autoincrement
-- ─────────────────────────────────────────────────────────────────────────────

PRAGMA foreign_keys = ON;

-- ─── Contenido estático (precargado, el alumno no escribe aquí) ───────────────

CREATE TABLE IF NOT EXISTS tema (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre  TEXT    NOT NULL,
  metodo  TEXT    NOT NULL,  -- slug: factor_comun | diff_cuadrados | trinomio_perfecto | trinomio_ax2 | cubos
  orden   INTEGER NOT NULL   -- orden de presentación en la UI
);

CREATE TABLE IF NOT EXISTS ejercicio (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  tema_id    INTEGER NOT NULL REFERENCES tema(id),
  expresion  TEXT    NOT NULL,   -- expresión a factorizar, ej. "x² - 9"
  dificultad TEXT    NOT NULL    -- 'facil' | 'medio' | 'dificil'
);

CREATE TABLE IF NOT EXISTS paso_esperado (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  ejercicio_id     INTEGER NOT NULL REFERENCES ejercicio(id),
  orden            INTEGER NOT NULL,
  expresion_paso   TEXT    NOT NULL,   -- respuesta normalizada que se compara
  descripcion      TEXT    NOT NULL,   -- texto que ve el alumno ("Escribe la forma factorizada")
  explicacion_error TEXT   NOT NULL,   -- mensaje si el alumno falla este paso
  pista            TEXT    NOT NULL    -- pista bajo demanda
);

-- ─── Datos del alumno (generados en uso) ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS alumno (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre          TEXT    NOT NULL,
  fecha_registro  TEXT    NOT NULL  -- ISO 8601: '2025-08-01'
);

CREATE TABLE IF NOT EXISTS progreso (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  alumno_id     INTEGER NOT NULL UNIQUE REFERENCES alumno(id),
  xp_total      INTEGER NOT NULL DEFAULT 0,
  nivel         INTEGER NOT NULL DEFAULT 1,
  racha_dias    INTEGER NOT NULL DEFAULT 0,
  ultima_sesion TEXT    -- ISO 8601, NULL si nunca completó un ejercicio
);

CREATE TABLE IF NOT EXISTS intento (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  alumno_id    INTEGER NOT NULL REFERENCES alumno(id),
  ejercicio_id INTEGER NOT NULL REFERENCES ejercicio(id),
  fecha        TEXT    NOT NULL,  -- ISO 8601 datetime
  completado   INTEGER NOT NULL DEFAULT 0,  -- 0 = falso, 1 = verdadero
  xp_obtenido  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS paso_resuelto (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  intento_id       INTEGER NOT NULL REFERENCES intento(id),
  paso_orden       INTEGER NOT NULL,
  respuesta_alumno TEXT    NOT NULL,
  es_correcto      INTEGER NOT NULL DEFAULT 0  -- 0 | 1
);

-- ─── Índices de consulta frecuente ───────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_ejercicio_tema     ON ejercicio(tema_id);
CREATE INDEX IF NOT EXISTS idx_paso_ejercicio     ON paso_esperado(ejercicio_id);
CREATE INDEX IF NOT EXISTS idx_intento_alumno     ON intento(alumno_id);
CREATE INDEX IF NOT EXISTS idx_intento_ejercicio  ON intento(ejercicio_id);
CREATE INDEX IF NOT EXISTS idx_paso_resuelto_int  ON paso_resuelto(intento_id);
