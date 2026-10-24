import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/bloc/ejercicio_bloc.dart';
import '../../../domain/entities/ejercicio.dart';
import '../../widgets/teclado_matematico.dart';

class EjercicioScreen extends StatelessWidget {
  final Ejercicio ejercicio;
  final int alumnoId;

  const EjercicioScreen({
    super.key,
    required this.ejercicio,
    required this.alumnoId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EjercicioBloc(alumnoId: alumnoId)..iniciar(ejercicio),
      child: const _EjercicioView(),
    );
  }
}

class _EjercicioView extends StatelessWidget {
  const _EjercicioView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EjercicioBloc, EjercicioState>(
      listener: (context, state) {
        if (state is EjercicioCompletado) {
          _mostrarResultado(context, state);
        }
      },
      builder: (context, state) {
        if (state is EjercicioEnProgreso) {
          return _PantallaEnProgreso(state: state);
        }
        if (state is PasoSuperado) {
          return _PantallaEnProgreso(state: state.estadoAnterior);
        }
        // Cuando el ejercicio se completó, seguimos mostrando la pantalla
        // del ejercicio en el fondo (detrás del modal de resultado).
        // Esto es necesario para que el doble-pop del modal funcione:
        // primer pop cierra el modal, segundo pop cierra esta pantalla.
        if (state is EjercicioCompletado) {
          return _PantallaEnProgreso(state: state.estadoFinal);
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _mostrarResultado(BuildContext context, EjercicioCompletado state) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetCompletado(state: state),
    );
  }
}

// ─── Pantalla en progreso ─────────────────────────────────────────────────────

class _PantallaEnProgreso extends StatelessWidget {
  final EjercicioEnProgreso state;
  const _PantallaEnProgreso({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.ejercicio.dificultad.etiqueta),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text('+${state.ejercicio.dificultad.xpBase} XP'),
              labelStyle: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: theme.colorScheme.primaryContainer,
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Expresión a factorizar ──
              Text(
                'Factoriza la siguiente expresión:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.ejercicio.expresion,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // ── Lista de pasos ──
              Text(
                'PASOS',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...state.ejercicio.pasos.asMap().entries.map((e) {
                return _ItemPaso(
                  paso: e.value,
                  index: e.key,
                  pasoActualIndex: state.pasoActualIndex,
                  completado: state.pasosCompletados[e.key],
                );
              }),

              const SizedBox(height: 16),

              // ── Error o pista ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: state.mostrarError
                    ? _CajaError(
                        key: const ValueKey('error'),
                        mensaje: state.pasoActual.explicacionError,
                      )
                    : state.mostrarPista
                        ? _CajaPista(
                            key: const ValueKey('pista'),
                            pista: state.pasoActual.pista,
                          )
                        : const SizedBox.shrink(key: ValueKey('nada')),
              ),

              // ── Campo de entrada ──
              _CampoEntrada(entrada: state.entradaActual, cursorPos: state.cursorPos),
              const SizedBox(height: 8),

              // ── Fila: errores + pista ──
              _FilaHint(
                errores: state.erroresCometidos,
                mostrarPista: state.mostrarPista,
              ),
              const SizedBox(height: 10),

              // ── Teclado matemático ──
              const TecladoMatematico(),
              const SizedBox(height: 12),

              // ── Botón verificar ──
              _BotonVerificar(entradaActual: state.entradaActual),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets de detalle ───────────────────────────────────────────────────────

class _ItemPaso extends StatelessWidget {
  final PasoEsperado paso;
  final int index;
  final int pasoActualIndex;
  final bool completado;

  const _ItemPaso({
    required this.paso,
    required this.index,
    required this.pasoActualIndex,
    required this.completado,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esActivo = index == pasoActualIndex;
    final esPendiente = index > pasoActualIndex;

    Color bgColor;
    Color fgColor;
    IconData icono;

    if (completado) {
      bgColor = theme.colorScheme.secondaryContainer;
      fgColor = theme.colorScheme.onSecondaryContainer;
      icono = Icons.check_rounded;
    } else if (esActivo) {
      bgColor = theme.colorScheme.primaryContainer;
      fgColor = theme.colorScheme.onPrimaryContainer;
      icono = Icons.edit_rounded;
    } else {
      bgColor = theme.colorScheme.surfaceVariant;
      fgColor = theme.colorScheme.onSurfaceVariant;
      icono = Icons.circle_outlined;
    }

    return AnimatedOpacity(
      opacity: esPendiente ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                paso.descripcion,
                style: TextStyle(fontSize: 13, color: fgColor),
              ),
            ),
            Icon(icono, size: 16, color: fgColor),
          ],
        ),
      ),
    );
  }
}

