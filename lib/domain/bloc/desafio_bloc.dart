import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../entities/ejercicio.dart';
import '../../data/repositories/progreso_repository.dart';

// ─── Configuración ────────────────────────────────────────────────────────────

const kSegundosPorPregunta = 30;
const kTotalPreguntas = 5;

/// XP base por pregunta según dificultad (más generoso que el modo normal
/// porque es contrarreloj y solo se valida el resultado final, no los pasos).
const _xpDesafio = {'facil': 15, 'medio': 30, 'dificil': 50};

/// Bonus por tiempo restante: por cada segundo sobrante se suma 0.5 XP.
int _bonusTiempo(int segundosRestantes) => (segundosRestantes * 0.5).round();

// ─── Eventos ─────────────────────────────────────────────────────────────────

abstract class DesafioEvent {}

/// El alumno confirma su respuesta al ejercicio actual.
class ResponderDesafio extends DesafioEvent {
  final String respuesta;
  ResponderDesafio(this.respuesta);
}

/// Tick interno del cronómetro (cada segundo).
class _TickCronometro extends DesafioEvent {}

/// El alumno presiona una tecla del teclado.
class TeclaDesafio extends DesafioEvent {
  final String valor;
  TeclaDesafio(this.valor);
}

/// Borrar último carácter.
class BorrarDesafio extends DesafioEvent {}

// ─── Estados ─────────────────────────────────────────────────────────────────

abstract class DesafioState {}

class DesafioInicial extends DesafioState {}

class DesafioEnProgreso extends DesafioState {
  final List<Ejercicio> ejercicios;
  final int indiceActual;
  final int segundosRestantes;
  final String entradaActual;
  final List<ResultadoPregunta> historial;
  final bool tiempoAgotado; // true solo el instante que se acaba

  DesafioEnProgreso({
    required this.ejercicios,
    required this.indiceActual,
    required this.segundosRestantes,
    required this.entradaActual,
    required this.historial,
    this.tiempoAgotado = false,
  });

  Ejercicio get ejercicioActual => ejercicios[indiceActual];
  bool get esUltimo => indiceActual == ejercicios.length - 1;
  int get numero => indiceActual + 1;
  double get progreso => indiceActual / ejercicios.length;

  DesafioEnProgreso copyWith({
    int? indiceActual,
    int? segundosRestantes,
    String? entradaActual,
    List<ResultadoPregunta>? historial,
    bool? tiempoAgotado,
  }) {
    return DesafioEnProgreso(
      ejercicios: ejercicios,
      indiceActual: indiceActual ?? this.indiceActual,
      segundosRestantes: segundosRestantes ?? this.segundosRestantes,
      entradaActual: entradaActual ?? this.entradaActual,
      historial: historial ?? this.historial,
      tiempoAgotado: tiempoAgotado ?? false,
    );
  }
}

class DesafioCompletado extends DesafioState {
  final List<ResultadoPregunta> historial;
  final int xpTotal;
  final int aciertos;
  final int errores;
  final int tiempoAgotados;

  DesafioCompletado({
    required this.historial,
    required this.xpTotal,
    required this.aciertos,
    required this.errores,
    required this.tiempoAgotados,
  });
}

class ResultadoPregunta {
  final Ejercicio ejercicio;
  final String respuestaAlumno;
  final bool correcta;
  final int segundosUsados;
  final int xpObtenido;

