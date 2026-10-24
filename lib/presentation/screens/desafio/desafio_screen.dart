import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/database_helper.dart';
import '../../../data/datasources/ejercicio_generator.dart';
import '../../../domain/bloc/desafio_bloc.dart';
import '../../../domain/entities/ejercicio.dart';
import '../../widgets/teclado_matematico_desafio.dart';

// ─── Pantalla de selección de tema para el desafío ───────────────────────────

class DesafioSeleccionScreen extends StatefulWidget {
  final int alumnoId;
  const DesafioSeleccionScreen({super.key, required this.alumnoId});

  @override
  State<DesafioSeleccionScreen> createState() => _DesafioSeleccionScreenState();
}

class _DesafioSeleccionScreenState extends State<DesafioSeleccionScreen> {
  List<Map<String, dynamic>> _temas = [];
  bool _cargando = true;

  static const _iconos = {
    'factor_comun': Icons.call_merge_rounded,
    'diff_cuadrados': Icons.crop_din_rounded,
    'trinomio_perfecto': Icons.auto_awesome_rounded,
    'trinomio_ax2': Icons.functions_rounded,
    'cubos': Icons.view_in_ar_rounded,
  };

  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.obtenerTemas().then((t) {
      if (mounted) setState(() { _temas = t; _cargando = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Desafío contrarreloj')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Cabecera informativa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_rounded,
                          color: theme.colorScheme.tertiary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('5 problemas · 30 seg c/u',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onTertiaryContainer,
                                )),
                            const SizedBox(height: 2),
                            Text(
                              'Dificultad creciente. Gana XP bonus por velocidad.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onTertiaryContainer
                                    .withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text('Elige un tema',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                ..._temas.map((tema) {
                  final icono = _iconos[tema['metodo']] ?? Icons.calculate_rounded;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _iniciarDesafio(tema),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icono,
                                  color: theme.colorScheme.tertiary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(tema['nombre'],
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Icon(Icons.play_circle_rounded,
                                color: theme.colorScheme.tertiary, size: 28),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Future<void> _iniciarDesafio(Map<String, dynamic> tema) async {
    // Generar 5 ejercicios escalando dificultad:
    // 2 fáciles → 2 medios → 1 difícil
    final metodo = tema['metodo'] as String;
    final semilla = widget.alumnoId * 9999 + DateTime.now().millisecond;
    final rng = Random(semilla);

    List<Ejercicio> ejercicios = [];

    final dificultades = ['facil', 'facil', 'medio', 'medio', 'dificil'];
    for (final dif in dificultades) {
      final generados = EjercicioGenerator.generar(
        metodo: metodo,
        dificultad: dif,
        cantidad: 1,
        semilla: rng.nextInt(99999),
      );
      if (generados.isNotEmpty) {
        final g = generados.first;
        final pasos = g.pasos.asMap().entries.map((e) => PasoEsperado(
          id: -(e.key + 1),
          ejercicioId: -1,
          orden: e.key + 1,
          expresionPaso: e.value['expresion']!,
          descripcion: e.value['descripcion']!,
          explicacionError: e.value['explicacion_error']!,
          pista: e.value['pista']!,
        )).toList();

        ejercicios.add(Ejercicio(
          id: -(ejercicios.length + 1),
          temaId: tema['id'],
          expresion: g.expresion,
          dificultad: _parseDif(dif),
          pasos: pasos,
        ));
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DesafioScreen(
        ejercicios: ejercicios,
        nombreTema: tema['nombre'],
        alumnoId: widget.alumnoId,
      ),
    ));
  }

  Dificultad _parseDif(String s) {
    switch (s) {
      case 'medio': return Dificultad.medio;
      case 'dificil': return Dificultad.dificil;
      default: return Dificultad.facil;
    }
  }
}

// ─── Pantalla principal del desafío ──────────────────────────────────────────

class DesafioScreen extends StatelessWidget {
  final List<Ejercicio> ejercicios;
  final String nombreTema;
  final int alumnoId;

  const DesafioScreen({
    super.key,
    required this.ejercicios,
    required this.nombreTema,
    required this.alumnoId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DesafioBloc(alumnoId: alumnoId)..iniciar(ejercicios),
      child: _DesafioView(nombreTema: nombreTema),
    );
  }
}

class _DesafioView extends StatelessWidget {
  final String nombreTema;
  const _DesafioView({required this.nombreTema});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DesafioBloc, DesafioState>(
      listener: (context, state) {
        if (state is DesafioCompletado) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => _ResultadoDesafioScreen(state: state),
          ));
        }
      },
      builder: (context, state) {
        if (state is DesafioEnProgreso) {
          return _PantallaDesafio(state: state, nombreTema: nombreTema);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// ─── Pantalla en progreso ─────────────────────────────────────────────────────

class _PantallaDesafio extends StatelessWidget {
  final DesafioEnProgreso state;
  final String nombreTema;
  const _PantallaDesafio({required this.state, required this.nombreTema});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = state.segundosRestantes / kSegundosPorPregunta;
    final colorCrono = pct > 0.5
        ? theme.colorScheme.primary
        : pct > 0.25
            ? Colors.orange
            : theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreTema),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _confirmarAbandonar(context),
            child: const Text('Salir'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Barra de progreso de preguntas ──
              Row(
                children: List.generate(kTotalPreguntas, (i) {
                  Color color;
                  if (i < state.indiceActual) {
                    final r = state.historial[i];
                    color = r.correcta
                        ? Colors.green
                        : theme.colorScheme.error;
                  } else if (i == state.indiceActual) {
                    color = theme.colorScheme.primary;
                  } else {
                    color = theme.colorScheme.surfaceVariant;
                  }
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // ── Cronómetro + número de pregunta ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pregunta ${state.numero} de $kTotalPreguntas',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant)),
                  // Dificultad badge
                  _BadgeDificultad(dificultad: state.ejercicioActual.dificultad),
                ],
              ),
              const SizedBox(height: 12),

              // ── Cronómetro circular ──
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72, height: 72,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 6,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(colorCrono),
                    ),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: state.segundosRestantes <= 10 ? 22 : 20,
                      fontWeight: FontWeight.w700,
                      color: colorCrono,
                    ),
                    child: Text('${state.segundosRestantes}'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Expresión ──
              if (state.tiempoAgotado)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('¡Tiempo agotado!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onErrorContainer)),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Factoriza:',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Text(state.ejercicioActual.expresion,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 22,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Campo de entrada ──
                _CampoEntradaDesafio(entrada: state.entradaActual),
                const SizedBox(height: 10),

                // ── Teclado compacto ──
                TecladoMatematicoDesafio(
                  onTecla: (v) => context.read<DesafioBloc>().add(TeclaDesafio(v)),
                  onBorrar: () => context.read<DesafioBloc>().add(BorrarDesafio()),
                  onConfirmar: () => context.read<DesafioBloc>().add(
                    ResponderDesafio(state.entradaActual),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Botón confirmar ──
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: state.entradaActual.isEmpty
                        ? null
                        : () => context.read<DesafioBloc>().add(
                              ResponderDesafio(state.entradaActual),
                            ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirmar respuesta'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarAbandonar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Salir del desafío?'),
        content: const Text('Perderás el progreso de este desafío.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Salir',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Pantalla de resultado ────────────────────────────────────────────────────

class _ResultadoDesafioScreen extends StatelessWidget {
  final DesafioCompletado state;
  const _ResultadoDesafioScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctAciertos = state.aciertos / kTotalPreguntas;

    Color colorResultado;
    String mensajeResultado;
    IconData iconoResultado;

    if (pctAciertos == 1.0) {
      colorResultado = Colors.green;
      mensajeResultado = '¡Perfecto! ¡Desafío dominado!';
      iconoResultado = Icons.emoji_events_rounded;
    } else if (pctAciertos >= 0.6) {
      colorResultado = theme.colorScheme.primary;
      mensajeResultado = '¡Buen resultado!';
      iconoResultado = Icons.thumb_up_rounded;
    } else {
      colorResultado = theme.colorScheme.error;
      mensajeResultado = 'Sigue practicando';
      iconoResultado = Icons.refresh_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del desafío'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Ícono resultado ──
            Icon(iconoResultado, size: 64, color: colorResultado),
            const SizedBox(height: 12),
            Text(mensajeResultado,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700, color: colorResultado),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // ── Stats ──
            Row(
              children: [
                Expanded(child: _StatDesafio(
                    valor: '${state.aciertos}/$kTotalPreguntas',
                    etiqueta: 'Aciertos',
                    color: Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: _StatDesafio(
                    valor: '${state.errores}',
                    etiqueta: 'Errores',
                    color: theme.colorScheme.error)),
                const SizedBox(width: 10),
                Expanded(child: _StatDesafio(
                    valor: '+${state.xpTotal} XP',
                    etiqueta: 'Ganados',
                    color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Detalle por pregunta ──
            Text('Detalle',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            ...state.historial.asMap().entries.map((e) {
              final r = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: r.correcta
                      ? Colors.green.withOpacity(0.08)
                      : theme.colorScheme.errorContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: r.correcta
                        ? Colors.green.withOpacity(0.3)
                        : theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      r.correcta ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: r.correcta ? Colors.green : theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.ejercicio.expresion,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          if (!r.correcta && r.respuestaAlumno.isEmpty)
                            Text('Tiempo agotado',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.error)),
                          if (!r.correcta && r.respuestaAlumno.isNotEmpty)
                            Text('Tu resp.: ${r.respuestaAlumno}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    if (r.correcta)
                      Text('+${r.xpObtenido} XP',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // ── Botones ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Volver a la selección de tema para repetir
                  Navigator.of(context).pop();
                },
                child: const Text('Otro desafío'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
                child: const Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _CampoEntradaDesafio extends StatelessWidget {
  final String entrada;
  const _CampoEntradaDesafio({required this.entrada});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        entrada.isEmpty ? ' ' : entrada,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _BadgeDificultad extends StatelessWidget {
  final Dificultad dificultad;
  const _BadgeDificultad({required this.dificultad});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg;
    switch (dificultad) {
      case Dificultad.facil:
        bg = const Color(0xFFDCF0CE); fg = const Color(0xFF2D6A0A); break;
      case Dificultad.medio:
        bg = const Color(0xFFFAEDC8); fg = const Color(0xFF7A4F08); break;
      case Dificultad.dificil:
        bg = const Color(0xFFFFE0E0); fg = const Color(0xFF8B1A1A); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(dificultad.etiqueta,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _StatDesafio extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final Color color;
  const _StatDesafio({required this.valor, required this.etiqueta, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(valor,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(etiqueta,
              style: TextStyle(fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
