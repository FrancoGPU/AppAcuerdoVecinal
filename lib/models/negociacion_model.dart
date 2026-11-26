import 'condicion_model.dart';

/// Lifecycle state of a neighborhood negotiation case.
enum EstadoNegociacion {
  enNegociacion,
  listoParaFirmar,
  formalizada;

  static EstadoNegociacion fromName(String? value) {
    return EstadoNegociacion.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoNegociacion.enNegociacion,
    );
  }
}

/// Core negotiation entity representing a conflict case and its clauses.
class NegociacionModel {
  const NegociacionModel({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.descripcionProblema,
    required this.dptoSolicitante,
    required this.dptoReceptor,
    required this.esAnonimo,
    required this.interesSolicitante,
    required this.interesReceptor,
    required this.condiciones,
    required this.estadoGeneral,
    required this.fechaCreacion,
    this.fechaFormalizacion,
    this.codigoActa,
    this.firmadoSolicitante = false,
    this.firmadoReceptor = false,
    this.firmaSolicitanteBase64,
    this.firmaReceptorBase64,
    this.condominioId,
    this.solicitanteId,
    this.receptorId,
  });

  final String id;
  final String titulo;
  final String categoria;
  final String descripcionProblema;
  final String dptoSolicitante;
  final String dptoReceptor;
  final bool esAnonimo;
  final String interesSolicitante;
  final String interesReceptor;
  final List<CondicionModel> condiciones;
  final EstadoNegociacion estadoGeneral;
  final DateTime fechaCreacion;
  final DateTime? fechaFormalizacion;
  final String? codigoActa;
  final bool firmadoSolicitante;
  final bool firmadoReceptor;
  final String? firmaSolicitanteBase64;
  final String? firmaReceptorBase64;
  final String? condominioId;
  final String? solicitanteId;
  final String? receptorId;

  bool get estaFormalizada => estadoGeneral == EstadoNegociacion.formalizada;

  bool get todasCondicionesAceptadas =>
      condiciones.isNotEmpty &&
      condiciones.every((c) => c.estado == EstadoCondicion.aceptada);

  int get condicionesAceptadasCount =>
      condiciones.where((c) => c.estado == EstadoCondicion.aceptada).length;

  int get condicionesPendientesDeAceptar =>
      condiciones.length - condicionesAceptadasCount;

  /// Masks the requester's apartment label when anonymous mode is enabled.
  String nombreVisiblePara(String departamento, String rolActivo) {
    if (departamento == dptoSolicitante && esAnonimo) {
      return rolActivo == dptoSolicitante
          ? 'Vecino Anónimo (Tú)'
          : 'Vecino Anónimo';
    }
    return departamento;
  }

  NegociacionModel copyWith({
    String? id,
    String? titulo,
    String? categoria,
    String? descripcionProblema,
    String? dptoSolicitante,
    String? dptoReceptor,
    bool? esAnonimo,
    String? interesSolicitante,
    String? interesReceptor,
    List<CondicionModel>? condiciones,
    EstadoNegociacion? estadoGeneral,
    DateTime? fechaCreacion,
    DateTime? fechaFormalizacion,
    String? codigoActa,
    bool? firmadoSolicitante,
    bool? firmadoReceptor,
    String? firmaSolicitanteBase64,
    String? firmaReceptorBase64,
    String? condominioId,
    String? solicitanteId,
    String? receptorId,
  }) {
    return NegociacionModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      categoria: categoria ?? this.categoria,
      descripcionProblema: descripcionProblema ?? this.descripcionProblema,
      dptoSolicitante: dptoSolicitante ?? this.dptoSolicitante,
      dptoReceptor: dptoReceptor ?? this.dptoReceptor,
      esAnonimo: esAnonimo ?? this.esAnonimo,
      interesSolicitante: interesSolicitante ?? this.interesSolicitante,
      interesReceptor: interesReceptor ?? this.interesReceptor,
      condiciones: condiciones ?? this.condiciones,
      estadoGeneral: estadoGeneral ?? this.estadoGeneral,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaFormalizacion: fechaFormalizacion ?? this.fechaFormalizacion,
      codigoActa: codigoActa ?? this.codigoActa,
      firmadoSolicitante: firmadoSolicitante ?? this.firmadoSolicitante,
      firmadoReceptor: firmadoReceptor ?? this.firmadoReceptor,
      firmaSolicitanteBase64:
          firmaSolicitanteBase64 ?? this.firmaSolicitanteBase64,
      firmaReceptorBase64: firmaReceptorBase64 ?? this.firmaReceptorBase64,
      condominioId: condominioId ?? this.condominioId,
      solicitanteId: solicitanteId ?? this.solicitanteId,
      receptorId: receptorId ?? this.receptorId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'categoria': categoria,
        'descripcionProblema': descripcionProblema,
        'dptoSolicitante': dptoSolicitante,
        'dptoReceptor': dptoReceptor,
        'esAnonimo': esAnonimo,
        'interesSolicitante': interesSolicitante,
        'interesReceptor': interesReceptor,
        'condiciones': condiciones.map((c) => c.toJson()).toList(),
        'estadoGeneral': estadoGeneral.name,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaFormalizacion': fechaFormalizacion?.toIso8601String(),
        'codigoActa': codigoActa,
        'firmadoSolicitante': firmadoSolicitante,
        'firmadoReceptor': firmadoReceptor,
        'firmaSolicitanteBase64': firmaSolicitanteBase64,
        'firmaReceptorBase64': firmaReceptorBase64,
        if (condominioId != null) 'condominioId': condominioId,
        if (solicitanteId != null) 'solicitanteId': solicitanteId,
        if (receptorId != null) 'receptorId': receptorId,
      };

