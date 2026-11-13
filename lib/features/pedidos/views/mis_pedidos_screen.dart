// lib/features/pedidos/views/mis_pedidos_screen.dart
//
// Bandeja "Mis pedidos" del cliente con filtros y línea de tiempo por orden (HU-09).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../models/estado_pedido.dart';
import '../viewmodels/pedidos_viewmodel.dart';
import 'widgets/pedido_card.dart';

/// Pantalla dedicada de la bandeja "Mis pedidos" (/cliente/pedidos).
class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pedidosVM = context.read<PedidosViewModel>();
      final email = context.read<AuthViewModel>().currentUser?.email;
      if (pedidosVM.status == PedidosStatus.initial) {
        pedidosVM.cargarPedidos(clienteEmail: email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedidosVM = context.watch<PedidosViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final pedidos = pedidosVM.pedidosFiltrados;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar pedidos',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => pedidosVM.cargarPedidos(
              clienteEmail: authVM.currentUser?.email,
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => pedidosVM.cargarPedidos(
          clienteEmail: authVM.currentUser?.email,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filtros por estado en línea de tiempo (48 dp)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Todos (${pedidosVM.totalPedidos})'),
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
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.black38,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes pedidos registrados en este estado.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ...pedidos.map((pedido) => PedidoCard(pedido: pedido)),
          ],
        ),
      ),
    );
  }
}

