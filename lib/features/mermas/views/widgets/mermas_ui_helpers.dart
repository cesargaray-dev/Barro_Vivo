// lib/features/mermas/views/widgets/mermas_ui_helpers.dart
//
// Helpers visuales, insignias de motivos y visor de evidencia fotográfica real
// (archivo de cámara/galería o URL remota) para el módulo de Registro de Mermas (HU-06).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../produccion/models/etapa_produccion.dart';
import '../../models/motivo_merma.dart';
import '../../models/registro_merma.dart';

class MermasUIHelpers {
  MermasUIHelpers._();

  /// Formatea un monto numérico a moneda mexicana: "$180.00 MXN".
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

  /// Formatea un monto numérico a moneda corta: "$180.00".
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

  /// Formatea una fecha en formato DD/MM/YYYY.
  static String formatFecha(DateTime f) {
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    final y = f.year;
    return '$d/$m/$y';
  }

  /// Color semántico asociado a cada motivo de merma.
  static Color colorDeMotivo(MotivoMerma motivo) {
    return switch (motivo) {
      MotivoMerma.despostillado => const Color(0xFFE65100),
      MotivoMerma.rotura => const Color(0xFFC62828),
      MotivoMerma.grietaTermica => AppColors.terracotta,
      MotivoMerma.defectoEsmalte => const Color(0xFF0277BD),
      MotivoMerma.deformacion => const Color(0xFF6D4C41),
      MotivoMerma.contaminacionPigmento => AppColors.cobaltBlue,
      MotivoMerma.otro => const Color(0xFF546E7A),
    };
  }

  /// Ícono representativo para cada motivo de merma.
  static IconData iconoDeMotivo(MotivoMerma motivo) {
    return switch (motivo) {
      MotivoMerma.despostillado => Icons.architecture_rounded,
      MotivoMerma.rotura => Icons.broken_image_rounded,
      MotivoMerma.grietaTermica => Icons.local_fire_department_rounded,
      MotivoMerma.defectoEsmalte => Icons.format_paint_rounded,
      MotivoMerma.deformacion => Icons.waves_rounded,
      MotivoMerma.contaminacionPigmento => Icons.brush_rounded,
      MotivoMerma.otro => Icons.report_problem_rounded,
    };
  }

  /// Extrae un nombre corto de archivo desde una URI o ruta de evidencia.
  static String nombreArchivoEvidencia(String evidenciaUrl) {
    final limpia = evidenciaUrl.trim();
    if (limpia.isEmpty) return 'Sin archivo';
    final segmentos = limpia.split(RegExp(r'[/\\]'));
    return segmentos.isNotEmpty ? segmentos.last : limpia;
  }

  /// Determina si [evidenciaUrl] corresponde a un archivo local existente en el dispositivo.
  static bool esArchivoLocalExistente(String evidenciaUrl) {
    if (kIsWeb) return false;
    final limpia = evidenciaUrl.trim();
    if (limpia.isEmpty ||
        limpia.startsWith('http://') ||
        limpia.startsWith('https://') ||
        limpia.startsWith('evidencia://')) {
      return false;
    }
    try {
      return File(limpia).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Determina si [evidenciaUrl] es una URL remota HTTP/HTTPS.
  static bool esUrlRemota(String evidenciaUrl) {
    final limpia = evidenciaUrl.trim().toLowerCase();
    return limpia.startsWith('http://') || limpia.startsWith('https://');
  }
}

/// Insignia visual que muestra el motivo del daño (Despostillado, Rotura, etc.).
class MotivoMermaBadge extends StatelessWidget {
  const MotivoMermaBadge({
    super.key,
    required this.motivo,
    this.compact = false,
  });

  final MotivoMerma motivo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = MermasUIHelpers.colorDeMotivo(motivo);
    final icono = MermasUIHelpers.iconoDeMotivo(motivo);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              motivo.etiqueta,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que renderiza la imagen real (archivo local o red) o su respaldo visual.
class _ImagenEvidenciaWidget extends StatelessWidget {
  const _ImagenEvidenciaWidget({
    required this.evidenciaUrl,
    required this.etapa,
    required this.motivo,
    required this.borderRadius,
    this.iconSize = 28,
  });

  final String evidenciaUrl;
  final EtapaProduccion etapa;
  final MotivoMerma motivo;
  final BorderRadius borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorMotivo = MermasUIHelpers.colorDeMotivo(motivo);

    Widget fallbackVisual() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              etapa.color.withValues(alpha: 0.85),
              colorMotivo.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Icon(
            MermasUIHelpers.iconoDeMotivo(motivo),
            color: Colors.white.withValues(alpha: 0.92),
            size: iconSize,
          ),
        ),
      );
    }

