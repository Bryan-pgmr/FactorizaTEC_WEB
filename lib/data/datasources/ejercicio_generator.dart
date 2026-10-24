import 'dart:math';

class EjercicioGenerator {
  static const _vars = ['x', 'y'];
  static const _cuadrados = [4, 9, 16, 25, 36, 49, 64, 81, 100];
  static const _raices    = [2, 3,  4,  5,  6,  7,  8,  9,  10];
  static const _cubos = [8, 27, 64, 125, 216, 343];
  static const _raicesCubicas = [2, 3, 4, 5, 6, 7];

  static List<_EjercicioGenerado> generar({
    required String metodo,
    required String dificultad,
    required int cantidad,
    int? semilla,
    /// Expresiones ya existentes en la BD (seed) para este tema+dificultad,
    /// que también se excluyen para evitar duplicados con el seed.
    Set<String>? expresionesExistentes,
  }) {
    final rng = semilla != null ? Random(semilla) : Random();
    final lista = <_EjercicioGenerado>[];
    // Conjunto de expresiones ya generadas en esta sesión + las del seed
    final usadas = <String>{...?expresionesExistentes};
    int intentos = 0;
    while (lista.length < cantidad && intentos < cantidad * 20) {
      intentos++;
      _EjercicioGenerado? ej;
      switch (metodo) {
        case 'factor_comun': ej = _factorComun(rng, dificultad); break;
        case 'diff_cuadrados': ej = _diffCuadrados(rng, dificultad); break;
        case 'trinomio_perfecto': ej = _trinomioPerfecto(rng, dificultad); break;
        case 'trinomio_ax2': ej = _trinomioAx2(rng, dificultad); break;
        case 'cubos': ej = _cubos_(rng, dificultad); break;
      }
      if (ej != null && !usadas.contains(ej.expresion)) {
        usadas.add(ej.expresion);
        lista.add(ej);
      }
    }
    return lista;
  }

  static String _v(Random r) => _vars[r.nextInt(_vars.length)];
  static String _v2(Random r, String exc) {
    final d = _vars.where((x) => x != exc).toList();
    return d[r.nextInt(d.length)];
  }
  static T _p<T>(Random r, List<T> l) => l[r.nextInt(l.length)];
  static List<int> _fac(int n) { final f=<int>[]; for(int i=1;i<=n;i++){if(n%i==0)f.add(i);} return f; }
  static int _mcd(int a, int b) { while(b!=0){final t=b;b=a%b;a=t;} return a; }
  static Map<String,String> _paso(String e, String d, String err, String p) =>
      {'expresion':e,'descripcion':d,'explicacion_error':err,'pista':p};

