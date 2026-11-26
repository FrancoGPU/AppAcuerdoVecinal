import '../core/constants/reglamento_data.dart';
import '../models/condicion_model.dart';
import '../models/mensaje_chat_model.dart';
import '../models/negociacion_model.dart';
import 'supabase_service.dart';

/// Output returned when the AI Mediator refines a persuasive argument and matches a bylaw.
class SugerenciaArgumentoIa {
  const SugerenciaArgumentoIa({
    required this.argumentoMejorado,
    required this.criterioSugerido,
    required this.explicacionBreve,
    required this.esGeminiNube,
  });

  final String argumentoMejorado;
  final String criterioSugerido;
  final String explicacionBreve;
  final bool esGeminiNube;
}

/// Complete structured Harvard-method negotiation fields generated from natural complaint text.
class CasoEstructuradoIa {
  const CasoEstructuradoIa({
    required this.titulo,
    required this.categoria,
    required this.descripcionProblema,
    required this.interesSolicitante,
    required this.tituloClausula,
    required this.descripcionPropuesta,
    required this.criterioObjetivo,
    required this.argumentoPersuasivo,
    required this.esGeminiNube,
    this.fueraDeAlcance = false,
    this.motivoFueraDeAlcance,
  });

  final String titulo;
  final String categoria;
  final String descripcionProblema;
  final String interesSolicitante;
  final String tituloClausula;
  final String descripcionPropuesta;
  final String criterioObjetivo;
  final String argumentoPersuasivo;
  final bool esGeminiNube;
  final bool fueraDeAlcance;
  final String? motivoFueraDeAlcance;
}

/// Complete balanced counter-offer suggested by the AI Mediator.
class ContrapropuestaSugeridaIa {
  const ContrapropuestaSugeridaIa({
    required this.nuevaPropuesta,
    required this.criterioSugerido,
    required this.argumentoMejorado,
    required this.explicacionBreve,
    required this.esGeminiNube,
  });

  final String nuevaPropuesta;
  final String criterioSugerido;
  final String argumentoMejorado;
  final String explicacionBreve;
  final bool esGeminiNube;
}

/// Output returned by the Harvard AI Mediator chat assistant.
class RespuestaMediadorIa {
  const RespuestaMediadorIa({
    required this.respuesta,
    required this.esGeminiNube,
  });

  final String respuesta;
  final bool esGeminiNube;
}

/// Coordinates Gemini Edge Function requests in Cloud mode with a deterministic
/// Harvard-method offline fallback for Demo mode or unavailable networks.
class MediadorIaService {
  const MediadorIaService({SupabaseService? supabaseService})
      : _supabase = supabaseService;

  final SupabaseService? _supabase;

  /// Converts an everyday neighbor complaint into a structured Harvard case.
  Future<CasoEstructuradoIa> estructurarCasoHarvard({
    required String relatoUsuario,
    required List<ArticuloReglamento> reglamento,
    bool intentarNube = true,
  }) async {
    final articulos =
        reglamento.isNotEmpty ? reglamento : kReglamentoInterno;
    final relatoLimpio = relatoUsuario.trim();

    if (intentarNube && (_supabase?.estaListo ?? false)) {
      final data = await _supabase!.invocarMediadorIa({
        'modo': 'estructurar_caso',
        'relatoUsuario': relatoLimpio,
        'categorias': kCategoriasConflicto,
        'reglamentoTexto': reglamentoComoContextoTexto(articulos),
      });

      if (data?['fueraDeAlcance'] == true) {
        final motivo = (data?['motivoRechazo'] as String? ?? '').trim();
        return CasoEstructuradoIa(
          titulo: '',
          categoria: kCategoriasConflicto.last,
          descripcionProblema: '',
          interesSolicitante: '',
          tituloClausula: '',
          descripcionPropuesta: '',
          criterioObjetivo: articulos.last.etiqueta,
          argumentoPersuasivo: '',
          esGeminiNube: true,
          fueraDeAlcance: true,
          motivoFueraDeAlcance: motivo.isNotEmpty
              ? motivo
              : 'Solo puedo estructurar situaciones de convivencia vecinal en el condominio.',
        );
      }

      final titulo = (data?['titulo'] as String? ?? '').trim();
      final desc = (data?['descripcionProblema'] as String? ?? '').trim();
      final interes = (data?['interesSolicitante'] as String? ?? '').trim();
      final clausula = (data?['tituloClausula'] as String? ?? '').trim();
      final propuesta = (data?['descripcionPropuesta'] as String? ?? '').trim();
      final argumento = (data?['argumentoPersuasivo'] as String? ?? '').trim();

      if (titulo.length >= 5 &&
          desc.length >= 10 &&
          interes.length >= 10 &&
          clausula.length >= 4 &&
          propuesta.length >= 10 &&
          argumento.length >= 15) {
        final rawCat = (data?['categoria'] as String? ?? '').trim();
        final catValida = kCategoriasConflicto.contains(rawCat)
            ? rawCat
            : _inferirCategoria(relatoLimpio);

        final rawCrit = (data?['criterioObjetivo'] as String? ?? '').trim();
        final critValido = articulos.any((a) => a.etiqueta == rawCrit)
            ? rawCrit
            : _seleccionarArticuloPorCategoria(catValida, articulos).etiqueta;

        return CasoEstructuradoIa(
          titulo: titulo,
          categoria: catValida,
          descripcionProblema: desc,
          interesSolicitante: interes,
          tituloClausula: clausula,
          descripcionPropuesta: propuesta,
          criterioObjetivo: critValido,
          argumentoPersuasivo: argumento,
          esGeminiNube: true,
        );
      }
    }

    return _estructurarCasoLocal(
      relatoUsuario: relatoLimpio,
      reglamento: articulos,
    );
  }