    if (MermasUIHelpers.esArchivoLocalExistente(evidenciaUrl)) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.file(
          File(evidenciaUrl.trim()),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => fallbackVisual(),
        ),
      );
    }

    if (MermasUIHelpers.esUrlRemota(evidenciaUrl)) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          evidenciaUrl.trim(),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => fallbackVisual(),
        ),
      );
    }

    return fallbackVisual();
  }
}

/// Tarjeta de previsualización de la evidencia fotográfica adjunta (HU-06 Criterio 2).
class EvidenciaFotograficaPreview extends StatelessWidget {
  const EvidenciaFotograficaPreview({
    super.key,
    required this.evidenciaUrl,
    required this.etapa,
    required this.motivo,
    this.descripcion,
    this.onTap,
    this.onRemove,
  });

  final String evidenciaUrl;
  final EtapaProduccion etapa;
  final MotivoMerma motivo;
  final String? descripcion;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final nombreArchivo = MermasUIHelpers.nombreArchivoEvidencia(evidenciaUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cobaltBlue.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              // Miniatura de la fotografía (real o respaldo)
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ImagenEvidenciaWidget(
                      evidenciaUrl: evidenciaUrl,
                      etapa: etapa,
                      motivo: motivo,
                      borderRadius: BorderRadius.circular(12),
                      iconSize: 26,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Metadatos de la evidencia fotográfica
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFF2E7D32),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Evidencia fotográfica adjunta',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nombreArchivo,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (descripcion != null && descripcion!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        descripcion!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              if (onRemove != null)
                IconButton(
                  tooltip: 'Quitar fotografía',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                  onPressed: onRemove,
                )
              else if (onTap != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cobaltBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 15, color: AppColors.cobaltBlue),
                      SizedBox(width: 3),
                      Text(
                        'Ver',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cobaltBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo visor de la evidencia fotográfica del daño en tamaño completo.
class EvidenciaFotograficaDialog extends StatelessWidget {
  const EvidenciaFotograficaDialog({
    super.key,
    required this.merma,
  });

  final RegistroMerma merma;

  static Future<void> show(BuildContext context, RegistroMerma merma) {
    return showDialog<void>(
      context: context,
      builder: (_) => EvidenciaFotograficaDialog(merma: merma),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreArchivo = MermasUIHelpers.nombreArchivoEvidencia(merma.evidenciaUrl);
    final esReal = MermasUIHelpers.esArchivoLocalExistente(merma.evidenciaUrl) ||
        MermasUIHelpers.esUrlRemota(merma.evidenciaUrl);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera_rounded, color: AppColors.cobaltBlue),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Evidencia Fotográfica del Daño',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cobaltBlue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fotografía real o respaldo visual
            SizedBox(
              width: double.infinity,
              height: 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ImagenEvidenciaWidget(
                    evidenciaUrl: merma.evidenciaUrl,
                    etapa: merma.etapa,
                    motivo: merma.motivo,
                    borderRadius: BorderRadius.circular(18),
                    iconSize: 48,
                  ),
                  if (!esReal)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 64),
                            Text(
                              '${merma.motivo.etiqueta} en ${merma.etapa.titulo}',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${merma.cantidadPiezas} ${merma.cantidadPiezas == 1 ? 'pieza dañada' : 'piezas dañadas'} · ${merma.loteCodigo}',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        MermasUIHelpers.formatFecha(merma.fecha),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 13, color: Colors.greenAccent),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                nombreArchivo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (merma.evidenciaDescripcion != null &&
                merma.evidenciaDescripcion!.isNotEmpty) ...[
              const Text(
                'Descripción de la evidencia:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                merma.evidenciaDescripcion!,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 10),
            ],

            Text(
              'Archivo: $nombreArchivo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar Visor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
