import 'dart:typed_data';

Future<void> compartirPdfBytes({
  required Uint8List bytes,
  required String fileName,
  required String subject,
  required String text,
}) {
  throw UnsupportedError('Exportación PDF no soportada en esta plataforma.');
}

Future<String> guardarPdfBytes({
  required Uint8List bytes,
  required String fileName,
}) {
  throw UnsupportedError('Guardado PDF no soportado en esta plataforma.');
}
