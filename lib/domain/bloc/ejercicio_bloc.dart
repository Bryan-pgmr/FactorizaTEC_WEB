import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../entities/ejercicio.dart';
import '../../data/repositories/progreso_repository.dart';

// ─── Eventos ─────────────────────────────────────────────────────────────────

abstract class EjercicioEvent {}

class VerificarPaso extends EjercicioEvent {
  final String respuestaAlumno;
  VerificarPaso(this.respuestaAlumno);
}

class TeclaPresionada extends EjercicioEvent {
  final String valor;
  TeclaPresionada(this.valor);
}

class BorrarCaracter extends EjercicioEvent {}

class SolicitarPista extends EjercicioEvent {}

class MoverCursor extends EjercicioEvent {
  final int posicion;
  MoverCursor(this.posicion);
}

// ─── Estados ─────────────────────────────────────────────────────────────────

abstract class EjercicioState {}

class EjercicioInicial extends EjercicioState {}

// Mantenido para compatibilidad, pero ya no se usa como pantalla de espera
class EjercicioGuardando extends EjercicioState {}

class EjercicioEnProgreso extends EjercicioState {
  final Ejercicio ejercicio;
  final int pasoActualIndex;
  final String entradaActual;
  final int cursorPos;
  final int erroresCometidos;
  final bool mostrarError;
  final bool mostrarPista;
  final List<bool> pasosCompletados;
  final List<({int orden, String respuesta, bool esCorrecta})> historialPasos;

  EjercicioEnProgreso({
    required this.ejercicio,
    required this.pasoActualIndex,
    required this.entradaActual,
    int? cursorPos,
    required this.erroresCometidos,
    required this.mostrarError,
    required this.mostrarPista,
    required this.pasosCompletados,
    required this.historialPasos,
  }) : cursorPos = cursorPos ?? entradaActual.length;

  PasoEsperado get pasoActual => ejercicio.pasos[pasoActualIndex];
  bool get esUltimoPaso => pasoActualIndex == ejercicio.pasos.length - 1;

  EjercicioEnProgreso copyWith({
    int? pasoActualIndex,
    String? entradaActual,
    int? cursorPos,
    int? erroresCometidos,
    bool? mostrarError,
    bool? mostrarPista,
    List<bool>? pasosCompletados,
    List<({int orden, String respuesta, bool esCorrecta})>? historialPasos,
  }) {
    final nuevaEntrada = entradaActual ?? this.entradaActual;
    final nuevoCursor = cursorPos ??
        (entradaActual != null ? nuevaEntrada.length : this.cursorPos);
    return EjercicioEnProgreso(
      ejercicio: ejercicio,
      pasoActualIndex: pasoActualIndex ?? this.pasoActualIndex,
      entradaActual: nuevaEntrada,
      cursorPos: nuevoCursor.clamp(0, nuevaEntrada.length),
      erroresCometidos: erroresCometidos ?? this.erroresCometidos,
      mostrarError: mostrarError ?? this.mostrarError,
      mostrarPista: mostrarPista ?? this.mostrarPista,
      pasosCompletados: pasosCompletados ?? this.pasosCompletados,
      historialPasos: historialPasos ?? this.historialPasos,
    );
  }
}

class PasoSuperado extends EjercicioState {
  final EjercicioEnProgreso estadoAnterior;
  PasoSuperado(this.estadoAnterior);
}

