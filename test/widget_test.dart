import 'dart:convert';
import 'dart:typed_data';

import 'package:acuerdo_vecinal/core/config/supabase_config.dart';
import 'package:acuerdo_vecinal/core/constants/reglamento_data.dart';
import 'package:acuerdo_vecinal/main.dart';
import 'package:acuerdo_vecinal/models/condicion_model.dart';
import 'package:acuerdo_vecinal/models/condominio_model.dart';
import 'package:acuerdo_vecinal/models/mensaje_chat_model.dart';
import 'package:acuerdo_vecinal/models/negociacion_model.dart';
import 'package:acuerdo_vecinal/models/usuario_model.dart';
import 'package:acuerdo_vecinal/providers/auth_provider.dart';
import 'package:acuerdo_vecinal/providers/negociacion_provider.dart';
import 'package:acuerdo_vecinal/providers/reglamento_provider.dart';
import 'package:acuerdo_vecinal/services/acta_pdf_service.dart';
import 'package:acuerdo_vecinal/services/mediador_ia_service.dart';
import 'package:acuerdo_vecinal/services/supabase_service.dart';
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

  group('v2.0: Usuarios, Condominio, Reglamento Dinámico y Mediador IA', () {
    test(
        'PerfilUsuario, CondominioModel, ArticuloReglamento y NegociacionModel Supabase',
        () {
      final fecha = DateTime(2026, 11, 25, 19, 0);
      final condominio = CondominioModel(
        id: 'condo-1',
        nombre: 'Residencial Los Pinos',
        direccion: 'Av. Salaverry 1200',
        codigoInvitacion: 'AV-9F2A',
        adminId: 'uid-admin',
        fechaCreacion: fecha,
      );
      final condoJson = CondominioModel.fromJson(condominio.toJson());
      expect(condoJson.codigoInvitacion, 'AV-9F2A');
      expect(condoJson.nombre, 'Residencial Los Pinos');

      const perfil = PerfilUsuario(
        id: 'uid-vecino',
        email: 'vecino@condo.pe',
        nombre: 'Ana Torres',
        rol: RolUsuario.vecino,
        departamento: 'Dpto. 501',
        condominioId: 'condo-1',
      );
      final perfilRoundTrip = PerfilUsuario.fromJson(perfil.toJson());
      expect(perfilRoundTrip.rol, RolUsuario.vecino);
      expect(perfilRoundTrip.departamento, 'Dpto. 501');

      const art = ArticuloReglamento(
        id: 'art-custom',
        etiqueta: 'Art. 40 - Uso de Ascensor de Carga',
        resumen: 'Mudanzas permitidas de 8:00 a.m. a 6:00 p.m.',
        categoria: 'Áreas Comunes',
        orden: 7,
      );
      final artRoundTrip = ArticuloReglamento.fromJson(art.toJson());
      expect(artRoundTrip.etiqueta, 'Art. 40 - Uso de Ascensor de Carga');
      expect(artRoundTrip.toSupabaseMap('condo-1')['condominio_id'], 'condo-1');

      final neg = NegociacionModel(
        id: 'neg-cloud-1',
        titulo: 'Mudanza en sábado',
        categoria: 'Áreas Comunes',
        descripcionProblema: 'Coordinación de horario de ascensor.',
        dptoSolicitante: 'Dpto. 501',
        dptoReceptor: 'Dpto. 502',
        esAnonimo: false,
        interesSolicitante: 'Trasladar muebles sin demoras.',
        interesReceptor: 'Mantener libre el ingreso familiar.',
        condiciones: const [],
        estadoGeneral: EstadoNegociacion.enNegociacion,
        fechaCreacion: fecha,
        condominioId: 'condo-1',
        solicitanteId: 'uid-vecino',
        receptorId: 'uid-receptor',
      );
      final fromSupa = NegociacionModel.fromSupabaseMap(neg.toSupabaseMap());
      expect(fromSupa.condominioId, 'condo-1');
      expect(fromSupa.solicitanteId, 'uid-vecino');
      expect(fromSupa.receptorId, 'uid-receptor');
      expect(fromSupa.dptoReceptor, 'Dpto. 502');
    });

    test('ReglamentoProvider CRUD persiste artículos en almacenamiento local',
        () async {
      final reg1 = ReglamentoProvider();
      await reg1.inicializarLocal();
      expect(reg1.articulos.length, kReglamentoInterno.length);

      final creado = await reg1.agregarArticulo(
        etiqueta: 'Art. 50 - Patios y Bicicletas',
        resumen: 'Estacionar bicicletas únicamente en el rack del sótano.',
        categoria: 'Áreas Comunes',
      );
      expect(reg1.articulos.length, kReglamentoInterno.length + 1);
      expect(reg1.comoContextoTexto(), contains('Art. 50 - Patios y Bicicletas'));

      await reg1.actualizarArticulo(
        creado.copyWith(resumen: 'Estacionar solo en el rack B del sótano.'),
      );

      final reg2 = ReglamentoProvider();
      await reg2.inicializarLocal();
      expect(
        reg2.buscarPorEtiqueta('Art. 50 - Patios y Bicicletas')?.resumen,
        'Estacionar solo en el rack B del sótano.',
      );

      await reg2.eliminarArticulo(creado.id);
      expect(reg2.articulos.length, kReglamentoInterno.length);
    });

    test('MediadorIaService respaldo local aplica Método Harvard y reglamento',
        () async {
      const ia = MediadorIaService();
      final sugerencia = await ia.mejorarArgumentoHarvard(
        categoria: 'Ruido',
        propuesta: 'Mantener música moderada desde las 10:00 p.m.',
        borradorArgumento: 'Necesitamos descansar.',
        reglamento: kReglamentoInterno,
        interesPropio: 'Descansar antes del trabajo',
        interesContraparte: 'Disfrutar música en casa',
        intentarNube: false,
      );

      expect(sugerencia.esGeminiNube, isFalse);
      expect(sugerencia.argumentoMejorado.length, greaterThanOrEqualTo(15));
      expect(sugerencia.criterioSugerido, contains('Art. 14'));

      final neg = NegociacionModel(
        id: 'neg-ia',
        titulo: 'Uso de cochera contigua',
        categoria: 'Cochera',
        descripcionProblema: 'Cierre cercano al límite.',
        dptoSolicitante: kDpto301,
        dptoReceptor: kDpto402,
        esAnonimo: false,
        interesSolicitante: 'Subir con mis hijos cómodamente.',
        interesReceptor: 'Estacionar sin maniobras extra.',
        condiciones: const [],
        estadoGeneral: EstadoNegociacion.enNegociacion,
        fechaCreacion: DateTime(2026, 11, 25),
      );
      final respuesta = await ia.consultarMediador(
        negociacion: neg,
        rolActivo: kDpto301,
        consultaUsuario: '¿Qué artículo del reglamento aplica?',
        reglamento: kReglamentoInterno,
        intentarNube: false,
      );
      expect(respuesta.esGeminiNube, isFalse);
      expect(respuesta.respuesta, contains('Art. 22'));
    });

    testWidgets(
        'Flujo Demo: AuthScreen -> Admin crea reglamento -> Vecino ve artículo y usa Mediador IA',
        (tester) async {
      final auth = AuthProvider();
      await tester.runAsync(auth.inicializar);

      await tester.pumpWidget(AcuerdoVecinalApp(authOverride: auth));
      await tester.pumpAndSettle();

      expect(find.text('Conectar Supabase e Ingresar'), findsOneWidget);
      await tester.ensureVisible(find.text('Demo Admin'));
      await tester.pumpAndSettle();
      expect(find.text('Demo Admin'), findsOneWidget);

      await tester.tap(find.text('Demo Admin'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Artículo'), findsOneWidget);
      await tester.tap(find.text('Nuevo Artículo'));
      await tester.pumpAndSettle();

      final adminFields = find.byType(TextFormField);
      await tester.enterText(adminFields.at(0), 'Art. 99 - Mascotas en Azotea');
      await tester.enterText(
        adminFields.at(1),
        'Las mascotas deben llevar correa en la terraza común.',
      );
      await tester.ensureVisible(find.text('Publicar en Reglamento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar en Reglamento'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();

      final verticalScrollables = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.scrollUntilVisible(
        find.text('Art. 99 - Mascotas en Azotea'),
        200,
        scrollable: verticalScrollables.first,
      );
      expect(find.text('Art. 99 - Mascotas en Azotea'), findsOneWidget);

      await tester.tap(find.text('Vista Vecino'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activos (2)'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consultar Reglamento Interno'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Art. 99 - Mascotas en Azotea'),
        200,
        scrollable: verticalScrollables.last,
      );
      expect(find.text('Art. 99 - Mascotas en Azotea'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Volumen de música y ensayos nocturnos'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mediador IA Harvard'));
      await tester.pumpAndSettle();
      expect(find.text('Mediador IA Harvard'), findsOneWidget);

      await tester.tap(find.text('Sugerir punto medio'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Análisis Harvard'), findsOneWidget);
    });

    test('SupabaseService inicializa cliente con flujo implícito sin PKCE nulo',
        () async {
      const cfg = SupabaseRuntimeConfig(
        url: 'https://demo-project.supabase.co/rest/v1/',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy-anon-key',
      );
      expect(cfg.normalizedUrl, 'https://demo-project.supabase.co');

      final service = SupabaseService();
      await service.inicializar(cfg);
      expect(service.estaListo, isTrue);
      expect(service.configActual?.isConfigured, isTrue);
      await service.inicializar(null);
      expect(service.estaListo, isFalse);
    });

    testWidgets(
        'ActaAcuerdoScreen abre Previsualizar PDF dentro de la app sin salir',
        (tester) async {
      final provider = NegociacionProvider();
      await provider.inicializar();

      await provider.registrarFirmaParticipante(
        negociacionId: 'demo-caso-2',
        firmaBase64: _samplePngBase64,
      );
      await provider.alternarRol();
      await provider.registrarFirmaParticipante(
        negociacionId: 'demo-caso-2',
        firmaBase64: _samplePngBase64,
      );

      await tester.pumpWidget(AcuerdoVecinalApp(providerOverride: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Formalizados (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uso del límite de cochera sótano 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver Acta / PDF'));
      await tester.pumpAndSettle();

      expect(find.text('Previsualizar PDF'), findsOneWidget);
      await tester.tap(find.text('Previsualizar PDF'));
      await tester.pump();
      await _esperarHasta(
        tester,
        () => find.textContaining('KB').evaluate().isNotEmpty,
      );

      expect(find.text('Vista Previa PDF'), findsOneWidget);
      expect(find.textContaining('ACTA-'), findsAtLeastNWidgets(1));
      expect(
        find.textContaining('Documento A4 verificable'),
        findsOneWidget,
      );
    });

    testWidgets(
        'AuthScreen oculta configuración de servidor cuando está compilado para producción',
        (tester) async {
      final authProd = AuthProvider(configuradoPorEntornoOverride: true);
      await tester.runAsync(authProd.inicializar);

      await tester.pumpWidget(AcuerdoVecinalApp(authOverride: authProd));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Configurar servidor (desarrollo)'), findsNothing);
      expect(find.text('Nube lista'), findsNothing);
    });
  });
}
