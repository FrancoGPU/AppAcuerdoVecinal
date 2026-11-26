import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/reglamento_data.dart';
import '../data/local_storage_service.dart';
import '../data/mock_negociaciones.dart';
import '../models/condicion_model.dart';
import '../models/mensaje_chat_model.dart';
import '../models/negociacion_model.dart';
import '../models/usuario_model.dart';
import '../services/mediador_ia_service.dart';
import '../services/supabase_service.dart';

/// Central state management and business rules for neighborhood negotiations,
/// supporting both Supabase Cloud Realtime and offline Local Demo mode.
class NegociacionProvider extends ChangeNotifier {
  NegociacionProvider({
    LocalStorageService? storageService,
    Uuid? uuid,
    SupabaseService? supabaseService,
    MediadorIaService? mediadorIaService,
  })  : _storage = storageService ?? LocalStorageService(),
        _uuid = uuid ?? const Uuid(),
        _supabase = supabaseService,
        _mediadorIa = mediadorIaService ??
            MediadorIaService(supabaseService: supabaseService);

  final LocalStorageService _storage;
  final Uuid _uuid;
  final SupabaseService? _supabase;
  final MediadorIaService _mediadorIa;

  List<NegociacionModel> _negociaciones = [];
  String _rolActivo = kDpto301;
  bool _cargando = true;
  bool _esModoNube = false;
  PerfilUsuario? _usuarioActual;
  RealtimeChannel? _canalNegociaciones;

  final Map<String, List<MensajeChatModel>> _chatsMediador = {};
  bool _consultandoIa = false;

  List<NegociacionModel> get negociaciones => List.unmodifiable(_negociaciones);
  String get rolActivo => _rolActivo;
  bool get cargando => _cargando;
  bool get esModoNube => _esModoNube;
  bool get consultandoIa => _consultandoIa;
  MediadorIaService get mediadorIa => _mediadorIa;

  String get otroDepartamento => _rolActivo == kDpto301 ? kDpto402 : kDpto301;

  List<NegociacionModel> get activos => _negociaciones
      .where((n) => n.estadoGeneral != EstadoNegociacion.formalizada)
      .toList();

  List<NegociacionModel> get formalizados => _negociaciones
      .where((n) => n.estadoGeneral == EstadoNegociacion.formalizada)
      .toList();

  List<MensajeChatModel> mensajesMediadorPara(String negociacionId) =>
      List.unmodifiable(_chatsMediador[negociacionId] ?? const []);

