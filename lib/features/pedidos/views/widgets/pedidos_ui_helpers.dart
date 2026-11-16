// lib/features/pedidos/views/widgets/pedidos_ui_helpers.dart
//
// Utilidades de presentación (colores, íconos y formato) para estados de pedidos (HU-09).

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/estado_pedido.dart';

class PedidosUIHelpers {
  PedidosUIHelpers._();

  static Color colorEstado(EstadoPedido estado) {
    return switch (estado) {
      EstadoPedido.enEsperaPago => const Color(0xFFE65100),
      EstadoPedido.pagado => AppColors.cobaltBlue,
      EstadoPedido.enPreparacion => AppColors.terracotta,
      EstadoPedido.enviado => const Color(0xFF00695C),
      EstadoPedido.entregado => const Color(0xFF2E7D32),
    };
  }

  static IconData iconoEstado(EstadoPedido estado) {
    return switch (estado) {
      EstadoPedido.enEsperaPago => Icons.schedule_rounded,
      EstadoPedido.pagado => Icons.payments_rounded,
      EstadoPedido.enPreparacion => Icons.inventory_2_rounded,
      EstadoPedido.enviado => Icons.local_shipping_rounded,
      EstadoPedido.entregado => Icons.verified_rounded,
    };
  }

  static String formatFecha(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year;
    final hh = fecha.hour.toString().padLeft(2, '0');
    final mm = fecha.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $hh:$mm';
  }

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
}

