import 'package:flutter/material.dart';
import '../../../data/datasources/database_helper.dart';
import 'ejercicios_screen.dart';

class TemasScreen extends StatefulWidget {
  final int alumnoId;
  const TemasScreen({super.key, required this.alumnoId});

  @override
  State<TemasScreen> createState() => _TemasScreenState();
}

class _TemasScreenState extends State<TemasScreen> {
  List<Map<String, dynamic>> _temas = [];
  bool _cargando = true;

  // Íconos por método
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
    _cargar();
  }

  Future<void> _cargar() async {
    final temas = await DatabaseHelper.instance.obtenerTemas();
    if (mounted) setState(() { _temas = temas; _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Temas')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _temas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final tema = _temas[i];
                final icono = _iconos[tema['metodo']] ?? Icons.calculate_rounded;

                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EjerciciosScreen(
                        tema: tema,
                        alumnoId: widget.alumnoId,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icono,
                              color: theme.colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tema['nombre'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fácil · Medio · Difícil',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
