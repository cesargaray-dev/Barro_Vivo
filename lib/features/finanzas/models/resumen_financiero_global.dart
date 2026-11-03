// lib/features/finanzas/models/resumen_financiero_global.dart
//
// Métricas consolidadas del taller para la toma de decisiones del dueño (HU-07).
//
// Regla arquitectónica: Modelo inmutable de dominio puro.

import 'analisis_financiero_lote.dart';
import 'categoria_costo.dart';
import 'item_desglose_costo.dart';
import 'nivel_rentabilidad.dart';

/// Resumen financiero global consolidado para el panel del dueño del taller.
class ResumenFinancieroGlobal {
  const ResumenFinancieroGlobal({
    required this.totalLotes,
    required this.totalPiezasIniciales,
    required this.totalPiezasUtiles,
    required this.totalPiezasMermadas,
    required this.gastoMateriaPrimaGlobal,
    required this.costoMermasGlobal,
    required this.ingresoTotalProyectado,
    required this.utilidadTotalProyectada,
    required this.desgloseCategoriasGlobal,
  });

  final int totalLotes;
  final int totalPiezasIniciales;
  final int totalPiezasUtiles;
  final int totalPiezasMermadas;
  final double gastoMateriaPrimaGlobal;
  final double costoMermasGlobal;
  final double ingresoTotalProyectado;
  final double utilidadTotalProyectada;
  final List<ItemDesgloseCosto> desgloseCategoriasGlobal;

  /// Inversión total monetaria requerida en la producción del taller.
  double get inversionTotalProduccion => gastoMateriaPrimaGlobal + costoMermasGlobal;

  /// Costo unitario ponderado por pieza útil producida en el taller.
  double get costoUnitarioPromedio {
    if (totalPiezasUtiles <= 0) return 0.0;
    return inversionTotalProduccion / totalPiezasUtiles;
  }

  /// Precio de venta promedio ponderado de las piezas útiles.
  double get precioVentaPromedio {
    if (totalPiezasUtiles <= 0) return 0.0;
    return ingresoTotalProyectado / totalPiezasUtiles;
  }

  /// Utilidad unitaria promedio ganada por pieza útil vendida.
  double get utilidadUnitariaPromedio => precioVentaPromedio - costoUnitarioPromedio;

  /// Margen porcentual promedio ponderado del taller (Criterio 3).
  double get margenPromedioPorcentaje {
    if (ingresoTotalProyectado <= 0.0) return 0.0;
    return (utilidadTotalProyectada / ingresoTotalProyectado) * 100.0;
  }

  /// Porcentaje de merma del taller sobre el total de piezas producidas.
  double get tasaMermaGlobalPorcentaje {
    if (totalPiezasIniciales <= 0) return 0.0;
    return (totalPiezasMermadas / totalPiezasIniciales) * 100.0;
  }

  /// Nivel de rentabilidad global del taller.
  NivelRentabilidad get nivelRentabilidadGlobal =>
      NivelRentabilidad.evaluar(margenPromedioPorcentaje);

  /// Construye el resumen consolidado a partir de una lista de análisis de lotes.
  factory ResumenFinancieroGlobal.desdeLotes(List<AnalisisFinancieroLote> lotes) {
    if (lotes.isEmpty) {
      return const ResumenFinancieroGlobal(
        totalLotes: 0,
        totalPiezasIniciales: 0,
        totalPiezasUtiles: 0,
        totalPiezasMermadas: 0,
        gastoMateriaPrimaGlobal: 0.0,
        costoMermasGlobal: 0.0,
        ingresoTotalProyectado: 0.0,
        utilidadTotalProyectada: 0.0,
        desgloseCategoriasGlobal: [],
      );
    }

    int piezasIniciales = 0;
    int piezasUtiles = 0;
    int piezasMermadas = 0;
    double gastoMP = 0.0;
    double costoMermas = 0.0;
    double ingresos = 0.0;
    double utilidad = 0.0;

    final montosPorCategoria = <CategoriaCosto, double>{
      for (final cat in CategoriaCosto.values) cat: 0.0,
    };

    for (final lote in lotes) {
      piezasIniciales += lote.cantidadPiezasIniciales;
      piezasUtiles += lote.piezasUtiles;
      piezasMermadas += lote.piezasMermadas;
      gastoMP += lote.gastoMateriaPrimaTotal;
      costoMermas += lote.costoMermasTotal;
      ingresos += lote.ingresoTotalEstimado;
      utilidad += lote.utilidadTotalEstimada;

      for (final item in lote.desgloseCompleto) {
        montosPorCategoria[item.categoria] =
            (montosPorCategoria[item.categoria] ?? 0.0) + item.monto;
      }
    }

    final totalInversion = gastoMP + costoMermas;
    final totalInversionSegura = totalInversion > 0 ? totalInversion : 1.0;

    final categoriasConsolidadas = montosPorCategoria.entries
        .where((e) => e.value > 0.0)
        .map((e) => ItemDesgloseCosto(
              categoria: e.key,
              monto: e.value,
              porcentaje: (e.value / totalInversionSegura) * 100.0,
            ))
        .toList();

    return ResumenFinancieroGlobal(
      totalLotes: lotes.length,
      totalPiezasIniciales: piezasIniciales,
      totalPiezasUtiles: piezasUtiles,
      totalPiezasMermadas: piezasMermadas,
      gastoMateriaPrimaGlobal: gastoMP,
      costoMermasGlobal: costoMermas,
      ingresoTotalProyectado: ingresos,
      utilidadTotalProyectada: utilidad,
      desgloseCategoriasGlobal: categoriasConsolidadas,
    );
  }
}

