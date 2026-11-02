// lib/features/finanzas/views/panel_financiero_screen.dart
//
// Pantalla principal del Panel Financiero, Costo Unitario y Utilidad (HU-07).
//
// Permite al dueño del taller:
//   1. Ver el costo unitario con merma prorrateada (Criterio 1).
//   2. Visualizar gráficas y desgloses por categoría (Criterio 2).
//   3. Analizar la utilidad estimada y el margen contra el precio de venta (Criterio 3).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../models/analisis_financiero_lote.dart';
import '../viewmodels/finanzas_viewmodel.dart';
import 'widgets/costo_unitario_card.dart';
import 'widgets/finanzas_ui_helpers.dart';
import 'widgets/grafica_desglose_categorias.dart';
import 'widgets/indicador_utilidad_card.dart';
import 'widgets/lote_financiero_card.dart';
import 'widgets/simulador_precio_dialog.dart';

class PanelFinancieroScreen extends StatefulWidget {
  const PanelFinancieroScreen({super.key});

  @override
  State<PanelFinancieroScreen> createState() => _PanelFinancieroScreenState();
}

class _PanelFinancieroScreenState extends State<PanelFinancieroScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<FinanzasViewModel>();
      if (vm.status == FinanzasStatus.initial) {
        vm.cargarDatos();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _abrirDetalleLote(AnalisisFinancieroLote lote) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Barra de arrastre
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Encabezado del modal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lote.loteCodigo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Análisis financiero y rentabilidad del lote',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Contenido deslizable del modal
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Criterio 1: Costo Unitario con Merma Prorrateada
                    CostoUnitarioCard(analisis: lote),
                    const SizedBox(height: 16),

                    // Criterio 3: Indicador de Utilidad y Margen
                    IndicadorUtilidadCard(
                      analisis: lote,
                      onEditarPrecio: () async {
                        Navigator.of(sheetContext).pop();
                        await SimuladorPrecioDialog.show(context, lote);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Criterio 2: Desglose por Categorías
                    GraficaDesgloseCategorias(
                      items: lote.desgloseCompleto,
                      costoTotal: lote.costoTotalProduccion,
                      titulo: 'Desglose de Costos de este Lote',
                      subtitulo: 'Partidas de insumos y mermas imputadas al lote',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanzasViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finanzas y Utilidad'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cobaltBlue,
          labelColor: AppColors.cobaltBlue,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Resumen Global', icon: Icon(Icons.dashboard_rounded, size: 20)),
            Tab(text: 'Lotes de Producción', icon: Icon(Icons.inventory_2_rounded, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar datos',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: vm.isLoading ? null : () => vm.cargarDatos(),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cobaltBlue),
            )
          : vm.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.terracotta),
                        const SizedBox(height: 12),
                        Text(
                          'No se pudieron cargar las finanzas',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.errorMessage ?? 'Error desconocido',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => vm.cargarDatos(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Pestaña 1: Resumen Global del Taller
                    _buildResumenGlobal(context, vm),

                    // Pestaña 2: Listado y desglose de Lotes
                    _buildListadoLotes(context, vm),
                  ],
                ),
    );
  }

  Widget _buildResumenGlobal(BuildContext context, FinanzasViewModel vm) {
    final resumen = vm.resumenGlobal;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de alerta si hay lotes en riesgo
          if (vm.cantidadLotesConMargenRiesgoso > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF6C00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF6C00).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF6C00), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vm.cantidadLotesConMargenRiesgoso} ${vm.cantidadLotesConMargenRiesgoso == 1 ? 'lote requiere' : 'lotes requieren'} revisión de precio',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'El margen de ganancia es muy ajustado o se encuentra en pérdida.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Matriz 2x2 de Métricas Maestras
          Row(
            children: [
              Expanded(
                child: _buildMetricaCard(
                  titulo: 'Inversión Total',
                  valor: FinanzasUIHelpers.formatMonedaCorta(resumen.inversionTotalProduccion),
                  subtitulo: 'MP: ${FinanzasUIHelpers.formatMonedaCorta(resumen.gastoMateriaPrimaGlobal)}',
                  icono: Icons.payments_rounded,
                  color: AppColors.cobaltBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricaCard(
                  titulo: 'Utilidad Proyectada',
                  valor: FinanzasUIHelpers.formatMonedaCorta(resumen.utilidadTotalProyectada),
                  subtitulo: 'Ganancia neta taller',
                  icono: Icons.trending_up_rounded,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricaCard(
                  titulo: 'Margen Promedio',
                  valor: FinanzasUIHelpers.formatPorcentaje(resumen.margenPromedioPorcentaje),
                  subtitulo: resumen.nivelRentabilidadGlobal.etiqueta,
                  icono: Icons.pie_chart_rounded,
                  color: FinanzasUIHelpers.colorDeRentabilidad(resumen.nivelRentabilidadGlobal),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricaCard(
                  titulo: 'Costo Unit. Promedio',
                  valor: FinanzasUIHelpers.formatMonedaCorta(resumen.costoUnitarioPromedio),
                  subtitulo: '${resumen.totalPiezasUtiles} piezas útiles',
                  icono: Icons.calculate_rounded,
                  color: AppColors.terracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Gráfica de Desglose por Categoría Global (HU-07 Criterio 2)
          GraficaDesgloseCategorias(
            items: resumen.desgloseCategoriasGlobal,
            costoTotal: resumen.inversionTotalProduccion,
            titulo: 'Desglose Consolidado del Taller',
            subtitulo: 'Distribución porcentual de los costos acumulados',
          ),
          const SizedBox(height: 24),

          // Resumen de piezas y mermas del taller
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: AppColors.terracotta,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eficiencia de Producción',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Text(
                              'Balance de piezas producidas vs mermadas',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDatoPiezas(
                        'Iniciales',
                        '${resumen.totalPiezasIniciales}',
                        Colors.black87,
                      ),
                      _buildDatoPiezas(
                        'Útiles',
                        '${resumen.totalPiezasUtiles}',
                        const Color(0xFF2E7D32),
                      ),
                      _buildDatoPiezas(
                        'Mermadas',
                        '${resumen.totalPiezasMermadas}',
                        AppColors.terracotta,
                      ),
                      _buildDatoPiezas(
                        'Tasa Merma',
                        FinanzasUIHelpers.formatPorcentaje(resumen.tasaMermaGlobalPorcentaje),
                        AppColors.terracotta,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildListadoLotes(BuildContext context, FinanzasViewModel vm) {
    final lotes = vm.lotesFiltrados;

    return Column(
      children: [
        // Selector de Filtros
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FiltroFinanzas.values.map((f) {
                final seleccionado = vm.filtro == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.etiqueta),
                    selected: seleccionado,
                    selectedColor: AppColors.cobaltBlue,
                    labelStyle: TextStyle(
                      color: seleccionado ? Colors.white : Colors.black87,
                      fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => vm.cambiarFiltro(f),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),

        // Lista de Lotes
        Expanded(
          child: lotes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay lotes en esta categoría.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: lotes.length,
                  itemBuilder: (context, index) {
                    final lote = lotes[index];
                    return LoteFinancieroCard(
                      analisis: lote,
                      onVerDetalle: () => _abrirDetalleLote(lote),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMetricaCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icono,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatoPiezas(String etiqueta, String valor, Color color) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
