// lib/features/produccion/views/widgets/etapa_progress_indicator.dart
//
// Indicador visual de progreso para las 5 etapas estrictas del oficio – HU-05.
// barro crudo -> jahuete -> esmaltado -> decorado -> terminado.

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/etapa_produccion.dart';

/// Indicador visual horizontal de las 5 etapas del oficio artesanal.
class EtapaProgressIndicator extends StatelessWidget {
  const EtapaProgressIndicator({
    super.key,
    required this.etapaActual,
  });

  final EtapaProduccion etapaActual;

  @override
  Widget build(BuildContext context) {
    const etapas = EtapaProduccion.values;

    return Row(
      children: List.generate(etapas.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Línea conectora entre etapas
          final etapaAnteriorIndex = index ~/ 2;
          final completada = etapaAnteriorIndex < etapaActual.orden - 1;
          return Expanded(
            child: Container(
              height: 3,
              color: completada
                  ? AppColors.cobaltBlue
                  : Colors.grey.shade300,
            ),
          );
        }

        final etapaIndex = index ~/ 2;
        final etapa = etapas[etapaIndex];
        final esActual = etapa == etapaActual;
        final estaCompletada = etapa.orden < etapaActual.orden;

        Color dotColor;
        Color borderColor;
        Widget child;

        if (esActual) {
          dotColor = etapa.color;
          borderColor = etapa.color;
          child = Icon(
            etapa.icono,
            size: 14,
            color: Colors.white,
          );
        } else if (estaCompletada) {
          dotColor = AppColors.cobaltBlue;
          borderColor = AppColors.cobaltBlue;
          child = const Icon(
            Icons.check_rounded,
            size: 13,
            color: Colors.white,
          );
        } else {
          dotColor = Colors.white;
          borderColor = Colors.grey.shade300;
          child = Text(
            '${etapa.orden}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          );
        }

        return Tooltip(
          message: '${etapa.orden}. ${etapa.titulo}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: esActual ? 26 : 22,
                height: esActual ? 26 : 22,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: esActual ? 2.5 : 1.5,
                  ),
                  boxShadow: esActual
                      ? [
                          BoxShadow(
                            color: etapa.color.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: child,
              ),
              const SizedBox(height: 4),
              Text(
                _abreviatura(etapa),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: esActual ? FontWeight.w700 : FontWeight.w500,
                  color: esActual
                      ? etapa.color
                      : (estaCompletada ? Colors.black87 : Colors.grey.shade500),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _abreviatura(EtapaProduccion etapa) {
    return switch (etapa) {
      EtapaProduccion.barroCrudo => 'Crudo',
      EtapaProduccion.jahuete => 'Jahuete',
      EtapaProduccion.esmaltado => 'Esmalte',
      EtapaProduccion.decorado => 'Decorado',
      EtapaProduccion.terminado => 'Listo',
    };
  }
}
