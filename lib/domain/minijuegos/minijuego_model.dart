
/// Tipos de mini juego disponibles
enum MiniJuegoTipo { memoria, empareja, carreraMcd }

extension MiniJuegoTipoExt on MiniJuegoTipo {
  String get nombre {
    switch (this) {
      case MiniJuegoTipo.memoria: return 'Memoria de Parejas';
      case MiniJuegoTipo.empareja: return 'Empareja Flotante';
      case MiniJuegoTipo.carreraMcd: return 'Carrera del MCD';
    }
  }

  String get descripcion {
    switch (this) {
      case MiniJuegoTipo.memoria: return 'Encuentra la pareja de cada expresión';
      case MiniJuegoTipo.empareja: return 'Toca los factores correctos antes de que se acabe el tiempo';
      case MiniJuegoTipo.carreraMcd: return 'Extrae el factor común antes de que caigan los términos';
    }
  }

  String get icono {
    switch (this) {
      case MiniJuegoTipo.memoria: return '🃏';
      case MiniJuegoTipo.empareja: return '🫧';
      case MiniJuegoTipo.carreraMcd: return '🏃';
    }
  }

  /// XP base al completar el mini juego
  int get xpBase {
    switch (this) {
      case MiniJuegoTipo.memoria: return 20;
      case MiniJuegoTipo.empareja: return 25;
      case MiniJuegoTipo.carreraMcd: return 30;
    }
  }
}

// ─── Modelo de par para Memoria ──────────────────────────────────────────────

class ParMemoria {
  final String expresionDesarrollada;
  final String expresionFactorizada;
  final String temaId;

  const ParMemoria({
    required this.expresionDesarrollada,
    required this.expresionFactorizada,
    required this.temaId,
  });
}

// ─── Modelo de ronda para Empareja Flotante ───────────────────────────────────

class RondaEmpareja {
  final String expresion;
  final List<String> opciones;
  final List<int> indicesCorrectos;
  final String temaId;

  const RondaEmpareja({
    required this.expresion,
    required this.opciones,
    required this.indicesCorrectos,
    required this.temaId,
  });
}

// ─── Modelo de ronda para Carrera MCD ────────────────────────────────────────

class RondaMcd {
  final List<String> terminos;       // ej. ['8x³', '12x²', '4x']
  final String mcdCorrecto;          // ej. '4x'
  final List<String> opcionesNum;    // ej. ['2', '4', '8']
  final List<String> opcionesVar;    // ej. ['x', 'x²', 'x³']
  final String numCorrecto;
  final String varCorrecta;

  const RondaMcd({
    required this.terminos,
    required this.mcdCorrecto,
    required this.opcionesNum,
    required this.opcionesVar,
    required this.numCorrecto,
    required this.varCorrecta,
  });
}

// ─── Resultado de mini juego ──────────────────────────────────────────────────

class ResultadoMiniJuego {
  final MiniJuegoTipo tipo;
  final int aciertos;
  final int errores;
  final int xpObtenido;
  final Duration tiempoTotal;

  const ResultadoMiniJuego({
    required this.tipo,
    required this.aciertos,
    required this.errores,
    required this.xpObtenido,
    required this.tiempoTotal,
  });
}

// ─── Banco de contenido para mini juegos ─────────────────────────────────────

class MiniJuegoData {
  /// Pares para el juego de memoria — 8 pares por sesión
  static List<ParMemoria> generarPares({String? temaFiltro}) {
    var todos = List<ParMemoria>.from(_pares);
    if (temaFiltro != null) {
      final filtrados = todos.where((p) => p.temaId == temaFiltro).toList();
      // Si hay suficientes del tema, usar solo esos; si no, completar con otros
      if (filtrados.length >= 4) {
        todos = filtrados;
      }
    }
    todos.shuffle();
    return todos.take(8).toList();
  }

  /// Rondas para Empareja Flotante — 5 por sesión
  static List<RondaEmpareja> generarRondasEmpareja({String? temaFiltro}) {
    var todos = List<RondaEmpareja>.from(_rondasEmpareja);
    if (temaFiltro != null) {
      final filtrados = todos.where((r) => r.temaId == temaFiltro).toList();
      if (filtrados.length >= 3) {
        todos = filtrados;
      }
    }
    todos.shuffle();
    return todos.take(5).toList();
  }

