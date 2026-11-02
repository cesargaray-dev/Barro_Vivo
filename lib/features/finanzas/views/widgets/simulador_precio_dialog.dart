// lib/features/finanzas/views/widgets/simulador_precio_dialog.dart
//
// Diálogo interactivo para simular y fijar precios de venta con base en datos reales (HU-07).
//
// Permite al dueño del taller ver en tiempo real cómo cambia su utilidad y margen
// al mover el precio, cumpliendo el Criterio 3 y accesibilidad mínima de 48 dp.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../models/analisis_financiero_lote.dart';
import '../../models/nivel_rentabilidad.dart';
import '../../viewmodels/finanzas_viewmodel.dart';
import 'finanzas_ui_helpers.dart';

class SimuladorPrecioDialog extends StatefulWidget {
  const SimuladorPrecioDialog({
    super.key,
    required this.analisis,
  });

  final AnalisisFinancieroLote analisis;

  static Future<bool?> show(BuildContext context, AnalisisFinancieroLote analisis) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SimuladorPrecioDialog(analisis: analisis),
    );
  }

  @override
  State<SimuladorPrecioDialog> createState() => _SimuladorPrecioDialogState();
}

class _SimuladorPrecioDialogState extends State<SimuladorPrecioDialog> {
  late final TextEditingController _precioController;
  late double _precioActual;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _precioActual = widget.analisis.precioVentaUnitario;
    _precioController = TextEditingController(
      text: _precioActual > 0 ? _precioActual.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  void _onPrecioCambiado(String valor) {
    final parseado = double.tryParse(valor.replaceAll('\$', '').trim()) ?? 0.0;
    setState(() {
      _precioActual = parseado;
    });
  }

  Future<void> _guardar() async {
    if (_precioActual <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un precio de venta mayor a \$0.'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    final vm = context.read<FinanzasViewModel>();
    final exito = await vm.actualizarPrecioVenta(
      loteId: widget.analisis.loteId,
      nuevoPrecio: _precioActual,
    );

    if (mounted) {
      setState(() => _guardando = false);
      if (exito) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Precio fijado en ${FinanzasUIHelpers.formatMoneda(_precioActual)} para ${widget.analisis.loteCodigo}',
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Error al guardar el precio.'),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final costoUnitario = widget.analisis.costoUnitario;
    final utilidad = _precioActual - costoUnitario;
    final margen = _precioActual > 0 ? (utilidad / _precioActual) * 100 : 0.0;
    final rentabilidad = NivelRentabilidad.evaluar(margen);
    final colorRentabilidad = FinanzasUIHelpers.colorDeRentabilidad(rentabilidad);
    final iconoRentabilidad = FinanzasUIHelpers.iconoDeRentabilidad(rentabilidad);

    final utilidadTotalLote = utilidad * widget.analisis.piezasUtiles;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cobaltBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.cobaltBlue, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fijar Precio de Venta',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.analisis.loteCodigo,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.cobaltBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Información del costo unitario innegociable
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COSTO UNITARIO REAL',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FinanzasUIHelpers.formatMoneda(costoUnitario),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${widget.analisis.piezasUtiles} piezas útiles',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Campo de entrada de Precio de Venta
              Text(
                'Precio de Venta Sugerido (\$ MXN)',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _precioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: _onPrecioCambiado,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.cobaltBlue),
                  hintText: '0.00',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cobaltBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Proyección en vivo de Utilidad y Margen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorRentabilidad.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorRentabilidad.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(iconoRentabilidad, size: 18, color: colorRentabilidad),
                            const SizedBox(width: 8),
                            Text(
                              rentabilidad.etiqueta,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorRentabilidad,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Margen: ${FinanzasUIHelpers.formatPorcentaje(margen)}',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorRentabilidad,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ganancia por pieza:', style: textTheme.bodySmall),
                        Text(
                          FinanzasUIHelpers.formatMoneda(utilidad),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorRentabilidad,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Utilidad total del lote:', style: textTheme.bodySmall),
                        Text(
                          FinanzasUIHelpers.formatMoneda(utilidadTotalLote),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorRentabilidad,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción accesibles (mínimo 48 dp)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cobaltBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Guardar Precio',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
