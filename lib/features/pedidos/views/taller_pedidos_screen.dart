// lib/features/pedidos/views/taller_pedidos_screen.dart
//
// Bandeja de pedidos del taller (/taller/pedidos) para seguimiento de folios
// emitidos y avance en la línea de tiempo de atención (HU-09).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../models/estado_pedido.dart';
import '../viewmodels/pedidos_viewmodel.dart';
import 'widgets/pedido_card.dart';

class TallerPedidosScreen extends StatefulWidget {
  const TallerPedidosScreen({super.key});

  @override
  State<TallerPedidosScreen> createState() => _TallerPedidosScreenState();
}

class _TallerPedidosScreenState extends State<TallerPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pedidosVM = context.read<PedidosViewModel>();
      if (pedidosVM.status == PedidosStatus.initial) {
        pedidosVM.cargarPedidos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedidosVM = context.watch<PedidosViewModel>();
    final pedidos = pedidosVM.pedidosFiltrados;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bandeja de Pedidos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar bandeja',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => pedidosVM.cargarPedidos(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => pedidosVM.cargarPedidos(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Resumen superior de la bandeja del taller
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.cobaltBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 16,
                runSpacing: 12,
                children: [
                  _MetricaBandeja(
                    etiqueta: 'Total órdenes',
                    valor: '${pedidosVM.totalPedidos}',
                    color: AppColors.cobaltBlue,
                  ),
                  _MetricaBandeja(
                    etiqueta: 'En espera de pago',
                    valor: '${pedidosVM.totalEnEsperaPago}',
                    color: const Color(0xFFE65100),
                  ),
                  _MetricaBandeja(
                    etiqueta: 'Entregados',
                    valor: '${pedidosVM.totalEntregados}',
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Chips de filtro
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: pedidosVM.filtroEstado == null,
                      onSelected: (_) => pedidosVM.seleccionarFiltroEstado(null),
                    ),
                  ),
                  ...EstadoPedido.values.map(
                    (estado) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(estado.titulo),
                        selected: pedidosVM.filtroEstado == estado,
                        onSelected: (selected) => pedidosVM.seleccionarFiltroEstado(
                          selected ? estado : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (pedidosVM.isLoading && pedidos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (pedidos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No hay pedidos en este estado.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ),
              )
            else
              ...pedidos.map(
                (pedido) => PedidoCard(
                  pedido: pedido,
                  esVistaTaller: true,
                  isProcessing: pedidosVM.isProcessing,
                  onAvanzarEstado: () async {
                    final siguiente = pedido.siguienteEstado;
                    final ok = await pedidosVM.avanzarEstadoPedido(pedido.id);
                    if (ok && context.mounted && siguiente != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pedido ${pedido.folio} actualizado a: ${siguiente.titulo}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricaBandeja extends StatelessWidget {
  const _MetricaBandeja({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          etiqueta,
          style: textTheme.labelSmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

