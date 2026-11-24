/// Status of an individual negotiable condition.
enum EstadoCondicion {
  pendiente,
  aceptada,
  rechazada;

  static EstadoCondicion fromName(String? value) {
    return EstadoCondicion.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoCondicion.pendiente,
    );
  }
}

/// Historical snapshot of a previous proposal round archived on counter-offer.
class RondaHistorial {
  const RondaHistorial({
    required this.propuestaAnterior,
    required this.argumentoAnterior,
    required this.autor,
    required this.fecha,
  });

  final String propuestaAnterior;
  final String argumentoAnterior;
  final String autor;
  final DateTime fecha;

  Map<String, dynamic> toJson() => {
        'propuestaAnterior': propuestaAnterior,
        'argumentoAnterior': argumentoAnterior,
        'autor': autor,
        'fecha': fecha.toIso8601String(),
      };

  factory RondaHistorial.fromJson(Map<String, dynamic> json) {
    return RondaHistorial(
      propuestaAnterior: json['propuestaAnterior'] as String? ?? '',
      argumentoAnterior: json['argumentoAnterior'] as String? ?? '',
      autor: json['autor'] as String? ?? '',
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Individual clause negotiated between neighbors using Harvard method principles.
class CondicionModel {
  const CondicionModel({
    required this.id,
    required this.tituloClausula,
    required this.descripcionPropuesta,
    required this.criterioObjetivo,
    required this.argumentoPersuasivo,
    required this.autorUltimaOferta,
    this.estado = EstadoCondicion.pendiente,
    this.motivoRechazo,
    this.historial = const [],
  });

  final String id;
  final String tituloClausula;
  final String descripcionPropuesta;
  final String criterioObjetivo;
  final String argumentoPersuasivo;
  final String autorUltimaOferta;
  final EstadoCondicion estado;
  final String? motivoRechazo;
  final List<RondaHistorial> historial;

  CondicionModel copyWith({
    String? id,
    String? tituloClausula,
    String? descripcionPropuesta,
    String? criterioObjetivo,
    String? argumentoPersuasivo,
    String? autorUltimaOferta,
    EstadoCondicion? estado,
    String? motivoRechazo,
    bool limpiarMotivoRechazo = false,
    List<RondaHistorial>? historial,
  }) {
    return CondicionModel(
      id: id ?? this.id,
      tituloClausula: tituloClausula ?? this.tituloClausula,
      descripcionPropuesta: descripcionPropuesta ?? this.descripcionPropuesta,
      criterioObjetivo: criterioObjetivo ?? this.criterioObjetivo,
      argumentoPersuasivo: argumentoPersuasivo ?? this.argumentoPersuasivo,
      autorUltimaOferta: autorUltimaOferta ?? this.autorUltimaOferta,
      estado: estado ?? this.estado,
      motivoRechazo:
          limpiarMotivoRechazo ? null : (motivoRechazo ?? this.motivoRechazo),
      historial: historial ?? this.historial,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tituloClausula': tituloClausula,
        'descripcionPropuesta': descripcionPropuesta,
        'criterioObjetivo': criterioObjetivo,
        'argumentoPersuasivo': argumentoPersuasivo,
        'autorUltimaOferta': autorUltimaOferta,
        'estado': estado.name,
        'motivoRechazo': motivoRechazo,
        'historial': historial.map((h) => h.toJson()).toList(),
      };

  factory CondicionModel.fromJson(Map<String, dynamic> json) {
    final rawHistorial = json['historial'] as List<dynamic>? ?? const [];
    return CondicionModel(
      id: json['id'] as String? ?? '',
      tituloClausula: json['tituloClausula'] as String? ?? '',
      descripcionPropuesta: json['descripcionPropuesta'] as String? ?? '',
      criterioObjetivo: json['criterioObjetivo'] as String? ?? '',
      argumentoPersuasivo: json['argumentoPersuasivo'] as String? ?? '',
      autorUltimaOferta: json['autorUltimaOferta'] as String? ?? '',
      estado: EstadoCondicion.fromName(json['estado'] as String?),
      motivoRechazo: json['motivoRechazo'] as String?,
      historial: rawHistorial
          .whereType<Map<String, dynamic>>()
          .map(RondaHistorial.fromJson)
          .toList(),
    );
  }
}
