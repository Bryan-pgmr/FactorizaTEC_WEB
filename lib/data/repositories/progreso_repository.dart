import '../datasources/database_helper.dart';
import '../../domain/entities/ejercicio.dart';

class ResultadoProgreso {
  final int xpObtenido;
  final int xpTotal;
  final int nivelAnterior;
  final int nivelNuevo;
  final int rachaNueva;
  final bool subioDeNivel;
  final bool bonusRacha;

  const ResultadoProgreso({
    required this.xpObtenido,
    required this.xpTotal,
    required this.nivelAnterior,
    required this.nivelNuevo,
    required this.rachaNueva,
    required this.subioDeNivel,
    required this.bonusRacha,
  });
}

class ProgresoRepository {
  final DatabaseHelper _db;
  ProgresoRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<ResultadoProgreso> guardarIntentoCompletado({
    required int alumnoId,
    required int ejercicioId,
    required int temaId,
    required String expresion,
    required Dificultad dificultad,
    required int erroresCometidos,
    required List<({int orden, String respuesta, bool esCorrecta})> pasos,
  }) async {
    final progresoActual = await _db.obtenerProgreso(alumnoId);
    final rachaActual = progresoActual?['racha_dias'] ?? 0;
    final ultimaSesion = progresoActual?['ultima_sesion'] as String?;
    final xpActual = progresoActual?['xp_total'] ?? 0;
    final nivelActual = progresoActual?['nivel'] ?? 1;

    final rachaNueva = _db.calcularRacha(
      rachaActual: rachaActual,
      ultimaSesion: ultimaSesion,
    );

    final esMultiploRacha = rachaNueva > 0 && rachaNueva % 5 == 0;
    final bonusRacha = esMultiploRacha && rachaNueva != rachaActual;

    int xpObtenido = ReglasXp.calcularXp(dificultad, erroresCometidos);
    if (bonusRacha) xpObtenido += 5;

    // Ejercicios generados (id < 0) no existen en la BD: los insertamos
    // primero para no violar la FK de la tabla `intento`.
    final idReal = await _db.resolverEjercicioId(
      ejercicioId: ejercicioId,
      temaId: temaId,
      expresion: expresion,
      dificultad: dificultad.name,
    );

    final intentoId = await _db.crearIntento(
      alumnoId: alumnoId,
      ejercicioId: idReal,
    );

    for (final paso in pasos) {
      await _db.insertarPasoResuelto(
        intentoId: intentoId,
        pasoOrden: paso.orden,
        respuestaAlumno: paso.respuesta,
        esCorrecta: paso.esCorrecta,
      );
    }

    await _db.completarIntento(intentoId: intentoId, xpObtenido: xpObtenido);

    final xpNuevo = xpActual + xpObtenido;
    final nivelNuevo = ReglasXp.nivelDesdeXp(xpNuevo).clamp(1, 10);

    await _db.actualizarProgreso(
      alumnoId: alumnoId,
      xpNuevo: xpNuevo,
      nivelNuevo: nivelNuevo,
      rachaNueva: rachaNueva,
    );

    return ResultadoProgreso(
      xpObtenido: xpObtenido,
      xpTotal: xpNuevo,
      nivelAnterior: nivelActual,
      nivelNuevo: nivelNuevo,
      rachaNueva: rachaNueva,
      subioDeNivel: nivelNuevo > nivelActual,
      bonusRacha: bonusRacha,
    );
  }

  /// Calcula y devuelve el resultado que se mostrará al alumno SIN escribir
  /// en BD. Se usa en el BLoC para mostrar el resultado de inmediato
  /// mientras el guardado real corre en background.
  Future<ResultadoProgreso> obtenerProgresoActual({
    required int alumnoId,
    required Dificultad dificultad,
    required int erroresCometidos,
  }) async {
    final progresoActual = await _db.obtenerProgreso(alumnoId);
    final rachaActual = progresoActual?['racha_dias'] ?? 0;
    final ultimaSesion = progresoActual?['ultima_sesion'] as String?;
    final xpActual = progresoActual?['xp_total'] ?? 0;
    final nivelActual = progresoActual?['nivel'] ?? 1;

    final rachaNueva = _db.calcularRacha(
      rachaActual: rachaActual,
      ultimaSesion: ultimaSesion,
    );
    final esMultiploRacha = rachaNueva > 0 && rachaNueva % 5 == 0;
    final bonusRacha = esMultiploRacha && rachaNueva != rachaActual;

    int xpObtenido = ReglasXp.calcularXp(dificultad, erroresCometidos);
    if (bonusRacha) xpObtenido += 5;

    final xpNuevo = xpActual + xpObtenido;
    final nivelNuevo = ReglasXp.nivelDesdeXp(xpNuevo).clamp(1, 10);

    return ResultadoProgreso(
      xpObtenido: xpObtenido,
      xpTotal: xpNuevo,
      nivelAnterior: nivelActual,
      nivelNuevo: nivelNuevo,
      rachaNueva: rachaNueva,
      subioDeNivel: nivelNuevo > nivelActual,
      bonusRacha: bonusRacha,
    );
  }

  /// Guarda XP ganado en mini juegos y desafíos directamente en el progreso.
  Future<void> guardarXpDesafio({
    required int alumnoId,
    required int xpObtenido,
  }) async {
    final progresoActual = await _db.obtenerProgreso(alumnoId);
    final xpActual = progresoActual?['xp_total'] ?? 0;
    final rachaActual = progresoActual?['racha_dias'] ?? 0;
    final ultimaSesion = progresoActual?['ultima_sesion'] as String?;

    final xpNuevo = xpActual + xpObtenido;
    final nivelNuevo = ReglasXp.nivelDesdeXp(xpNuevo).clamp(1, 10);
    final rachaNueva = _db.calcularRacha(
      rachaActual: rachaActual,
      ultimaSesion: ultimaSesion,
    );

    await _db.actualizarProgreso(
      alumnoId: alumnoId,
      xpNuevo: xpNuevo,
      nivelNuevo: nivelNuevo,
      rachaNueva: rachaNueva,
    );
  }
}
