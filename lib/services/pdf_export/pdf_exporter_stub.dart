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
  throw UnsupportedError('Exportación PDF no soportada en esta plataforma.');
}

Future<List<Uint8List>?> renderizarPdfPaginasNativas(Uint8List bytes) async =>
    null;

void abrirPdfEnNuevaPestana(Uint8List bytes, String fileName) {}
