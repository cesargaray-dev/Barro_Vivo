// lib/features/catalogo/views/widgets/catalogo_ui_helpers.dart
//
// Utilidades de presentación (formato de moneda, colores e íconos) para HU-08.

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class CatalogoUIHelpers {
  CatalogoUIHelpers._();

  /// Formatea un monto monetario en pesos mexicanos (ej. "$1,850.00").
  static String formatMoneda(double valor) {
    final abs = valor.abs();
    final partes = abs.toStringAsFixed(2).split('.');
    final entero = partes[0];
    final decimal = partes[1];

    final buffer = StringBuffer();
    for (int i = 0; i < entero.length; i++) {
      final posDesdeDerecha = entero.length - i;
      if (i > 0 && posDesdeDerecha % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(entero[i]);
    }
    final signo = valor < 0 ? '-' : '';
    return '$signo\$${buffer.toString()}.$decimal';
  }

  /// Devuelve el ícono representativo según la categoría de pieza artesanal.
  static IconData iconoCategoria(String categoria) {
    final norm = categoria.toLowerCase();
    if (norm.contains('vajilla')) return Icons.dinner_dining_rounded;
    if (norm.contains('taza')) return Icons.coffee_rounded;
    if (norm.contains('decora')) return Icons.spa_rounded;
    if (norm.contains('azulejo') || norm.contains('mural')) {
      return Icons.grid_view_rounded;
    }
    return Icons.local_mall_rounded;
  }

  /// Devuelve un color de acento armónico con la paleta de Barro Vivo.
  static Color colorCategoria(String categoria) {
    final norm = categoria.toLowerCase();
    if (norm.contains('vajilla')) return AppColors.cobaltBlue;
    if (norm.contains('decora')) return AppColors.terracotta;
    if (norm.contains('taza')) return const Color(0xFF00695C);
    if (norm.contains('azulejo') || norm.contains('mural')) {
      return const Color(0xFF455A64);
    }
    return AppColors.cobaltBlue;
  }
}