  /// Generates a balanced middle-ground counter-offer (proposal + bylaw + argument).
  Future<ContrapropuestaSugeridaIa> sugerirContrapropuestaHarvard({
    required String tituloClausula,
    required String propuestaActual,
    String? motivoRechazo,
    required String categoria,
    required List<ArticuloReglamento> reglamento,
    String interesPropio = '',
    String interesContraparte = '',
    bool intentarNube = true,
  }) async {
    final articulos =
        reglamento.isNotEmpty ? reglamento : kReglamentoInterno;

    if (intentarNube && (_supabase?.estaListo ?? false)) {
      final data = await _supabase!.invocarMediadorIa({
        'modo': 'sugerir_contrapropuesta',
        'tituloClausula': tituloClausula.trim(),
        'propuestaActual': propuestaActual.trim(),
        'motivoRechazo': (motivoRechazo ?? '').trim(),
        'categoria': categoria,
        'interesPropio': interesPropio.trim(),
        'interesContraparte': interesContraparte.trim(),
        'reglamentoTexto': reglamentoComoContextoTexto(articulos),
      });

      final nuevaPropuesta = (data?['nuevaPropuesta'] as String? ?? '').trim();
      final argumento = (data?['argumentoMejorado'] as String? ?? '').trim();
      if (nuevaPropuesta.length >= 10 && argumento.length >= 15) {
        final rawCrit = (data?['criterioSugerido'] as String? ?? '').trim();
        final critValido = articulos.any((a) => a.etiqueta == rawCrit)
            ? rawCrit
            : _seleccionarArticuloPorCategoria(categoria, articulos).etiqueta;
        return ContrapropuestaSugeridaIa(
          nuevaPropuesta: nuevaPropuesta,
          criterioSugerido: critValido,
          argumentoMejorado: argumento,
          explicacionBreve:
              (data?['explicacionBreve'] as String? ?? '').trim().isNotEmpty
                  ? (data!['explicacionBreve'] as String).trim()
                  : 'Punto medio sugerido por Gemini IA.',
          esGeminiNube: true,
        );
      }
    }

    return _sugerirContrapropuestaLocal(
      tituloClausula: tituloClausula,
      propuestaActual: propuestaActual,
      motivoRechazo: motivoRechazo,
      categoria: categoria,
      reglamento: articulos,
      interesPropio: interesPropio,
      interesContraparte: interesContraparte,
    );
  }