  static _EjercicioGenerado _factorComun(Random r, String dif) {
    final v = _v(r);
    if (dif == 'facil') {
      // Garantizar que m y n sean coprimos entre sí para que k sea el MFC real.
      // Pares (m,n) coprimos seleccionados a mano:
      const pares = [[2,3],[2,5],[2,7],[3,4],[3,5],[3,7],[4,5],[4,7],[5,6],[5,7]];
      final k = _p(r,[2,3,4,5,6]);
      final par = _p(r, pares);
      final m = par[0]; final n = par[1];
      final a = k*m; final b = k*n;
      // Verificación: el MCD real debe ser exactamente k
      assert(_mcd(a,b)==k, 'MCD($a,$b)=${_mcd(a,b)} ≠ $k');
      return _EjercicioGenerado('${a}$v + $b', dif, [
        _paso('$k','Encuentra el MFC de $a y $b','El MFC de $a y $b es $k.','Factores de $a: ${_fac(a).join(", ")}. Factores de $b: ${_fac(b).join(", ")}.'),
        _paso('$k(${m}$v+$n)','Escribe la expresión factorizada','Divide: ${a}$v÷$k=${m}$v y $b÷$k=$n.','La forma es $k(__ + __).'),
        _paso('${a}${v}+$b','Verifica distribuyendo','$k×${m}$v=${a}$v y $k×$n=$b.','Multiplica $k por cada término dentro del paréntesis.'),
      ]);
    }
    if (dif == 'medio') {
      // p, q, s deben ser coprimos entre sí para que k sea el MFC real.
      const trios = [[2,3,5],[2,3,7],[2,5,7],[3,4,5],[3,5,7],[4,5,7]];
      final k = _p(r,[2,3,4]);
      final trio = _p(r, trios);
      final p = trio[0]; final q = trio[1]; final s = trio[2];
      final a=k*p; final b=k*q; final c=k*s;
      return _EjercicioGenerado('${a}${v}³ - ${b}${v}² + ${c}$v', dif, [
        _paso('${k}$v','Encuentra el MFC de coeficientes y variables','El MFC de $a, $b y $c es $k. La variable común con menor exponente es ${v}¹. Escribe: ${k}$v','Busca el MCD de los coeficientes ($a, $b, $c) y la variable con el exponente más pequeño.'),
        _paso('${k}${v}(${p}${v}²-${q}$v+$s)','Escribe la factorización completa','Divide cada término entre ${k}$v: ${a}${v}³÷${k}$v=${p}${v}², ${b}${v}²÷${k}$v=${q}$v, ${c}$v÷${k}$v=$s.','La forma es ${k}$v(__ - __ + __). Divide cada coeficiente entre $k y resta 1 a cada exponente.'),
        _paso('${a}${v}³-${b}${v}²+${c}$v','Verifica distribuyendo ${k}$v en el trinomio','${k}$v·${p}${v}²=${a}${v}³ ✓, ${k}$v·${q}$v=${b}${v}² ✓, ${k}$v·$s=${c}$v ✓.','Multiplica ${k}$v por cada término dentro del paréntesis.'),
      ]);
    }
    // Difícil: dos variables. p, q, s coprimos para que k sea MFC real.
    const trios = [[2,3,5],[2,3,7],[2,5,7],[3,4,5],[3,5,7]];
    final v2=_v2(r,v); final k=_p(r,[2,3]); final trio=_p(r,trios);
    final p=trio[0]; final q=trio[1]; final s=trio[2];
    final e1=k*p; final e2=k*q; final e3=k*s;
    return _EjercicioGenerado('${e1}${v}²${v2}³ - ${e2}$v${v2}⁴ + ${e3}${v}³${v2}²', dif, [
      _paso('${k}$v${v2}²','Encuentra el MFC con dos variables','MFC coef=$k. Para $v: exp mín=1. Para $v2: exp mín=2. MFC=${k}$v${v2}².','MFC de números y menor exponente de cada variable.'),
      _paso('${k}$v${v2}²(${p}$v${v2}-${q}${v2}²+${s}${v}²)','Escribe la factorización','Divide coef entre $k y resta exponentes.','Resta exponentes al dividir variables.'),
      _paso('${e1}${v}²${v2}³-${e2}$v${v2}⁴+${e3}${v}³${v2}²','Verifica distribuyendo','Multiplica ${k}$v${v2}² por cada término.','Al multiplicar, suma los exponentes.'),
    ]);
  }

