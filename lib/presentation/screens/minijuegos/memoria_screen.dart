import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../../domain/minijuegos/minijuego_model.dart';
import 'empareja_screen.dart';
import 'carrera_mcd_screen.dart';
import 'resultado_minijuego.dart';

// ─── Hub de mini juegos ───────────────────────────────────────────────────────

class MiniJuegosHubScreen extends StatelessWidget {
  final int alumnoId;
  final String? temaFiltro;
  final String? nombreTema;

  const MiniJuegosHubScreen({
    super.key,
    required this.alumnoId,
    this.temaFiltro,
    this.nombreTema,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(temaFiltro != null ? 'Mini Juegos · ${nombreTema ?? ""}' : 'Mini Juegos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🎮', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡Practica jugando!',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: theme.colorScheme.onPrimaryContainer,
                          )),
                      Text(temaFiltro != null ? 'Ejercicios de ${nombreTema ?? ""}' : 'Todos los temas mixtos',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.8),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _TarjetaJuego(
            tipo: MiniJuegoTipo.memoria,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MemoriaParejas(alumnoId: alumnoId, temaFiltro: temaFiltro),
            )),
          ),
          const SizedBox(height: 12),
          _TarjetaJuego(
            tipo: MiniJuegoTipo.empareja,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => EmparejaScreen(alumnoId: alumnoId, temaFiltro: temaFiltro),
            )),
          ),
          const SizedBox(height: 12),
          _TarjetaJuego(
            tipo: MiniJuegoTipo.carreraMcd,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CarreraMcdScreen(alumnoId: alumnoId, temaFiltro: temaFiltro),
            )),
          ),
        ],
      ),
    );
  }
}

class _TarjetaJuego extends StatelessWidget {
  final MiniJuegoTipo tipo;
  final VoidCallback onTap;
  const _TarjetaJuego({required this.tipo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outlineVariant, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(tipo.icono, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tipo.nombre,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(tipo.descripcion,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('+${tipo.xpBase} XP base',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded,
                color: theme.colorScheme.primary, size: 28),
          ],
        ),
      ),
    );
  }
}

// ─── Memoria de Parejas ───────────────────────────────────────────────────────

class MemoriaParejas extends StatefulWidget {
  final int alumnoId;
  final String? temaFiltro;
  const MemoriaParejas({super.key, required this.alumnoId, this.temaFiltro});

  @override
  State<MemoriaParejas> createState() => _MemoriaParejasState();
}

class _MemoriaParejasState extends State<MemoriaParejas> {
  // Cada carta: {id, texto, tipo ('expr'|'fact'), parejId, volteada, resuelta}
  late List<Map<String, dynamic>> _cartas;
  int? _primerIndex;
  bool _bloqueado = false;
  int _aciertos = 0;
  int _errores = 0;
  late DateTime _inicio;
  bool _completado = false;

  @override
  void initState() {
    super.initState();
    _inicio = DateTime.now();
    _inicializar();
  }

  void _inicializar() {
    final pares = MiniJuegoData.generarPares(temaFiltro: widget.temaFiltro);
    final cartas = <Map<String, dynamic>>[];
    for (int i = 0; i < pares.length; i++) {
      cartas.add({
        'id': i * 2,
        'texto': pares[i].expresionDesarrollada,
        'parejId': i * 2 + 1,
        'volteada': false,
        'resuelta': false,
      });
      cartas.add({
        'id': i * 2 + 1,
        'texto': pares[i].expresionFactorizada,
        'parejId': i * 2,
        'volteada': false,
        'resuelta': false,
      });
    }
    cartas.shuffle();
    setState(() { _cartas = cartas; });
  }

  void _tocarCarta(int index) {
    if (_bloqueado) return;
    final carta = _cartas[index];
    if (carta['volteada'] || carta['resuelta']) return;

    setState(() { _cartas[index]['volteada'] = true; });

    if (_primerIndex == null) {
      _primerIndex = index;
      return;
    }

    // Segunda carta
    final primero = _cartas[_primerIndex!];
    final segundo = _cartas[index];
    _bloqueado = true;

    if (primero['parejId'] == segundo['id']) {
      // Acierto
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() {
          _cartas[_primerIndex!]['resuelta'] = true;
          _cartas[index]['resuelta'] = true;
          _aciertos++;
          _primerIndex = null;
          _bloqueado = false;
          if (_aciertos == _cartas.length ~/ 2) {
            _completado = true;
            _guardarXp();
          }
        });
      });
    } else {
      // Error
      Future.delayed(const Duration(milliseconds: 900), () {
        setState(() {
          _cartas[_primerIndex!]['volteada'] = false;
          _cartas[index]['volteada'] = false;
          _errores++;
          _primerIndex = null;
          _bloqueado = false;
        });
      });
    }
  }

  Future<void> _guardarXp() async {
    final xp = _calcularXp();
    await ProgresoRepository().guardarXpDesafio(
      alumnoId: widget.alumnoId,
      xpObtenido: xp,
    );
  }

  int _calcularXp() {
    final base = MiniJuegoTipo.memoria.xpBase;
    final penalizacion = (_errores * 2).clamp(0, base - 5);
    return (base - penalizacion).clamp(5, base);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_completado) {
      return PantallaResultadoMiniJuego(
        tipo: MiniJuegoTipo.memoria,
        aciertos: _aciertos,
        errores: _errores,
        xpObtenido: _calcularXp(),
        tiempoTotal: DateTime.now().difference(_inicio),
        onReintentar: () => setState(() {
          _aciertos = 0;
          _errores = 0;
          _completado = false;
          _primerIndex = null;
          _bloqueado = false;
          _inicio = DateTime.now();
          _inicializar();
        }),
        onSalir: () => Navigator.pop(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoria de Parejas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text('$_aciertos',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Icon(Icons.cancel_rounded,
                    color: theme.colorScheme.error, size: 16),
                const SizedBox(width: 4),
                Text('$_errores',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Progreso
            LinearProgressIndicator(
              value: _aciertos / (_cartas.length / 2),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text('${_aciertos} de ${_cartas.length ~/ 2} pares encontrados',
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),

            // Grid de cartas 4×4
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: _cartas.length,
                itemBuilder: (context, i) => _Carta(
                  carta: _cartas[i],
                  onTap: () => _tocarCarta(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Carta extends StatelessWidget {
  final Map<String, dynamic> carta;
  final VoidCallback onTap;
  const _Carta({required this.carta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final volteada = carta['volteada'] as bool;
    final resuelta = carta['resuelta'] as bool;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: resuelta
              ? Colors.green.withOpacity(0.15)
              : volteada
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: resuelta
                ? Colors.green
                : volteada
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
            width: resuelta || volteada ? 1.5 : 0.5,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: volteada || resuelta
            ? Text(
                carta['texto'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: resuelta
                      ? Colors.green.shade700
                      : theme.colorScheme.onPrimaryContainer,
                ),
              )
            : Icon(Icons.help_outline_rounded,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                size: 24),
      ),
    );
  }
}
