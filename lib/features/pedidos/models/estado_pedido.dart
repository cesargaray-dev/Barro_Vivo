// lib/features/pedidos/models/estado_pedido.dart
//
// Enumeración de los 5 estados estrictos del ciclo de vida de un pedido (HU-09).
//
// Secuencia del timeline:
//   1. En espera de pago
//   2. Pagado
//   3. En preparación
//   4. Enviado
//   5. Entregado

/// Estados posibles de una orden de compra en Barro Vivo.
enum EstadoPedido {
  enEsperaPago(
    codigo: 'en_espera_pago',
    titulo: 'En espera de pago',
    descripcion:
        'Pedido confirmado con folio asignado. En espera de validación de pago.',
    orden: 1,
  ),
  pagado(
    codigo: 'pagado',
    titulo: 'Pagado',
    descripcion: 'Pago confirmado. El taller prepara tu orden.',
    orden: 2,
  ),
  enPreparacion(
    codigo: 'en_preparacion',
    titulo: 'En preparación',
    descripcion: 'Piezas en inspección de calidad y embalaje de protección.',
    orden: 3,
  ),
  enviado(
    codigo: 'enviado',
    titulo: 'Enviado',
    descripcion: 'Pedido en tránsito hacia el domicilio de entrega.',
    orden: 4,
  ),
  entregado(
    codigo: 'entregado',
    titulo: 'Entregado',
    descripcion: 'Pedido entregado satisfactoriamente al cliente.',
    orden: 5,
  );

  const EstadoPedido({
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.orden,
  });

  /// Código persistente para Supabase y JSON.
  final String codigo;

  /// Nombre visible en la línea de tiempo del cliente y bandeja del taller.
  final String titulo;

  /// Explicación breve del estado actual.
  final String descripcion;

  /// Posición ordinal en el flujo (1 a 5).
  final int orden;

  /// Estado inmediato siguiente en la línea de tiempo, o `null` si ya fue entregado.
  EstadoPedido? get siguiente {
    return switch (this) {
      EstadoPedido.enEsperaPago => EstadoPedido.pagado,
      EstadoPedido.pagado => EstadoPedido.enPreparacion,
      EstadoPedido.enPreparacion => EstadoPedido.enviado,
      EstadoPedido.enviado => EstadoPedido.entregado,
      EstadoPedido.entregado => null,
    };
  }

  /// Indica si el pedido completó todo su ciclo de entrega.
  bool get esFinal => this == EstadoPedido.entregado;

  /// Valida que la transición avance estrictamente al siguiente estado de la secuencia.
  bool puedeTransicionarA(EstadoPedido destino) => siguiente == destino;

  /// Resuelve el [EstadoPedido] a partir de su código textual.
  static EstadoPedido fromCodigo(String? codigo) {
    if (codigo == null) return EstadoPedido.enEsperaPago;
    final norm = codigo.trim().toLowerCase();
    return EstadoPedido.values.firstWhere(
      (e) => e.codigo == norm,
      orElse: () => EstadoPedido.enEsperaPago,
    );
  }
}