  static _EjercicioGenerado _diffCuadrados(Random r, String dif) {
    final v=_v(r); final idx=r.nextInt(_cuadrados.length);
    final b2=_cuadrados[idx]; final b=_raices[idx];
    if (dif == 'facil') {
      return _EjercicioGenerado('${v}² - $b2', dif, [
        _paso(v,'Identifica p = √(${v}²)','√(${v}²) = $v.','¿Qué elevado al cuadrado da ${v}²?'),
        _paso('$b','Identifica q = √$b2','√$b2 = $b porque $b² = $b2.','¿Qué número al cuadrado da $b2?'),
        _paso('($v+$b)($v-$b)','Escribe la forma (p+q)(p-q)','Con p=$v y q=$b: ($v+$b)($v-$b).','Sustituye en (p+q)(p-q).'),
      ]);
    }
    if (dif == 'medio') {
      final k=_p(r,[2,3,4,5]); final k2=k*k;
      return _EjercicioGenerado('${k2}${v}² - $b2', dif, [
        _paso('${k}$v','Identifica p = √(${k2}${v}²)','√$k2=$k y √(${v}²)=$v, entonces p=${k}$v.','√$k2=$k.'),
        _paso('$b','Identifica q = √$b2','√$b2=$b, entonces q=$b.','$b²=$b2.'),
        _paso('(${k}$v+$b)(${k}$v-$b)','Escribe la forma factorizada','Con p=${k}$v y q=$b: aplica (p+q)(p-q).','Aplica (p+q)(p-q).'),
      ]);
    }
    final v2=_v2(r,v); final k=_p(r,[2,3,4,5]); final m=_p(r,[2,3,4,5,6,7]);
    final k2=k*k; final m2=m*m;
    return _EjercicioGenerado('${k2}${v}⁴ - ${m2}${v2}²', dif, [
      _paso('${k}${v}²','Identifica p = √(${k2}${v}⁴)','√$k2=$k y √(${v}⁴)=${v}².','Raíz de ${v}⁴ es ${v}² (exp÷2).'),
      _paso('${m}$v2','Identifica q = √(${m2}${v2}²)','√$m2=$m y √(${v2}²)=$v2.','√$m2=$m.'),
      _paso('(${k}${v}²+${m}$v2)(${k}${v}²-${m}$v2)','Escribe la forma factorizada','(${k}${v}²+${m}$v2)(${k}${v}²-${m}$v2).','Sustituye en (p+q)(p-q) donde p=${k}${v}², q=${m}$v2.'),
    ]);
  }

  static _EjercicioGenerado _trinomioPerfecto(Random r, String dif) {
    final v=_v(r); final idx=r.nextInt(_raices.length);
    final b=_raices[idx]; final b2=_cuadrados[idx]; final tm=2*b;
    final sg=r.nextBool()?'+':'-'; final sf=sg=='+' ?'+':'-';
    if (dif == 'facil') {
      return _EjercicioGenerado('${v}² $sg ${tm}$v + $b2', dif, [
        _paso(v,'Encuentra p = √(${v}²)','√(${v}²)=$v.','¿Qué al cuadrado da ${v}²?'),
        _paso('$b','Encuentra q = √$b2','√$b2=$b.','$b²=$b2.'),
        _paso('${tm}$v','Verifica término medio: 2·p·q=2·$v·$b','2·$v·$b=${tm}$v ✓.','Calcula 2×$v×$b.'),
        _paso('($v${sf}$b)²','Escribe la forma ($v$sf$b)²','Con p=$v y q=$b: ($v$sf$b)².','El signo del término medio indica el del binomio.'),
      ]);
    }
    if (dif == 'medio') {
      final k=_p(r,[2,3,4,5]); final k2=k*k; final tmk=2*k*b;
      return _EjercicioGenerado('${k2}${v}² $sg ${tmk}$v + $b2', dif, [
        _paso('${k}$v','Encuentra p = √(${k2}${v}²)','√$k2=$k y √(${v}²)=$v, entonces p=${k}$v.','√$k2=$k.'),
        _paso('$b','Encuentra q = √$b2','√$b2=$b, entonces q=$b.','$b²=$b2.'),
        _paso('${tmk}$v','Verifica: 2·p·q=2·${k}$v·$b','2·${k}$v·$b=${tmk}$v ✓.','Multiplica 2×${k}$v×$b.'),
        _paso('(${k}$v${sf}$b)²','Escribe (${k}$v$sf$b)²','Con p=${k}$v y q=$b: aplica (p$sf q)².','Aplica (p$sf q)².'),
      ]);
    }
    final v2=_v2(r,v); final k=_p(r,[2,3,4]); final m=_p(r,[2,3,4]);
    final k2=k*k; final m2=m*m; final tm2=2*k*m;
    return _EjercicioGenerado('${k2}${v}² $sg ${tm2}$v${v2} + ${m2}${v2}²', dif, [
      _paso('${k}$v','Encuentra p = √(${k2}${v}²)','√$k2=$k, entonces p=${k}$v.','√$k2=$k.'),
      _paso('${m}$v2','Encuentra q = √(${m2}${v2}²)','√$m2=$m, entonces q=${m}$v2.','√$m2=$m.'),
      _paso('${tm2}$v$v2','Verifica: 2·p·q=2·${k}$v·${m}$v2','2·${k}$v·${m}$v2=${tm2}$v$v2 ✓.','Multiplica 2×${k}$v×${m}$v2.'),
      _paso('(${k}$v${sf}${m}$v2)²','Escribe el cuadrado del binomio','Con p=${k}$v y q=${m}$v2: (${k}$v${sf}${m}$v2)².','Aplica (p$sf q)².'),
    ]);
  }

