import 'package:sqflite/sqflite.dart';

/// Contenido precargado: 5 temas, 3 ejercicios por tema (fácil/medio/difícil),
/// cada ejercicio con sus pasos esperados completos.
/// Se ejecuta una sola vez al crear la base de datos.
class SeedData {
  static Future<void> insertar(Database db) async {
    final batch = db.batch();
    _insertarTemas(batch);
    await batch.commit(noResult: true);

    // Insertar ejercicios con sus pasos (necesitamos los IDs de tema)
    final temas = await db.query('tema', orderBy: 'orden ASC');
    final ids = {for (final t in temas) t['metodo'] as String: t['id'] as int};

    await _insertarEjerciciosFactor(db, ids['factor_comun']!);
    await _insertarEjerciciosDiffCuadrados(db, ids['diff_cuadrados']!);
    await _insertarEjerciciosTrinomioPerfecto(db, ids['trinomio_perfecto']!);
    await _insertarEjerciciosTrinomioAx2(db, ids['trinomio_ax2']!);
    await _insertarEjerciciosCubos(db, ids['cubos']!);
  }

  // ─── Temas ──────────────────────────────────────────────────────────────

  static void _insertarTemas(Batch batch) {
    final temas = [
      {'nombre': 'Factor común', 'metodo': 'factor_comun', 'orden': 1},
      {'nombre': 'Diferencia de cuadrados', 'metodo': 'diff_cuadrados', 'orden': 2},
      {'nombre': 'Trinomio cuadrado perfecto', 'metodo': 'trinomio_perfecto', 'orden': 3},
      {'nombre': 'Trinomio ax²+bx+c', 'metodo': 'trinomio_ax2', 'orden': 4},
      {'nombre': 'Suma y diferencia de cubos', 'metodo': 'cubos', 'orden': 5},
    ];
    for (final t in temas) {
      batch.insert('tema', t);
    }
  }

  // ─── Helper ─────────────────────────────────────────────────────────────

  static Future<int> _ejercicio(
    Database db,
    int temaId,
    String expresion,
    String dificultad,
  ) async {
    return db.insert('ejercicio', {
      'tema_id': temaId,
      'expresion': expresion,
      'dificultad': dificultad,
    });
  }

  static Future<void> _pasos(Database db, int ejercicioId, List<Map<String, String>> pasos) async {
    for (int i = 0; i < pasos.length; i++) {
      await db.insert('paso_esperado', {
        'ejercicio_id': ejercicioId,
        'orden': i + 1,
        'expresion_paso': pasos[i]['expresion']!,
        'descripcion': pasos[i]['descripcion']!,
        'explicacion_error': pasos[i]['error']!,
        'pista': pasos[i]['pista']!,
      });
    }
  }

  // ─── 1. Factor común ─────────────────────────────────────────────────────

