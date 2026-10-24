import 'package:flutter/material.dart';
import '../../../data/datasources/database_helper.dart';
import '../../../domain/entities/ejercicio.dart';

// ─── Progreso ────────────────────────────────────────────────────────────────

class ProgresoScreen extends StatefulWidget {
  final int alumnoId;
  const ProgresoScreen({super.key, required this.alumnoId});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  Map<String, dynamic>? _progreso;
  List<Map<String, dynamic>> _intentos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final db = DatabaseHelper.instance;
    final progreso = await db.obtenerProgreso(widget.alumnoId);
    // Últimos 10 intentos completados
    final sqlDb = await db.database;
    final intentos = await sqlDb.rawQuery('''
      SELECT i.fecha, i.xp_obtenido, e.expresion, e.dificultad, t.nombre AS tema
      FROM intento i
      JOIN ejercicio e ON e.id = i.ejercicio_id
      JOIN tema t ON t.id = e.tema_id
      WHERE i.alumno_id = ? AND i.completado = 1
      ORDER BY i.fecha DESC
      LIMIT 10
    ''', [widget.alumnoId]);

    if (mounted) {
      setState(() {
        _progreso = progreso;
        _intentos = intentos;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xp = _progreso?['xp_total'] ?? 0;
    final nivel = _progreso?['nivel'] ?? 1;
    final racha = _progreso?['racha_dias'] ?? 0;
    final xpAnt = ReglasXp.xpParaNivel(nivel);
    final xpSig = ReglasXp.xpParaSiguienteNivel(nivel);
    final pct = xpSig > xpAnt
        ? ((xp - xpAnt) / (xpSig - xpAnt)).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nivel y barra ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nivel $nivel',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )),
                            Text('$xp / $xpSig XP',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Faltan ${xpSig - xp} XP para el nivel ${nivel + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats ──
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        icono: Icons.star_rounded,
                        valor: '$xp',
                        etiqueta: 'XP total',
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                        icono: Icons.local_fire_department_rounded,
                        valor: '$racha',
                        etiqueta: 'Días de racha',
                        destacar: racha >= 5,
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                        icono: Icons.check_circle_rounded,
                        valor: '${_intentos.length}',
                        etiqueta: 'Ejercicios',
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Historial ──
                  Text('Historial reciente',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  if (_intentos.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aún no has completado ejercicios.\n¡Ve a practicar!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...(_intentos.map((intento) => _ItemHistorial(intento: intento))),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final bool destacar;

  const _StatCard({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.destacar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icono,
              size: 22,
              color: destacar
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(valor,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          Text(etiqueta,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ItemHistorial extends StatelessWidget {
  final Map<String, dynamic> intento;
  const _ItemHistorial({required this.intento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fecha = intento['fecha']?.toString().substring(0, 10) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intento['expresion'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${intento['tema']} · $fecha',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${intento['xp_obtenido']} XP',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Perfil ───────────────────────────────────────────────────────────────────
