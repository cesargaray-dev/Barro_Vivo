// lib/features/mermas/views/widgets/merma_card.dart
//
// Tarjeta visual de un registro de merma con etapa, motivo, evidencia fotográfica
// obligatoria y desglose del costo estimado según insumos consumidos (HU-06).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../produccion/views/widgets/etapa_badge.dart';
import '../../models/registro_merma.dart';
import '../../viewmodels/mermas_viewmodel.dart';
import 'mermas_ui_helpers.dart';

class MermaCard extends StatefulWidget {
  const MermaCard({
    super.key,
    required this.merma,
  });

  final RegistroMerma merma;

  @override
  State<MermaCard> createState() => _MermaCardState();
}

class _MermaCardState extends State<MermaCard> {
  bool _mostrarDesgloseInsumos = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final merma = widget.merma;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.terracotta.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Encabezado: Código de lote, Fecha y Menú de opciones
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merma.loteCodigo,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.cobaltBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Registrada el ${MermasUIHelpers.formatFecha(merma.fecha)}',
                        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge de Piezas Perdidas
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image_outlined,
                          size: 14,
                          color: AppColors.terracotta,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${merma.cantidadPiezas} ${merma.cantidadPiezas == 1 ? 'pza perdida' : 'pzas perdidas'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.terracotta,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.black45),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (opcion) {
                    if (opcion == 'eliminar') {
                      _confirmarBaja(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Dar de baja registro', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Criterio 1: Etapa en la que ocurrió el daño y Motivo (despostillado, rotura, etc.)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                EtapaBadge(etapa: merma.etapa),
                MotivoMermaBadge(motivo: merma.motivo),
              ],
            ),

            if (merma.observaciones != null && merma.observaciones!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                merma.observaciones!,
                style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
            ],
            const SizedBox(height: 14),

            // 3. Criterio 2: Evidencia Fotográfica Obligatoria Adjunta
            EvidenciaFotograficaPreview(
              evidenciaUrl: merma.evidenciaUrl,
              etapa: merma.etapa,
              motivo: merma.motivo,
              descripcion: merma.evidenciaDescripcion,
              onTap: () => EvidenciaFotograficaDialog.show(context, merma),
            ),
            const SizedBox(height: 14),

            // 4. Criterio 3: Costo Estimado de la Pérdida según Insumos Consumidos
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.terracotta.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'COSTO ESTIMADO DE LA MERMA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.terracotta,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${MermasUIHelpers.formatMonedaCorta(merma.costoUnitarioEstimado)}/pza × ${merma.cantidadPiezas} ${merma.cantidadPiezas == 1 ? 'pieza' : 'piezas'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            MermasUIHelpers.formatMoneda(merma.costoTotalEstimado),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Botón para desplegar/ocultar insumos consumidos
                  InkWell(
                    onTap: () {
                      setState(() {
                        _mostrarDesgloseInsumos = !_mostrarDesgloseInsumos;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            size: 16,
                            color: AppColors.cobaltBlue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Insumos consumidos (${merma.insumosConsumidos.length} partidas)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cobaltBlue,
                              ),
                            ),
                          ),
                          Icon(
                            _mostrarDesgloseInsumos
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 20,
                            color: AppColors.cobaltBlue,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_mostrarDesgloseInsumos) ...[
                    const SizedBox(height: 8),
                    ...merma.insumosConsumidos.map((insumo) {
                      final cantTotal = insumo.cantidadTotalConsumida(merma.cantidadPiezas);
                      final subtotal = insumo.subtotalParaPiezas(merma.cantidadPiezas);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• ${insumo.nombre} (${cantTotal.toStringAsFixed(2)} ${insumo.unidad})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              MermasUIHelpers.formatMonedaCorta(subtotal),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarBaja(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('¿Dar de baja este registro de merma?'),
        content: Text(
          'El registro de ${widget.merma.cantidadPiezas} piezas en "${widget.merma.loteCodigo}" dejará de contabilizarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dlgContext).pop();
              await context.read<MermasViewModel>().darDeBajaMerma(widget.merma.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
  }
}