  static Future<void> _insertarEjerciciosFactor(Database db, int temaId) async {
    // Fácil: 6x + 9
    int id = await _ejercicio(db, temaId, '6x + 9', 'facil');
    await _pasos(db, id, [
      {
        'expresion': '3',
        'descripcion': 'Encuentra el máximo factor común (MFC) de los coeficientes',
        'error': 'El MFC de 6 y 9 es 3, no otro número. Divide ambos coeficientes entre cada candidato.',
        'pista': 'Los factores de 6 son 1, 2, 3, 6. Los de 9 son 1, 3, 9. ¿Cuál es el mayor común?',
      },
      {
        'expresion': '3(2x+3)',
        'descripcion': 'Escribe la expresión factorizada: MFC × (términos divididos)',
        'error': 'Divide cada término entre el MFC: 6x÷3 = 2x y 9÷3 = 3.',
        'pista': 'La forma es 3(__ + __). Divide 6x entre 3 y 9 entre 3.',
      },
      {
        'expresion': '6x+9',
        'descripcion': 'Verifica distribuyendo: 3(2x+3) debe dar la expresión original',
        'error': '3×2x = 6x y 3×3 = 9. La suma debe ser 6x + 9.',
        'pista': 'Multiplica 3 por cada término dentro del paréntesis.',
      },
    ]);

    // Medio: 4x³ - 8x² + 12x
    id = await _ejercicio(db, temaId, '4x³ - 8x² + 12x', 'medio');
    await _pasos(db, id, [
      {
        'expresion': '4x',
        'descripcion': 'Encuentra el MFC de coeficientes y variables',
        'error': 'El MFC de 4, 8 y 12 es 4. La variable común con menor exponente es x¹.',
        'pista': 'Para las variables, toma la de menor exponente: x³, x², x → el menor es x.',
      },
      {
        'expresion': '4x(x^2-2x+3)',
        'descripcion': 'Escribe la factorización completa',
        'error': 'Divide cada término entre 4x: 4x³÷4x = x², -8x²÷4x = -2x, 12x÷4x = 3.',
        'pista': 'La forma es 4x(__ - __ + __). Divide cada término entre 4x.',
      },
      {
        'expresion': '4x^3-8x^2+12x',
        'descripcion': 'Verifica distribuyendo 4x en el trinomio',
        'error': '4x·x² = 4x³, 4x·(-2x) = -8x², 4x·3 = 12x.',
        'pista': 'Multiplica 4x por cada término del paréntesis.',
      },
    ]);

    // Difícil: 6x²y³ - 9xy⁴ + 3x³y²
    id = await _ejercicio(db, temaId, '6x²y³ - 9xy⁴ + 3x³y²', 'dificil');
    await _pasos(db, id, [
      {
        'expresion': '3xy^2',
        'descripcion': 'Encuentra el MFC con dos variables (x e y)',
        'error': 'MFC de coeficientes: MFC(6,9,3) = 3. Para x: mínimo exponente = 1. Para y: mínimo = 2. Resultado: 3xy².',
        'pista': 'Busca el MFC de los números y luego la variable de menor grado para cada letra.',
      },
      {
        'expresion': '3xy^2(2xy-3y^2+x^2)',
        'descripcion': 'Escribe la factorización dividiendo cada término entre el MFC',
        'error': '6x²y³÷3xy² = 2xy, -9xy⁴÷3xy² = -3y², 3x³y²÷3xy² = x².',
        'pista': 'Divide coeficientes entre 3, y para cada variable resta los exponentes.',
      },
      {
        'expresion': '6x^2y^3-9xy^4+3x^3y^2',
        'descripcion': 'Verifica distribuyendo',
        'error': 'Revisa que 3xy²·2xy = 6x²y³, 3xy²·(-3y²) = -9xy⁴ y 3xy²·x² = 3x³y².',
        'pista': 'Al multiplicar, suma los exponentes de las variables iguales.',
      },
    ]);
  }

  // ─── 2. Diferencia de cuadrados ──────────────────────────────────────────

  static Future<void> _insertarEjerciciosDiffCuadrados(Database db, int temaId) async {
    // Fácil: x² - 9
    int id = await _ejercicio(db, temaId, 'x² - 9', 'facil');
    await _pasos(db, id, [
      {
        'expresion': 'x',
        'descripcion': 'Identifica a: ¿cuál es la raíz cuadrada del primer término?',
        'error': '√(x²) = x. La raíz cuadrada de x² es simplemente x.',
        'pista': 'Pregúntate: ¿qué elevado al cuadrado da x²?',
      },
      {
        'expresion': '3',
        'descripcion': 'Identifica b: ¿cuál es la raíz cuadrada del segundo término?',
        'error': '√9 = 3. Verifica: 3² = 9 ✓',
        'pista': '¿Qué número multiplicado por sí mismo da 9?',
      },
      {
        'expresion': '(x+3)(x-3)',
        'descripcion': 'Escribe la forma factorizada (a+b)(a-b)',
        'error': 'La fórmula es (a+b)(a-b). Con a=x y b=3: (x+3)(x-3).',
        'pista': 'Sustituye a y b en el patrón (a+b)(a-b).',
      },
    ]);

    // Medio: 4x² - 25
    id = await _ejercicio(db, temaId, '4x² - 25', 'medio');
    await _pasos(db, id, [
      {
        'expresion': '2x',
        'descripcion': 'Identifica a = √(4x²)',
        'error': '√(4x²) = 2x. Recuerda que √(4)=2 y √(x²)=x.',
        'pista': '√4 = 2 y √(x²) = x, así que √(4x²) = 2x.',
      },
      {
        'expresion': '5',
        'descripcion': 'Identifica b = √25',
        'error': '√25 = 5 porque 5² = 25.',
        'pista': '¿Qué número al cuadrado da 25?',
      },
      {
        'expresion': '(2x+5)(2x-5)',
        'descripcion': 'Escribe la forma factorizada',
        'error': 'Con a=2x y b=5: (2x+5)(2x-5).',
        'pista': 'Aplica (a+b)(a-b) con tus valores de a y b.',
      },
    ]);

    // Difícil: 9x⁴ - 16y²
    id = await _ejercicio(db, temaId, '9x⁴ - 16y²', 'dificil');
    await _pasos(db, id, [
      {
        'expresion': '3x^2',
        'descripcion': 'Identifica p = √(9x⁴)',
        'error': '√(9x⁴) = 3x². Recuerda: √9=3 y √(x⁴)=x².',
        'pista': 'La raíz de x⁴ es x² (divide el exponente entre 2).',
      },
      {
        'expresion': '4y',
        'descripcion': 'Identifica q = √(16y²)',
        'error': '√(16y²) = 4y. √16=4 y √(y²)=y.',
        'pista': '√16 = 4, √(y²) = y.',
      },
      {
        'expresion': '(3x^2+4y)(3x^2-4y)',
        'descripcion': 'Escribe la forma factorizada completa',
        'error': 'Con p=3x² y q=4y: (3x²+4y)(3x²-4y).',
        'pista': 'Sustituye en (p+q)(p-q).',
      },
    ]);
  }