  /// Rondas para Carrera MCD — 5 por sesión
  static List<RondaMcd> generarRondasMcd({String? temaFiltro}) {
    // Carrera MCD siempre es factor_comun — el filtro no aplica temáticamente
    // pero se respeta si viene explícito y hay rondas disponibles
    final todos = List<RondaMcd>.from(_rondasMcd);
    todos.shuffle();
    return todos.take(5).toList();
  }

  // ─── Banco de pares (memoria) ───────────────────────────────────────────────

  static List<ParMemoria> get _pares => [
    const ParMemoria(expresionDesarrollada: 'x² + 5x + 6',   expresionFactorizada: '(x+2)(x+3)',   temaId: 'trinomio_ax2'),
    const ParMemoria(expresionDesarrollada: 'x² - 9',        expresionFactorizada: '(x+3)(x-3)',   temaId: 'diff_cuadrados'),
    const ParMemoria(expresionDesarrollada: 'x² + 6x + 9',   expresionFactorizada: '(x+3)²',       temaId: 'trinomio_perfecto'),
    const ParMemoria(expresionDesarrollada: '4x² - 25',      expresionFactorizada: '(2x+5)(2x-5)', temaId: 'diff_cuadrados'),
    const ParMemoria(expresionDesarrollada: '6x + 9',        expresionFactorizada: '3(2x+3)',       temaId: 'factor_comun'),
    const ParMemoria(expresionDesarrollada: 'x³ + 8',        expresionFactorizada: '(x+2)(x²-2x+4)', temaId: 'cubos'),
    const ParMemoria(expresionDesarrollada: 'x² - 4x + 4',  expresionFactorizada: '(x-2)²',       temaId: 'trinomio_perfecto'),
    const ParMemoria(expresionDesarrollada: '2x² + 7x + 3',  expresionFactorizada: '(2x+1)(x+3)',  temaId: 'trinomio_ax2'),
    const ParMemoria(expresionDesarrollada: 'x² - 16',       expresionFactorizada: '(x+4)(x-4)',   temaId: 'diff_cuadrados'),
    const ParMemoria(expresionDesarrollada: '4x³ - 8x² + 12x', expresionFactorizada: '4x(x²-2x+3)', temaId: 'factor_comun'),
    const ParMemoria(expresionDesarrollada: 'x² + 8x + 16',  expresionFactorizada: '(x+4)²',       temaId: 'trinomio_perfecto'),
    const ParMemoria(expresionDesarrollada: 'x³ - 27',       expresionFactorizada: '(x-3)(x²+3x+9)', temaId: 'cubos'),
    const ParMemoria(expresionDesarrollada: '3x² + 10x + 8', expresionFactorizada: '(3x+4)(x+2)',  temaId: 'trinomio_ax2'),
    const ParMemoria(expresionDesarrollada: '9x² - 1',       expresionFactorizada: '(3x+1)(3x-1)', temaId: 'diff_cuadrados'),
    const ParMemoria(expresionDesarrollada: '5x² - 10x',     expresionFactorizada: '5x(x-2)',      temaId: 'factor_comun'),
    const ParMemoria(expresionDesarrollada: 'x² - 10x + 25', expresionFactorizada: '(x-5)²',       temaId: 'trinomio_perfecto'),
  ];

  // ─── Banco de rondas Empareja Flotante ─────────────────────────────────────