  /// Enhances a persuasive argument and suggests the closest bylaw article.
  Future<SugerenciaArgumentoIa> mejorarArgumentoHarvard({
    required String categoria,
    required String propuesta,
    required String borradorArgumento,
    required List<ArticuloReglamento> reglamento,
    String interesPropio = '',
    String interesContraparte = '',
    bool intentarNube = true,
  }) async {
    final articulos =
        reglamento.isNotEmpty ? reglamento : kReglamentoInterno;
    final contextoReglamento = reglamentoComoContextoTexto(articulos);

    if (intentarNube && (_supabase?.estaListo ?? false)) {
      final data = await _supabase!.invocarMediadorIa({
        'modo': 'mejorar_argumento',
        'categoria': categoria,
        'propuesta': propuesta.trim(),
        'borradorArgumento': borradorArgumento.trim(),
        'interesPropio': interesPropio.trim(),
        'interesContraparte': interesContraparte.trim(),
        'reglamentoTexto': contextoReglamento,
      });

      final argumento = (data?['argumentoMejorado'] as String? ?? '').trim();
      final criterio = (data?['criterioSugerido'] as String? ?? '').trim();
      if (argumento.length >= 15) {
        final criterioValido = articulos.any((a) => a.etiqueta == criterio)
            ? criterio
            : _seleccionarArticuloPorCategoria(categoria, articulos).etiqueta;
        return SugerenciaArgumentoIa(
          argumentoMejorado: argumento,
          criterioSugerido: criterioValido,
          explicacionBreve:
              (data?['explicacionBreve'] as String? ?? '').trim().isNotEmpty
                  ? (data!['explicacionBreve'] as String).trim()
                  : 'Redactado por Gemini IA con enfoque Harvard.',
          esGeminiNube: true,
        );
      }
    }

    return _mejorarArgumentoLocal(
      categoria: categoria,
      propuesta: propuesta,
      borradorArgumento: borradorArgumento,
      reglamento: articulos,
      interesPropio: interesPropio,
      interesContraparte: interesContraparte,
    );
  }

  /// Generates an impartial Harvard mediation response grounded in the case and bylaws.
  Future<RespuestaMediadorIa> consultarMediador({
    required NegociacionModel negociacion,
    required String rolActivo,
    required String consultaUsuario,
    required List<ArticuloReglamento> reglamento,
    List<MensajeChatModel> historial = const [],
    bool intentarNube = true,
  }) async {
    final articulos =
        reglamento.isNotEmpty ? reglamento : kReglamentoInterno;
    final contextoReglamento = reglamentoComoContextoTexto(articulos);

    if (intentarNube && (_supabase?.estaListo ?? false)) {
      final data = await _supabase!.invocarMediadorIa({
        'modo': 'consulta_mediador',
        'rolActivo': rolActivo,
        'consultaUsuario': consultaUsuario.trim(),
        'reglamentoTexto': contextoReglamento,
        'negociacion': {
          'titulo': negociacion.titulo,
          'categoria': negociacion.categoria,
          'descripcionProblema': negociacion.descripcionProblema,
          'dptoSolicitante': negociacion.dptoSolicitante,
          'dptoReceptor': negociacion.dptoReceptor,
          'interesSolicitante': negociacion.interesSolicitante,
          'interesReceptor': negociacion.interesReceptor,
          'condiciones': negociacion.condiciones
              .map(
                (c) => {
                  'tituloClausula': c.tituloClausula,
                  'descripcionPropuesta': c.descripcionPropuesta,
                  'criterioObjetivo': c.criterioObjetivo,
                  'estado': c.estado.name,
                },
              )
              .toList(),
        },
        'historial': historial
            .map(
              (m) => {
                'texto': m.texto,
                'esUsuario': m.esUsuario,
              },
            )
            .toList(),
      });

      final respuesta = (data?['respuesta'] as String? ?? '').trim();
      if (respuesta.isNotEmpty) {
        return RespuestaMediadorIa(
          respuesta: respuesta,
          esGeminiNube: true,
        );
      }
    }

    return RespuestaMediadorIa(
      respuesta: _consultarMediadorLocal(
        negociacion: negociacion,
        rolActivo: rolActivo,
        consultaUsuario: consultaUsuario,
        reglamento: articulos,
      ),
      esGeminiNube: false,
    );
  }

  String _inferirCategoria(String texto) {
    final lower = texto.toLowerCase();
    if (lower.contains('ruido') ||
        lower.contains('música') ||
        lower.contains('musica') ||
        lower.contains('volumen') ||
        lower.contains('fiesta') ||
        lower.contains('guitarra') ||
        lower.contains('noche')) {
      return 'Ruido';
    }
    if (lower.contains('mascota') ||
        lower.contains('perro') ||
        lower.contains('gato') ||
        lower.contains('ladrido') ||
        lower.contains('correa')) {
      return 'Mascotas';
    }
    if (lower.contains('cochera') ||
        lower.contains('estacionamiento') ||
        lower.contains('auto') ||
        lower.contains('camioneta') ||
        lower.contains('carro')) {
      return 'Cochera';
    }
    if (lower.contains('parrilla') ||
        lower.contains('terraza') ||
        lower.contains('ascensor') ||
        lower.contains('pasadizo') ||
        lower.contains('área') ||
        lower.contains('area')) {
      return 'Áreas Comunes';
    }
    return 'Otros';
  }