  // ─── 3. Trinomio cuadrado perfecto ───────────────────────────────────────

  static Future<void> _insertarEjerciciosTrinomioPerfecto(Database db, int temaId) async {
    // Fácil: x² + 6x + 9
    int id = await _ejercicio(db, temaId, 'x² + 6x + 9', 'facil');
    await _pasos(db, id, [
      {
        'expresion': 'x',
        'descripcion': 'Encuentra a = √(primer término)',
        'error': '√(x²) = x.',
        'pista': '¿Qué al cuadrado da x²?',
      },
      {
        'expresion': '3',
        'descripcion': 'Encuentra b = √(último término)',
        'error': '√9 = 3.',
        'pista': '¿Qué al cuadrado da 9?',
      },
      {
        'expresion': '6x',
        'descripcion': 'Verifica el término medio: debe ser 2ab',
        'error': '2·x·3 = 6x. El término medio del trinomio debe coincidir con 2ab.',
        'pista': 'Calcula 2 × a × b y compara con el término medio del trinomio.',
      },
      {
        'expresion': '(x+3)^2',
        'descripcion': 'Escribe la forma factorizada (a+b)²',
        'error': 'Como el signo del término medio es +, la forma es (a+b)² = (x+3)².',
        'pista': 'Si el término medio es positivo, usa (a+b)².',
      },
    ]);

    // Medio: x² - 10x + 25
    id = await _ejercicio(db, temaId, 'x² - 10x + 25', 'medio');
    await _pasos(db, id, [
      {
        'expresion': 'x',
        'descripcion': 'Encuentra a = √(x²)',
        'error': '√(x²) = x.',
        'pista': '¿Qué al cuadrado da x²?',
      },
      {
        'expresion': '5',
        'descripcion': 'Encuentra b = √25',
        'error': '√25 = 5.',
        'pista': '5² = 25.',
      },
      {
        'expresion': '-10x',
        'descripcion': 'Verifica que el término medio sea -2ab',
        'error': '-2·x·5 = -10x. El signo negativo del término medio indica (a-b)².',
        'pista': 'Calcula -2 × a × b.',
      },
      {
        'expresion': '(x-5)^2',
        'descripcion': 'Escribe la forma factorizada (a-b)²',
        'error': 'El signo negativo del término medio indica (a-b)² = (x-5)².',
        'pista': 'Si el término medio es negativo, usa (a-b)².',
      },
    ]);

    // Difícil: 4x² + 12xy + 9y²
    id = await _ejercicio(db, temaId, '4x² + 12xy + 9y²', 'dificil');
    await _pasos(db, id, [
      {
        'expresion': '2x',
        'descripcion': 'Encuentra a = √(4x²)',
        'error': '√(4x²) = 2x.',
        'pista': '√4 = 2, √(x²) = x.',
      },
      {
        'expresion': '3y',
        'descripcion': 'Encuentra b = √(9y²)',
        'error': '√(9y²) = 3y.',
        'pista': '√9 = 3, √(y²) = y.',
      },
      {
        'expresion': '12xy',
        'descripcion': 'Verifica el término medio: 2ab = 2·(2x)·(3y)',
        'error': '2·(2x)·(3y) = 12xy. ¿Coincide con el término medio?',
        'pista': 'Multiplica 2 × 2x × 3y.',
      },
      {
        'expresion': '(2x+3y)^2',
        'descripcion': 'Escribe la factorización final',
        'error': 'Con a=2x y b=3y, y término medio positivo: (2x+3y)².',
        'pista': 'Aplica (a+b)² con tus valores.',
      },
    ]);
  }