  static List<RondaEmpareja> get _rondasEmpareja => [
    RondaEmpareja(
      expresion: 'x² - 9',
      opciones: ['(x+3)', '(x-3)', '(x+9)', '(x-9)', '(x+1)', '(x-1)'],
      indicesCorrectos: [0, 1],
      temaId: 'diff_cuadrados',
    ),
    RondaEmpareja(
      expresion: 'x² + 5x + 6',
      opciones: ['(x+2)', '(x+3)', '(x+1)', '(x+6)', '(x-2)', '(x-3)'],
      indicesCorrectos: [0, 1],
      temaId: 'trinomio_ax2',
    ),
    RondaEmpareja(
      expresion: '4x² - 25',
      opciones: ['(2x+5)', '(2x-5)', '(4x+5)', '(4x-5)', '(x+5)', '(x-5)'],
      indicesCorrectos: [0, 1],
      temaId: 'diff_cuadrados',
    ),
    RondaEmpareja(
      expresion: 'x² - 16',
      opciones: ['(x+4)', '(x-4)', '(x+8)', '(x-8)', '(x+2)', '(x-2)'],
      indicesCorrectos: [0, 1],
      temaId: 'diff_cuadrados',
    ),
    RondaEmpareja(
      expresion: 'x² + 7x + 12',
      opciones: ['(x+3)', '(x+4)', '(x+6)', '(x+2)', '(x-3)', '(x-4)'],
      indicesCorrectos: [0, 1],
      temaId: 'trinomio_ax2',
    ),
    RondaEmpareja(
      expresion: '9x² - 1',
      opciones: ['(3x+1)', '(3x-1)', '(9x+1)', '(9x-1)', '(x+1)', '(x-1)'],
      indicesCorrectos: [0, 1],
      temaId: 'diff_cuadrados',
    ),
    RondaEmpareja(
      expresion: 'x² - 25',
      opciones: ['(x+5)', '(x-5)', '(x+25)', '(x-25)', '(x+1)', '(x-1)'],
      indicesCorrectos: [0, 1],
      temaId: 'diff_cuadrados',
    ),
    RondaEmpareja(
      expresion: 'x² + 4x + 4',
      opciones: ['(x+2)', '(x+2)', '(x+4)', '(x+1)', '(x-2)', '(x-4)'],
      indicesCorrectos: [0, 1],
      temaId: 'trinomio_perfecto',
    ),
  ];

  // ─── Banco de rondas Carrera MCD ───────────────────────────────────────────

  static List<RondaMcd> get _rondasMcd => [
    const RondaMcd(
      terminos: ['6x', '9x²', '3x³'],
      mcdCorrecto: '3x',
      opcionesNum: ['2', '3', '6'],
      opcionesVar: ['x', 'x²', 'x³'],
      numCorrecto: '3',
      varCorrecta: 'x',
    ),
    const RondaMcd(
      terminos: ['8x³', '12x²', '4x'],
      mcdCorrecto: '4x',
      opcionesNum: ['2', '4', '8'],
      opcionesVar: ['x', 'x²', 'x³'],
      numCorrecto: '4',
      varCorrecta: 'x',
    ),
    const RondaMcd(
      terminos: ['10x²', '15x³', '5x'],
      mcdCorrecto: '5x',
      opcionesNum: ['5', '10', '15'],
      opcionesVar: ['x', 'x²', 'x³'],
      numCorrecto: '5',
      varCorrecta: 'x',
    ),
    const RondaMcd(
      terminos: ['4x²y', '6xy²', '2xy'],
      mcdCorrecto: '2xy',
      opcionesNum: ['2', '4', '6'],
      opcionesVar: ['xy', 'x²y', 'xy²'],
      numCorrecto: '2',
      varCorrecta: 'xy',
    ),
    const RondaMcd(
      terminos: ['9x³', '6x²', '3x'],
      mcdCorrecto: '3x',
      opcionesNum: ['3', '6', '9'],
      opcionesVar: ['x', 'x²', 'x³'],
      numCorrecto: '3',
      varCorrecta: 'x',
    ),
    const RondaMcd(
      terminos: ['12y²', '8y³', '4y'],
      mcdCorrecto: '4y',
      opcionesNum: ['2', '4', '8'],
      opcionesVar: ['y', 'y²', 'y³'],
      numCorrecto: '4',
      varCorrecta: 'y',
    ),
    const RondaMcd(
      terminos: ['15y³', '10y²', '5y'],
      mcdCorrecto: '5y',
      opcionesNum: ['5', '10', '15'],
      opcionesVar: ['y', 'y²', 'y³'],
      numCorrecto: '5',
      varCorrecta: 'y',
    ),
  ];
}
