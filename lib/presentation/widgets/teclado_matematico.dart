import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/bloc/ejercicio_bloc.dart';

class TecladoMatematico extends StatelessWidget {
  const TecladoMatematico({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Fila de variables y superíndices
        _fila(context, colorScheme, [
          _Tecla('x'),
          _Tecla('y'),
          _Tecla('²', display: '□²', esExponente: true),
          _Tecla('³', display: '□³', esExponente: true),
          _Tecla('⁴', display: '□⁴', esExponente: true),
          _Tecla('⌫', esBorrar: true),
        ]),
        const SizedBox(height: 6),
        _fila(context, colorScheme, [
          _Tecla('7'), _Tecla('8'), _Tecla('9'),
          _Tecla('(', esOperador: true),
          _Tecla(')', esOperador: true),
        ]),
        const SizedBox(height: 6),
        _fila(context, colorScheme, [
          _Tecla('4'), _Tecla('5'), _Tecla('6'),
          _Tecla('+', esOperador: true),
          _Tecla('-', esOperador: true),
        ]),
        const SizedBox(height: 6),
        _fila(context, colorScheme, [
          _Tecla('1'), _Tecla('2'), _Tecla('3'),
          _Tecla('×', esOperador: true),
          _Tecla('÷', esOperador: true),
        ]),
        const SizedBox(height: 6),
        _fila(context, colorScheme, [
          _Tecla('◀', esMoverCursor: true, moverDelta: -1),
          _Tecla('0'),
          _Tecla(' ', display: '⎵', esEspacio: true),
          _Tecla('▶', esMoverCursor: true, moverDelta: 1),
          _Tecla('↵', esAccion: true),
        ]),
      ],
    );
  }

  Widget _fila(BuildContext ctx, ColorScheme cs, List<_Tecla> teclas) {
    return Row(
      children: teclas.map((t) {
        return Expanded(
          flex: t.ancho,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _BotonTecla(tecla: t),
          ),
        );
      }).toList(),
    );
  }
}

class _Tecla {
  final String valor;
  final String? display;
  final int ancho;
  final bool esOperador;
  final bool esBorrar;
  final bool esAccion;
  final bool esExponente;
  final bool esMoverCursor;
  final bool esEspacio;
  final int moverDelta; // -1 = izquierda, +1 = derecha

  const _Tecla(
    this.valor, {
    this.display,
    this.ancho = 1,
    this.esOperador = false,
    this.esBorrar = false,
    this.esAccion = false,
    this.esExponente = false,
    this.esMoverCursor = false,
    this.esEspacio = false,
    this.moverDelta = 0,
  });
}

class _BotonTecla extends StatelessWidget {
  final _Tecla tecla;
  const _BotonTecla({required this.tecla});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bgColor;
    Color fgColor;

    if (tecla.esAccion) {
      bgColor = colorScheme.primary;
      fgColor = colorScheme.onPrimary;
    } else if (tecla.esBorrar || tecla.esMoverCursor) {
      bgColor = colorScheme.surfaceVariant;
      fgColor = colorScheme.onSurfaceVariant;
    } else if (tecla.esExponente) {
      bgColor = colorScheme.tertiaryContainer;
      fgColor = colorScheme.onTertiaryContainer;
    } else if (tecla.esEspacio) {
      bgColor = colorScheme.secondaryContainer;
      fgColor = colorScheme.onSecondaryContainer;
    } else if (tecla.esOperador) {
      bgColor = colorScheme.secondaryContainer;
      fgColor = colorScheme.onSecondaryContainer;
    } else {
      bgColor = colorScheme.surface;
      fgColor = colorScheme.onSurface;
    }

    // Para teclas de exponente, mostrar con estilo superíndice visual
    Widget label;
    if (tecla.esExponente) {
      final exp = tecla.valor; // '²', '³', '⁴'
      label = RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '□',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: fgColor.withOpacity(0.5),
              ),
            ),
            TextSpan(
              text: exp,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: fgColor,
              ),
            ),
          ],
        ),
      );
    } else {
      label = Text(
        tecla.display ?? tecla.valor,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: tecla.esAccion ? null : 'monospace',
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: () => _onPresionar(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: label,
      ),
    );
  }

  void _onPresionar(BuildContext context) {
    final bloc = context.read<EjercicioBloc>();
    if (tecla.esBorrar) {
      bloc.add(BorrarCaracter());
    } else if (tecla.esMoverCursor) {
      final state = bloc.state;
      if (state is EjercicioEnProgreso) {
        final nuevaPos = state.cursorPos + tecla.moverDelta;
        bloc.add(MoverCursor(nuevaPos));
      }
    } else if (tecla.valor == '↵') {
      final state = bloc.state;
      if (state is EjercicioEnProgreso) {
        bloc.add(VerificarPaso(state.entradaActual));
      }
    } else {
      bloc.add(TeclaPresionada(tecla.valor));
    }
  }
}
