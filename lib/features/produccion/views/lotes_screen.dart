// lib/features/produccion/views/lotes_screen.dart
//
// Pantalla principal del módulo de Producción y Lotes – HU-05.
//
// Permite al artesano:
//   – Ver todos los lotes del taller y filtrarlos por las cinco etapas del oficio.
//   – Registrar un nuevo lote con fecha asignada (Criterio 1).
//   – Mover lotes por la secuencia estricta de 5 etapas (Criterio 2).
//   – Consultar el historial de fechas de cada lote (Criterio 3).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../models/etapa_produccion.dart';
import '../viewmodels/produccion_viewmodel.dart';
import 'widgets/lote_card.dart';
import 'widgets/nuevo_lote_sheet.dart';

/// Pantalla de gestión de lotes y etapas del oficio para el taller.
class LotesScreen extends StatefulWidget {
  const LotesScreen({super.key});

  @override
  State<LotesScreen> createState() => _LotesScreenState();
}

class _LotesScreenState extends State<LotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProduccionViewModel>();
      if (vm.status == ProduccionStatus.initial) {
        vm.cargarLotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final vm = context.watch<ProduccionViewModel>();
    final lotes = vm.lotesFiltrados;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Producción y Lotes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: vm.isLoading ? null : () => vm.cargarLotes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => NuevoLoteSheet.show(context),
        backgroundColor: AppColors.cobaltBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo Lote',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.cargarLotes(),
        color: AppColors.cobaltBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Resumen de Métricas de Producción
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _MetricaChip(
                      titulo: 'En proceso',
                      valor: '${vm.totalEnProceso}',
                      color: AppColors.terracotta,
                      icono: Icons.timelapse_rounded,
                    ),
                    const SizedBox(width: 10),
                    _MetricaChip(
                      titulo: 'Terminados',
                      valor: '${vm.totalTerminados}',
                      color: const Color(0xFF2E7D32),
                      icono: Icons.verified_rounded,
                    ),
                    const SizedBox(width: 10),
                    _MetricaChip(
                      titulo: 'Total lotes',
                      valor: '${vm.totalLotes}',
                      color: AppColors.cobaltBlue,
                      icono: Icons.inventory_2_outlined,
                    ),
                  ],
                ),
              ),
            ),

            // Filtro horizontal por las cinco etapas estrictas
            SliverToBoxAdapter(
              child: Container(
                height: 52,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    FilterChip(
                      label: Text('Todos (${vm.totalLotes})'),
                      selected: vm.filtroEtapa == null,
                      onSelected: (_) => vm.setFiltroEtapa(null),
                      selectedColor: AppColors.cobaltBlue.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.cobaltBlue,
                      labelStyle: TextStyle(
                        fontWeight: vm.filtroEtapa == null ? FontWeight.bold : FontWeight.normal,
                        color: vm.filtroEtapa == null ? AppColors.cobaltBlue : Colors.black87,
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
                            size: 16,
                            color: seleccionada ? etapa.color : Colors.black54,
                          ),
                          label: Text('${etapa.titulo} ($conteo)'),
                          selected: seleccionada,
                          onSelected: (_) => vm.setFiltroEtapa(etapa),
                          selectedColor: etapa.color.withValues(alpha: 0.15),
                          checkmarkColor: etapa.color,
                          labelStyle: TextStyle(
                            fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
                            color: seleccionada ? etapa.color : Colors.black87,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Contenido dinámico (carga, error, vacío o lista)
            if (vm.isLoading && vm.totalLotes == 0)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.cobaltBlue),
                      SizedBox(height: 16),
                      Text('Cargando lotes de producción...'),
                    ],
                  ),
                ),
              )
            else if (vm.hasError && vm.totalLotes == 0)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.terracotta,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No se pudieron cargar los lotes',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          vm.errorMessage ?? '',
                          style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => vm.cargarLotes(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (lotes.isEmpty)
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
                            color: AppColors.cobaltBlue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            size: 48,
                            color: AppColors.cobaltBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          vm.filtroEtapa != null
                              ? 'Sin lotes en etapa "${vm.filtroEtapa!.titulo}"'
                              : 'No hay lotes registrados aún',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.filtroEtapa != null
                              ? 'Prueba cambiando de etapa en los filtros superiores o registra un nuevo lote.'
                              : 'Registra tu primera producción artesanal para rastrearla por las 5 etapas del oficio.',
                          style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => NuevoLoteSheet.show(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Registrar Primer Lote'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cobaltBlue,
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
                    (context, index) => LoteCard(lote: lotes[index]),
                    childCount: lotes.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricaChip extends StatelessWidget {
  const _MetricaChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              child: Icon(icono, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
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
