// lib/features/mermas/views/mermas_screen.dart
//
// Pantalla principal de Registro de Mermas con Costo Estimado (HU-06).
//
// Permite al usuario del taller:
//   – Registrar piezas perdidas indicando etapa del daño y motivo (Criterio 1).
//   – Adjuntar obligatoriamente evidencia fotográfica del daño (Criterio 2).
//   – Conocer el costo estimado de la pérdida según insumos consumidos (Criterio 3).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../produccion/models/etapa_produccion.dart';
import '../../produccion/viewmodels/produccion_viewmodel.dart';
import '../models/motivo_merma.dart';
import '../viewmodels/mermas_viewmodel.dart';
import 'widgets/merma_card.dart';
import 'widgets/mermas_ui_helpers.dart';
import 'widgets/registrar_merma_sheet.dart';

class MermasScreen extends StatefulWidget {
  const MermasScreen({super.key});

  @override
  State<MermasScreen> createState() => _MermasScreenState();
}

class _MermasScreenState extends State<MermasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mermasVM = context.read<MermasViewModel>();
      if (mermasVM.status == MermasStatus.initial) {
        mermasVM.cargarMermas();
      }
      try {
        final prodVM = context.read<ProduccionViewModel>();
        if (prodVM.status == ProduccionStatus.initial) {
          prodVM.cargarLotes();
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final vm = context.watch<MermasViewModel>();
    final mermas = vm.mermasFiltradas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registro de Mermas'),
        actions: [
          IconButton(
            tooltip: 'Recargar mermas',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: vm.isLoading ? null : () => vm.cargarMermas(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => RegistrarMermaSheet.show(context),
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text(
          'Registrar Merma',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.cargarMermas(),
        color: AppColors.terracotta,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Resumen de Métricas de Mermas y Costo Estimado
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _MetricaMermaChip(
                      titulo: 'Piezas perdidas',
                      valor: '${vm.totalPiezasMermadas}',
                      color: AppColors.terracotta,
                      icono: Icons.broken_image_rounded,
                    ),
                    const SizedBox(width: 8),
                    _MetricaMermaChip(
                      titulo: 'Costo estimado',
                      valor: MermasUIHelpers.formatMonedaCorta(
                        vm.costoTotalMermasEstimado,
                      ),
                      color: const Color(0xFFC62828),
                      icono: Icons.attach_money_rounded,
                    ),
                    const SizedBox(width: 8),
                    _MetricaMermaChip(
                      titulo: 'Incidentes',
                      valor: '${vm.totalIncidentes}',
                      color: AppColors.cobaltBlue,
                      icono: Icons.photo_camera_rounded,
                    ),
                  ],
                ),
              ),
            ),

            // 2. Filtro por Etapa del Oficio (Criterio 1)
            SliverToBoxAdapter(
              child: Container(
                height: 46,
                margin: const EdgeInsets.only(top: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    FilterChip(
                      label: Text('Todas las etapas (${vm.totalIncidentes})'),
                      selected: vm.filtroEtapa == null,
                      onSelected: (_) => vm.setFiltroEtapa(null),
                      selectedColor: AppColors.cobaltBlue.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.cobaltBlue,
                      labelStyle: TextStyle(
                        fontWeight: vm.filtroEtapa == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: vm.filtroEtapa == null
                            ? AppColors.cobaltBlue
                            : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...EtapaProduccion.values.map((etapa) {
                      final conteo = vm.conteoPorEtapa(etapa);
                      final seleccionada = vm.filtroEtapa == etapa;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(
                            etapa.icono,
                            size: 15,
                            color: seleccionada ? etapa.color : Colors.black54,
                          ),
                          label: Text('${etapa.titulo} ($conteo)'),
                          selected: seleccionada,
                          onSelected: (_) => vm.setFiltroEtapa(etapa),
                          selectedColor: etapa.color.withValues(alpha: 0.15),
                          checkmarkColor: etapa.color,
                          labelStyle: TextStyle(
                            fontWeight:
                                seleccionada ? FontWeight.bold : FontWeight.normal,
                            color: seleccionada ? etapa.color : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // 3. Filtro por Motivo del Daño (Criterio 1)
            SliverToBoxAdapter(
              child: Container(
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    FilterChip(
                      label: const Text('Todos los motivos'),
                      selected: vm.filtroMotivo == null,
                      onSelected: (_) => vm.setFiltroMotivo(null),
                      selectedColor: AppColors.terracotta.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.terracotta,
                      labelStyle: TextStyle(
                        fontWeight: vm.filtroMotivo == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: vm.filtroMotivo == null
                            ? AppColors.terracotta
                            : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...MotivoMerma.values.map((motivo) {
                      final conteo = vm.conteoPorMotivo(motivo);
                      final seleccionado = vm.filtroMotivo == motivo;
                      final color = MermasUIHelpers.colorDeMotivo(motivo);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${motivo.etiqueta} ($conteo)'),
                          selected: seleccionado,
                          onSelected: (_) => vm.setFiltroMotivo(motivo),
                          selectedColor: color.withValues(alpha: 0.15),
                          checkmarkColor: color,
                          labelStyle: TextStyle(
                            fontWeight: seleccionado
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: seleccionado ? color : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // 4. Lista de Mermas Registradas
            if (vm.isLoading && vm.totalIncidentes == 0)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.terracotta),
                      SizedBox(height: 16),
                      Text('Cargando registro de mermas...'),
                    ],
                  ),
                ),
              )
            else if (mermas.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppColors.terracotta,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (vm.filtroEtapa != null || vm.filtroMotivo != null)
                              ? 'Sin mermas con el filtro seleccionado'
                              : 'No hay mermas registradas',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registra las piezas dañadas indicando la etapa, el motivo y su evidencia fotográfica para calcular el costo real.',
                          style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => RegistrarMermaSheet.show(context),
                          icon: const Icon(Icons.add_a_photo_rounded),
                          label: const Text('Registrar Merma'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => MermaCard(merma: mermas[index]),
                    childCount: mermas.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricaMermaChip extends StatelessWidget {
  const _MetricaMermaChip({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, size: 15, color: color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      valor,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