  const ResultadoPregunta({
    required this.ejercicio,
    required this.respuestaAlumno,
    required this.correcta,
    required this.segundosUsados,
    required this.xpObtenido,
  });
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class DesafioBloc extends Bloc<DesafioEvent, DesafioState> {
  final int alumnoId;
  final ProgresoRepository _repo;
  Timer? _timer;

  DesafioBloc({required this.alumnoId, ProgresoRepository? repo})
      : _repo = repo ?? ProgresoRepository(),
        super(DesafioInicial()) {
    on<TeclaDesafio>(_onTecla);
    on<BorrarDesafio>(_onBorrar);
    on<ResponderDesafio>(_onResponder);
    on<_TickCronometro>(_onTick);
  }

  /// Inicia el desafío con los ejercicios generados para este alumno y tema.
  void iniciar(List<Ejercicio> ejercicios) {
    _iniciarCronometro();
    emit(DesafioEnProgreso(
      ejercicios: ejercicios,
      indiceActual: 0,
      segundosRestantes: kSegundosPorPregunta,
      entradaActual: '',
      historial: [],
    ));
  }

  void _iniciarCronometro() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(_TickCronometro());
    });
  }

  void _onTecla(TeclaDesafio event, Emitter<DesafioState> emit) {
    if (state is! DesafioEnProgreso) return;
    final s = state as DesafioEnProgreso;
    emit(s.copyWith(entradaActual: s.entradaActual + event.valor));
  }

  void _onBorrar(BorrarDesafio event, Emitter<DesafioState> emit) {
    if (state is! DesafioEnProgreso) return;
    final s = state as DesafioEnProgreso;
    if (s.entradaActual.isEmpty) return;
    emit(s.copyWith(
      entradaActual: s.entradaActual.substring(0, s.entradaActual.length - 1),
    ));
  }

  Future<void> _onTick(_TickCronometro event, Emitter<DesafioState> emit) async {
    if (state is! DesafioEnProgreso) return;
    final s = state as DesafioEnProgreso;

    if (s.segundosRestantes <= 1) {
      // Tiempo agotado: cuenta como respuesta incorrecta
      emit(s.copyWith(tiempoAgotado: true));
      await Future.delayed(const Duration(milliseconds: 800));
      await _registrarRespuesta(
        estado: s,
        respuesta: '',
        correcta: false,
        segundosUsados: kSegundosPorPregunta,
        emit: emit,
      );
    } else {
      emit(s.copyWith(segundosRestantes: s.segundosRestantes - 1));
    }
  }

  Future<void> _onResponder(
      ResponderDesafio event, Emitter<DesafioState> emit) async {
    if (state is! DesafioEnProgreso) return;
    final s = state as DesafioEnProgreso;

    // Solo se valida el resultado final (última expresión del paso esperado)
    final respuestaCorrecta = s.ejercicioActual.pasos.last.expresionPaso;
    final correcta = _normalizar(event.respuesta) == _normalizar(respuestaCorrecta);
    final segundosUsados = kSegundosPorPregunta - s.segundosRestantes;

    await _registrarRespuesta(
      estado: s,
      respuesta: event.respuesta,
      correcta: correcta,
      segundosUsados: segundosUsados,
      emit: emit,
    );
  }

  Future<void> _registrarRespuesta({
    required DesafioEnProgreso estado,
    required String respuesta,
    required bool correcta,
    required int segundosUsados,
    required Emitter<DesafioState> emit,
  }) async {
    final xpBase = _xpDesafio[estado.ejercicioActual.dificultad.name] ?? 15;
    final xpObtenido = correcta
        ? xpBase + _bonusTiempo(kSegundosPorPregunta - segundosUsados)
        : 0;

    final resultado = ResultadoPregunta(
      ejercicio: estado.ejercicioActual,
      respuestaAlumno: respuesta,
      correcta: correcta,
      segundosUsados: segundosUsados,
      xpObtenido: xpObtenido,
    );

    final nuevoHistorial = [...estado.historial, resultado];

    if (estado.esUltimo) {
      // Desafío terminado
      _timer?.cancel();
      final xpTotal = nuevoHistorial.fold(0, (sum, r) => sum + r.xpObtenido);
      final aciertos = nuevoHistorial.where((r) => r.correcta).length;
      final tiempoAgotados = nuevoHistorial
          .where((r) => !r.correcta && r.respuestaAlumno.isEmpty)
          .length;

      // Guardar XP en la base de datos
      if (xpTotal > 0) {
        try {
          // Usamos el repositorio existente con un ejercicio representativo
          await _repo.guardarXpDesafio(
            alumnoId: alumnoId,
            xpObtenido: xpTotal,
          );
        } catch (_) {}
      }

      emit(DesafioCompletado(
        historial: nuevoHistorial,
        xpTotal: xpTotal,
        aciertos: aciertos,
        errores: nuevoHistorial.length - aciertos,
        tiempoAgotados: tiempoAgotados,
      ));
    } else {
      // Siguiente pregunta, reiniciar cronómetro
      _iniciarCronometro();
      emit(estado.copyWith(
        indiceActual: estado.indiceActual + 1,
        segundosRestantes: kSegundosPorPregunta,
        entradaActual: '',
        historial: nuevoHistorial,
      ));
    }
  }

  String _normalizar(String expr) {
    return expr
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('×', '*')
        .replaceAll('−', '-')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('√', 'sqrt');
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
