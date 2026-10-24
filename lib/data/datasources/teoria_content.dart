/// Contenido teórico precargado para cada método de factorización.
/// Incluye definición, fórmula y un ejemplo resuelto paso a paso.
class TeoriaContent {
  final String titulo;
  final String definicion;
  final String formula;
  final String formulaDesc;
  final String ejemploExpresion;
  final List<PasoEjemplo> pasos;

  const TeoriaContent({
    required this.titulo,
    required this.definicion,
    required this.formula,
    required this.formulaDesc,
    required this.ejemploExpresion,
    required this.pasos,
  });
}

class PasoEjemplo {
  final String paso;
  final String resultado;
  const PasoEjemplo(this.paso, this.resultado);
}

class TeoriaData {
  static const Map<String, TeoriaContent> contenido = {
    'factor_comun': TeoriaContent(
      titulo: 'Factor Común',
      definicion:
          'Consiste en identificar el factor que comparten todos los términos '
          'de un polinomio (número y/o variable común), extraerlo fuera de un '
          'paréntesis y dividir cada término entre dicho factor.',
      formula: 'ax + ay + az = a(x + y + z)',
      formulaDesc:
          'Donde "a" es el Máximo Factor Común (MFC) de todos los términos.',
      ejemploExpresion: '12x³ - 8x² + 4x',
      pasos: [
        PasoEjemplo(
          '1. Encuentra el MFC de 12, 8 y 4',
          'MFC = 4',
        ),
        PasoEjemplo(
          '2. Identifica la variable de menor exponente',
          'Variable común: x¹',
        ),
        PasoEjemplo(
          '3. El MFC completo es 4x. Divide cada término entre 4x',
          '12x³÷4x = 3x²,  -8x²÷4x = -2x,  4x÷4x = 1',
        ),
        PasoEjemplo(
          '4. Escribe la factorización',
          '4x(3x² - 2x + 1)',
        ),
        PasoEjemplo(
          '5. Verifica distribuyendo',
          '4x·3x² - 4x·2x + 4x·1 = 12x³ - 8x² + 4x ✓',
        ),
      ],
    ),

    'diff_cuadrados': TeoriaContent(
      titulo: 'Diferencia de Cuadrados',
      definicion:
          'Se aplica cuando tenemos la resta de dos cuadrados perfectos. '
          'El resultado siempre es el producto de dos binomios: uno con suma '
          'y otro con diferencia de las raíces cuadradas.',
      formula: 'a² - b² = (a + b)(a - b)',
      formulaDesc:
          'Donde "a" y "b" son las raíces cuadradas de cada término.',
      ejemploExpresion: '25x² - 49',
      pasos: [
        PasoEjemplo(
          '1. Identifica a = √(25x²)',
          'a = 5x  (porque (5x)² = 25x²)',
        ),
        PasoEjemplo(
          '2. Identifica b = √49',
          'b = 7  (porque 7² = 49)',
        ),
        PasoEjemplo(
          '3. Aplica la fórmula (a+b)(a-b)',
          '(5x + 7)(5x - 7)',
        ),
        PasoEjemplo(
          '4. Verifica multiplicando',
          '(5x)² - 7² = 25x² - 49 ✓',
        ),
      ],
    ),

    'trinomio_perfecto': TeoriaContent(
      titulo: 'Trinomio Cuadrado Perfecto',
      definicion:
          'Un trinomio es cuadrado perfecto cuando el primer y último término '
          'son cuadrados perfectos, y el término medio es el doble del '
          'producto de sus raíces cuadradas.',
      formula: 'a² ± 2ab + b² = (a ± b)²',
      formulaDesc:
          'El signo del binomio al cuadrado coincide con el signo del término medio.',
      ejemploExpresion: '9x² - 12x + 4',
      pasos: [
        PasoEjemplo(
          '1. Verifica: ¿el primer término es cuadrado perfecto?',
          '√(9x²) = 3x  ✓',
        ),
        PasoEjemplo(
          '2. Verifica: ¿el último término es cuadrado perfecto?',
          '√4 = 2  ✓',
        ),
        PasoEjemplo(
          '3. Verifica el término medio: 2ab = 2·(3x)·(2)',
          '2·3x·2 = 12x. El trinomio tiene -12x  ✓',
        ),
        PasoEjemplo(
          '4. El signo del término medio es (-), usa (a - b)²',
          '(3x - 2)²',
        ),
        PasoEjemplo(
          '5. Verifica: (3x - 2)² = (3x)² - 2(3x)(2) + 2²',
          '9x² - 12x + 4 ✓',
        ),
      ],
    ),

    'trinomio_ax2': TeoriaContent(
      titulo: 'Trinomio ax² + bx + c',
      definicion:
          'Se factoriza un trinomio donde el coeficiente de x² es distinto de 1. '
          'Se usa el método de factorización por agrupación: se multiplica a×c, '
          'se buscan dos números con ese producto y cuya suma sea b, '
          'luego se reagrupa y se extrae el factor binomial común.',
      formula: 'ax² + bx + c = (px + q)(rx + s)',
      formulaDesc:
          'Se buscan p, q, r, s tal que p·r = a, q·s = c y p·s + q·r = b.',
      ejemploExpresion: '3x² + 10x + 8',
      pasos: [
        PasoEjemplo(
          '1. Calcula a·c = 3 × 8',
          'a·c = 24',
        ),
        PasoEjemplo(
          '2. Busca dos números con producto 24 y suma 10 (valor de b)',
          '4 × 6 = 24  y  4 + 6 = 10  ✓',
        ),
        PasoEjemplo(
          '3. Reescribe 10x como 4x + 6x',
          '3x² + 4x + 6x + 8',
        ),
        PasoEjemplo(
          '4. Agrupa y extrae factor de cada par',
          'x(3x + 4) + 2(3x + 4)',
        ),
        PasoEjemplo(
          '5. Extrae el factor binomial común (3x + 4)',
          '(3x + 4)(x + 2)',
        ),
        PasoEjemplo(
          '6. Verifica: (3x + 4)(x + 2)',
          '3x² + 6x + 4x + 8 = 3x² + 10x + 8 ✓',
        ),
      ],
    ),

    'cubos': TeoriaContent(
      titulo: 'Suma y Diferencia de Cubos',
      definicion:
          'Se aplica cuando tenemos la suma o resta de dos cubos perfectos. '
          'Cada caso tiene su propia fórmula. El trinomio resultante '
          'NUNCA es un cuadrado perfecto (el coeficiente central siempre es 1, no 2).',
      formula: 'a³ + b³ = (a+b)(a²-ab+b²)\na³ - b³ = (a-b)(a²+ab+b²)',
      formulaDesc:
          'El signo del binomio coincide con el de la operación original. '
          'El trinomio siempre empieza positivo.',
      ejemploExpresion: '8x³ - 27',
      pasos: [
        PasoEjemplo(
          '1. Identifica a = ∛(8x³)',
          'a = 2x  (porque (2x)³ = 8x³)',
        ),
        PasoEjemplo(
          '2. Identifica b = ∛27',
          'b = 3  (porque 3³ = 27)',
        ),
        PasoEjemplo(
          '3. Es diferencia de cubos, aplica (a-b)(a²+ab+b²)',
          'Binomio: (2x - 3)',
        ),
        PasoEjemplo(
          '4. Calcula cada término del trinomio',
          'a² = 4x²,  ab = 6x,  b² = 9',
        ),
        PasoEjemplo(
          '5. Escribe la factorización completa',
          '(2x - 3)(4x² + 6x + 9)',
        ),
        PasoEjemplo(
          '6. Verifica multiplicando el binomio por el trinomio',
          '8x³ + 12x² + 18x - 12x² - 18x - 27 = 8x³ - 27 ✓',
        ),
      ],
    ),
  };

  /// Devuelve el contenido teórico del método o null si no existe.
  static TeoriaContent? obtener(String metodo) => contenido[metodo];
}
