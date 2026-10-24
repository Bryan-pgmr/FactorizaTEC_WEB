import 'package:flutter/material.dart';
import '../../../data/datasources/database_helper.dart';
import '../../../main.dart';

class PerfilScreen extends StatefulWidget {
  final int alumnoId;
  const PerfilScreen({super.key, required this.alumnoId});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _alumno;
  Map<String, dynamic>? _progreso;
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final db = DatabaseHelper.instance;
    final alumno = await db.obtenerAlumno(widget.alumnoId);
    final progreso = await db.obtenerProgreso(widget.alumnoId);
    if (mounted) setState(() { _alumno = alumno; _progreso = progreso; _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = _alumno?['nombre'] ?? '';
    final registro = _alumno?['fecha_registro']?.toString() ?? '';
    final nivel = _progreso?['nivel'] ?? 1;
    final xp = _progreso?['xp_total'] ?? 0;
    final racha = _progreso?['racha_dias'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(nombre, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Registrado el $registro',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  _FilaStat(etiqueta: 'Nivel actual', valor: '$nivel'),
                  _FilaStat(etiqueta: 'XP total', valor: '$xp XP'),
                  _FilaStat(etiqueta: 'Racha activa', valor: '$racha ${racha == 1 ? "día" : "días"}'),
                  const SizedBox(height: 10),

                  // ── Toggle modo oscuro ──
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: temaNotifier,
                    builder: (context, modo, _) {
                      final esOscuro = modo == ThemeMode.dark ||
                          (modo == ThemeMode.system &&
                              MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  esOscuro ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Modo oscuro',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            Switch(
                              value: modo == ThemeMode.dark,
                              onChanged: (_) => temaNotifier.toggleOscuro(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Botón "Usar tema del sistema"
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: temaNotifier,
                    builder: (context, modo, _) {
                      if (modo == ThemeMode.system) return const SizedBox.shrink();
                      return TextButton.icon(
                        onPressed: () => temaNotifier.usarSistema(),
                        icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                        label: const Text('Usar tema del sistema'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _FilaStat extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _FilaStat({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
