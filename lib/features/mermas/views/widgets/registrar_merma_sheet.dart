// lib/features/mermas/views/widgets/registrar_merma_sheet.dart
//
// Formulario modal para registrar una merma de lote con evidencia fotográfica
// obligatoria (cámara/galería real con image_picker) y cálculo automático del
// costo estimado según insumos consumidos (HU-06).
//
// Cumple con:
//   - Criterio 1: Piezas perdidas indicando etapa en la que ocurrió el daño y motivo.
//   - Criterio 2: Obligatorio adjuntar evidencia fotográfica del daño (cámara o galería).
//   - Criterio 3: Calcula el costo estimado de la pérdida según los insumos consumidos.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../finanzas/viewmodels/finanzas_viewmodel.dart';
import '../../../inventario/viewmodels/inventario_viewmodel.dart';
import '../../../produccion/models/etapa_produccion.dart';
import '../../../produccion/models/lote_produccion.dart';
import '../../../produccion/viewmodels/produccion_viewmodel.dart';
import '../../models/insumo_consumido_merma.dart';
import '../../models/motivo_merma.dart';
import '../../models/registro_merma.dart';
import '../../viewmodels/mermas_viewmodel.dart';
import 'mermas_ui_helpers.dart';

class _OpcionLoteSelector {
  const _OpcionLoteSelector({
    required this.id,
    required this.codigo,
    required this.etapaActual,
    required this.cantidadPiezas,
  });

  final String id;
  final String codigo;
  final EtapaProduccion etapaActual;
  final int cantidadPiezas;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OpcionLoteSelector &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class RegistrarMermaSheet extends StatefulWidget {
  const RegistrarMermaSheet({
    super.key,
    this.lotePreseleccionado,
    this.imagePickerOverride,
  });

  final LoteProduccion? lotePreseleccionado;

  /// Callback opcional para inyectar selección de imagen en pruebas de widgets.
  final Future<String?> Function(ImageSource source)? imagePickerOverride;

  static Future<bool?> show(
    BuildContext context, {
    LoteProduccion? lotePreseleccionado,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegistrarMermaSheet(
        lotePreseleccionado: lotePreseleccionado,
      ),
    );
  }

  @override
  State<RegistrarMermaSheet> createState() => _RegistrarMermaSheetState();
}

class _RegistrarMermaSheetState extends State<RegistrarMermaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController(text: '1');
  final _observacionesController = TextEditingController();
  final _evidenciaDescController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late List<_OpcionLoteSelector> _opcionesLotes;
  late _OpcionLoteSelector _loteSeleccionado;
  late EtapaProduccion _etapaSeleccionada;
  MotivoMerma _motivoSeleccionado = MotivoMerma.despostillado;
  late DateTime _fechaMerma;

  // Criterio 2: Evidencia fotográfica obligatoria
  String _evidenciaUrl = '';
  bool _mostrarErrorEvidencia = false;
  bool _capturandoImagen = false;

  // Criterio 3: Insumos consumidos para el cálculo automático del costo estimado
  late List<InsumoConsumidoMerma> _insumosConsumidos;

