// lib/views/cliente/cliente_home_screen.dart
//
// Pantalla principal del área de Cliente (comprador) – HU-08.
// Catálogo de piezas terminadas con existencia y acceso directo al carrito.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/catalogo/viewmodels/catalogo_viewmodel.dart';
import '../../features/catalogo/views/widgets/catalogo_ui_helpers.dart';
import '../../features/catalogo/views/widgets/pieza_catalogo_card.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Pantalla principal del área de Cliente.
///
/// Accesible solo para usuarios con rol [UserRole.cliente].
class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalogoVM = context.read<CatalogoViewModel>();
      if (catalogoVM.status == CatalogoStatus.initial) {
        catalogoVM.cargarCatalogo();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final catalogoVM = context.watch<CatalogoViewModel>();
    final textTheme = Theme.of(context).textTheme;

    final piezas = catalogoVM.piezasFiltradas;
    final categorias = catalogoVM.categoriasDisponibles;
    final totalEnCarrito = catalogoVM.cantidadTotalEnCarrito;
    final resumen = catalogoVM.resumenCarrito;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Barro Vivo – Tienda'),
        actions: [
          IconButton(
            tooltip: 'Mis pedidos',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => context.push(AppRoutes.misPedidos),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
          IconButton(
            tooltip: 'Mi Carrito',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => context.push(AppRoutes.carrito),
            icon: Badge(
              isLabelVisible: totalEnCarrito > 0,
              backgroundColor: AppColors.terracotta,
              label: Text(
                '$totalEnCarrito',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthViewModel>().signOut();
              if (context.mounted) context.go(AppRoutes.splash);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => catalogoVM.cargarCatalogo(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Bienvenida al cliente
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.terracotta.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.terracotta,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${authVM.currentUser?.displayName ?? 'Cliente'}',
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.cobaltBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Talavera artesanal de Dolores Hidalgo lista para envío.',
                        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.misPedidos),
                    icon: const Icon(Icons.timeline_rounded, size: 18),
                    label: const Text('Mis pedidos'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Banner de regla de negocio crítica (solo piezas terminadas con existencia)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Catálogo verificado: solo se muestran piezas en etapa Terminado con existencia inmediata (${catalogoVM.piezasPublicadas.length} disponibles).',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Buscador
            TextField(
              controller: _searchController,
              onChanged: catalogoVM.actualizarBusqueda,
              decoration: InputDecoration(
                hintText: 'Buscar vajillas, tibores, tazas o lote...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: catalogoVM.busqueda.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();
                          catalogoVM.actualizarBusqueda('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Filtros por categoría (mínimo 48dp de área táctil)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todas'),
                      selected: catalogoVM.categoriaSeleccionada == null,
                      onSelected: (_) => catalogoVM.seleccionarCategoria(null),
                    ),
                  ),
                  ...categorias.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: catalogoVM.categoriaSeleccionada == cat,
                        onSelected: (selected) => catalogoVM.seleccionarCategoria(
                          selected ? cat : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

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
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (catalogoVM.isLoading && piezas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (piezas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.black38,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay piezas terminadas con existencia para este filtro.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ...piezas.map(
                (pieza) => PiezaCatalogoCard(
                  pieza: pieza,
                  cantidadEnCarrito: catalogoVM.cantidadEnCarrito(pieza.id),
                  onAgregar: () {
                    final ok = catalogoVM.agregarAlCarrito(pieza);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text('${pieza.nombre} agregado al carrito'),
                        ),
                      );
                    }
                  },
                  onIncrementar: () => catalogoVM.incrementarCantidad(pieza.id),
                  onDecrementar: () => catalogoVM.decrementarCantidad(pieza.id),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: totalEnCarrito > 0
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalEnCarrito ${totalEnCarrito == 1 ? 'pieza' : 'piezas'} en carrito',
                            style: textTheme.labelMedium?.copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Total: ${CatalogoUIHelpers.formatMoneda(resumen.totalAPagar)} MXN',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.cobaltBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.carrito),
                        icon: const Icon(Icons.shopping_cart_checkout_rounded),
                        label: const Text('Ver Carrito'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