class EjercicioCompletado extends EjercicioState {
  final ResultadoProgreso resultado;
  final EjercicioEnProgreso estadoFinal;
  EjercicioCompletado({required this.resultado, required this.estadoFinal});
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class EjercicioBloc extends Bloc<EjercicioEvent, EjercicioState> {
  final int alumnoId;
  final ProgresoRepository _repo;

  EjercicioBloc({
    required this.alumnoId,
    ProgresoRepository? repo,
  })  : _repo = repo ?? ProgresoRepository(),
        super(EjercicioInicial()) {
    on<TeclaPresionada>(_onTeclaPresionada);
    on<BorrarCaracter>(_onBorrarCaracter);
    on<VerificarPaso>(_onVerificarPaso);
    on<SolicitarPista>(_onSolicitarPista);
    on<MoverCursor>(_onMoverCursor);
  }

  void iniciar(Ejercicio ejercicio) {
    emit(EjercicioEnProgreso(
      ejercicio: ejercicio,
      pasoActualIndex: 0,
      entradaActual: '',
      erroresCometidos: 0,
      mostrarError: false,
      mostrarPista: false,
      pasosCompletados: List.filled(ejercicio.pasos.length, false),
      historialPasos: const [],
    ));
  }

  void _onTeclaPresionada(TeclaPresionada event, Emitter<EjercicioState> emit) {
    if (state is! EjercicioEnProgreso) return;
    final s = state as EjercicioEnProgreso;
    final pos = s.cursorPos.clamp(0, s.entradaActual.length);
    final nueva = s.entradaActual.substring(0, pos) +
        event.valor +
        s.entradaActual.substring(pos);
    emit(s.copyWith(
      entradaActual: nueva,
      cursorPos: pos + event.valor.length,
      mostrarError: false,
    ));
  }

  void _onBorrarCaracter(BorrarCaracter event, Emitter<EjercicioState> emit) {
    if (state is! EjercicioEnProgreso) return;
    final s = state as EjercicioEnProgreso;
    if (s.entradaActual.isEmpty || s.cursorPos == 0) return;
    final pos = s.cursorPos.clamp(0, s.entradaActual.length);
    final nueva = s.entradaActual.substring(0, pos - 1) +
        s.entradaActual.substring(pos);
    emit(s.copyWith(
      entradaActual: nueva,
      cursorPos: pos - 1,
      mostrarError: false,
    ));
  }

  void _onMoverCursor(MoverCursor event, Emitter<EjercicioState> emit) {
    if (state is! EjercicioEnProgreso) return;
    final s = state as EjercicioEnProgreso;
    final nuevaPos = event.posicion.clamp(0, s.entradaActual.length);
    emit(s.copyWith(cursorPos: nuevaPos));
  }

  Future<void> _onVerificarPaso(
    VerificarPaso event,
    Emitter<EjercicioState> emit,
  ) async {
    if (state is! EjercicioEnProgreso) return;
    final s = state as EjercicioEnProgreso;

    final esCorrecta = _normalizar(event.respuestaAlumno) ==
        _normalizar(s.pasoActual.expresionPaso);

    final nuevoHistorial = [
      ...s.historialPasos,
      (
        orden: s.pasoActual.orden,
        respuesta: event.respuestaAlumno,
        esCorrecta: esCorrecta,
      ),
    ];

    if (!esCorrecta) {
      emit(s.copyWith(
        erroresCometidos: s.erroresCometidos + 1,
        mostrarError: true,
        mostrarPista: false,
        historialPasos: nuevoHistorial,
      ));
      return;
    }

    final nuevosCompletados = List<bool>.from(s.pasosCompletados);
    nuevosCompletados[s.pasoActualIndex] = true;

    if (s.esUltimoPaso) {
      // ── Calcular XP localmente y mostrar resultado de inmediato ──
      // El guardado en BD se lanza en background; si el usuario presiona
      // atrás antes de que termine, la BD igual se actualiza correctamente
      // porque el Future corre en el isolate de Dart, independiente del BLoC.
      final xpObtenido = ReglasXp.calcularXp(s.ejercicio.dificultad, s.erroresCometidos);

      // Lanzar guardado fire-and-forget (no bloquea el UI).
      // Se pasan temaId y expresion para que ejercicios generados (id<0)
      // puedan insertarse en la BD antes de crear el intento (evita FK error).
      unawaited(_repo.guardarIntentoCompletado(
        alumnoId: alumnoId,
        ejercicioId: s.ejercicio.id,
        temaId: s.ejercicio.temaId,
        expresion: s.ejercicio.expresion,
        dificultad: s.ejercicio.dificultad,
        erroresCometidos: s.erroresCometidos,
        pasos: nuevoHistorial,
      ).catchError((_) {})); // silenciar errores de red/DB

      // Obtener progreso actual para mostrar en el resultado
      // (puede estar ligeramente desactualizado si el guardado aún no terminó)
      ResultadoProgreso resultado;
      try {
        resultado = await _repo.obtenerProgresoActual(
          alumnoId: alumnoId,
          dificultad: s.ejercicio.dificultad,
          erroresCometidos: s.erroresCometidos,
        );
      } catch (_) {
        resultado = ResultadoProgreso(
          xpObtenido: xpObtenido,
          xpTotal: xpObtenido,
          nivelAnterior: 1,
          nivelNuevo: 1,
          rachaNueva: 0,
          subioDeNivel: false,
          bonusRacha: false,
        );
      }
      emit(EjercicioCompletado(resultado: resultado, estadoFinal: s));
    } else {
      final siguiente = s.copyWith(
        pasoActualIndex: s.pasoActualIndex + 1,
        entradaActual: '',
        mostrarError: false,
        mostrarPista: false,
        pasosCompletados: nuevosCompletados,
        historialPasos: nuevoHistorial,
      );
      emit(PasoSuperado(siguiente));
      await Future.delayed(const Duration(milliseconds: 600));
      emit(siguiente);
    }
  }

  void _onSolicitarPista(SolicitarPista event, Emitter<EjercicioState> emit) {
    if (state is! EjercicioEnProgreso) return;
    final s = state as EjercicioEnProgreso;
    emit(s.copyWith(mostrarPista: true, mostrarError: false));
  }

  String _normalizar(String expr) {
    var s = expr.trim().toLowerCase();

    // Normalizar símbolos antes de cualquier otra cosa
    s = s
        .replaceAll('×', '*')
        .replaceAll('·', '*')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('⁴', '^4')
        .replaceAll('⁵', '^5');

    // Caso especial: par de números (para pasos de trinomio ax²+bx+c).
    // Acepta "2 3", "2,3", "2, 3", "2 y 3" → normaliza a "2 3"
    final parRegex = RegExp(r'^(-?\d+)\s*(?:,\s*|\s+y\s+|\s+)(-?\d+)$');
    final parMatch = parRegex.firstMatch(s);
    if (parMatch != null) {
      return '${parMatch[1]} ${parMatch[2]}';
    }

    // Para todo lo demás: quitar espacios y normalizar potencias implícitas
    return s
        .replaceAll(' ', '')
        .replaceAllMapped(
          RegExp(r'([a-z])([0-9]+)'),
          (m) => '${m[1]}^${m[2]}',
        )
        .replaceAll(RegExp(r'^\((.+)\)$'), r'$1');
  }
}
