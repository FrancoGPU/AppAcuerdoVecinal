import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> compartirPdfBytes({
  required Uint8List bytes,
  required String fileName,
  required String subject,
  required String text,
}) async {
  _descargarEnNavegador(bytes, fileName);
}

Future<String> guardarPdfBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  _descargarEnNavegador(bytes, fileName);
  return 'Descargas del navegador ($fileName)';
}

Future<List<Uint8List>?> renderizarPdfPaginasNativas(Uint8List bytes) async =>
    null;

void abrirPdfEnNuevaPestana(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  web.window.open(url, '_blank');
  Future<void>.delayed(
    const Duration(minutes: 1),
    () => web.URL.revokeObjectURL(url),
  );
}

void _descargarEnNavegador(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
