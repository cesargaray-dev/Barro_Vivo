// lib/features/produccion/views/widgets/nuevo_lote_sheet.dart
//
// Formulario modal para registrar un nuevo lote de producción – HU-05.
//
// Cumple Criterio 1: "Se puede crear un lote de producción y asignarle una fecha."
// Cumple Criterio 2: Inicia automáticamente en la etapa estricta "Barro crudo".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../models/etapa_produccion.dart';
import '../../viewmodels/produccion_viewmodel.dart';
import 'etapa_badge.dart';

/// Modal inferior para la creación de un nuevo lote artesanal.
class NuevoLoteSheet extends StatefulWidget {
  const NuevoLoteSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NuevoLoteSheet(),
    );
  }

  @override
  State<NuevoLoteSheet> createState() => _NuevoLoteSheetState();
}

class _NuevoLoteSheetState extends State<NuevoLoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _notasController = TextEditingController();

  late DateTime _fechaCreacion;

  @override
  void initState() {
    super.initState();
    _fechaCreacion = DateTime.now();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _cantidadController.dispose();
    _descripcionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaCreacion,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha asignada al lote',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );

    if (seleccionada != null) {
      setState(() {
        _fechaCreacion = DateTime(
          seleccionada.year,
          seleccionada.month,
          seleccionada.day,
          _fechaCreacion.hour,
          _fechaCreacion.minute,
        );
      });
    }
  }

  Future<void> _guardarLote() async {
    if (!_formKey.currentState!.validate()) return;

    final codigo = _codigoController.text.trim();
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;
    final descripcion = _descripcionController.text.trim();
    final notas = _notasController.text.trim();

    final vm = context.read<ProduccionViewModel>();
    final exito = await vm.crearLote(
      codigo: codigo,
      cantidadPiezas: cantidad,
      fechaCreacion: _fechaCreacion,
      descripcion: descripcion.isNotEmpty ? descripcion : null,
      notasIniciales: notas.isNotEmpty ? notas : null,
    );

    if (mounted) {
      if (exito) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Lote "$codigo" creado en etapa Barro crudo!'),
            backgroundColor: AppColors.cobaltBlue,
          ),
        );
      } else if (vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final vm = context.watch<ProduccionViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrastre
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cobaltBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_box_rounded,
                      color: AppColors.cobaltBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Registrar Lote de Producción',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.cobaltBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Banner informativo de etapa inicial estricta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EtapaProduccion.barroCrudo.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: EtapaProduccion.barroCrudo.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const EtapaBadge(etapa: EtapaProduccion.barroCrudo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Todo nuevo lote inicia estrictamente en la etapa 1: Barro crudo.',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Código / Nombre del Lote
              TextFormField(
                controller: _codigoController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Código o nombre del lote *',
                  hintText: 'Ej: LOTE-2024-001 o Jarrones Talavera',
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.cobaltBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El código o nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fila: Cantidad de Piezas y Selector de Fecha
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cantidad de piezas
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Piezas *',
                        hintText: 'Ej: 25',
                        prefixIcon: const Icon(Icons.numbers_rounded, color: AppColors.cobaltBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final parsed = int.tryParse(valor.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Inválido (> 0)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Fecha Asignada (Criterio 1)
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: _seleccionarFecha,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha asignada *',
                          prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.cobaltBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _formatearFecha(_fechaCreacion),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Descripción o tipo de pieza
              TextFormField(
                controller: _descripcionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Tipo de piezas o descripción (opcional)',
                  hintText: 'Ej: Azulejos 10x10 cm, tibor floral, etc.',
                  prefixIcon: const Icon(Icons.description_outlined, color: Colors.black45),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),

              // Notas iniciales del artesano
              TextFormField(
                controller: _notasController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Observaciones iniciales (opcional)',
                  hintText: 'Ej: Barro negro mezclado, piezas torneadas a mano.',
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: Colors.black45),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 22),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: vm.isSaving ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: vm.isSaving ? null : _guardarLote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cobaltBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: vm.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Crear Lote',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  String _formatearFecha(DateTime f) {
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    final y = f.year;
    return '$d/$m/$y';
  }
}
