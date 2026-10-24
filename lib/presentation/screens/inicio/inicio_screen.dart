import 'package:flutter/material.dart';
import '../../../data/datasources/database_helper.dart';
import '../../../domain/entities/ejercicio.dart';
import '../temas/temas_screen.dart';
import '../progreso/progreso_screen.dart';
import '../perfil/perfil_screen.dart';
import '../desafio/desafio_screen.dart';
import '../minijuegos/memoria_screen.dart';

class InicioScreen extends StatefulWidget {
  final int alumnoId;
  const InicioScreen({super.key, required this.alumnoId});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  Map<String, dynamic>? _alumno;
  Map<String, dynamic>? _progreso;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final db = DatabaseHelper.instance;
    final alumno = await db.obtenerAlumno(widget.alumnoId);
    final progreso = await db.obtenerProgreso(widget.alumnoId);
    if (mounted) {
      setState(() {
        _alumno = alumno;
        _progreso = progreso;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factorización'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Mi perfil',
            onPressed: () => _ir(PerfilScreen(alumnoId: widget.alumnoId)),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Mascota ──
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/mascota_neutral.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 16),
                        // ── Saludo ──
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hola, ${_alumno?['nombre'] ?? ''}",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sigue practicando para dominar la factorización.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Tarjetas de progreso ──
                    _TarjetasProgreso(progreso: _progreso),
                    const SizedBox(height: 28),

                    // ── Accesos directos ──
                    Text(
                      '¿Qué quieres hacer?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _AccesoDirecto(
                      icono: Icons.school_rounded,
                      titulo: 'Practicar',
                      descripcion: 'Elige un tema y resuelve ejercicios',
                      color: theme.colorScheme.primaryContainer,
                      iconColor: theme.colorScheme.primary,
                      onTap: () => _ir(TemasScreen(alumnoId: widget.alumnoId)),
                    ),
                    const SizedBox(height: 12),
                    _AccesoDirecto(
                      icono: Icons.bar_chart_rounded,
                      titulo: 'Mi progreso',
                      descripcion: 'Revisa tu XP, nivel y racha',
                      color: theme.colorScheme.secondaryContainer,
                      iconColor: theme.colorScheme.secondary,
                      onTap: () => _ir(ProgresoScreen(alumnoId: widget.alumnoId)),
                    ),
                    const SizedBox(height: 12),
                    _AccesoDirecto(
                      icono: Icons.person_rounded,
                      titulo: 'Mi perfil',
                      descripcion: 'Tus datos y estadísticas',
                      color: theme.colorScheme.tertiaryContainer,
                      iconColor: theme.colorScheme.tertiary,
                      onTap: () => _ir(PerfilScreen(alumnoId: widget.alumnoId)),
                    ),
                    const SizedBox(height: 12),
                    _AccesoDirecto(
                      icono: Icons.timer_rounded,
                      titulo: 'Desafío contrarreloj',
                      descripcion: '5 problemas · 30 seg c/u · XP bonus',
                      color: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFEA6C00),
                      onTap: () => _ir(DesafioSeleccionScreen(alumnoId: widget.alumnoId)),
                    ),
                    const SizedBox(height: 12),
                    _AccesoDirecto(
                      icono: Icons.games_rounded,
                      titulo: 'Mini Juegos',
                      descripcion: 'Memoria, Empareja y Carrera del MCD',
                      color: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      onTap: () => _ir(MiniJuegosHubScreen(alumnoId: widget.alumnoId)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  void _ir(Widget pantalla) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => pantalla))
        .then((_) => _cargarDatos()); // refresca al volver
  }
}

// ─── Tarjetas de XP, nivel y racha ──────────────────────────────────────────

class _TarjetasProgreso extends StatelessWidget {
  final Map<String, dynamic>? progreso;
  const _TarjetasProgreso({this.progreso});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xp = progreso?['xp_total'] ?? 0;
    final nivel = progreso?['nivel'] ?? 1;
    final racha = progreso?['racha_dias'] ?? 0;

    // XP para el nivel siguiente
    final xpInicioNivel = ReglasXp.xpParaNivel(nivel);
    final xpSiguiente = ReglasXp.xpParaSiguienteNivel(nivel);
    final progresoPct = xpSiguiente > xpInicioNivel
        ? ((xp - xpInicioNivel) / (xpSiguiente - xpInicioNivel)).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      children: [
        // Nivel + barra de progreso
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nivel $nivel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '$xp / $xpSiguiente XP',  // xpSiguiente = techo del nivel actual
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progresoPct,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // XP total y racha
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                icono: Icons.star_rounded,
                valor: '$xp',
                etiqueta: 'XP total',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniCard(
                icono: Icons.local_fire_department_rounded,
                valor: '$racha',
                etiqueta: racha == 1 ? 'día de racha' : 'días de racha',
                destacar: racha >= 5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final bool destacar;

  const _MiniCard({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.destacar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            size: 22,
            color: destacar
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de acceso directo ───────────────────────────────────────────────

class _AccesoDirecto extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _AccesoDirecto({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
