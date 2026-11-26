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
                  : 'Redactado por Gemini Flash con enfoque Harvard.',
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
          'Tip: puedes usar el botón "Mejorar con IA" al contraofertar para insertarlo directo.';
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
