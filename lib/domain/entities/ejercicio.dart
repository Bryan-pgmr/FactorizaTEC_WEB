// ─── Entidades del dominio ───────────────────────────────────────────────────

enum Dificultad { facil, medio, dificil }

extension DificultadXp on Dificultad {
  int get xpBase {
    switch (this) {
      case Dificultad.facil:
        return 10;
      case Dificultad.medio:
        return 20;
      case Dificultad.dificil:
        return 30;
    }
  }

  String get etiqueta {
    switch (this) {
      case Dificultad.facil:
        return 'Fácil';
      case Dificultad.medio:
        return 'Medio';
      case Dificultad.dificil:
        return 'Difícil';
    }
  }
}

class PasoEsperado {
  final int id;
  final int ejercicioId;
  final int orden;
  final String expresionPaso; // respuesta correcta normalizada
  final String descripcion;   // texto que describe qué hacer en este paso
  final String explicacionError; // se muestra si el alumno falla
  final String pista;

  const PasoEsperado({
    required this.id,
    required this.ejercicioId,
    required this.orden,
    required this.expresionPaso,
    required this.descripcion,
    required this.explicacionError,
    required this.pista,
  });
}

class Ejercicio {
  final int id;
  final int temaId;
  final String expresion;
  final Dificultad dificultad;
  final List<PasoEsperado> pasos;

  const Ejercicio({
    required this.id,
    required this.temaId,
    required this.expresion,
    required this.dificultad,
    required this.pasos,
  });
}

// ─── Reglas de negocio: cálculo de XP ───────────────────────────────────────

class ReglasXp {
  static const double _penalizacionPorError = 0.15;
  static const double _pisoMinimo = 0.40;

  /// XP final = xpBase × max(0.4, 1 − errores × 0.15)
  static int calcularXp(Dificultad dificultad, int erroresCometidos) {
    final double factor = (1 - erroresCometidos * _penalizacionPorError)
        .clamp(_pisoMinimo, 1.0);
    return (dificultad.xpBase * factor).round();
  }

  /// XP acumulado necesario para SUBIR al nivel (n+1).
  /// Nivel 1→2: 100 XP, Nivel 2→3: 300 XP, Nivel 3→4: 600 XP …
  /// Fórmula: 100n + 50n(n-1) = 50n(n+1)
  static int xpParaSiguienteNivel(int nivelActual) {
    return 50 * nivelActual * (nivelActual + 1);
  }

  /// XP total acumulado hasta el inicio del nivel n (para barra de progreso).
  /// Nivel 1 empieza en 0 XP.
  static int xpParaNivel(int nivel) {
    if (nivel <= 1) return 0;
    return xpParaSiguienteNivel(nivel - 1);
  }

  /// Nivel actual dado el xp total acumulado. Mínimo nivel 1.
  static int nivelDesdeXp(int xpTotal) {
    int nivel = 1;
    while (nivel < 10 && xpTotal >= xpParaSiguienteNivel(nivel)) {
      nivel++;
    }
    return nivel;
  }
}
