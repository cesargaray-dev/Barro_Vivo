// lib/views/taller/taller_home_screen.dart
//
// Pantalla principal del área de Taller (artesano / dueño).
// Acceso al módulo de inventario (HU-03/04) y producción de lotes (HU-05).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/inventario/viewmodels/inventario_viewmodel.dart';
import '../../features/produccion/viewmodels/produccion_viewmodel.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Pantalla principal del área de Taller.
///
/// Accesible solo para usuarios con rol [UserRole.taller].
class TallerHomeScreen extends StatefulWidget {
  const TallerHomeScreen({super.key});

  @override
  State<TallerHomeScreen> createState() => _TallerHomeScreenState();
}

class _TallerHomeScreenState extends State<TallerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final invVM = context.read<InventarioViewModel>();
      if (invVM.status == InventarioStatus.initial) {
        invVM.cargarInsumos();
      }

      final prodVM = context.read<ProduccionViewModel>();
      if (prodVM.status == ProduccionStatus.initial) {
        prodVM.cargarLotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final inventarioVM = context.watch<InventarioViewModel>();
    final produccionVM = context.watch<ProduccionViewModel>();
    final textTheme = Theme.of(context).textTheme;

    final totalInsumos = inventarioVM.totalInsumos;
    final insumosBajos = inventarioVM.insumosConStockBajo.length;

    final totalLotes = produccionVM.totalLotes;
    final lotesEnProceso = produccionVM.totalEnProceso;
    final lotesTerminados = produccionVM.totalTerminados;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Barro Vivo – Taller'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthViewModel>().signOut();
              if (context.mounted) context.go(AppRoutes.splash);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo y encabezado
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.cobaltBlue.withValues(alpha: 0.12),
                  child: const Icon(Icons.person_rounded, color: AppColors.cobaltBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${authVM.currentUser?.displayName ?? 'Maestro Artesano'}!',
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.cobaltBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        authVM.currentUser?.email ?? '',
                        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Panel de Gestión',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Tarjeta Destacada 1: Inventario de Materias Primas (HU-03 / HU-04)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: insumosBajos > 0
                      ? AppColors.terracotta.withValues(alpha: 0.5)
                      : AppColors.cobaltBlue.withValues(alpha: 0.2),
                  width: insumosBajos > 0 ? 1.5 : 1,
                ),
              ),
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push(AppRoutes.inventario),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cobaltBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: AppColors.cobaltBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Materias Primas',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cobaltBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gestión de stock, altas, ediciones y bajas de insumos.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.black54,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Métricas rápidas del inventario
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              inventarioVM.isLoading && totalInsumos == 0
                                  ? 'Cargando...'
                                  : '$totalInsumos ${totalInsumos == 1 ? 'insumo activo' : 'insumos activos'}',
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (insumosBajos > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.terracotta.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: AppColors.terracotta,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$insumosBajos por agotarse',
                                    style: textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.terracotta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta Destacada 2: Producción y Horno (Lotes) – HU-05
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppColors.terracotta.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push(AppRoutes.lotes),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.terracotta.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.terracotta,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Producción y Horno',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.terracotta,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.cobaltBlue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '5 ETAPAS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Control de lotes por las 5 etapas: barro crudo, jahuete, esmaltado, decorado y terminado.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.black54,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Métricas rápidas de producción
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.terracotta.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timelapse_rounded,
                                  size: 14,
                                  color: AppColors.terracotta,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  produccionVM.isLoading && totalLotes == 0
                                      ? 'Cargando...'
                                      : '$lotesEnProceso en proceso',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.terracotta,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$lotesTerminados terminados',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
