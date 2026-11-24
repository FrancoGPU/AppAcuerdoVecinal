import 'dart:convert';
import 'dart:typed_data';

import 'package:acuerdo_vecinal/core/constants/reglamento_data.dart';
import 'package:acuerdo_vecinal/main.dart';
import 'package:acuerdo_vecinal/models/condicion_model.dart';
import 'package:acuerdo_vecinal/models/mensaje_chat_model.dart';
import 'package:acuerdo_vecinal/models/negociacion_model.dart';
import 'package:acuerdo_vecinal/providers/negociacion_provider.dart';
import 'package:acuerdo_vecinal/services/acta_pdf_service.dart';
import 'package:acuerdo_vecinal/widgets/signature_pad_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Valid 1x1 transparent PNG encoded in base64 for unit serialization tests.
const String _samplePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

Future<void> _esperarHasta(
  WidgetTester tester,
  bool Function() condicion,
) async {
  for (var i = 0; i < 30 && !condicion(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Modelos JSON round-trip', () {
    test('NegociacionModel, CondicionModel, RondaHistorial y MensajeChatModel',
        () {
      final fecha = DateTime(2026, 11, 18, 22, 30);
      final condicion = CondicionModel(
        id: 'cond-1',
        tituloClausula: 'Horario nocturno',
        descripcionPropuesta: 'Silencio desde las 10:00 p.m.',
        criterioObjetivo: kReglamentoInterno.first.etiqueta,
        argumentoPersuasivo:
            'Garantiza el descanso laboral sin impedir la recreación diurna.',
        autorUltimaOferta: kDpto301,
        estado: EstadoCondicion.rechazada,
        motivoRechazo: 'Requiero ensayar los sábados por la tarde.',
        historial: [
          RondaHistorial(
            propuestaAnterior: 'Silencio desde las 9:00 p.m.',
            argumentoAnterior: 'Horario temprano sugerido inicialmente.',
            autor: kDpto301,
            fecha: fecha,
          ),
        ],
      );

      final negociacion = NegociacionModel(
        id: 'neg-1',
        titulo: 'Ruido nocturno',
        categoria: 'Ruido',
        descripcionProblema: 'Música elevada de noche.',
        dptoSolicitante: kDpto301,
        dptoReceptor: kDpto402,
        esAnonimo: true,
        interesSolicitante: 'Dormir antes de turno laboral',
        interesReceptor: 'Practicar guitarra en mi tiempo libre',
        condiciones: [condicion],
        estadoGeneral: EstadoNegociacion.formalizada,
        fechaCreacion: fecha,
        fechaFormalizacion: fecha,
        codigoActa: 'ACTA-2026-001',
        firmadoSolicitante: true,
        firmadoReceptor: true,
        firmaSolicitanteBase64: _samplePngBase64,
        firmaReceptorBase64: _samplePngBase64,
      );

      final decodedNeg = NegociacionModel.fromJson(negociacion.toJson());
      expect(decodedNeg.id, negociacion.id);
      expect(decodedNeg.esAnonimo, isTrue);
      expect(decodedNeg.firmaSolicitanteBase64, _samplePngBase64);
      expect(decodedNeg.firmaReceptorBase64, _samplePngBase64);
      expect(decodedNeg.condiciones.length, 1);
      expect(decodedNeg.condiciones.first.estado, EstadoCondicion.rechazada);
      expect(decodedNeg.condiciones.first.historial.length, 1);
      expect(decodedNeg.condiciones.first.historial.first.autor, kDpto301);

      final chatMsg = MensajeChatModel(
        id: 'msg-1',
        negociacionId: 'neg-1',
        texto: 'Sugerencia de punto medio',
        esUsuario: false,
        fecha: fecha,
      );
      final decodedChat = MensajeChatModel.fromJson(chatMsg.toJson());
      expect(decodedChat.id, 'msg-1');
      expect(decodedChat.negociacionId, 'neg-1');
      expect(decodedChat.esUsuario, isFalse);
      expect(decodedChat.fecha, fecha);
    });
  });

  group('ActaPdfService con firma PNG real de SignaturePadController', () {
    testWidgets('genera un PDF válido embebiendo firmas reales trazadas',
        (tester) async {
      final controller = SignaturePadController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SignaturePadWidget(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragFrom(
        tester.getCenter(find.text('Firme aquí con el dedo')),
        const Offset(60, 25),
      );
      await tester.pumpAndSettle();
      expect(controller.tieneFirma, isTrue);

      Uint8List? realPng;
      await tester.runAsync(() async {
        realPng = await controller.exportarPngBytes();
      });
      expect(realPng, isNotNull);
      expect(realPng!.length, greaterThan(100));

      final realBase64 = base64Encode(realPng!);
      final negociacion = NegociacionModel(
        id: 'neg-pdf-real',
        titulo: 'Control de ruido en ensayos nocturnos',
        categoria: 'Ruido',
        descripcionProblema: 'Ensayos musicales después de las 10:30 p.m.',
        dptoSolicitante: kDpto301,
        dptoReceptor: kDpto402,
        esAnonimo: false,
        interesSolicitante:
            'Descansar adecuadamente antes del turno laboral de la mañana.',
        interesReceptor:
            'Practicar guitarra acústica sin perder el espacio recreativo.',
        condiciones: [
          CondicionModel(
            id: 'c1',
            tituloClausula: 'Horario de silencio entre semana',
            descripcionPropuesta:
                'Suspender ensayos de lunes a viernes desde las 10:00 p.m.',
            criterioObjetivo: kReglamentoInterno.first.etiqueta,
            argumentoPersuasivo:
                'Equilibra el descanso laboral con la práctica musical vespertina.',
            autorUltimaOferta: kDpto301,
            estado: EstadoCondicion.aceptada,
          ),
        ],
        estadoGeneral: EstadoNegociacion.formalizada,
        fechaCreacion: DateTime(2026, 11, 18, 21, 0),
        fechaFormalizacion: DateTime(2026, 11, 18, 23, 15),
        codigoActa: 'ACTA-2026-001',
        firmadoSolicitante: true,
        firmadoReceptor: true,
        firmaSolicitanteBase64: realBase64,
        firmaReceptorBase64: realBase64,
      );

      final pdfBytes = await ActaPdfService.generarActaPdf(
        negociacion,
        rolActivo: kDpto301,
      );

      expect(pdfBytes.length, greaterThan(1000));
      expect(ascii.decode(pdfBytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('NegociacionProvider reglas de negocio y firma por vecino', () {
    test('carga datos semilla iniciales y persiste creaciones entre reinicios',
        () async {
      final provider1 = NegociacionProvider();
      await provider1.inicializar();

      expect(provider1.negociaciones.length, 2);
      expect(provider1.activos.length, 2);
      expect(provider1.formalizados, isEmpty);

      final creada = await provider1.crearNegociacion(
        titulo: 'Mascota en pasadizo',
        categoria: 'Mascotas',
        descripcionProblema: 'Perro suelto en áreas comunes.',
        esAnonimo: false,
        interesSolicitante: 'Evitar accidentes con niños pequeños.',
        tituloClausulaInicial: 'Uso de correa',
        descripcionPropuestaInicial: 'Usar correa en ascensor y pasadizos.',
        criterioObjetivoInicial: kReglamentoInterno[1].etiqueta,
        argumentoPersuasivoInicial:
            'Brinda seguridad a todos los vecinos y protege también a la mascota.',
      );

      final provider2 = NegociacionProvider();
      await provider2.inicializar();
      expect(provider2.negociaciones.length, 3);
      expect(provider2.obtenerPorId(creada.id)?.titulo, 'Mascota en pasadizo');
    });

    test('firma por participante sella automáticamente al firmar ambos vecinos',
        () async {
      final provider = NegociacionProvider();
      await provider.inicializar();

      final caso2 = provider.obtenerPorId('demo-caso-2')!;
      expect(caso2.dptoSolicitante, kDpto402);
      expect(caso2.dptoReceptor, kDpto301);
      expect(provider.rolActivo, kDpto301);
      expect(provider.faltaMiFirma(caso2), isTrue);

      final parcial = await provider.registrarFirmaParticipante(
        negociacionId: caso2.id,
        firmaBase64: _samplePngBase64,
      );
      expect(parcial, isNotNull);
      expect(parcial!.firmadoReceptor, isTrue);
      expect(parcial.firmadoSolicitante, isFalse);
      expect(parcial.estaFormalizada, isFalse);
      expect(parcial.estadoGeneral, EstadoNegociacion.listoParaFirmar);
      expect(provider.faltaMiFirma(parcial), isFalse);

      await provider.alternarRol();
      expect(provider.rolActivo, kDpto402);
      expect(provider.faltaMiFirma(parcial), isTrue);

      final sellada = await provider.registrarFirmaParticipante(
        negociacionId: caso2.id,
        firmaBase64: _samplePngBase64,
      );
      expect(sellada, isNotNull);
      expect(sellada!.estaFormalizada, isTrue);
      expect(sellada.firmadoSolicitante, isTrue);
      expect(sellada.firmadoReceptor, isTrue);
      expect(sellada.codigoActa, startsWith('ACTA-'));
    });

    test('control de turnos, rechazo con motivo, contraoferta e inmutabilidad',
        () async {
      final provider = NegociacionProvider();
      await provider.inicializar();

      final caso1 = provider.obtenerPorId('demo-caso-1')!;
      final cond1 = caso1.condiciones.first;

      expect(provider.rolActivo, kDpto301);
      final propioAceptar = await provider.aceptarCondicion(
        negociacionId: caso1.id,
        condicionId: cond1.id,
      );
      expect(propioAceptar, isFalse);

      await provider.alternarRol();
      expect(provider.rolActivo, kDpto402);

      final rechazoVacio = await provider.rechazarCondicion(
        negociacionId: caso1.id,
        condicionId: cond1.id,
        motivoRechazo: '   ',
      );
      expect(rechazoVacio, isFalse);

      final rechazoOk = await provider.rechazarCondicion(
        negociacionId: caso1.id,
        condicionId: cond1.id,
        motivoRechazo: 'Necesito hasta las 10:30 p.m. los viernes.',
      );
      expect(rechazoOk, isTrue);

      final contraofertaOk = await provider.contraofertarCondicion(
        negociacionId: caso1.id,
        condicionId: cond1.id,
        nuevaPropuesta: 'Silencio lunes a jueves 10:00 p.m., viernes 10:30 p.m.',
        nuevoCriterioObjetivo: kReglamentoInterno.first.etiqueta,
        nuevoArgumentoPersuasivo:
            'Equilibra el descanso entre semana con un margen breve el viernes.',
      );
      expect(contraofertaOk, isTrue);

      final actualizado1 = provider.obtenerPorId(caso1.id)!;
      expect(actualizado1.condiciones.first.historial.length, 1);
      expect(actualizado1.condiciones.first.autorUltimaOferta, kDpto402);
      expect(actualizado1.condiciones.first.estado, EstadoCondicion.pendiente);
      expect(actualizado1.condiciones.first.motivoRechazo, isNull);

      await provider.alternarRol();
      final cond2 = actualizado1.condiciones[1];
      await provider.aceptarCondicion(
        negociacionId: caso1.id,
        condicionId: cond1.id,
      );
      final reformulado = await provider.contraofertarCondicion(
        negociacionId: caso1.id,
        condicionId: cond2.id,
        nuevaPropuesta: 'Guitarra acústica los sábados hasta las 9:30 p.m.',
        nuevoCriterioObjetivo: kReglamentoInterno.last.etiqueta,
        nuevoArgumentoPersuasivo:
            'Permite tu ensayo del sábado sin afectar mi descanso nocturno.',
      );
      expect(reformulado, isTrue);

      await provider.alternarRol();
      final acepta2 = await provider.aceptarCondicion(
        negociacionId: caso1.id,
        condicionId: cond2.id,
      );
      expect(acepta2, isTrue);

      final listo = provider.obtenerPorId(caso1.id)!;
      expect(listo.estadoGeneral, EstadoNegociacion.listoParaFirmar);

      final acta = await provider.formalizarAcuerdo(
        negociacionId: caso1.id,
        firmaSolicitanteBase64: _samplePngBase64,
        firmaReceptorBase64: _samplePngBase64,
      );
      expect(acta, isNotNull);
      expect(acta!.estaFormalizada, isTrue);

      final editarTrasSello = await provider.agregarCondicion(
        negociacionId: caso1.id,
        tituloClausula: 'Cláusula tardía',
        descripcionPropuesta: 'No debería agregarse.',
        criterioObjetivo: kReglamentoInterno.first.etiqueta,
        argumentoPersuasivo: 'Intento después de formalización.',
      );
      expect(editarTrasSello, isFalse);
    });
  });

  group('Smoke tests UI AcuerdoVecinal', () {
    testWidgets(
        'filtros, reglamento y firma secuencial por vecino en modal dedicado',
        (tester) async {
      final provider = NegociacionProvider();
      await provider.inicializar();

      await tester.pumpWidget(AcuerdoVecinalApp(providerOverride: provider));
      await tester.pumpAndSettle();

      expect(find.text('AcuerdoVecinal'), findsOneWidget);
      expect(find.text('Activos (2)'), findsOneWidget);
      expect(find.text('Falta tu firma'), findsOneWidget);

      // Filter by category.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Cochera'));
      await tester.pumpAndSettle();
      expect(find.text('Activos (1)'), findsOneWidget);
      expect(find.text('Uso del límite de cochera sótano 1'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
      await tester.pumpAndSettle();
      expect(find.text('Activos (2)'), findsOneWidget);

      // Open Reglamento Interno modal.
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consultar Reglamento Interno'));
      await tester.pumpAndSettle();
      expect(find.text('Reglamento Interno del Condominio'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      // Open Case 2 -> Formalizar Acuerdo.
      await tester.tap(find.text('Uso del límite de cochera sótano 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Formalizar Acuerdo'));
      await tester.pumpAndSettle();

      // Neighbor 1 (Dpto. 301) signs inside dedicated non-scrollable modal.
      expect(find.text('Firmar como Dpto. 301'), findsOneWidget);
      await tester.tap(find.text('Firmar como Dpto. 301'));
      await tester.pumpAndSettle();

      expect(find.text('Traza tu firma debajo'), findsOneWidget);
      await tester.dragFrom(
        tester.getCenter(find.byType(SignaturePadWidget)),
        const Offset(0, 45),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar mi firma'));
      await tester.pump();
      await _esperarHasta(
        tester,
        () => provider.obtenerPorId('demo-caso-2')!.firmadoReceptor,
      );

      expect(
        find.textContaining('Falta la firma de Dpto. 402'),
        findsOneWidget,
      );

      // Toggle role to Dpto. 402 directly on Acta screen and sign.
      await tester.tap(find.text('Soy: Dpto. 301'));
      await tester.pumpAndSettle();
      expect(find.text('Firmar como Dpto. 402'), findsOneWidget);

      await tester.tap(find.text('Firmar como Dpto. 402'));
      await tester.pumpAndSettle();
      await tester.dragFrom(
        tester.getCenter(find.byType(SignaturePadWidget)),
        const Offset(55, 25),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar mi firma'));
      await tester.pump();
      await _esperarHasta(
        tester,
        () => provider.obtenerPorId('demo-caso-2')!.estaFormalizada,
      );

      expect(find.text('ACUERDO FORMALIZADO Y VIGENTE'), findsOneWidget);
      expect(find.text('Guardar PDF'), findsOneWidget);
      expect(find.text('Compartir'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Firmas registradas'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Firmas registradas'), findsOneWidget);

      await tester.tap(find.text('Volver al Inicio'));
      await tester.pumpAndSettle();

      expect(find.text('Activos (1)'), findsOneWidget);
      expect(find.text('Formalizados (1)'), findsOneWidget);
    });

    testWidgets(
        'flujo móvil 360x780 crear negociación y modales en mesa sin overflow ni errores',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = NegociacionProvider();
      await provider.inicializar();

      await tester.pumpWidget(AcuerdoVecinalApp(providerOverride: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva Negociación'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Mascota sin correa en ascensor');
      await tester.tap(find.text('Ruido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mascotas').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        fields.at(1),
        'El perro circula sin correa en horas punta del ascensor.',
      );
      await tester.scrollUntilVisible(
        fields.at(2),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        fields.at(2),
        'Evitar sustos o incidentes con niños al salir del ascensor.',
      );

      await tester.scrollUntilVisible(
        fields.at(5),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(fields.at(3), 'Uso de correa en ascensor');
      await tester.enterText(
        fields.at(4),
        'Mantener correa puesta en pasadizos y ascensores.',
      );
      await tester.enterText(
        fields.at(5),
        'Brinda tranquilidad a las familias y protege a la mascota.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar Negociación'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'Garantizar seguridad para adultos mayores y niños.',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Agregar otra condición'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Agregar otra condición'));
      await tester.pumpAndSettle();
      final modalFields = find.byType(TextFormField);
      await tester.enterText(modalFields.at(0), 'Limpieza en áreas comunes');
      await tester.enterText(
        modalFields.at(1),
        'Recoger inmediatamente cualquier residuo en jardines.',
      );
      await tester.enterText(
        modalFields.at(2),
        'Mantiene el edificio higiénico y agradable para todos.',
      );
      await tester.tap(find.text('Añadir a la mesa'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Soy: Dpto. 301'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Rechazar').first,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Rechazar').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'Prefiero solo en ascensor, no en jardín exterior.',
      );
      await tester.tap(find.text('Confirmar rechazo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contraofertar').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'Usar correa dentro del edificio y jardín principal.',
      );
      await tester.tap(find.text('Enviar Contrapropuesta'));
      await tester.pumpAndSettle();

      expect(find.text('Última oferta: Dpto. 402'), findsOneWidget);
    });
  });
}