  static _EjercicioGenerado _trinomioAx2(Random r, String dif) {
    final v=_v(r);
    if (dif == 'facil') {
      final p=_p(r,[1,2,3,4]); final q=_p(r,[2,3,4,5]);
      final b=p+q; final c=p*q;
      return _EjercicioGenerado('${v}² + ${b}$v + $c', dif, [
        _paso('$p $q','Encuentra dos números: producto=$c y suma=$b. Escríbelos separados por espacio: "$p $q"','$p×$q=$c ✓ y $p+$q=$b ✓. Formato: "$p $q"','Lista pares con producto $c. Escríbelos como: "num1 num2"'),
        _paso('($v+$p)($v+$q)','Escribe la factorización completa','La forma es ($v+$p)($v+$q).','($v+__)($v+__).'),
      ]);
    }
    if (dif == 'medio') {
      final a=_p(r,[2,3]); final r1=_p(r,[1,2,3]); final r2=_p(r,[1,2,3]);
      final b=a*r2+r1; final c=r1*r2; final ac=a*c;
      return _EjercicioGenerado('${a}${v}² + ${b}$v + $c', dif, [
        _paso('$ac','Calcula ac = $a×$c','ac=$ac.','Multiplica el coef de ${v}² por el término independiente.'),
        _paso('$r1 ${a*r2}','Encuentra dos números: producto=$ac y suma=$b. Escríbelos separados por espacio: "$r1 ${a*r2}"','$r1×${a*r2}=$ac ✓ y $r1+${a*r2}=$b ✓. Formato: "$r1 ${a*r2}"','Prueba pares con producto $ac. Escríbelos como: "num1 num2"'),
        _paso('${a}${v}^2+${r1}$v+${a*r2}$v+$c','Reescribe ${b}$v como ${r1}$v+${a*r2}$v','Sustituye ${b}$v.','Descompón usando los dos números.'),
        _paso('(${a}$v+$c)($v+$r2)','Factoriza por agrupación','Agrupa y saca factor binomial.','Saca factor de cada par.'),
      ]);
    }
    final a=_p(r,[2,3,4]); final p=_p(r,[2,3]); final q=_p(r,[2,3]);
    final b=-(a*q-p); final c=-(p*q); final ac=a*c;
    return _EjercicioGenerado('${a}${v}² + ${b}$v + $c', dif, [
      _paso('$ac','Calcula ac = $a×($c)','ac=$ac. Cuida el signo.','a=$a, c=$c.'),
      _paso('$p ${-(a*q)}','Encuentra dos números: producto=$ac y suma=$b. Escríbelos separados por espacio: "$p ${-(a*q)}"','$p×${-(a*q)}=$ac ✓. Formato: "$p ${-(a*q)}"','Uno positivo y uno negativo. Escríbelos como: "num1 num2"'),
      _paso('${a}${v}^2+${p}$v+${-(a*q)}$v+$c','Reescribe ${b}$v','Sustituye usando los dos números.','Descompón.'),
      _paso('($a$v+$p)($v-$q)','Factoriza por agrupación','Extrae el factor binomial común.','Saca factor de cada par.'),
    ]);
  }

