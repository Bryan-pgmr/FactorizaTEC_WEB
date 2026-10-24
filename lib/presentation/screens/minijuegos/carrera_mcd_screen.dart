import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repositories/progreso_repository.dart';
import 'resultado_minijuego.dart';
import '../../../domain/minijuegos/minijuego_model.dart';

class CarreraMcdScreen extends StatefulWidget {
  final int alumnoId;
  final String? temaFiltro;
  const CarreraMcdScreen({super.key, required this.alumnoId, this.temaFiltro});

  @override
  State<CarreraMcdScreen> createState() => _CarreraMcdScreenState();
}

class _CarreraMcdScreenState extends State<CarreraMcdScreen>
    with TickerProviderStateMixin {
  late List<RondaMcd> _rondas;
  int _rondaActual = 0;
  int _aciertos = 0;
  int _errores = 0;
  late DateTime _inicio;
  bool _completado = false;

  // Selección del alumno
  String? _numSeleccionado;
  String? _varSeleccionada;
  bool _verificado = false;
  bool _correcto = false;

  // Animación de caída
  late AnimationController _caida;
  late Animation<double> _caidaAnim;
  Timer? _timerCaida;

  @override
  void initState() {
    super.initState();
    _inicio = DateTime.now();
    _rondas = MiniJuegoData.generarRondasMcd(temaFiltro: widget.temaFiltro);
    _iniciarCaida();
  }

  @override
  void dispose() {
    _caida.dispose();
    _timerCaida?.cancel();
    super.dispose();
  }

  void _iniciarCaida() {
    _caida = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _caidaAnim = Tween(begin: 0.0, end: 1.0).animate(_caida)
      ..addListener(() { setState(() {}); })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Tiempo agotado
          _registrarError();
        }
      });
    _caida.forward();
  }

  void _seleccionarNum(String num) {
    if (_verificado) return;
    setState(() => _numSeleccionado = num);
    _intentarVerificar();
  }

  void _seleccionarVar(String v) {
    if (_verificado) return;
    setState(() => _varSeleccionada = v);
    _intentarVerificar();
  }

  void _intentarVerificar() {
    if (_numSeleccionado == null || _varSeleccionada == null) return;
    Future.delayed(const Duration(milliseconds: 200), _verificar);
  }

  void _verificar() {
    if (_verificado) return;
    final ronda = _rondas[_rondaActual];
    final esCorrecta = _numSeleccionado == ronda.numCorrecto &&
        _varSeleccionada == ronda.varCorrecta;

    _caida.stop();
    _timerCaida?.cancel();

    setState(() {
      _verificado = true;
      _correcto = esCorrecta;
      if (esCorrecta) _aciertos++; else _errores++;
    });

    Future.delayed(const Duration(milliseconds: 1200), _siguienteRonda);
  }

  void _registrarError() {
    if (_verificado) return;
    _caida.stop();
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
    _caida.dispose();
    setState(() {
      _rondaActual++;
      _numSeleccionado = null;
      _varSeleccionada = null;
      _verificado = false;
      _correcto = false;
    });
    _iniciarCaida();
  }

  Future<void> _guardarXp() async {
    await ProgresoRepository().guardarXpDesafio(
      alumnoId: widget.alumnoId,
      xpObtenido: _calcularXp(),
    );
  }

  int _calcularXp() {
    final base = MiniJuegoTipo.carreraMcd.xpBase;
    final penalizacion = (_errores * 4).clamp(0, base - 5);
    return (base - penalizacion).clamp(5, base);
  }

  @override
  Widget build(BuildContext context) {
    if (_completado) {
      return PantallaResultadoMiniJuego(
        tipo: MiniJuegoTipo.carreraMcd,
        aciertos: _aciertos,
        errores: _errores,
        xpObtenido: _calcularXp(),
        tiempoTotal: DateTime.now().difference(_inicio),
        onReintentar: () {
          _caida.dispose();
          setState(() {
            _rondaActual = 0;
            _aciertos = 0;
            _errores = 0;
            _completado = false;
            _numSeleccionado = null;
            _varSeleccionada = null;
            _verificado = false;
            _inicio = DateTime.now();
            _rondas = MiniJuegoData.generarRondasMcd(temaFiltro: widget.temaFiltro);
            _iniciarCaida();
          });
        },
        onSalir: () => Navigator.pop(context),
      );
    }

    final theme = Theme.of(context);
    final ronda = _rondas[_rondaActual];
    final pctCaida = _caidaAnim.value;
    final colorPeligro = pctCaida < 0.5
        ? Colors.green
        : pctCaida < 0.75 ? Colors.orange : theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrera del MCD'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text('$_aciertos',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(Icons.cancel_rounded,
                  color: theme.colorScheme.error, size: 16),
              const SizedBox(width: 4),
              Text('$_errores',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Progreso
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
              const SizedBox(height: 12),

              Text('Ronda ${_rondaActual + 1} de ${_rondas.length}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),

              // ── Área de caída de términos ──
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _verificado
                        ? (_correcto ? Colors.green : theme.colorScheme.error)
                        : colorPeligro.withOpacity(0.4),
                    width: _verificado ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Barra de peligro (sube desde abajo)
                      Positioned(
                        bottom: 0,
                        left: 0, right: 0,
                        height: 180 * pctCaida,
                        child: Container(
                          color: colorPeligro.withOpacity(0.08),
                        ),
                      ),

                      // Términos cayendo
                      ...ronda.terminos.asMap().entries.map((e) {
                        final offset = e.key / ronda.terminos.length;
                        final topPct = (pctCaida + offset * 0.1).clamp(0.0, 0.85);
                        return Positioned(
                          top: 180 * topPct * (1 - offset * 0.15),
                          left: 20.0 + e.key * (MediaQuery.of(context).size.width - 80) / ronda.terminos.length,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _verificado
                                  ? (_correcto
                                      ? Colors.green.withOpacity(0.2)
                                      : theme.colorScheme.errorContainer)
                                  : theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _verificado
                                    ? (_correcto
                                        ? Colors.green
                                        : theme.colorScheme.error)
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        );
                      }),

                      // Mensaje de resultado
                      if (_verificado)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _correcto
                                  ? Colors.green
                                  : theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _correcto
                                  ? '¡Correcto! MCD = ${ronda.mcdCorrecto} 🎉'
                                  : 'Era ${ronda.mcdCorrecto} ❌',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                      // Línea de suelo
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 4,
                          color: colorPeligro.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Elige el MFC: número y variable',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),

              // ── Botones de número ──
              Row(
                children: ronda.opcionesNum.map((numOp) {
                  final seleccionado = _numSeleccionado == numOp;
                  final esCorrecta = numOp == ronda.numCorrecto;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _BotonOpcion(
                        texto: numOp,
                        seleccionado: seleccionado,
                        verificado: _verificado,
                        esCorrecta: esCorrecta,
                        onTap: () => _seleccionarNum(numOp),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // ── Botones de variable ──
              Row(
                children: ronda.opcionesVar.map((v) {
                  final seleccionada = _varSeleccionada == v;
                  final esCorrecta = v == ronda.varCorrecta;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _BotonOpcion(
                        texto: v,
                        seleccionado: seleccionada,
                        verificado: _verificado,
                        esCorrecta: esCorrecta,
                        onTap: () => _seleccionarVar(v),
                        fontMono: true,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // MCD construido en tiempo real
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: (_numSeleccionado != null && _varSeleccionada != null)
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('MCD = ',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                    Text(
                      '${_numSeleccionado ?? "?"}${_varSeleccionada ?? "?"}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: (_numSeleccionado != null &&
                                _varSeleccionada != null)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  final String texto;
  final bool seleccionado;
  final bool verificado;
  final bool esCorrecta;
  final VoidCallback onTap;
  final bool fontMono;

  const _BotonOpcion({
    required this.texto,
    required this.seleccionado,
    required this.verificado,
    required this.esCorrecta,
    required this.onTap,
    this.fontMono = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bgColor;
    Color borderColor;

    if (verificado) {
      if (esCorrecta) {
        bgColor = Colors.green.withOpacity(0.15);
        borderColor = Colors.green;
      } else if (seleccionado) {
        bgColor = theme.colorScheme.errorContainer;
        borderColor = theme.colorScheme.error;
      } else {
        bgColor = theme.colorScheme.surface;
        borderColor = theme.colorScheme.outlineVariant;
      }
    } else {
      bgColor = seleccionado
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface;
      borderColor = seleccionado
          ? theme.colorScheme.primary
          : theme.colorScheme.outlineVariant;
    }

    return GestureDetector(
      onTap: verificado ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: borderColor, width: seleccionado ? 2 : 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          style: TextStyle(
            fontFamily: fontMono ? 'monospace' : null,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: seleccionado
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
