import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/datasources/database_helper.dart';
import '../../../data/datasources/teoria_content.dart';
import '../../../data/datasources/ejercicio_generator.dart';
import '../minijuegos/memoria_screen.dart';
import '../../../domain/entities/ejercicio.dart';
import '../ejercicio/ejercicio_screen.dart';

class EjerciciosScreen extends StatefulWidget {
  final Map<String, dynamic> tema;
  final int alumnoId;

  const EjerciciosScreen({
    super.key,
    required this.tema,
    required this.alumnoId,
  });

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  List<Map<String, dynamic>> _ejercicios = [];
  Set<int> _completados = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final db = DatabaseHelper.instance;
      final results = await Future.wait([
        db.obtenerEjerciciosConGenerados(
          temaId: widget.tema['id'],
          alumnoId: widget.alumnoId,
        ),
        db.obtenerEjerciciosCompletados(widget.alumnoId),
      ]).timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _ejercicios = results[0] as List<Map<String, dynamic>>;
          _completados = results[1] as Set<int>;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<Ejercicio> _construirEjercicio(Map<String, dynamic> row) async {
    final db = DatabaseHelper.instance;
    // Usar pasos generados en memoria si existen (ejercicios generados,
    // aunque ya tengan ID positivo tras haber sido completados antes).
    final tienePasosGenerados = row['_pasos_generados'] != null;

    final pasosRows = tienePasosGenerados
        ? db.obtenerPasosGenerados(row)
        : await db.obtenerPasos(row['id']).timeout(const Duration(seconds: 5));

    final pasos = pasosRows.map((p) => PasoEsperado(
      id: p['id'],
      ejercicioId: p['ejercicio_id'],
      orden: p['orden'],
      expresionPaso: p['expresion_paso'],
      descripcion: p['descripcion'],
      explicacionError: p['explicacion_error'],
      pista: p['pista'],
    )).toList();

    return Ejercicio(
      id: row['id'],
      temaId: row['tema_id'],
      expresion: row['expresion'],
      dificultad: _parseDificultad(row['dificultad']),
      pasos: pasos,
    );
  }

  Dificultad _parseDificultad(String s) {
    switch (s) {
      case 'medio': return Dificultad.medio;
      case 'dificil': return Dificultad.dificil;
      default: return Dificultad.facil;
    }
  }

  /// Genera un ejercicio aleatorio para el nivel dado y navega a él.
  Future<void> _irAEjercicioAleatorio(String dificultad) async {
    final metodo = widget.tema['metodo'] as String;
    final semilla = DateTime.now().millisecondsSinceEpoch ^ Random().nextInt(9999);
    final generados = EjercicioGenerator.generar(
      metodo: metodo,
      dificultad: dificultad,
      cantidad: 1,
      semilla: semilla,
    );
    if (generados.isEmpty) return;
    final gen = generados.first;

    // Construir el Ejercicio en memoria sin ID de BD
    const idVirtual = -9999;
    final rowVirtual = {
      'id': idVirtual,
      'tema_id': widget.tema['id'],
      'expresion': gen.expresion,
      'dificultad': gen.dificultad,
      '_pasos_generados': gen.pasos,
    };
    final ejercicio = await _construirEjercicio(rowVirtual);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EjercicioScreen(
          ejercicio: ejercicio,
          alumnoId: widget.alumnoId,
        ),
      ),
    );
    if (mounted) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final metodo = widget.tema['metodo'] as String;
    final teoria = TeoriaData.obtener(metodo);

    final porDificultad = <String, List<Map<String, dynamic>>>{
      'facil': [], 'medio': [], 'dificil': [],
    };
    for (final e in _ejercicios) {
      porDificultad[e['dificultad']]?.add(e);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.tema['nombre'])),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Tarjeta de teoría desplegable ──
                if (teoria != null) ...[
                  _TarjetaTeoria(teoria: teoria),
                  const SizedBox(height: 20),
                ],

                // ── Acceso a mini juegos del tema ──
                _BotonMiniJuegos(alumnoId: widget.alumnoId, tema: widget.tema),
                const SizedBox(height: 16),

                // ── Ejercicios por dificultad ──
                for (final dif in ['facil', 'medio', 'dificil'])
                  if (porDificultad[dif]!.isNotEmpty) ...[
                    _SeccionHeader(
                      titulo: dif == 'facil' ? 'Fácil'
                            : dif == 'medio' ? 'Medio' : 'Difícil',
                      dificultad: dif,
                      onAleatorio: () => _irAEjercicioAleatorio(dif),
                    ),
                    const SizedBox(height: 8),
                    ...porDificultad[dif]!.asMap().entries.map((e) {
                      final id = e.value['id'] as int;
                      final yaCompletado = id > 0 && _completados.contains(id);
                      return _TarjetaEjercicio(
                        numero: e.key + 1,
                        row: e.value,
                        completado: yaCompletado,
                        onTap: () => _irAEjercicio(e.value),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
              ],
            ),
    );
  }

  Future<void> _irAEjercicio(Map<String, dynamic> row) async {
    Ejercicio ejercicio;
    try {
      ejercicio = await _construirEjercicio(row);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EjercicioScreen(
          ejercicio: ejercicio,
          alumnoId: widget.alumnoId,
        ),
      ),
    );
    if (mounted) await _cargar();
  }
}

