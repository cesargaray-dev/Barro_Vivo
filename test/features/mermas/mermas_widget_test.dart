// test/features/mermas/mermas_widget_test.dart
//
// Pruebas de widgets para HU-06 (Registro de mermas con costo estimado).
// Verifica el renderizado de MermaCard, MermasScreen y la validación de evidencia
// fotográfica obligatoria en RegistrarMermaSheet.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';
import 'package:barro_vivo/features/mermas/models/insumo_consumido_merma.dart';
import 'package:barro_vivo/features/mermas/models/motivo_merma.dart';
import 'package:barro_vivo/features/mermas/models/registro_merma.dart';
import 'package:barro_vivo/features/mermas/repositories/mermas_repository.dart';
import 'package:barro_vivo/features/mermas/viewmodels/mermas_viewmodel.dart';
import 'package:barro_vivo/features/mermas/views/mermas_screen.dart';
import 'package:barro_vivo/features/mermas/views/widgets/merma_card.dart';
import 'package:barro_vivo/features/mermas/views/widgets/registrar_merma_sheet.dart';
import 'package:barro_vivo/theme/app_theme.dart';

class _MockMermasRepo implements MermasRepository {
  _MockMermasRepo({List<RegistroMerma>? inicial})
      : _items = inicial != null ? List.of(inicial) : [];

  final List<RegistroMerma> _items;

  @override
  Future<List<RegistroMerma>> getMermas({
    String? loteId,
    bool soloActivos = true,
  }) async {
    return _items;
  }

  @override
  Future<RegistroMerma> registrarMerma({
    required String loteId,
    required String loteCodigo,
    required EtapaProduccion etapa,
    required MotivoMerma motivo,
    required int cantidadPiezas,
    required String evidenciaUrl,
    required List<InsumoConsumidoMerma> insumosConsumidos,
    required DateTime fecha,
    String? evidenciaDescripcion,
    String? observaciones,
  }) async {
    final nueva = RegistroMerma(
      id: 'merma_new',
      loteId: loteId,
      loteCodigo: loteCodigo,
      etapa: etapa,
      motivo: motivo,
      cantidadPiezas: cantidadPiezas,
      evidenciaUrl: evidenciaUrl,
      evidenciaDescripcion: evidenciaDescripcion,
      insumosConsumidos: insumosConsumidos,
      observaciones: observaciones,
      fecha: fecha,
    );
    nueva.validarReglasDeNegocio();
    _items.insert(0, nueva);
    return nueva;
  }

