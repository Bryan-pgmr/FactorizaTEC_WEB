import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasources/db_factory.dart';
import 'presentation/screens/bienvenida/bienvenida_screen.dart';
import 'presentation/screens/inicio/inicio_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // PWA: debe ejecutarse antes de cualquier acceso a la base de datos.
  await configurarBaseDeDatos();
  final prefs = await SharedPreferences.getInstance();
  final alumnoId = prefs.getInt('alumno_id');
  final modoOscuro = prefs.getBool('modo_oscuro'); // null = sistema

  runApp(FactorizacionApp(
    alumnoIdInicial: alumnoId,
    modoOscuroInicial: modoOscuro,
  ));
}

/// Notifier global para cambiar el modo oscuro sin reiniciar la app.
class TemaNotifier extends ValueNotifier<ThemeMode> {
  TemaNotifier(super.value);

  Future<void> toggleOscuro() async {
    final prefs = await SharedPreferences.getInstance();
    if (value == ThemeMode.dark) {
      value = ThemeMode.light;
      await prefs.setBool('modo_oscuro', false);
    } else {
      value = ThemeMode.dark;
      await prefs.setBool('modo_oscuro', true);
    }
  }

  Future<void> usarSistema() async {
    final prefs = await SharedPreferences.getInstance();
    value = ThemeMode.system;
    await prefs.remove('modo_oscuro');
  }
}

/// Instancia global accesible desde cualquier pantalla.
final temaNotifier = TemaNotifier(ThemeMode.system);

class FactorizacionApp extends StatelessWidget {
  final int? alumnoIdInicial;
  final bool? modoOscuroInicial;

  const FactorizacionApp({
    super.key,
    this.alumnoIdInicial,
    this.modoOscuroInicial,
  });

  @override
  Widget build(BuildContext context) {
    // Sincroniza el notifier con la preferencia guardada
    if (modoOscuroInicial == true) {
      temaNotifier.value = ThemeMode.dark;
    } else if (modoOscuroInicial == false) {
      temaNotifier.value = ThemeMode.light;
    } else {
      temaNotifier.value = ThemeMode.system;
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Factorización',
          debugShowCheckedModeBanner: false,
          theme: _temaClaro(),
          darkTheme: _temaOscuro(),
          themeMode: mode,
          // En web/escritorio la app se muestra como una columna centrada
          // de ancho móvil, para que la UI no se estire en pantallas grandes.
          builder: (context, child) {
            if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
            return ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: child,
                ),
              ),
            );
          },
          home: alumnoIdInicial != null
              ? InicioScreen(alumnoId: alumnoIdInicial!)
              : const BienvenidaScreen(),
        );
      },
    );
  }

  ThemeData _temaClaro() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A47C4),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: base.surface,
        foregroundColor: base.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.primary,
          foregroundColor: base.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  ThemeData _temaOscuro() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A47C4),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: base.surface,
        foregroundColor: base.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.primary,
          foregroundColor: base.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
