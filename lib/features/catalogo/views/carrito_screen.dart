// lib/features/catalogo/views/carrito_screen.dart
//
// Vista del carrito de compras del cliente con ajuste de cantidades y totales explícitos (HU-08).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../models/item_carrito.dart';
import '../viewmodels/catalogo_viewmodel.dart';
import 'widgets/catalogo_ui_helpers.dart';
import 'widgets/resumen_totales_carrito_card.dart';

/// Pantalla completa para el carrito de compras (/cliente/carrito).
class CarritoScreen extends StatelessWidget {
  const CarritoScreen({
    super.key,
    this.onConfirmarPedido,
  });

  /// Callback opcional al confirmar el pedido (conectado en HU-09).
  final Future<void> Function()? onConfirmarPedido;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Carrito'),
      ),
      body: CarritoContentView(onConfirmarPedido: onConfirmarPedido),
    );
  }
}

/// Contenido reutilizable del carrito de compras para pestañas o pantallas dedicadas.
class CarritoContentView extends StatelessWidget {
  const CarritoContentView({
    super.key,
    this.onConfirmarPedido,
    this.onIrACatalogo,
    this.isProcessingOrder = false,
  });

  final Future<void> Function()? onConfirmarPedido;
  final VoidCallback? onIrACatalogo;
  final bool isProcessingOrder;

  @override
  Widget build(BuildContext context) {
    final catalogoVM = context.watch<CatalogoViewModel>();
    final items = catalogoVM.itemsCarrito;
    final resumen = catalogoVM.resumenCarrito;
    final textTheme = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
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
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: AppColors.cobaltBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu carrito está vacío',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explora las piezas de talavera terminadas disponibles en el taller para armar tu pedido.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              if (onIrACatalogo != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onIrACatalogo,
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Explorar catálogo'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (catalogoVM.hasError) ...[
          MaterialBanner(
            backgroundColor: AppColors.terracotta.withValues(alpha: 0.1),
            content: Text(
              catalogoVM.errorMessage ?? '',
              style: const TextStyle(color: AppColors.terracotta),
            ),
            actions: [
              TextButton(
                onPressed: catalogoVM.limpiarError,
                child: const Text('Entendido'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Artículos seleccionados (${resumen.totalPiezas})',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () => catalogoVM.vaciarCarrito(),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Vaciar'),
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 48),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...items.map(
          (item) => _ItemCarritoCard(
            item: item,
            onIncrementar: () => catalogoVM.incrementarCantidad(item.pieza.id),
            onDecrementar: () => catalogoVM.decrementarCantidad(item.pieza.id),
            onEliminar: () => catalogoVM.eliminarDelCarrito(item.pieza.id),
          ),
        ),
        const SizedBox(height: 12),

        ResumenTotalesCarritoCard(
          resumen: resumen,
          isProcessing: isProcessingOrder,
          onProcederAlPago: () async {
            if (onConfirmarPedido != null) {
              await onConfirmarPedido!();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Total explícito listo para confirmar: ${CatalogoUIHelpers.formatMoneda(resumen.totalAPagar)} MXN',
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ItemCarritoCard extends StatelessWidget {
  const _ItemCarritoCard({
    required this.item,
    required this.onIncrementar,
    required this.onDecrementar,
    required this.onEliminar,
  });

  final ItemCarrito item;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.pieza.nombre,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CatalogoUIHelpers.formatMoneda(item.precioUnitario)} c/u · Disponible: ${item.stockDisponible}',
                        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar del carrito',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: onEliminar,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: onDecrementar,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Icon(Icons.remove_rounded, size: 18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '${item.cantidad}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: item.puedeIncrementar ? onIncrementar : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Icon(Icons.add_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal línea',
                      style: textTheme.labelSmall?.copyWith(color: Colors.black45),
                    ),
                    Text(
                      '${CatalogoUIHelpers.formatMoneda(item.subtotal)} MXN',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.cobaltBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

