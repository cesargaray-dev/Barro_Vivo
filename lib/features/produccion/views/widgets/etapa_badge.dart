// lib/features/produccion/views/widgets/etapa_badge.dart
//
// Badge visual distintivo para cada una de las 5 etapas del oficio – HU-05.

import 'package:flutter/material.dart';

import '../../models/etapa_produccion.dart';

/// Badge visual compacto con ícono, color y etiqueta de la etapa de producción.
class EtapaBadge extends StatelessWidget {
  const EtapaBadge({
    super.key,
    required this.etapa,
    this.compact = false,
  });

  final EtapaProduccion etapa;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = etapa.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            etapa.icono,
            size: compact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            etapa.titulo,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
