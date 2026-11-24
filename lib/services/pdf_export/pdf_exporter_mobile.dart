import 'package:flutter/services.dart';

const MethodChannel _pdfChannel = MethodChannel('acuerdo_vecinal/pdf_export');

Future<void> compartirPdfBytes({
  required Uint8List bytes,
  required String fileName,
  required String subject,
  required String text,
}) async {
  await _pdfChannel.invokeMethod<void>('compartirPdf', {
    'bytes': bytes,
    'fileName': fileName,
    'subject': subject,
    'text': text,
  });
}

Future<String> guardarPdfBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  final ubicacion = await _pdfChannel.invokeMethod<String>(
    'guardarPdfEnDescargas',
    {
      'bytes': bytes,
      'fileName': fileName,
    },
  );
  return ubicacion ?? 'Descargas/$fileName';
}
