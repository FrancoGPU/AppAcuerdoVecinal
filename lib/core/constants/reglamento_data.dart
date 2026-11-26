/// Constants for apartment roles in the local simulator.
const String kDpto301 = 'Dpto. 301';
const String kDpto402 = 'Dpto. 402';

/// Supported conflict categories in AcuerdoVecinal.
const List<String> kCategoriasConflicto = [
  'Ruido',
  'Mascotas',
  'Cochera',
  'Áreas Comunes',
  'Otros',
];

/// Supported categories when administrators add custom bylaws.
const List<String> kCategoriasReglamento = [
  'Ruido',
  'Mascotas',
  'Cochera',
  'Áreas Comunes',
  'Otros',
  'General',
];

/// Represents an article or objective criterion from the condominium bylaws.
class ArticuloReglamento {
  const ArticuloReglamento({
    required this.id,
    required this.etiqueta,
    required this.resumen,
    required this.categoria,
    this.orden = 0,
  });

  final String id;
  final String etiqueta;
  final String resumen;
  final String categoria;
  final int orden;

  ArticuloReglamento copyWith({
    String? id,
    String? etiqueta,
    String? resumen,
    String? categoria,
    int? orden,
  }) {
    return ArticuloReglamento(
      id: id ?? this.id,
      etiqueta: etiqueta ?? this.etiqueta,
      resumen: resumen ?? this.resumen,
      categoria: categoria ?? this.categoria,
      orden: orden ?? this.orden,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'etiqueta': etiqueta,
        'resumen': resumen,
        'categoria': categoria,
        'orden': orden,
      };

  factory ArticuloReglamento.fromJson(Map<String, dynamic> json) {
    return ArticuloReglamento(
      id: json['id'] as String? ?? '',
      etiqueta: json['etiqueta'] as String? ?? '',
      resumen: json['resumen'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'General',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }

  factory ArticuloReglamento.fromSupabaseMap(Map<String, dynamic> map) {
    return ArticuloReglamento(
      id: map['id']?.toString() ?? '',
      etiqueta: map['etiqueta'] as String? ?? '',
      resumen: map['resumen'] as String? ?? '',
      categoria: map['categoria'] as String? ?? 'General',
      orden: (map['orden'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toSupabaseMap(String condominioId) => {
        'condominio_id': condominioId,
        'etiqueta': etiqueta.trim(),
        'resumen': resumen.trim(),
        'categoria': categoria,
        'orden': orden,
      };
}

/// Condominium internal rules used as objective criteria in Phase 1
/// and as lightweight RAG context for the Gemini AI mediator.
const List<ArticuloReglamento> kReglamentoInterno = [
  ArticuloReglamento(
    id: 'art_14',
    etiqueta: 'Art. 14 - Reglamento Interno (Ruidos Molestos)',
    resumen:
        'Horario de silencio obligatorio de lunes a jueves de 10:00 p.m. a 7:00 a.m., y viernes/sábados desde la medianoche.',
    categoria: 'Ruido',
    orden: 1,
  ),
  ArticuloReglamento(
    id: 'art_18',
    etiqueta: 'Art. 18 - Reglamento Interno (Tenencia de Mascotas)',
    resumen:
        'Uso obligatorio de correa en áreas comunes y responsabilidad por ladridos persistentes en balcones.',
    categoria: 'Mascotas',
    orden: 2,
  ),
  ArticuloReglamento(
    id: 'art_22',
    etiqueta: 'Art. 22 - Reglamento Interno (Estacionamientos)',
    resumen:
        'Respeto estricto a las líneas demarcadas; prohibido obstruir parcialmente el acceso contiguo.',
    categoria: 'Cochera',
    orden: 3,
  ),
  ArticuloReglamento(
    id: 'art_27',
    etiqueta: 'Art. 27 - Reglamento Interno (Áreas Comunes y Parrillas)',
    resumen:
        'Reserva previa con 48 horas y entrega limpia antes de las 11:00 p.m.',
    categoria: 'Áreas Comunes',
    orden: 4,
  ),
  ArticuloReglamento(
    id: 'art_31',
    etiqueta: 'Art. 31 - Reglamento Interno (Filtraciones y Mantenimiento)',
    resumen:
        'Reparación compartida o asumida por el departamento origen en un plazo máximo de 7 días.',
    categoria: 'Otros',
    orden: 5,
  ),
  ArticuloReglamento(
    id: 'beneficio_mutuo',
    etiqueta: 'Criterio de Beneficio Mutuo / Buena Convivencia',
    resumen:
        'Acuerdo voluntario sin escalar a multa de la Junta de Propietarios.',
    categoria: 'General',
    orden: 6,
  ),
];

/// Finds the matching article by label in [fuente] (or [kReglamentoInterno]),
/// returning null if custom or not found.
ArticuloReglamento? buscarArticuloPorEtiqueta(
  String etiqueta, [
  List<ArticuloReglamento>? fuente,
]) {
  final lista = fuente ?? kReglamentoInterno;
  for (final articulo in lista) {
    if (articulo.etiqueta == etiqueta) return articulo;
  }
  return null;
}

/// Serializes the internal bylaws as plain text for AI Mediator context injection.
String reglamentoComoContextoTexto([List<ArticuloReglamento>? articulos]) {
  final lista = articulos ?? kReglamentoInterno;
  final buffer = StringBuffer('REGLAMENTO INTERNO DEL CONDOMINIO:\n');
  for (final art in lista) {
    buffer.writeln('- ${art.etiqueta}: ${art.resumen}');
  }
  return buffer.toString();
}
