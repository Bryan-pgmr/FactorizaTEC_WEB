import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/datasources/database_helper.dart';
import '../inicio/inicio_screen.dart';

class BienvenidaScreen extends StatefulWidget {
  const BienvenidaScreen({super.key});

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  final _controller = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe tu nombre para continuar.');
      return;
    }

    setState(() { _cargando = true; _error = null; });

    try {
      final db = DatabaseHelper.instance;
      final alumnoId = await db.insertarAlumno(nombre);

      // Guardar id localmente para no volver a pedir el nombre
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('alumno_id', alumnoId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => InicioScreen(alumnoId: alumnoId)),
      );
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Ocurrió un error. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Mascota ──
              Image.asset(
                'assets/images/mascota_neutral.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              Text(
                'Bienvenido',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Cómo te llamas? Usaremos tu nombre para guardar tu progreso.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Tu nombre',
                  hintText: 'Ej. María González',
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                onSubmitted: (_) => _continuar(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _continuar,
                  child: _cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Comenzar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