  factory NegociacionModel.fromJson(Map<String, dynamic> json) {
    final rawCondiciones = json['condiciones'] as List<dynamic>? ?? const [];
    return NegociacionModel(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'Otros',
      descripcionProblema: json['descripcionProblema'] as String? ?? '',
      dptoSolicitante: json['dptoSolicitante'] as String? ?? '',
      dptoReceptor: json['dptoReceptor'] as String? ?? '',
      esAnonimo: json['esAnonimo'] as bool? ?? false,
      interesSolicitante: json['interesSolicitante'] as String? ?? '',
      interesReceptor: json['interesReceptor'] as String? ?? '',
      condiciones: rawCondiciones
          .whereType<Map<String, dynamic>>()
          .map(CondicionModel.fromJson)
          .toList(),
      estadoGeneral: EstadoNegociacion.fromName(json['estadoGeneral'] as String?),
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] as String? ?? '') ??
              DateTime.now(),
      fechaFormalizacion: json['fechaFormalizacion'] != null
          ? DateTime.tryParse(json['fechaFormalizacion'] as String)
          : null,
      codigoActa: json['codigoActa'] as String?,
      firmadoSolicitante: json['firmadoSolicitante'] as bool? ?? false,
      firmadoReceptor: json['firmadoReceptor'] as bool? ?? false,
      firmaSolicitanteBase64: json['firmaSolicitanteBase64'] as String?,
      firmaReceptorBase64: json['firmaReceptorBase64'] as String?,
      condominioId: json['condominioId'] as String?,
      solicitanteId: json['solicitanteId'] as String?,
      receptorId: json['receptorId'] as String?,
    );
  }

  Map<String, dynamic> toSupabaseMap() => {
        'id': id,
        'condominio_id': condominioId,
        'titulo': titulo,
        'categoria': categoria,
        'descripcion_problema': descripcionProblema,
        'solicitante_id': solicitanteId,
        'receptor_id': receptorId,
        'dpto_solicitante': dptoSolicitante,
        'dpto_receptor': dptoReceptor,
        'es_anonimo': esAnonimo,
        'interes_solicitante': interesSolicitante,
        'interes_receptor': interesReceptor,
        'condiciones': condiciones.map((c) => c.toJson()).toList(),
        'estado_general': estadoGeneral.name,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'fecha_formalizacion': fechaFormalizacion?.toIso8601String(),
        'codigo_acta': codigoActa,
        'firmado_solicitante': firmadoSolicitante,
        'firmado_receptor': firmadoReceptor,
        'firma_solicitante_base64': firmaSolicitanteBase64,
        'firma_receptor_base64': firmaReceptorBase64,
      };

  factory NegociacionModel.fromSupabaseMap(Map<String, dynamic> map) {
    final rawCondiciones = map['condiciones'] as List<dynamic>? ?? const [];
    return NegociacionModel(
      id: map['id']?.toString() ?? '',
      titulo: map['titulo'] as String? ?? '',
      categoria: map['categoria'] as String? ?? 'Otros',
      descripcionProblema: map['descripcion_problema'] as String? ?? '',
      dptoSolicitante: map['dpto_solicitante'] as String? ?? '',
      dptoReceptor: map['dpto_receptor'] as String? ?? '',
      esAnonimo: map['es_anonimo'] as bool? ?? false,
      interesSolicitante: map['interes_solicitante'] as String? ?? '',
      interesReceptor: map['interes_receptor'] as String? ?? '',
      condiciones: rawCondiciones
          .whereType<Map>()
          .map((e) => CondicionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      estadoGeneral: EstadoNegociacion.fromName(map['estado_general'] as String?),
      fechaCreacion:
          DateTime.tryParse(map['fecha_creacion'] as String? ?? '') ??
              DateTime.now(),
      fechaFormalizacion: map['fecha_formalizacion'] != null
          ? DateTime.tryParse(map['fecha_formalizacion'] as String)
          : null,
      codigoActa: map['codigo_acta'] as String?,
      firmadoSolicitante: map['firmado_solicitante'] as bool? ?? false,
      firmadoReceptor: map['firmado_receptor'] as bool? ?? false,
      firmaSolicitanteBase64: map['firma_solicitante_base64'] as String?,
      firmaReceptorBase64: map['firma_receptor_base64'] as String?,
      condominioId: map['condominio_id']?.toString(),
      solicitanteId: map['solicitante_id']?.toString(),
      receptorId: map['receptor_id']?.toString(),
    );
  }
}
