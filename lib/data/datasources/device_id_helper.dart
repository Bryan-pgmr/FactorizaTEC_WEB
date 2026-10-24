import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Genera y persiste un ID único por instalación.
/// Se usa como parte de la semilla del generador para que cada dispositivo
/// obtenga ejercicios distintos aunque el alumnoId sea el mismo.
class DeviceIdHelper {
  static const _key = 'device_install_id';

  static int? _cache;

  /// Devuelve el ID de instalación (entero de 6 dígitos).
  /// En el primer llamado lo genera y lo persiste; después lo lee de caché.
  static Future<int> obtener() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt(_key);
    if (id == null) {
      id = 100000 + Random().nextInt(900000); // 100000 – 999999
      await prefs.setInt(_key, id);
    }
    _cache = id;
    return id;
  }
}