  bool _esConsultaFueraDeAlcance(String texto) {
    final lower = texto.toLowerCase();
    const enDominio = [
      'vecin',
      'dpto',
      'departamento',
      'edificio',
      'condominio',
      'reglamento',
      'artículo',
      'articulo',
      'ruido',
      'música',
      'musica',
      'bulla',
      'mascota',
      'perro',
      'gato',
      'cochera',
      'estacionamiento',
      'auto',
      'carro',
      'área',
      'area',
      'pasadizo',
      'ascensor',
      'terraza',
      'parrilla',
      'acuerdo',
      'cláusula',
      'clausula',
      'propuesta',
      'contrapropuesta',
      'contraoferta',
      'negoci',
      'mediad',
      'harvard',
      'punto medio',
      'criterio',
      'acta',
      'firma',
      'interés',
      'interes',
      'concilia',
      'conflicto',
      'convivencia',
      'horario',
      'silencio',
      'limpieza',
      'basura',
      'agua',
      'filtraci',
      'olor',
      'humo',
      'fiesta',
      'balcón',
      'balcon',
      'puerta',
      'llave',
      'portón',
      'porton',
      'administr',
      'multa',
      'sanción',
      'sancion',
      'reclamo',
      'queja',
      'empat',
      'redact',
      'tono',
      'solución',
      'solucion',
    ];
    for (final palabra in enDominio) {
      if (lower.contains(palabra)) return false;
    }

    const fueraDeDominio = [
      'programar',
      'hola mundo',
      'hello world',
      'código',
      'codigo',
      'python',
      'javascript',
      'java',
      'html',
      'css',
      'flutter',
      'dart',
      'sql',
      'algoritmo',
      'compilar',
      'receta',
      'cocinar',
      'ingredientes',
      'chiste',
      'poema',
      'canción',
      'cancion',
      'película',
      'pelicula',
      'fútbol',
      'futbol',
      'partido',
      'clima',
      'temperatura',
      'capital de',
      'quién ganó',
      'quien gano',
      'cuánto es',
      'cuanto es',
      'ecuación',
      'ecuacion',
      'derivada',
      'integral',
      'traduce',
      'traducir',
      'bitcoin',
      'cripto',
      'horóscopo',
      'horoscopo',
      'videojuego',
      'minecraft',
      'fortnite',
    ];
    for (final palabra in fueraDeDominio) {
      if (lower.contains(palabra)) return true;
    }
    return false;
  }