  @override
  Future<void> darDeBajaMerma(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

void main() {
  final mermaEjemplo = RegistroMerma(
    id: 'merma_test_1',
    loteId: 'lote_1',
    loteCodigo: 'LOTE-2026-001 (Vajilla Real)',
    etapa: EtapaProduccion.decorado,
    motivo: MotivoMerma.despostillado,
    cantidadPiezas: 3,
    evidenciaUrl: 'evidencia://camara_taller/despostillado_01.jpg',
    evidenciaDescripcion: 'Borde despostillado en plato trinche decorado.',
    insumosConsumidos: InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.decorado),
    observaciones: 'Accidente al trasladar a estantería.',
    fecha: DateTime(2026, 11, 8),
  );

  testWidgets('MermaCard muestra etapa, motivo, evidencia fotográfica y costo estimado',
      (tester) async {
    final vm = MermasViewModel(
      mermasRepository: _MockMermasRepo(inicial: [mermaEjemplo]),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider<MermasViewModel>.value(
          value: vm,
          child: Scaffold(
            body: ListView(
              children: [
                MermaCard(merma: mermaEjemplo),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LOTE-2026-001 (Vajilla Real)'), findsOneWidget);
    expect(find.text('3 pzas perdidas'), findsOneWidget);
    expect(find.text('Decorado'), findsOneWidget);
    expect(find.text('Despostillado'), findsOneWidget);
    expect(find.text('Evidencia fotográfica adjunta'), findsOneWidget);
    expect(find.text('COSTO ESTIMADO DE LA MERMA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MermasScreen renderiza métricas y listado de mermas correctamente',
      (tester) async {
    final vm = MermasViewModel(
      mermasRepository: _MockMermasRepo(inicial: [mermaEjemplo]),
    );
    await vm.cargarMermas();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider<MermasViewModel>.value(
          value: vm,
          child: const MermasScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registro de Mermas'), findsOneWidget);
    expect(find.text('Piezas perdidas'), findsOneWidget);
    expect(find.text('Costo estimado'), findsOneWidget);
    expect(find.text('LOTE-2026-001 (Vajilla Real)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RegistrarMermaSheet exige evidencia fotográfica obligatoria antes de guardar',
      (tester) async {
    final vm = MermasViewModel(mermasRepository: _MockMermasRepo());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider<MermasViewModel>.value(
          value: vm,
          child: Scaffold(
            body: RegistrarMermaSheet(
              imagePickerOverride: (_) async =>
                  '/storage/emulated/0/DCIM/Camera/evidencia_dano.jpg',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Intentar guardar sin adjuntar foto
    final botonGuardar = find.text('Guardar Merma');
    await tester.ensureVisible(botonGuardar);
    await tester.tap(botonGuardar);
    await tester.pumpAndSettle();

    // Debe mostrar el error de evidencia fotográfica obligatoria y no guardar
    expect(
      find.text('Es obligatorio adjuntar una evidencia fotográfica del daño.'),
      findsOneWidget,
    );
    expect(vm.totalIncidentes, equals(0));

    // Ahora adjuntar fotografía con el botón "Tomar Foto"
    final botonTomarFoto = find.text('Tomar Foto');
    await tester.ensureVisible(botonTomarFoto);
    await tester.tap(botonTomarFoto);
    await tester.pumpAndSettle();

    expect(find.text('Evidencia fotográfica adjunta'), findsOneWidget);

    // Guardar nuevamente con la evidencia adjunta
    await tester.ensureVisible(botonGuardar);
    await tester.tap(botonGuardar);
    await tester.pumpAndSettle();

    expect(vm.totalIncidentes, equals(1));
  });

  testWidgets('RegistrarMermaSheet invoca cámara y galería reales para capturar archivo fotográfico',
      (tester) async {
    final vm = MermasViewModel(mermasRepository: _MockMermasRepo());
    final fuentesInvocadas = <ImageSource>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider<MermasViewModel>.value(
          value: vm,
          child: Scaffold(
            body: RegistrarMermaSheet(
              imagePickerOverride: (source) async {
                fuentesInvocadas.add(source);
                return source == ImageSource.camera
                    ? '/storage/emulated/0/DCIM/Camera/IMG_MERMA_CAMARA.jpg'
                    : '/storage/emulated/0/Pictures/IMG_MERMA_GALERIA.jpg';
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Probar captura desde Cámara
    final botonCamara = find.text('Tomar Foto');
    await tester.ensureVisible(botonCamara);
    await tester.tap(botonCamara);
    await tester.pumpAndSettle();

    expect(fuentesInvocadas, contains(ImageSource.camera));
    expect(find.text('Evidencia fotográfica adjunta'), findsOneWidget);

    // 2. Probar selección desde Galería usando el botón "Cambiar de galería"
    final botonGaleria = find.text('Cambiar de galería');
    await tester.ensureVisible(botonGaleria);
    await tester.tap(botonGaleria);
    await tester.pumpAndSettle();

    expect(fuentesInvocadas, contains(ImageSource.gallery));

    // Guardar y verificar que la ruta real seleccionada quedó registrada
    final botonGuardar = find.text('Guardar Merma');
    await tester.ensureVisible(botonGuardar);
    await tester.tap(botonGuardar);
    await tester.pumpAndSettle();

    expect(vm.totalIncidentes, equals(1));
    expect(
      vm.mermas.first.evidenciaUrl,
      equals('/storage/emulated/0/Pictures/IMG_MERMA_GALERIA.jpg'),
    );
  });

  testWidgets('Prevención de desbordamientos (overflow) en pantallas estrechas (320px)',
      (tester) async {
    // Simulamos una pantalla pequeña de 320x640 lógicos (donde ocurría el overflow de 24px)
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final vm = MermasViewModel(
      mermasRepository: _MockMermasRepo(inicial: [mermaEjemplo]),
    );
    await vm.cargarMermas();

    // 1. Verificar MermasScreen y MermaCard sin overflow en 320px
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider<MermasViewModel>.value(
          value: vm,
          child: const MermasScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Expandir el desglose de insumos en MermaCard en pantalla de 320px
    final botonInsumos = find.textContaining('Insumos consumidos');
    await tester.ensureVisible(botonInsumos);
    await tester.tap(botonInsumos);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 2. Verificar RegistrarMermaSheet sin overflow en 320px
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChangeNotifierProvider<MermasViewModel>.value(
          value: vm,
          child: Scaffold(
            body: RegistrarMermaSheet(
              imagePickerOverride: (_) async =>
                  '/storage/emulated/0/DCIM/Camera/IMG_MERMA_320PX.jpg',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