class _CajaError extends StatelessWidget {
  final String mensaje;
  const _CajaError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mascota ──
          Image.asset('assets/images/mascota_error.png',
              width: 48, height: 48, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CajaPista extends StatelessWidget {
  final String pista;
  const _CajaPista({super.key, required this.pista});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mascota ──
          Image.asset('assets/images/mascota_pista.png',
              width: 48, height: 48, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pista,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onTertiaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoEntrada extends StatelessWidget {
  final String entrada;
  final int cursorPos;
  const _CampoEntrada({required this.entrada, required this.cursorPos});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<EjercicioBloc>();

    // Dividir el texto en: antes del cursor y después del cursor
    final pos = cursorPos.clamp(0, entrada.length);
    final antes = entrada.substring(0, pos);
    final despues = entrada.substring(pos);

    return GestureDetector(
      onTapDown: (details) {
        // Detectar en qué posición se tocó para mover cursor
        // Usamos la posición relativa horizontal para estimar el índice
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx - 14; // padding
        if (localX <= 0) {
          bloc.add(MoverCursor(0));
          return;
        }
        // Estimación: ~12px por carácter monospace a fontSize 20
        const charWidth = 12.0;
        final estimado = (localX / charWidth).round().clamp(0, entrada.length);
        bloc.add(MoverCursor(estimado));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 1),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(text: antes.isEmpty && despues.isEmpty ? ' ' : antes),
                    // Cursor parpadeante inline
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _CursorParpadeo(),
                    ),
                    TextSpan(text: despues),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CursorParpadeo extends StatefulWidget {
  @override
  State<_CursorParpadeo> createState() => _CursorParpadeoState();
}

class _CursorParpadeoState extends State<_CursorParpadeo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 22,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _FilaHint extends StatelessWidget {
  final int errores;
  final bool mostrarPista;

  const _FilaHint({required this.errores, required this.mostrarPista});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (errores > 0)
          Chip(
            label: Text('$errores error${errores > 1 ? 'es' : ''}'),
            labelStyle: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
            avatar: Icon(Icons.close, size: 14, color: theme.colorScheme.error),
            backgroundColor: theme.colorScheme.errorContainer,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          )
        else
          const SizedBox.shrink(),
        TextButton.icon(
          onPressed: mostrarPista
              ? null
              : () => context.read<EjercicioBloc>().add(SolicitarPista()),
          icon: const Icon(Icons.lightbulb_outline_rounded, size: 14),
          label: Text(mostrarPista ? 'Pista visible' : 'Ver pista'),
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _BotonVerificar extends StatelessWidget {
  final String entradaActual;
  const _BotonVerificar({required this.entradaActual});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: entradaActual.isEmpty
            ? null
            : () => context
                .read<EjercicioBloc>()
                .add(VerificarPaso(entradaActual)),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Verificar paso',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Bottom sheet: ejercicio completado ──────────────────────────────────────

class _BottomSheetCompletado extends StatelessWidget {
  final EjercicioCompletado state;
  const _BottomSheetCompletado({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = state.resultado;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Mascota ──
          Image.asset(
            r.subioDeNivel
                ? 'assets/images/mascota_exito.png'
                : 'assets/images/mascota_exito.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),

          Text(
            r.subioDeNivel
                ? '¡Subiste al nivel ${r.nivelNuevo}!'
                : '¡Ejercicio completado!',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Racha
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 16,
                  color: r.rachaNueva >= 5
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${r.rachaNueva} ${r.rachaNueva == 1 ? 'día' : 'días'} de racha',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // XP ganado
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '+${r.xpObtenido} XP',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                // Bonus de racha visible
                if (r.bonusRacha) ...[
                  const SizedBox(height: 6),
                  Text(
                    '¡Incluye +5 XP por racha de ${r.rachaNueva} días! 🔥',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer
                          .withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // XP total acumulado
          Text(
            'Total: ${r.xpTotal} XP · Nivel ${r.nivelNuevo}',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                  child: const Text('Volver'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                      ..pop()
                      ..pop(true);
                  },
                  child: const Text('Otro ejercicio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