// ─── Tarjeta de teoría desplegable ──────────────────────────────────────────

class _TarjetaTeoria extends StatefulWidget {
  final TeoriaContent teoria;
  const _TarjetaTeoria({required this.teoria});

  @override
  State<_TarjetaTeoria> createState() => _TarjetaTeoriaState();
}

class _TarjetaTeoriaState extends State<_TarjetaTeoria>
    with SingleTickerProviderStateMixin {
  bool _expandida = false;
  late AnimationController _ctrl;
  late Animation<double> _rotacion;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _rotacion = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    setState(() { _expandida = !_expandida; });
    _expandida ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.teoria;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ver teoría: ${t.titulo}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotacion,
                    child: Icon(Icons.expand_more_rounded,
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ContenidoTeoria(teoria: t),
            crossFadeState: _expandida
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _ContenidoTeoria extends StatelessWidget {
  final TeoriaContent teoria;
  const _ContenidoTeoria({required this.teoria});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = teoria;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          Text('¿Qué es?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant, letterSpacing: .5)),
          const SizedBox(height: 6),
          Text(t.definicion,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, height: 1.5)),
          const SizedBox(height: 14),

          Text('Fórmula',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant, letterSpacing: .5)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.formula,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    )),
                const SizedBox(height: 4),
                Text(t.formulaDesc,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text('Ejemplo resuelto',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant, letterSpacing: .5)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(t.ejemploExpresion,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                ...t.pasos.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20, height: 20,
                        margin: const EdgeInsets.only(top: 1, right: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            )),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value.paso,
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(entry.value.resultado,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _SeccionHeader extends StatelessWidget {
  final String titulo;
  final String dificultad;
  final VoidCallback onAleatorio;

  const _SeccionHeader({
    required this.titulo,
    required this.dificultad,
    required this.onAleatorio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    switch (dificultad) {
      case 'facil':
        color = theme.brightness == Brightness.dark
            ? const Color(0xFF81C784)
            : const Color(0xFF3B6D11);
        break;
      case 'medio':
        color = theme.brightness == Brightness.dark
            ? const Color(0xFFFFB74D)
            : const Color(0xFF854F0B);
        break;
      default:
        color = theme.brightness == Brightness.dark
            ? const Color(0xFFEF9A9A)
            : const Color(0xFFA32D2D);
    }

    return Row(
      children: [
        Container(width: 4, height: 18, color: color,
            margin: const EdgeInsets.only(right: 8)),
        Text(titulo, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: color, letterSpacing: .5,
        )),
        const Spacer(),
        // Botón ejercicio aleatorio
        GestureDetector(
          onTap: onAleatorio,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.casino_rounded, size: 13, color: color),
                const SizedBox(width: 4),
                Text('Aleatorio', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color,
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaEjercicio extends StatelessWidget {
  final int numero;
  final Map<String, dynamic> row;
  final VoidCallback onTap;
  final bool completado;

  const _TarjetaEjercicio({
    required this.numero,
    required this.row,
    required this.onTap,
    this.completado = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esGenerado = (row['id'] as int) < 0;

    // Verde si completado, normal si no
    final borderColor = completado
        ? theme.colorScheme.secondary.withOpacity(0.6)
        : theme.colorScheme.outlineVariant;
    final bgColor = completado
        ? theme.colorScheme.secondaryContainer.withOpacity(0.25)
        : theme.colorScheme.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: completado ? 1.0 : 0.5),
          ),
          child: Row(
            children: [
              // Número o checkmark
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: completado
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: completado
                    ? Icon(Icons.check_rounded,
                        size: 18, color: theme.colorScheme.secondary)
                    : Text('$numero',
                        style: TextStyle(fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(row['expresion'],
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: completado
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : theme.colorScheme.onSurface)),
              ),
              if (esGenerado)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('único',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onTertiaryContainer)),
                ),
              if (completado)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('✓ hecho',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary)),
                ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}


class _BotonMiniJuegos extends StatelessWidget {
  final int alumnoId;
  final Map<String, dynamic> tema;
  const _BotonMiniJuegos({required this.alumnoId, required this.tema});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Colores adaptados al tema
    final bg = theme.brightness == Brightness.dark
        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
        : const Color(0xFFE8F5E9);
    final borderColor = theme.colorScheme.primary.withOpacity(0.3);
    final textColor = theme.colorScheme.primary;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MiniJuegosHubScreen(
          alumnoId: alumnoId,
          temaFiltro: tema['metodo'] as String,
          nombreTema: tema['nombre'] as String,
        ),
      )),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Text('🎮', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mini Juegos',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: textColor,
                      )),
                  Text('Practica este tema jugando',
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.7),
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }
}