  // ─── 4. Trinomio ax² + bx + c ────────────────────────────────────────────

  static Future<void> _insertarEjerciciosTrinomioAx2(Database db, int temaId) async {
    // Fácil: x² + 5x + 6
    int id = await _ejercicio(db, temaId, 'x² + 5x + 6', 'facil');
    await _pasos(db, id, [
      {
        'expresion': '2 3',
        'descripcion': 'Encuentra dos números: producto=c=6 y suma=b=5. Escríbelos separados por espacio: "2 3"',
        'error': 'Necesitas dos números con producto=6 y suma=5. Prueba pares: 1×6=6, 1+6=7 (no). 2×3=6, 2+3=5 (sí). Escribe: "2 3"',
        'pista': 'Prueba (1,6): 1+6=7 ✗. Prueba (2,3): 2+3=5 ✓. Escribe "2 3"',
      },
      {
        'expresion': '(x+2)(x+3)',
        'descripcion': 'Escribe la factorización usando los números encontrados',
        'error': 'La forma es (x + primer número)(x + segundo número) = (x+2)(x+3).',
        'pista': 'Coloca cada número en un factor: (x+__)(x+__).',
      },
    ]);

    // Medio: 2x² + 7x + 3
    id = await _ejercicio(db, temaId, '2x² + 7x + 3', 'medio');
    await _pasos(db, id, [
      {
        'expresion': '6',
        'descripcion': 'Calcula el producto ac: a=2, c=3, entonces ac = 2×3',
        'error': 'ac = 2 × 3 = 6. Este es el número clave para el método de factorización por agrupación.',
        'pista': 'Multiplica el coeficiente de x² por el término independiente.',
      },
      {
        'expresion': '1 6',
        'descripcion': 'Encuentra dos números: producto=6 y suma=7 (b). Escríbelos separados por espacio: "1 6"',
        'error': 'Pares con producto 6: (1,6)→suma 7 ✓. Escríbelos así: "1 6"',
        'pista': '1 × 6 = 6 y 1 + 6 = 7. Formato: "1 6"',
      },
      {
        'expresion': '2x^2+x+6x+3',
        'descripcion': 'Reescribe el término 7x como x + 6x y agrupa',
        'error': 'Sustituye 7x por 1x + 6x: 2x² + x + 6x + 3.',
        'pista': 'Separa el término del medio usando los dos números encontrados.',
      },
      {
        'expresion': '(2x+1)(x+3)',
        'descripcion': 'Factoriza por agrupación: (2x²+x) + (6x+3)',
        'error': 'Grupo 1: x(2x+1). Grupo 2: 3(2x+1). Factor común: (2x+1)(x+3).',
        'pista': 'Saca factor de las primeras dos y las últimas dos, luego factor común binomial.',
      },
    ]);

    // Difícil: 6x² - 11x - 10
    id = await _ejercicio(db, temaId, '6x² - 11x - 10', 'dificil');
    await _pasos(db, id, [
      {
        'expresion': '-60',
        'descripcion': 'Calcula ac = 6 × (-10)',
        'error': 'ac = 6 × (-10) = -60. El signo negativo es importante.',
        'pista': 'a=6, c=-10. Multiplícalos con cuidado del signo.',
      },
      {
        'expresion': '4 -15',
        'descripcion': 'Encuentra dos números: producto=-60 y suma=-11. Escríbelos separados por espacio: "4 -15"',
        'error': '4 × (-15) = -60 ✓ y 4 + (-15) = -11 ✓. Escríbelos así: "4 -15"',
        'pista': 'Uno positivo y uno negativo. Prueba pares. Formato: "4 -15"',
      },
      {
        'expresion': '6x^2+4x-15x-10',
        'descripcion': 'Reescribe -11x como 4x - 15x',
        'error': 'Sustituye -11x por +4x - 15x: 6x² + 4x - 15x - 10.',
        'pista': 'Descompón -11x usando los dos números: +4x y -15x.',
      },
      {
        'expresion': '(3x-5)(2x+2)',
        'descripcion': 'Factoriza por agrupación',
        'error': 'Grupo 1: 2x(3x+2). Grupo 2: -5(3x+2). Factor común: (3x+2)(2x-5).',
        'pista': 'Agrupa las primeras dos y las últimas dos, saca factor de cada grupo.',
      },
    ]);
  }

