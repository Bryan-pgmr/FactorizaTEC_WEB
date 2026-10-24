import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../../domain/minijuegos/minijuego_model.dart';
import 'resultado_minijuego.dart';

class EmparejaScreen extends StatefulWidget {
  final int alumnoId;
  final String? temaFiltro;
  const EmparejaScreen({super.key, required this.alumnoId, this.temaFiltro});

  @override
  State<EmparejaScreen> createState() => _EmparejaScreenState();
}

class _EmparejaScreenState extends State<EmparejaScreen> {
  late List<RondaEmpareja> _rondas;
  int _rondaActual = 0;
  int _segundos = 20;
  int _aciertos = 0;
  int _errores = 0;
  Timer? _timer;
  late DateTime _inicio;
  bool _completado = false;

  // Selección del alumno (máximo 2)
  final List<int> _seleccionados = [];
  bool _verificado = false;
  bool _correcto = false;

  @override
  void initState() {
    super.initState();
    _inicio = DateTime.now();
    _rondas = MiniJuegoData.generarRondasEmpareja(temaFiltro: widget.temaFiltro);
    _iniciarCronometro();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarCronometro() {
    _timer?.cancel();
    _segundos = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() { _segundos--; });
      if (_segundos <= 0) {
        _timer?.cancel();
        _registrarError();
      }
    });
  }

  void _tocarOpcion(int index) {
    if (_verificado) return;
    if (_seleccionados.contains(index)) {
      setState(() => _seleccionados.remove(index));
      return;
    }
    if (_seleccionados.length >= 2) return;
    setState(() => _seleccionados.add(index));

    // Auto-verificar cuando selecciona 2
    if (_seleccionados.length == 2) {
      Future.delayed(const Duration(milliseconds: 300), _verificar);
    }
  }

  void _verificar() {
    final ronda = _rondas[_rondaActual];
    final correctos = ronda.indicesCorrectos.toSet();
    final seleccionados = _seleccionados.toSet();
    final esCorrecta = correctos.containsAll(seleccionados) &&
        seleccionados.containsAll(correctos);

    _timer?.cancel();
    setState(() {
      _verificado = true;
      _correcto = esCorrecta;
      if (esCorrecta) _aciertos++; else _errores++;
    });

    Future.delayed(const Duration(milliseconds: 1200), _siguienteRonda);
  }

  void _registrarError() {
    setState(() {
      _verificado = true;
      _correcto = false;
      _errores++;
    });
    Future.delayed(const Duration(milliseconds: 800), _siguienteRonda);
  }

  void _siguienteRonda() {
    if (_rondaActual >= _rondas.length - 1) {
      setState(() => _completado = true);
      _guardarXp();
      return;
    }
    setState(() {
      _rondaActual++;
      _seleccionados.clear();
      _verificado = false;
      _correcto = false;
    });
    _iniciarCronometro();
  }

  Future<void> _guardarXp() async {
    await ProgresoRepository().guardarXpDesafio(
      alumnoId: widget.alumnoId,
      xpObtenido: _calcularXp(),
    );
  }

  int _calcularXp() {
    final base = MiniJuegoTipo.empareja.xpBase;
    final penalizacion = (_errores * 3).clamp(0, base - 5);
    return (base - penalizacion).clamp(5, base);
  }

  @override
  Widget build(BuildContext context) {
    if (_completado) {
      return PantallaResultadoMiniJuego(
        tipo: MiniJuegoTipo.empareja,
        aciertos: _aciertos,
        errores: _errores,
        xpObtenido: _calcularXp(),
        tiempoTotal: DateTime.now().difference(_inicio),
        onReintentar: () => setState(() {
          _rondaActual = 0;
          _aciertos = 0;
          _errores = 0;
          _completado = false;
          _seleccionados.clear();
          _verificado = false;
          _inicio = DateTime.now();
          _rondas = MiniJuegoData.generarRondasEmpareja(temaFiltro: widget.temaFiltro);
          _iniciarCronometro();
        }),
        onSalir: () => Navigator.pop(context),
      );
    }

    final theme = Theme.of(context);
    final ronda = _rondas[_rondaActual];
    final pctTiempo = _segundos / 20;
    final colorTiempo = pctTiempo > 0.5
        ? theme.colorScheme.primary
        : pctTiempo > 0.25 ? Colors.orange : theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empareja Flotante'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text('$_aciertos', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(Icons.cancel_rounded, color: theme.colorScheme.error, size: 16),
              const SizedBox(width: 4),
              Text('$_errores', style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Progreso de rondas
              Row(
                children: List.generate(_rondas.length, (i) => Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i < _rondaActual
                          ? theme.colorScheme.primary
                          : i == _rondaActual
                              ? theme.colorScheme.primary.withOpacity(0.4)
                              : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),

              // Cronómetro
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ronda ${_rondaActual + 1} de ${_rondas.length}',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant)),
                  Row(children: [
                    Icon(Icons.timer_rounded, color: colorTiempo, size: 18),
                    const SizedBox(width: 4),
                    Text('$_segundos seg',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorTiempo)),
                  ]),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pctTiempo,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(colorTiempo),
                ),
              ),
              const SizedBox(height: 20),

              // Expresión central
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: _verificado
                      ? (_correcto
                          ? Colors.green.withOpacity(0.1)
                          : theme.colorScheme.errorContainer.withOpacity(0.4))
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _verificado
                        ? (_correcto ? Colors.green : theme.colorScheme.error)
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: _verificado ? 2 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text('Factoriza:',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Text(ronda.expresion,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 26,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                    if (_verificado) ...[
                      const SizedBox(height: 8),
                      Text(
                        _correcto ? '¡Correcto! 🎉' : 'Incorrecto ❌',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _correcto
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('Toca los 2 factores correctos',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),

              // Grid de opciones 2×3
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: ronda.opciones.length,
                  itemBuilder: (context, i) {
                    final seleccionada = _seleccionados.contains(i);
                    final esCorrecta = ronda.indicesCorrectos.contains(i);
                    Color bgColor;
                    Color borderColor;

                    if (_verificado) {
                      if (esCorrecta) {
                        bgColor = Colors.green.withOpacity(0.15);
                        borderColor = Colors.green;
                      } else if (seleccionada) {
                        bgColor = theme.colorScheme.errorContainer;
                        borderColor = theme.colorScheme.error;
                      } else {
                        bgColor = theme.colorScheme.surface;
                        borderColor = theme.colorScheme.outlineVariant;
                      }
                    } else {
                      bgColor = seleccionada
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface;
                      borderColor = seleccionada
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant;
                    }

                    return GestureDetector(
                      onTap: () => _tocarOpcion(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: borderColor,
                              width: seleccionada ? 2 : 0.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ronda.opciones[i],
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: seleccionada
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
