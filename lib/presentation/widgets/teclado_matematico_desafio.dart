import 'package:flutter/material.dart';

/// Versión compacta del teclado matemático para el modo desafío.
/// Usa callbacks en lugar de BLoC para ser reutilizable.
class TecladoMatematicoDesafio extends StatelessWidget {
  final void Function(String) onTecla;
  final VoidCallback onBorrar;
  final VoidCallback onConfirmar;

  const TecladoMatematicoDesafio({
    super.key,
    required this.onTecla,
    required this.onBorrar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        _fila(cs, [
          _K('x'), _K('y'), _K('²', label: 'x²'), _K('('), _K('⌫', esBorrar: true),
        ], onTecla, onBorrar, onConfirmar),
        const SizedBox(height: 5),
        _fila(cs, [
          _K('7'), _K('8'), _K('9'), _K('+'), _K('-'),
        ], onTecla, onBorrar, onConfirmar),
        const SizedBox(height: 5),
        _fila(cs, [
          _K('4'), _K('5'), _K('6'), _K('×'), _K('÷'),
        ], onTecla, onBorrar, onConfirmar),
        const SizedBox(height: 5),
        _fila(cs, [
          _K('1'), _K('2'), _K('3'), _K('0'), _K('↵', esAccion: true),
        ], onTecla, onBorrar, onConfirmar),
      ],
    );
  }

  Widget _fila(ColorScheme cs, List<_K> teclas,
      void Function(String) onT, VoidCallback onB, VoidCallback onC) {
    return Row(
      children: teclas.map((t) {
        Color bg;
        Color fg;
        if (t.esAccion) {
          bg = cs.primary; fg = cs.onPrimary;
        } else if (t.esBorrar) {
          bg = cs.surfaceVariant; fg = cs.onSurfaceVariant;
        } else if ('+-×÷()'.contains(t.valor)) {
          bg = cs.secondaryContainer; fg = cs.onSecondaryContainer;
        } else {
          bg = cs.surface; fg = cs.onSurface;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  if (t.esBorrar) onB();
                  else if (t.esAccion) onC();
                  else onT(t.valor);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: cs.outlineVariant, width: 0.5),
                  ),
                ),
                child: Text(t.label ?? t.valor,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: t.esAccion ? null : 'monospace',
                    )),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _K {
  final String valor;
  final String? label;
  final bool esBorrar;
  final bool esAccion;
  const _K(this.valor, {this.label, this.esBorrar = false, this.esAccion = false});
}