  static _EjercicioGenerado _cubos_(Random r, String dif) {
    final v=_v(r); final idx=r.nextInt(_cubos.length);
    final b3=_cubos[idx]; final b=_raicesCubicas[idx]; final b2=b*b;
    final sg=r.nextBool()?'+':'-'; final esSuma=sg=='+';
    if (dif == 'facil') {
      final f=esSuma?'($v+$b)(${v}²-${b}$v+$b2)':'($v-$b)(${v}²+${b}$v+$b2)';
      final fm=esSuma?'(p+q)(p²-pq+q²)':'(p-q)(p²+pq+q²)';
      return _EjercicioGenerado('${v}³ $sg $b3', dif, [
        _paso(v,'Encuentra p = ∛(${v}³)','∛(${v}³)=$v.','¿Qué al cubo da ${v}³?'),
        _paso('$b','Encuentra q = ∛$b3','$b³=$b3.','$b×$b×$b=$b3.'),
        _paso(f,'Aplica $fm','Con p=$v y q=$b: $f.','La fórmula es $fm.'),
      ]);
    }
    if (dif == 'medio') {
      final k=_p(r,[2,3,4]); final k3=k*k*k; final k2=k*k;
      final pStr='${k}$v'; final p2='${k2}${v}²'; final pq='${k*b}$v';
      final f=esSuma?'($pStr+$b)($p2-${pq}+$b2)':'($pStr-$b)($p2+${pq}+$b2)';
      return _EjercicioGenerado('${k3}${v}³ $sg $b3', dif, [
        _paso(pStr,'Encuentra p = ∛(${k3}${v}³)','∛$k3=$k y ∛(${v}³)=$v, entonces p=${k}$v.','$k³=$k3.'),
        _paso('$b','Encuentra q = ∛$b3','$b³=$b3, entonces q=$b.','$b×$b×$b=$b3.'),
        _paso(f,'Aplica ${esSuma?"suma":"diferencia"} de cubos','p²=$p2, pq=$pq, q²=$b2.','Calcula p², p·q y q² con p=${k}$v, q=$b.'),
      ]);
    }
    final v2=_v2(r,v); final k=_p(r,[2,3,4]); final m=_p(r,[2,3,4]);
    final k3=k*k*k; final m3=m*m*m; final k2=k*k; final m2=m*m;
    final pStr='${k}$v'; final qStr='${m}$v2';
    final p2='${k2}${v}²'; final q2='${m2}${v2}²'; final pq='${k*m}$v$v2';
    final f=esSuma?'($pStr+$qStr)($p2-$pq+$q2)':'($pStr-$qStr)($p2+$pq+$q2)';
    return _EjercicioGenerado('${k3}${v}³ $sg ${m3}${v2}³', dif, [
      _paso(pStr,'Encuentra p = ∛(${k3}${v}³)','∛$k3=$k y ∛(${v}³)=$v, entonces p=${k}$v.','$k³=$k3.'),
      _paso(qStr,'Encuentra q = ∛(${m3}${v2}³)','∛$m3=$m y ∛(${v2}³)=$v2, entonces q=${m}$v2.','$m³=$m3.'),
      _paso(f,'Aplica ${esSuma?"suma":"diferencia"} de cubos','p²=$p2, pq=$pq, q²=$q2.','Calcula p², p·q y q² con p=${k}$v, q=${m}$v2.'),
    ]);
  }
}

class _EjercicioGenerado {
  final String expresion;
  final String dificultad;
  final List<Map<String, String>> pasos;
  const _EjercicioGenerado(this.expresion, this.dificultad, this.pasos);
}