  CasoEstructuradoIa _estructurarCasoLocal({
    required String relatoUsuario,
    required List<ArticuloReglamento> reglamento,
  }) {
    if (_esConsultaFueraDeAlcance(relatoUsuario)) {
      return CasoEstructuradoIa(
        titulo: '',
        categoria: kCategoriasConflicto.last,
        descripcionProblema: '',
        interesSolicitante: '',
        tituloClausula: '',
        descripcionPropuesta: '',
        criterioObjetivo: reglamento.last.etiqueta,
        argumentoPersuasivo: '',
        esGeminiNube: false,
        fueraDeAlcance: true,
        motivoFueraDeAlcance:
            'Solo puedo estructurar situaciones de convivencia vecinal en el condominio (ruido, mascotas, cochera, áreas comunes u otros acuerdos entre vecinos).',
      );
    }

    final cat = _inferirCategoria(relatoUsuario);
    final art = _seleccionarArticuloPorCategoria(cat, reglamento);

    final String titulo;
    final String interes;
    final String clausula;
    final String propuesta;

    switch (cat) {
      case 'Ruido':
        titulo = 'Coordinación de horarios y niveles de ruido';
        interes =
            'Proteger el descanso nocturno y el bienestar en el hogar sin impedir actividades diurnas.';
        clausula = 'Franja de silencio entre semana y fines de semana';
        propuesta =
            'Mantener un volumen moderado desde las 10:00 p.m. de domingo a jueves y acordar un horario tope los fines de semana.';
      case 'Mascotas':
        titulo = 'Convivencia responsable con mascotas';
        interes =
            'Garantizar la seguridad de los residentes y el cuidado tranquilo de las mascotas en el edificio.';
        clausula = 'Uso de correa y control en zonas compartidas';
        propuesta =
            'Transitar con correa en ascensores y pasadizos comunes y evitar permanencia prolongada en balcones durante la noche.';
      case 'Cochera':
        titulo = 'Uso ordenado de límites en estacionamiento';
        interes =
            'Facilitar el ingreso, salida y apertura segura de puertas de ambos vehículos.';
        clausula = 'Estacionamiento centrado dentro de las líneas';
        propuesta =
            'Alinear ambos vehículos dejando margen suficiente respecto a la línea divisoria para permitir el ascenso cómodo.';
      case 'Áreas Comunes':
        titulo = 'Uso compartido de áreas comunes';
        interes =
            'Disfrutar de los espacios compartidos con orden, limpieza y respeto a todos los vecinos.';
        clausula = 'Reserva previa y horario de cierre de espacio común';
        propuesta =
            'Coordinar reserva anticipada y entregar el área limpia y en silencio antes de las 11:00 p.m.';
      default:
        titulo = 'Acuerdo preventivo de buena convivencia';
        interes =
            'Resolver el incidente de manera oportuna cuidando la tranquilidad y el respeto mutuo entre departamentos.';
        clausula = 'Compromiso de solución y seguimiento vecinal';
        propuesta =
            'Acordar medidas concretas y plazos claros para atender la situación dentro de los próximos 7 días.';
    }

    final descripcionBase = relatoUsuario.length >= 12
        ? 'Situación reportada de manera objetiva: ${_asegurarPuntoFinal(relatoUsuario)} Se busca canalizar una solución pacífica mediante diálogo estructurado.'
        : 'Situación vecinal vinculada a $cat que requiere definir acuerdos claros entre ambas viviendas.';

    return CasoEstructuradoIa(
      titulo: titulo,
      categoria: cat,
      descripcionProblema: descripcionBase,
      interesSolicitante: interes,
      tituloClausula: clausula,
      descripcionPropuesta: propuesta,
      criterioObjetivo: art.etiqueta,
      argumentoPersuasivo:
          'Esta propuesta protege las necesidades de ambos hogares mediante reglas claras respaldadas en ${art.etiqueta}, evitando multas o tensiones vecinales.',
      esGeminiNube: false,
    );
  }

  ContrapropuestaSugeridaIa _sugerirContrapropuestaLocal({
    required String tituloClausula,
    required String propuestaActual,
    String? motivoRechazo,
    required String categoria,
    required List<ArticuloReglamento> reglamento,
    required String interesPropio,
    required String interesContraparte,
  }) {
    final art = _seleccionarArticuloPorCategoria(categoria, reglamento);
    final motivoLimpio = (motivoRechazo ?? '').trim();

    final nuevaPropuesta = motivoLimpio.isNotEmpty
        ? 'Ajustar "$tituloClausula" contemplando la observación ("${_acortar(motivoLimpio, 55)}") con horarios definidos de común acuerdo y revisión a los 15 días.'
        : 'Aplicar "$tituloClausula" de forma gradual y flexible: respetar el criterio base entre semana y habilitar margen acordado los fines de semana.';

    final argumento = (interesPropio.trim().isNotEmpty &&
            interesContraparte.trim().isNotEmpty)
        ? 'Esta alternativa equilibra "${_acortar(interesPropio, 50)}" con "${_acortar(interesContraparte, 50)}", tomando como marco neutral ${art.etiqueta}.'
        : 'Busca un punto de encuentro práctico que recoge las inquietudes planteadas y se apoya en ${art.etiqueta} para beneficio mutuo.';

    return ContrapropuestaSugeridaIa(
      nuevaPropuesta: nuevaPropuesta,
      criterioSugerido: art.etiqueta,
      argumentoMejorado: argumento,
      explicacionBreve:
          'Integra el reparo anterior y las necesidades de ambas viviendas.',
      esGeminiNube: false,
    );
  }

  ArticuloReglamento _seleccionarArticuloPorCategoria(
    String categoria,
    List<ArticuloReglamento> articulos,
  ) {
    for (final art in articulos) {
      if (art.categoria.toLowerCase() == categoria.toLowerCase()) {
        return art;
      }
    }
    return articulos.last;
  }