  @override
  void initState() {
    super.initState();
    _fechaMerma = DateTime.now();
    _opcionesLotes = _construirOpcionesLotes();
    _loteSeleccionado = _opcionesLotes.first;
    _etapaSeleccionada = widget.lotePreseleccionado?.etapaActual ??
        _loteSeleccionado.etapaActual;
    _insumosConsumidos =
        InsumoConsumidoMerma.plantillaPorEtapa(_etapaSeleccionada);

    _cantidadController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final prodVM = context.read<ProduccionViewModel>();
        if (prodVM.lotes.isEmpty) {
          await prodVM.cargarLotes();
        }
        if (mounted && prodVM.lotes.isNotEmpty) {
          setState(() {
            _opcionesLotes = _construirOpcionesLotes();
            final existenteIdx = _opcionesLotes
                .indexWhere((o) => o.id == _loteSeleccionado.id);
            if (existenteIdx != -1) {
              _loteSeleccionado = _opcionesLotes[existenteIdx];
            } else {
              _loteSeleccionado = _opcionesLotes.first;
              _etapaSeleccionada = widget.lotePreseleccionado?.etapaActual ??
                  _loteSeleccionado.etapaActual;
              _insumosConsumidos =
                  InsumoConsumidoMerma.plantillaPorEtapa(_etapaSeleccionada);
            }
          });
        }
      } catch (_) {}
    });
  }

  List<_OpcionLoteSelector> _construirOpcionesLotes() {
    final resultado = <_OpcionLoteSelector>[];

    if (widget.lotePreseleccionado != null) {
      final lp = widget.lotePreseleccionado!;
      resultado.add(
        _OpcionLoteSelector(
          id: lp.id,
          codigo: lp.codigo,
          etapaActual: lp.etapaActual,
          cantidadPiezas: lp.cantidadPiezas,
        ),
      );
    }

    try {
      final prodVM = context.read<ProduccionViewModel>();
      for (final l in prodVM.lotes) {
        if (!resultado.any((r) => r.id == l.id)) {
          resultado.add(
            _OpcionLoteSelector(
              id: l.id,
              codigo: l.codigo,
              etapaActual: l.etapaActual,
              cantidadPiezas: l.cantidadPiezas,
            ),
          );
        }
      }
    } catch (_) {
      // Ignorar si ProduccionViewModel no está en el árbol de prueba
    }

    if (resultado.isEmpty) {
      resultado.addAll(const [
        _OpcionLoteSelector(
          id: 'lote_seed_001',
          codigo: 'LOTE-2024-001 (Vajilla Clásica)',
          etapaActual: EtapaProduccion.terminado,
          cantidadPiezas: 60,
        ),
        _OpcionLoteSelector(
          id: 'lote_seed_002',
          codigo: 'LOTE-2024-002 (Juego de Tazas)',
          etapaActual: EtapaProduccion.decorado,
          cantidadPiezas: 40,
        ),
        _OpcionLoteSelector(
          id: 'lote_seed_003',
          codigo: 'LOTE-2024-003 (Florero Cervantino)',
          etapaActual: EtapaProduccion.jahuete,
          cantidadPiezas: 15,
        ),
        _OpcionLoteSelector(
          id: 'lote_seed_004',
          codigo: 'LOTE-2024-004 (Azulejos Mayólica)',
          etapaActual: EtapaProduccion.esmaltado,
          cantidadPiezas: 100,
        ),
      ]);
    }

    return resultado;
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionesController.dispose();
    _evidenciaDescController.dispose();
    super.dispose();
  }

  int get _cantidadPiezasActual {
    final parsed = int.tryParse(_cantidadController.text.trim()) ?? 0;
    return parsed > 0 ? parsed : 0;
  }

  double get _costoUnitarioEstimado =>
      RegistroMerma.calcularCostoUnitario(_insumosConsumidos);

  double get _costoTotalEstimado => RegistroMerma.calcularCostoTotal(
        cantidadPiezas: _cantidadPiezasActual,
        insumos: _insumosConsumidos,
      );

  void _cambiarEtapa(EtapaProduccion nuevaEtapa) {
    setState(() {
      _etapaSeleccionada = nuevaEtapa;
      _insumosConsumidos = InsumoConsumidoMerma.plantillaPorEtapa(nuevaEtapa);
    });
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaMerma,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha del incidente de merma',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );

    if (seleccionada != null && mounted) {
      setState(() {
        _fechaMerma = DateTime(
          seleccionada.year,
          seleccionada.month,
          seleccionada.day,
          _fechaMerma.hour,
          _fechaMerma.minute,
        );
      });
    }
  }

  /// Abre la cámara real del dispositivo o la galería de fotos mediante [ImagePicker].
  Future<void> _seleccionarEvidencia(ImageSource source) async {
    if (_capturandoImagen) return;

    setState(() {
      _capturandoImagen = true;
    });

    try {
      String? rutaSeleccionada;

      if (widget.imagePickerOverride != null) {
        rutaSeleccionada = await widget.imagePickerOverride!(source);
      } else {
        final XFile? archivo = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1600,
          maxHeight: 1600,
        );
        rutaSeleccionada = archivo?.path;
      }

      if (!mounted) return;

      if (rutaSeleccionada != null && rutaSeleccionada.trim().isNotEmpty) {
        setState(() {
          _evidenciaUrl = rutaSeleccionada!.trim();
          _mostrarErrorEvidencia = false;
          if (_evidenciaDescController.text.trim().isEmpty) {
            final origenStr =
                source == ImageSource.camera ? 'cámara' : 'galería';
            _evidenciaDescController.text =
                'Fotografía desde $origenStr: ${_motivoSeleccionado.etiqueta} en ${_etapaSeleccionada.titulo}.';
          }
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo acceder a la ${source == ImageSource.camera ? 'cámara' : 'galería'}: ${e.message ?? 'Verifica los permisos de la aplicación.'}',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } on MissingPluginException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El módulo nativo de ${source == ImageSource.camera ? 'cámara' : 'galería'} requiere reiniciar la app (detén y vuelve a ejecutar flutter run).',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('[RegistrarMermaSheet] Error al obtener fotografía: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo obtener la fotografía. Intenta de nuevo.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturandoImagen = false;
        });
      }
    }
  }

  Future<void> _agregarInsumoPersonalizado() async {
    List<String> sugerenciasInventario = [];
    try {
      final invVM = context.read<InventarioViewModel>();
      sugerenciasInventario = invVM.insumos.map((i) => i.nombre).toList();
    } catch (_) {}

    final nombreCtrl = TextEditingController(
      text: sugerenciasInventario.isNotEmpty ? sugerenciasInventario.first : '',
    );
    final cantidadCtrl = TextEditingController(text: '0.50');
    final costoCtrl = TextEditingController(text: '25.00');
    String unidad = 'kg';

    final nuevoInsumo = await showDialog<InsumoConsumidoMerma>(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Agregar Insumo Consumido',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del insumo *',
                    hintText: 'Ej: Óxido de cobalto, Barro blanco',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cantidadCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Cant. por pieza *',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: unidad,
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'lt', child: Text('lt')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => unidad = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Costo por unidad (\$ MXN) *',
                    prefixText: '\$ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = nombreCtrl.text.trim();
                final cant = double.tryParse(cantidadCtrl.text.trim()) ?? 0.0;
                final costo = double.tryParse(costoCtrl.text.trim()) ?? 0.0;
                if (nombre.isNotEmpty && cant > 0 && costo > 0) {
                  Navigator.of(dlgContext).pop(
                    InsumoConsumidoMerma(
                      insumoId: 'ins_${DateTime.now().millisecondsSinceEpoch}',
                      nombre: nombre,
                      unidad: unidad,
                      cantidadPorPieza: cant,
                      costoPorUnidad: costo,
                      etapaAsociada: _etapaSeleccionada,
                    ),
                  );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );

    if (nuevoInsumo != null && mounted) {
      setState(() {
        _insumosConsumidos = [..._insumosConsumidos, nuevoInsumo];
      });
    }
  }

  Future<void> _guardarMerma() async {
    final formValido = _formKey.currentState?.validate() ?? false;

    // Validar obligatoriamente la evidencia fotográfica (Criterio 2)
    if (_evidenciaUrl.trim().isEmpty) {
      setState(() {
        _mostrarErrorEvidencia = true;
      });
    }

    if (!formValido || _evidenciaUrl.trim().isEmpty) {
      return;
    }

    final mermasVM = context.read<MermasViewModel>();
    final exito = await mermasVM.registrarMerma(
      loteId: _loteSeleccionado.id,
      loteCodigo: _loteSeleccionado.codigo,
      etapa: _etapaSeleccionada,
      motivo: _motivoSeleccionado,
      cantidadPiezas: _cantidadPiezasActual,
      evidenciaUrl: _evidenciaUrl.trim(),
      evidenciaDescripcion: _evidenciaDescController.text.trim().isNotEmpty
          ? _evidenciaDescController.text.trim()
          : null,
      insumosConsumidos: _insumosConsumidos,
      fecha: _fechaMerma,
      observaciones: _observacionesController.text.trim().isNotEmpty
          ? _observacionesController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (exito) {
      // Sincronizar con FinanzasViewModel si el lote existe en finanzas (HU-06 + HU-07)
      try {
        final finanzasVM = context.read<FinanzasViewModel>();
        final loteFin = finanzasVM.todosLosLotes.where(
          (l) =>
              l.loteId == _loteSeleccionado.id ||
              l.loteCodigo == _loteSeleccionado.codigo,
        );
        if (loteFin.isNotEmpty) {
          final actual = loteFin.first;
          await finanzasVM.guardarAnalisis(
            actual.copyWith(
              piezasMermadas: actual.piezasMermadas + _cantidadPiezasActual,
              costoMermasTotal: actual.costoMermasTotal + _costoTotalEstimado,
              updatedAt: DateTime.now(),
            ),
          );
        }
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Merma registrada (${MermasUIHelpers.formatMoneda(_costoTotalEstimado)}) con evidencia fotográfica!',
          ),
          backgroundColor: AppColors.terracotta,
        ),
      );
    } else if (mermasVM.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mermasVM.errorMessage!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mermasVM = context.watch<MermasViewModel>();

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
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
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.terracotta,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar Merma de Producción',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.terracotta,
                          ),
                        ),
                        const Text(
                          'Documenta daños, evidencia fotográfica y costo por insumos',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. Selección del Lote de Producción
              DropdownButtonFormField<_OpcionLoteSelector>(
                key: ValueKey('${_loteSeleccionado.id}_${_opcionesLotes.length}'),
                initialValue: _opcionesLotes.contains(_loteSeleccionado)
                    ? _loteSeleccionado
                    : _opcionesLotes.first,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Lote afectado *',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.cobaltBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: _opcionesLotes
                    .map(
                      (op) => DropdownMenuItem<_OpcionLoteSelector>(
                        value: op,
                        child: Text(
                          '${op.codigo} (${op.cantidadPiezas} pzas)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.lotePreseleccionado != null
                    ? null
                    : (nuevo) {
                        if (nuevo != null) {
                          setState(() {
                            _loteSeleccionado = nuevo;
                            _cambiarEtapa(nuevo.etapaActual);
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),

              // 2. Criterio 1: Etapa en la que ocurrió el daño
              const Text(
                'Etapa en la que ocurrió el daño *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: EtapaProduccion.values.map((etapa) {
                    final seleccionada = _etapaSeleccionada == etapa;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          etapa.icono,
                          size: 16,
                          color: seleccionada ? Colors.white : etapa.color,
                        ),
                        label: Text('${etapa.orden}. ${etapa.titulo}'),
                        selected: seleccionada,
                        selectedColor: etapa.color,
                        labelStyle: TextStyle(
                          color: seleccionada ? Colors.white : Colors.black87,
                          fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => _cambiarEtapa(etapa),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Criterio 1: Motivo del daño (despostillado, rotura, etc.)
              const Text(
                'Motivo del daño *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MotivoMerma.values.map((motivo) {
                  final seleccionado = _motivoSeleccionado == motivo;
                  final color = MermasUIHelpers.colorDeMotivo(motivo);
                  return ChoiceChip(
                    avatar: Icon(
                      MermasUIHelpers.iconoDeMotivo(motivo),
                      size: 15,
                      color: seleccionado ? Colors.white : color,
                    ),
                    label: Text(motivo.etiqueta),
                    selected: seleccionado,
                    selectedColor: color,
                    labelStyle: TextStyle(
                      color: seleccionado ? Colors.white : Colors.black87,
                      fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _motivoSeleccionado = motivo;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 4. Fila: Cantidad de piezas perdidas y Fecha
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Piezas perdidas *',
                        prefixIcon: const Icon(
                          Icons.numbers_rounded,
                          color: AppColors.terracotta,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final parsed = int.tryParse(valor.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Mayor a 0';
                        }
                        if (parsed > _loteSeleccionado.cantidadPiezas) {
                          return 'Máx ${_loteSeleccionado.cantidadPiezas} pzas';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _seleccionarFecha,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha del daño *',
                          prefixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.cobaltBlue,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          MermasUIHelpers.formatFecha(_fechaMerma),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 5. Criterio 2: Evidencia Fotográfica Obligatoria (Cámara / Galería real)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.cobaltBlue),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Evidencia fotográfica del daño *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'OBLIGATORIO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_evidenciaUrl.trim().isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _mostrarErrorEvidencia
                        ? Colors.red.shade50
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _mostrarErrorEvidencia
                          ? Colors.red.shade400
                          : Colors.grey.shade300,
                      width: _mostrarErrorEvidencia ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: 32,
                        color: _mostrarErrorEvidencia
                            ? Colors.red.shade700
                            : AppColors.cobaltBlue,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _mostrarErrorEvidencia
                            ? 'Es obligatorio adjuntar una evidencia fotográfica del daño.'
                            : 'Toma una foto con la cámara o selecciona una imagen de tu galería.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mostrarErrorEvidencia
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _mostrarErrorEvidencia
                              ? Colors.red.shade800
                              : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _capturandoImagen
                                  ? null
                                  : () => _seleccionarEvidencia(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_rounded, size: 18),
                              label: const Text(
                                'Tomar Foto',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cobaltBlue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _capturandoImagen
                                  ? null
                                  : () => _seleccionarEvidencia(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined, size: 18),
                              label: const Text(
                                'Galería',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                EvidenciaFotograficaPreview(
                  evidenciaUrl: _evidenciaUrl,
                  etapa: _etapaSeleccionada,
                  motivo: _motivoSeleccionado,
                  descripcion: _evidenciaDescController.text,
                  onRemove: () {
                    setState(() {
                      _evidenciaUrl = '';
                    });
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: _capturandoImagen
                          ? null
                          : () => _seleccionarEvidencia(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text('Repetir foto', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _capturandoImagen
                          ? null
                          : () => _seleccionarEvidencia(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: const Text('Cambiar de galería', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),

              // 6. Criterio 3: Insumos Consumidos y Costo Estimado Automático
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cobaltBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.cobaltBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Insumos Consumidos hasta esta Etapa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cobaltBlue,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _agregarInsumoPersonalizado,
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: const Text(
                            'Añadir insumo',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ..._insumosConsumidos.map((insumo) {
                      final cantTotal =
                          insumo.cantidadTotalConsumida(_cantidadPiezasActual);
                      final subtotal =
                          insumo.subtotalParaPiezas(_cantidadPiezasActual);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.cobaltBlue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${insumo.nombre} (${cantTotal.toStringAsFixed(2)} ${insumo.unidad})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              MermasUIHelpers.formatMonedaCorta(subtotal),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Costo estimado de la pérdida:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${MermasUIHelpers.formatMonedaCorta(_costoUnitarioEstimado)}/pza × $_cantidadPiezasActual pzas',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              MermasUIHelpers.formatMoneda(_costoTotalEstimado),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 7. Observaciones adicionales (opcional)
              TextFormField(
                controller: _observacionesController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Observaciones del daño (opcional)',
                  hintText: 'Ej: Daño detectado al descargar la segunda tanda del horno...',
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: Colors.black45),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),

              // Botones de Acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: mermasVM.isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: mermasVM.isSaving ? null : _guardarMerma,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                      ),
                      icon: mermasVM.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: const Text(
                        'Guardar Merma',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
