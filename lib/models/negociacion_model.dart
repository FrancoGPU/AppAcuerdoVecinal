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
    );
  }
}