  // ─── 5. Suma y diferencia de cubos ───────────────────────────────────────

  static Future<void> _insertarEjerciciosCubos(Database db, int temaId) async {
    // Fácil: x³ + 8
    int id = await _ejercicio(db, temaId, 'x³ + 8', 'facil');
    await _pasos(db, id, [
      {
        'expresion': 'x',
        'descripcion': 'Encuentra a = ∛(x³)',
        'error': '∛(x³) = x.',
        'pista': '¿Qué al cubo da x³?',
      },
      {
        'expresion': '2',
        'descripcion': 'Encuentra b = ∛8',
        'error': '∛8 = 2 porque 2³ = 8.',
        'pista': '2 × 2 × 2 = 8.',
      },
      {
        'expresion': '(x+2)(x^2-2x+4)',
        'descripcion': 'Aplica la fórmula de suma de cubos: (a+b)(a²-ab+b²)',
        'error': 'Suma de cubos: (a+b)(a²-ab+b²). Con a=x y b=2: (x+2)(x²-2x+4).',
        'pista': 'La fórmula es (a+b)(a²-ab+b²). Sustituye a=x y b=2.',
      },
    ]);

    // Medio: 27x³ - 64
    id = await _ejercicio(db, temaId, '27x³ - 64', 'medio');
    await _pasos(db, id, [
      {
        'expresion': '3x',
        'descripcion': 'Encuentra a = ∛(27x³)',
        'error': '∛27 = 3 y ∛(x³) = x, entonces a = 3x.',
        'pista': '3³ = 27. La raíz cúbica de 27x³ es 3x.',
      },
      {
        'expresion': '4',
        'descripcion': 'Encuentra b = ∛64',
        'error': '∛64 = 4 porque 4³ = 64.',
        'pista': '4 × 4 × 4 = 64.',
      },
      {
        'expresion': '(3x-4)(9x^2+12x+16)',
        'descripcion': 'Aplica la fórmula de diferencia de cubos: (a-b)(a²+ab+b²)',
        'error': 'Diferencia de cubos: (a-b)(a²+ab+b²). a²=(3x)²=9x², ab=(3x)(4)=12x, b²=16.',
        'pista': 'La fórmula es (a-b)(a²+ab+b²). Calcula cada parte con a=3x y b=4.',
      },
    ]);

    // Difícil: 8x³ + 125y³
    id = await _ejercicio(db, temaId, '8x³ + 125y³', 'dificil');
    await _pasos(db, id, [
      {
        'expresion': '2x',
        'descripcion': 'Encuentra p = ∛(8x³)',
        'error': '∛8 = 2 y ∛(x³) = x, entonces p = 2x.',
        'pista': '2³ = 8.',
      },
      {
        'expresion': '5y',
        'descripcion': 'Encuentra q = ∛(125y³)',
        'error': '∛125 = 5 y ∛(y³) = y, entonces q = 5y.',
        'pista': '5³ = 125.',
      },
      {
        'expresion': '(2x+5y)(4x^2-10xy+25y^2)',
        'descripcion': 'Aplica suma de cubos: (p+q)(p²-pq+q²)',
        'error': 'p²=(2x)²=4x², pq=(2x)(5y)=10xy, q²=(5y)²=25y². Resultado: (2x+5y)(4x²-10xy+25y²).',
        'pista': 'Calcula p², p×q y q² con tus valores y sustituye en la fórmula.',
      },
    ]);
  }
}