  SugerenciaArgumentoIa _mejorarArgumentoLocal({
    required String categoria,
    required String propuesta,
    required String borradorArgumento,
    required List<ArticuloReglamento> reglamento,
    required String interesPropio,
    required String interesContraparte,
  }) {
    final articulo = _seleccionarArticuloPorCategoria(categoria, reglamento);
    final propuestaLimpia = propuesta.trim();
    final borradorLimpio = borradorArgumento.trim();

    final partes = <String>[];
    if (propuestaLimpia.isNotEmpty) {
      partes.add(
        'Esta propuesta busca una solución equilibrada y verificable sin afectar la buena convivencia del edificio.',
      );
    } else {
      partes.add(
        'Buscamos una medida práctica que proteja las necesidades de ambas viviendas con respeto mutuo.',
      );
    }

    if (interesPropio.trim().isNotEmpty &&
        interesContraparte.trim().isNotEmpty) {
      partes.add(
        'Atiende tanto "${_acortar(interesPropio, 60)}" como "${_acortar(interesContraparte, 60)}".',
      );
    } else if (borradorLimpio.length >= 10) {
      partes.add(_asegurarPuntoFinal(borradorLimpio));
    }

    partes.add(
      'Se respalda objetivamente en ${articulo.etiqueta} (${_acortar(articulo.resumen, 95)}).',
    );

    return SugerenciaArgumentoIa(
      argumentoMejorado: partes.join(' '),
      criterioSugerido: articulo.etiqueta,
      explicacionBreve:
          'Alinea intereses compartidos y cita un criterio objetivo del reglamento vigente.',
      esGeminiNube: false,
    );
  }

  String _consultarMediadorLocal({
    required NegociacionModel negociacion,
    required String rolActivo,
    required String consultaUsuario,
    required List<ArticuloReglamento> reglamento,
  }) {
    if (_esConsultaFueraDeAlcance(consultaUsuario)) {
      return 'Solo puedo orientarte sobre convivencia vecinal, el Reglamento Interno y el Método Harvard aplicados al caso "${negociacion.titulo}". ¿Quieres revisar qué artículo aplica o explorar un punto medio?';
    }

    final articulo = _seleccionarArticuloPorCategoria(
      negociacion.categoria,
      reglamento,
    );
    final query = consultaUsuario.toLowerCase();
    final pendientes = negociacion.condiciones
        .where((c) => c.estado != EstadoCondicion.aceptada)
        .toList();

    if (query.contains('reglamento') ||
        query.contains('artículo') ||
        query.contains('articulo') ||
        query.contains('criterio')) {
      return 'Para "${negociacion.titulo}" (${negociacion.categoria}), el criterio objetivo más directo es:\n'
          '• ${articulo.etiqueta}\n'
          '• Alcance: ${articulo.resumen}\n\n'
          'Sugerencia Harvard: cita esta norma como marco neutral en lugar de exigir concesiones personales.';
    }

    if (query.contains('redact') ||
        query.contains('propuesta') ||
        query.contains('empat')) {
      final foco = pendientes.isNotEmpty
          ? pendientes.first.tituloClausula
          : negociacion.titulo;
      return 'Propuesta constructiva sugerida para "$foco":\n'
          '"Comprendo tu necesidad de mantener tu rutina y propongo acordar horarios claros respaldados en ${articulo.etiqueta}, '
          'de modo que ambos hogares ganemos tranquilidad sin llegar a sanciones."\n\n'
          'Tip: puedes usar el botón "Sugerir punto medio con IA" al contraofertar para insertarlo directo.';
    }

    final intSol = negociacion.interesSolicitante.trim().isNotEmpty
        ? _acortar(negociacion.interesSolicitante, 70)
        : 'tranquilidad y orden';
    final intRec = negociacion.interesReceptor.trim().isNotEmpty
        ? _acortar(negociacion.interesReceptor, 70)
        : 'respetar su autonomía sin conflictos';

    return 'Análisis Harvard para $rolActivo sobre "${negociacion.titulo}":\n'
        '1. Intereses en juego: $intSol ↔ $intRec.\n'
        '2. Base objetiva aplicable: ${articulo.etiqueta}.\n'
        '3. Siguiente paso: ${pendientes.isEmpty ? "Todas las cláusulas están aceptadas; ya pueden pasar a firma del Acta." : "Propón una franja horaria o límite concreto sobre \"${pendientes.first.tituloClausula}\" que cubra ambos intereses."}';
  }

  String _acortar(String text, int max) {
    final clean = text.trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max - 1)}…';
  }

  String _asegurarPuntoFinal(String text) {
    if (text.endsWith('.') || text.endsWith('!')) return text;
    return '$text.';
  }
}