  NegociacionModel? obtenerPorId(String id) {
    for (final item in _negociaciones) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Syncs negotiations with the authenticated cloud user or local demo session.
  Future<void> sincronizarConSesion({
    PerfilUsuario? usuario,
    required bool esNube,
  }) async {
    await _limpiarCanal();
    _usuarioActual = usuario;
    _esModoNube =
        esNube && usuario != null && (_supabase?.estaListo ?? false);

    if (_esModoNube) {
      _cargando = true;
      _rolActivo = usuario!.esAdmin ? 'Administración' : usuario.departamento;
      notifyListeners();

      try {
        _negociaciones =
            await _supabase!.cargarNegociaciones(usuario.condominioId);
        _canalNegociaciones = _supabase.suscribirNegociaciones(
          usuario.condominioId,
          _recargarDesdeNube,
        );
      } finally {
        _cargando = false;
        notifyListeners();
      }
      return;
    }

    await inicializar();
  }

  Future<void> _recargarDesdeNube() async {
    final usuario = _usuarioActual;
    if (!_esModoNube || usuario == null || _supabase == null) return;
    try {
      _negociaciones =
          await _supabase.cargarNegociaciones(usuario.condominioId);
      notifyListeners();
    } catch (_) {}
  }

  /// Loads persisted negotiations and role, seeding demo data on first launch.
  Future<void> inicializar() async {
    _cargando = true;

    final rolGuardado = await _storage.cargarRolActivo();
    if (rolGuardado == kDpto301 || rolGuardado == kDpto402) {
      _rolActivo = rolGuardado!;
    }

    final guardadas = await _storage.cargarNegociaciones();
    if (guardadas == null) {
      _negociaciones = generarNegociacionesDemo();
      await _storage.guardarNegociaciones(_negociaciones);
    } else {
      _negociaciones = guardadas;
    }

    _cargando = false;
    notifyListeners();
  }

  /// Resets stored cases back to the initial demonstration seed data.
  Future<void> restaurarDatosDemo() async {
    if (_esModoNube) return;
    _negociaciones = generarNegociacionesDemo();
    await _storage.guardarNegociaciones(_negociaciones);
    notifyListeners();
  }

  /// Toggles the simulated active department between Dpto. 301 and Dpto. 402
  /// in Local Demo mode. Disabled in authenticated Cloud mode.
  Future<void> alternarRol() async {
    if (_esModoNube) return;
    _rolActivo = otroDepartamento;
    await _storage.guardarRolActivo(_rolActivo);
    notifyListeners();
  }

  /// Returns true when the active role can accept/reject/counter an offer.
  bool puedeEvaluarCondicion(
    CondicionModel condicion,
    NegociacionModel negociacion,
  ) {
    if (negociacion.estaFormalizada) return false;
    if (condicion.estado == EstadoCondicion.aceptada) return false;
    return condicion.autorUltimaOferta != _rolActivo;
  }

  /// Returns true when the active role may submit a counter-offer or reformulate.
  bool puedeContraofertarCondicion(
    CondicionModel condicion,
    NegociacionModel negociacion,
  ) {
    if (negociacion.estaFormalizada) return false;
    if (condicion.estado == EstadoCondicion.aceptada) return false;
    return condicion.autorUltimaOferta != _rolActivo ||
        condicion.estado == EstadoCondicion.rechazada;
  }

  /// Creates a new negotiation case with its initial condition and persists it.
  Future<NegociacionModel> crearNegociacion({
    required String titulo,
    required String categoria,
    required String descripcionProblema,
    required bool esAnonimo,
    required String interesSolicitante,
    required String tituloClausulaInicial,
    required String descripcionPropuestaInicial,
    required String criterioObjetivoInicial,
    required String argumentoPersuasivoInicial,
    String? dptoReceptorOverride,
    String? receptorIdOverride,
  }) async {
    final nuevaCondicion = CondicionModel(
      id: _uuid.v4(),
      tituloClausula: tituloClausulaInicial.trim(),
      descripcionPropuesta: descripcionPropuestaInicial.trim(),
      criterioObjetivo: criterioObjetivoInicial,
      argumentoPersuasivo: argumentoPersuasivoInicial.trim(),
      autorUltimaOferta: _rolActivo,
      estado: EstadoCondicion.pendiente,
    );

    final nueva = NegociacionModel(
      id: _uuid.v4(),
      titulo: titulo.trim(),
      categoria: categoria,
      descripcionProblema: descripcionProblema.trim(),
      dptoSolicitante: _rolActivo,
      dptoReceptor: dptoReceptorOverride ?? otroDepartamento,
      esAnonimo: esAnonimo,
      interesSolicitante: interesSolicitante.trim(),
      interesReceptor: '',
      condiciones: [nuevaCondicion],
      estadoGeneral: EstadoNegociacion.enNegociacion,
      fechaCreacion: DateTime.now(),
      condominioId: _esModoNube ? _usuarioActual?.condominioId : null,
      solicitanteId: _esModoNube ? _usuarioActual?.id : null,
      receptorId: _esModoNube ? receptorIdOverride : null,
    );

    if (_esModoNube && _supabase != null) {
      final guardadaNube = await _supabase.crearNegociacion(nueva);
      _negociaciones = [guardadaNube, ..._negociaciones];
      notifyListeners();
      return guardadaNube;
    }

    _negociaciones = [nueva, ..._negociaciones];
    await _storage.guardarNegociaciones(_negociaciones);
    notifyListeners();
    return nueva;
  }

  /// Updates the underlying interest for the currently active party.
  Future<bool> actualizarInteres({
    required String negociacionId,
    required String nuevoInteres,
  }) async {
    final index = _negociaciones.indexWhere((n) => n.id == negociacionId);
    if (index == -1) return false;

    final actual = _negociaciones[index];
    if (actual.estaFormalizada) return false;

    final limpio = nuevoInteres.trim();
    if (limpio.isEmpty) return false;

    final actualizada = _rolActivo == actual.dptoSolicitante
        ? actual.copyWith(interesSolicitante: limpio)
        : actual.copyWith(interesReceptor: limpio);

    return _guardarActualizacion(index, actualizada);
  }

  /// Appends a new negotiable clause while the case is still open.
  Future<bool> agregarCondicion({
    required String negociacionId,
    required String tituloClausula,
    required String descripcionPropuesta,
    required String criterioObjetivo,
    required String argumentoPersuasivo,
  }) async {
    final index = _negociaciones.indexWhere((n) => n.id == negociacionId);
    if (index == -1) return false;

    final actual = _negociaciones[index];
    if (actual.estaFormalizada) return false;

    final nuevaCondicion = CondicionModel(
      id: _uuid.v4(),
      tituloClausula: tituloClausula.trim(),
      descripcionPropuesta: descripcionPropuesta.trim(),
      criterioObjetivo: criterioObjetivo,
      argumentoPersuasivo: argumentoPersuasivo.trim(),
      autorUltimaOferta: _rolActivo,
      estado: EstadoCondicion.pendiente,
    );

    final condicionesActualizadas = [...actual.condiciones, nuevaCondicion];
    final actualizada = actual.copyWith(
      condiciones: condicionesActualizadas,
      estadoGeneral: EstadoNegociacion.enNegociacion,
    );

    return _guardarActualizacion(index, actualizada);
  }

  /// Accepts a pending or rejected condition if offered by the counterpart.
  Future<bool> aceptarCondicion({
    required String negociacionId,
    required String condicionId,
  }) async {
    final index = _negociaciones.indexWhere((n) => n.id == negociacionId);
    if (index == -1) return false;

    final actual = _negociaciones[index];
    if (actual.estaFormalizada) return false;

    final condIndex =
        actual.condiciones.indexWhere((c) => c.id == condicionId);
    if (condIndex == -1) return false;

    final condicion = actual.condiciones[condIndex];
    if (condicion.autorUltimaOferta == _rolActivo) return false;

    final nuevasCondiciones = [...actual.condiciones];
    nuevasCondiciones[condIndex] = condicion.copyWith(
      estado: EstadoCondicion.aceptada,
      limpiarMotivoRechazo: true,
    );

    final todasAceptadas = nuevasCondiciones.isNotEmpty &&
        nuevasCondiciones.every((c) => c.estado == EstadoCondicion.aceptada);

    final actualizada = actual.copyWith(
      condiciones: nuevasCondiciones,
      estadoGeneral: todasAceptadas
          ? EstadoNegociacion.listoParaFirmar
          : EstadoNegociacion.enNegociacion,
    );

    return _guardarActualizacion(index, actualizada);
  }

  /// Rejects a condition with a mandatory explanation if offered by counterpart.
  Future<bool> rechazarCondicion({
    required String negociacionId,
    required String condicionId,
    required String motivoRechazo,
  }) async {
    final motivoLimpio = motivoRechazo.trim();
    if (motivoLimpio.isEmpty) return false;

    final index = _negociaciones.indexWhere((n) => n.id == negociacionId);
    if (index == -1) return false;

    final actual = _negociaciones[index];
    if (actual.estaFormalizada) return false;

    final condIndex =
        actual.condiciones.indexWhere((c) => c.id == condicionId);
    if (condIndex == -1) return false;

    final condicion = actual.condiciones[condIndex];
    if (condicion.autorUltimaOferta == _rolActivo) return false;

    final nuevasCondiciones = [...actual.condiciones];
    nuevasCondiciones[condIndex] = condicion.copyWith(
      estado: EstadoCondicion.rechazada,
      motivoRechazo: motivoLimpio,
    );

    final actualizada = actual.copyWith(
      condiciones: nuevasCondiciones,
      estadoGeneral: EstadoNegociacion.enNegociacion,
    );

    return _guardarActualizacion(index, actualizada);
  }

  /// Submits a counter-offer, archiving the previous round into history.
  Future<bool> contraofertarCondicion({
    required String negociacionId,
    required String condicionId,
    required String nuevaPropuesta,
    required String nuevoCriterioObjetivo,
    required String nuevoArgumentoPersuasivo,
    String? interesReceptorOpcional,
  }) async {
    final index = _negociaciones.indexWhere((n) => n.id == negociacionId);
    if (index == -1) return false;

    final actual = _negociaciones[index];
    if (actual.estaFormalizada) return false;

    final condIndex =
        actual.condiciones.indexWhere((c) => c.id == condicionId);
    if (condIndex == -1) return false;

    final condicion = actual.condiciones[condIndex];
    if (!puedeContraofertarCondicion(condicion, actual)) return false;

    final rondaArchivada = RondaHistorial(
      propuestaAnterior: condicion.descripcionPropuesta,
      argumentoAnterior: condicion.argumentoPersuasivo,
      autor: condicion.autorUltimaOferta,
      fecha: DateTime.now(),
    );

    final nuevasCondiciones = [...actual.condiciones];
    nuevasCondiciones[condIndex] = condicion.copyWith(
      descripcionPropuesta: nuevaPropuesta.trim(),
      criterioObjetivo: nuevoCriterioObjetivo,
      argumentoPersuasivo: nuevoArgumentoPersuasivo.trim(),
      autorUltimaOferta: _rolActivo,
      estado: EstadoCondicion.pendiente,
      limpiarMotivoRechazo: true,
      historial: [rondaArchivada, ...condicion.historial],
    );

    var interesReceptorActualizado = actual.interesReceptor;
    if (_rolActivo == actual.dptoReceptor &&
        interesReceptorOpcional != null &&
        interesReceptorOpcional.trim().isNotEmpty) {
      interesReceptorActualizado = interesReceptorOpcional.trim();
    }

    final actualizada = actual.copyWith(
      condiciones: nuevasCondiciones,
      interesReceptor: interesReceptorActualizado,
      estadoGeneral: EstadoNegociacion.enNegociacion,
    );

    return _guardarActualizacion(index, actualizada);
  }

  /// Returns how many conditions are awaiting the active role's review.
  int condicionesPorRevisarParaRol(NegociacionModel negociacion) {
    if (negociacion.estaFormalizada) return 0;
    return negociacion.condiciones
        .where(
          (c) =>
              c.estado != EstadoCondicion.aceptada &&
              c.autorUltimaOferta != _rolActivo,
        )
        .length;
  }

  /// Returns true when the case is ready to sign and the active role has not signed yet.
  bool faltaMiFirma(NegociacionModel negociacion) {
    if (negociacion.estaFormalizada || !negociacion.todasCondicionesAceptadas) {
      return false;
    }
    if (_rolActivo == negociacion.dptoSolicitante) {
      return !negociacion.firmadoSolicitante;
    }
    if (_rolActivo == negociacion.dptoReceptor) {
      return !negociacion.firmadoReceptor;
    }
    return false;
  }

  /// Registers the active neighbor's signature and auto-seals once both sign.
  Future<NegociacionModel?> registrarFirmaParticipante({
    required String negociacionId,
    required String firmaBase64,
  }) async {
    final limpia = firmaBase64.trim();
    if (limpia.isEmpty) return null;

    final index = _negociaciones.indexWhere((n) => n.id == negociacionId);
    if (index == -1) return null;

    final actual = _negociaciones[index];
    if (actual.estaFormalizada || !actual.todasCondicionesAceptadas) {
      return null;
    }

    final NegociacionModel conFirma;
    if (_rolActivo == actual.dptoSolicitante) {
      conFirma = actual.copyWith(
        firmadoSolicitante: true,
        firmaSolicitanteBase64: limpia,
      );
    } else if (_rolActivo == actual.dptoReceptor) {
      conFirma = actual.copyWith(
        firmadoReceptor: true,
        firmaReceptorBase64: limpia,
      );
    } else {
      return null;
    }

    final ambosFirmaron =
        conFirma.firmadoSolicitante && conFirma.firmadoReceptor;
    if (!ambosFirmaron) {
      await _guardarActualizacion(index, conFirma);
      return conFirma;
    }

    final ahora = DateTime.now();
    final correlativo =
        (formalizados.length + 1).toString().padLeft(3, '0');
    final codigo = 'ACTA-${ahora.year}-$correlativo';

    final formalizada = conFirma.copyWith(
      estadoGeneral: EstadoNegociacion.formalizada,
      fechaFormalizacion: ahora,
      codigoActa: codigo,
    );

    await _guardarActualizacion(index, formalizada);
    return formalizada;
  }

  /// Seals the negotiation as formalized once 100% of conditions are accepted.
  Future<NegociacionModel?> formalizarAcuerdo({
    required String negociacionId,
    String? firmaSolicitanteBase64,
    String? firmaReceptorBase64,
  }) async {
    final index = _negociaciones.indexWhere((n) => n.id == negociacionId);
    if (index == -1) return null;

    final actual = _negociaciones[index];
    if (actual.estaFormalizada || !actual.todasCondicionesAceptadas) {
      return null;
    }

    final ahora = DateTime.now();
    final correlativo =
        (formalizados.length + 1).toString().padLeft(3, '0');
    final codigo = 'ACTA-${ahora.year}-$correlativo';

    final formalizada = actual.copyWith(
      estadoGeneral: EstadoNegociacion.formalizada,
      fechaFormalizacion: ahora,
      codigoActa: codigo,
      firmadoSolicitante: true,
      firmadoReceptor: true,
      firmaSolicitanteBase64: firmaSolicitanteBase64,
      firmaReceptorBase64: firmaReceptorBase64,
    );

    await _guardarActualizacion(index, formalizada);
    return formalizada;
  }

  /// Loads AI Mediator chat history for [negociacionId].
  Future<void> cargarMensajesMediador(String negociacionId) async {
    if (_esModoNube && _supabase != null) {
      final remotos = await _supabase.cargarMensajesMediador(negociacionId);
      if (remotos.isNotEmpty) {
        _chatsMediador[negociacionId] = remotos;
        notifyListeners();
      }
    }
  }

  /// Sends a question to the Harvard AI Mediator (Gemini cloud or local fallback).
  Future<RespuestaMediadorIa?> enviarConsultaMediador({
    required String negociacionId,
    required String consulta,
    required List<ArticuloReglamento> reglamento,
  }) async {
    final limpio = consulta.trim();
    if (limpio.isEmpty) return null;

    final negociacion = obtenerPorId(negociacionId);
    if (negociacion == null) return null;

    final msgUsuario = MensajeChatModel(
      id: _uuid.v4(),
      negociacionId: negociacionId,
      texto: limpio,
      esUsuario: true,
      fecha: DateTime.now(),
    );

    final actual = [...(_chatsMediador[negociacionId] ?? const <MensajeChatModel>[])];
    actual.add(msgUsuario);
    _chatsMediador[negociacionId] = actual;
    _consultandoIa = true;
    notifyListeners();

    if (_esModoNube && _supabase != null && _usuarioActual != null) {
      await _supabase.guardarMensajeMediador(
        msgUsuario,
        usuarioId: _usuarioActual!.id,
      );
    }

    try {
      final resultado = await _mediadorIa.consultarMediador(
        negociacion: negociacion,
        rolActivo: _rolActivo,
        consultaUsuario: limpio,
        reglamento: reglamento,
        historial: actual,
        intentarNube: _esModoNube,
      );

      final msgIa = MensajeChatModel(
        id: _uuid.v4(),
        negociacionId: negociacionId,
        texto: resultado.respuesta,
        esUsuario: false,
        fecha: DateTime.now(),
      );

      _chatsMediador[negociacionId] = [
        ...(_chatsMediador[negociacionId] ?? const <MensajeChatModel>[]),
        msgIa,
      ];

      if (_esModoNube && _supabase != null && _usuarioActual != null) {
        await _supabase.guardarMensajeMediador(
          msgIa,
          usuarioId: _usuarioActual!.id,
        );
      }

      return resultado;
    } finally {
      _consultandoIa = false;
      notifyListeners();
    }
  }

  Future<bool> _guardarActualizacion(
    int index,
    NegociacionModel actualizada,
  ) async {
    final copia = [..._negociaciones];
    copia[index] = actualizada;
    _negociaciones = copia;

    if (_esModoNube && _supabase != null) {
      notifyListeners();
      try {
        final remota = await _supabase.actualizarNegociacion(actualizada);
        final idxActual =
            _negociaciones.indexWhere((n) => n.id == actualizada.id);
        if (idxActual != -1) {
          final refrescada = [..._negociaciones];
          refrescada[idxActual] = remota;
          _negociaciones = refrescada;
        }
        notifyListeners();
        return true;
      } catch (_) {
        await _recargarDesdeNube();
        return false;
      }
    }

    await _storage.guardarNegociaciones(_negociaciones);
    notifyListeners();
    return true;
  }

  Future<void> _limpiarCanal() async {
    if (_canalNegociaciones != null && _supabase != null) {
      await _supabase.removerCanal(_canalNegociaciones);
      _canalNegociaciones = null;
    }
  }

  @override
  void dispose() {
    if (_canalNegociaciones != null && _supabase != null) {
      _supabase.removerCanal(_canalNegociaciones);
    }
    super.dispose();
  }
}
