// lib/features/finanzas/views/widgets/finanzas_ui_helpers.dart
//
// Constantes visuales y formateadores para el módulo financiero (HU-07).
// Cumple con la identidad visual artesanal de Barro Vivo y accesibilidad WCAG.

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/categoria_costo.dart';
import '../../models/nivel_rentabilidad.dart';

class FinanzasUIHelpers {
  FinanzasUIHelpers._();

  /// Formatea un valor numérico a moneda mexicana: "$180.00 MXN".
  static String formatMoneda(double monto) {
    final negativo = monto < 0;
    final valorAbsoluto = monto.abs().toStringAsFixed(2);
    final partes = valorAbsoluto.split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final formatted = '\$$entero.${partes[1]} MXN';
    return negativo ? '-$formatted' : formatted;
  }

  /// Formatea un valor numérico a moneda corta: "$180.00".
  static String formatMonedaCorta(double monto) {
    final negativo = monto < 0;
    final valorAbsoluto = monto.abs().toStringAsFixed(2);
    final partes = valorAbsoluto.split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final formatted = '\$$entero.${partes[1]}';
    return negativo ? '-$formatted' : formatted;
  }

  /// Formatea un porcentaje: "58.3%".
  static String formatPorcentaje(double porcentaje) {
    return '${porcentaje.toStringAsFixed(1)}%';
  }

  /// Obtiene el color temático para cada categoría de costo.
  static Color colorDeCategoria(CategoriaCosto categoria) {
    return switch (categoria) {
      CategoriaCosto.barroPastas => AppColors.terracotta,
      CategoriaCosto.esmaltesVidriado => const Color(0xFF0288D1),
      CategoriaCosto.pigmentosDecorado => AppColors.cobaltBlue,
      CategoriaCosto.horneadoEnergia => const Color(0xFFE65100),
      CategoriaCosto.mermaProrrateada => const Color(0xFFB71C1C),
      CategoriaCosto.otrosInsumos => const Color(0xFF546E7A),
    };
  }

  /// Obtiene el ícono representativo de cada categoría de costo.
  static IconData iconoDeCategoria(CategoriaCosto categoria) {
    return switch (categoria) {
      CategoriaCosto.barroPastas => Icons.terrain_rounded,
      CategoriaCosto.esmaltesVidriado => Icons.format_paint_rounded,
      CategoriaCosto.pigmentosDecorado => Icons.brush_rounded,
      CategoriaCosto.horneadoEnergia => Icons.local_fire_department_rounded,
      CategoriaCosto.mermaProrrateada => Icons.broken_image_rounded,
      CategoriaCosto.otrosInsumos => Icons.category_rounded,
    };
  }

  /// Color semántico según el nivel de rentabilidad de la producción.
  static Color colorDeRentabilidad(NivelRentabilidad nivel) {
    return switch (nivel) {
      NivelRentabilidad.excelente => const Color(0xFF2E7D32),
      NivelRentabilidad.saludable => AppColors.cobaltBlue,
      NivelRentabilidad.ajustado => const Color(0xFFEF6C00),
      NivelRentabilidad.perdida => const Color(0xFFC62828),
    };
  }

  /// Ícono representativo del estado de rentabilidad.
  static IconData iconoDeRentabilidad(NivelRentabilidad nivel) {
    return switch (nivel) {
      NivelRentabilidad.excelente => Icons.trending_up_rounded,
      NivelRentabilidad.saludable => Icons.check_circle_outline_rounded,
      NivelRentabilidad.ajustado => Icons.warning_amber_rounded,
      NivelRentabilidad.perdida => Icons.error_outline_rounded,
    };
  }
}

