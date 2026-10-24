import 'package:flutter/material.dart';
import '../../../domain/minijuegos/minijuego_model.dart';

class PantallaResultadoMiniJuego extends StatelessWidget {
  final MiniJuegoTipo tipo;
  final int aciertos;
  final int errores;
  final int xpObtenido;
  final Duration tiempoTotal;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const PantallaResultadoMiniJuego({
    super.key,
    required this.tipo,
    required this.aciertos,
    required this.errores,
    required this.xpObtenido,
    required this.tiempoTotal,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutos = tiempoTotal.inMinutes;
    final segundos = tiempoTotal.inSeconds % 60;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tipo.icono, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('¡${tipo.nombre} completado!',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _StatCard(
                      valor: '$aciertos', etiqueta: 'Aciertos',
                      color: Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                      valor: '$errores', etiqueta: 'Errores',
                      color: theme.colorScheme.error)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                      valor: '${minutos}m ${segundos}s',
                      etiqueta: 'Tiempo',
                      color: theme.colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text('+$xpObtenido XP',
                        style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: onReintentar,
                  child: const Text('Jugar de nuevo'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton(
                  onPressed: onSalir,
                  child: const Text('Volver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final Color color;
  const _StatCard({
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(valor, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(etiqueta, style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
