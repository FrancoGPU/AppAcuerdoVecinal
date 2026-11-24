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

/// Represents an article or objective criterion from the condominium bylaws.
class ArticuloReglamento {
  const ArticuloReglamento({
    required this.id,
    required this.etiqueta,
    required this.resumen,
    required this.categoria,
  });

  final String id;
  final String etiqueta;
  final String resumen;
  final String categoria;

  Map<String, dynamic> toJson() => {
        'id': id,
        'etiqueta': etiqueta,
        'resumen': resumen,
        'categoria': categoria,
      };
}

/// Condominium internal rules used as objective criteria in Phase 1
/// and as lightweight RAG context for the Phase 2 Gemini mediator.
const List<ArticuloReglamento> kReglamentoInterno = [
  ArticuloReglamento(
    id: 'art_14',
    etiqueta: 'Art. 14 - Reglamento Interno (Ruidos Molestos)',
    resumen:
        'Horario de silencio obligatorio de lunes a jueves de 10:00 p.m. a 7:00 a.m., y viernes/sábados desde la medianoche.',
    categoria: 'Ruido',
  ),
  ArticuloReglamento(
    id: 'art_18',
    etiqueta: 'Art. 18 - Reglamento Interno (Tenencia de Mascotas)',
    resumen:
        'Uso obligatorio de correa en áreas comunes y responsabilidad por ladridos persistentes en balcones.',
    categoria: 'Mascotas',
  ),
  ArticuloReglamento(
    id: 'art_22',
    etiqueta: 'Art. 22 - Reglamento Interno (Estacionamientos)',
    resumen:
        'Respeto estricto a las líneas demarcadas; prohibido obstruir parcialmente el acceso contiguo.',
    categoria: 'Cochera',
  ),
  ArticuloReglamento(
    id: 'art_27',
    etiqueta: 'Art. 27 - Reglamento Interno (Áreas Comunes y Parrillas)',
    resumen:
        'Reserva previa con 48 horas y entrega limpia antes de las 11:00 p.m.',
    categoria: 'Áreas Comunes',
  ),
  ArticuloReglamento(
    id: 'art_31',
    etiqueta: 'Art. 31 - Reglamento Interno (Filtraciones y Mantenimiento)',
    resumen:
        'Reparación compartida o asumida por el departamento origen en un plazo máximo de 7 días.',
    categoria: 'Otros',
  ),
  ArticuloReglamento(
    id: 'beneficio_mutuo',
    etiqueta: 'Criterio de Beneficio Mutuo / Buena Convivencia',
    resumen:
        'Acuerdo voluntario sin escalar a multa de la Junta de Propietarios.',
    categoria: 'General',
  ),
];

/// Finds the matching article by label, returning null if custom/not found.
ArticuloReglamento? buscarArticuloPorEtiqueta(String etiqueta) {
  for (final articulo in kReglamentoInterno) {
    if (articulo.etiqueta == etiqueta) return articulo;
  }
  return null;
}

/// Serializes the internal bylaws as plain text for Phase 2 Gemini context injection.
String reglamentoComoContextoTexto() {
  final buffer = StringBuffer('REGLAMENTO INTERNO DEL CONDOMINIO:\n');
  for (final art in kReglamentoInterno) {
    buffer.writeln('- ${art.etiqueta}: ${art.resumen}');
  }
  return buffer.toString();
}
