import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/negociacion_model.dart';
import 'pdf_export/pdf_exporter.dart';

/// Pure-Dart generator and cross-platform exporter for signed agreement PDFs.
class ActaPdfService {
  const ActaPdfService._();

  static final PdfColor _primary = PdfColor.fromHex('#2563EB');
  static final PdfColor _darkText = PdfColor.fromHex('#0F172A');
  static final PdfColor _mutedText = PdfColor.fromHex('#475569');
  static final PdfColor _surfaceLight = PdfColor.fromHex('#F1F5F9');
  static final PdfColor _border = PdfColor.fromHex('#CBD5E1');
  static final PdfColor _greenText = PdfColor.fromHex('#047857');
  static final PdfColor _greenBg = PdfColor.fromHex('#ECFDF5');

  /// Generates an official A4 PDF document embedding both parties' signatures.
  static Future<Uint8List> generarActaPdf(
    NegociacionModel negociacion, {
    required String rolActivo,
  }) async {
    final doc = pw.Document(
      title: 'Acta de Compromiso ${negociacion.codigoActa ?? ''}',
      author: 'AcuerdoVecinal',
    );

    final formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');
    final fechaSello = negociacion.fechaFormalizacion ?? DateTime.now();
    final solicitante = negociacion.nombreVisiblePara(
      negociacion.dptoSolicitante,
      rolActivo,
    );
    final codigo = negociacion.codigoActa ?? 'BORRADOR';

    final firmaSolicitanteImg = _decodificarFirma(
      negociacion.firmaSolicitanteBase64,
    );
    final firmaReceptorImg = _decodificarFirma(
      negociacion.firmaReceptorBase64,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _border, width: 0.7)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'AcuerdoVecinal - Documento generado localmente ($codigo)',
                style: pw.TextStyle(fontSize: 9, color: _mutedText),
              ),
              pw.Text(
                'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: _mutedText),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _greenBg,
              border: pw.Border.all(color: _greenText, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ACUERDOVECINAL - ACTA DE COMPROMISO DIGITAL',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  negociacion.titulo,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkText,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Código: $codigo   |   Categoría: ${negociacion.categoria}   |   Estado: FORMALIZADO Y VIGENTE',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _greenText,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Sellado el ${formatoFechaHora.format(fechaSello)}   |   Partes: $solicitante <-> ${negociacion.dptoReceptor}',
                  style: pw.TextStyle(fontSize: 9.5, color: _mutedText),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          if (negociacion.descripcionProblema.trim().isNotEmpty) ...[
            pw.Text(
              'Contexto del conflicto',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _darkText,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              negociacion.descripcionProblema,
              style: pw.TextStyle(fontSize: 10.5, color: _darkText),
            ),
            pw.SizedBox(height: 14),
          ],
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _surfaceLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Intereses conciliados (Método Harvard)',
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkText,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '- $solicitante: ${negociacion.interesSolicitante}',
                  style: pw.TextStyle(fontSize: 10, color: _darkText),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '- ${negociacion.dptoReceptor}: ${negociacion.interesReceptor.trim().isEmpty ? 'No registrado' : negociacion.interesReceptor}',
                  style: pw.TextStyle(fontSize: 10, color: _darkText),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Cláusulas acordadas (${negociacion.condiciones.length})',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _darkText,
            ),
          ),
          pw.SizedBox(height: 8),
          for (var i = 0; i < negociacion.condiciones.length; i++) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${i + 1}. ${negociacion.condiciones[i].tituloClausula}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _darkText,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    negociacion.condiciones[i].descripcionPropuesta,
                    style: pw.TextStyle(fontSize: 10, color: _darkText),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Sustento: ${negociacion.condiciones[i].argumentoPersuasivo}',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontStyle: pw.FontStyle.italic,
                      color: _mutedText,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Criterio objetivo: ${negociacion.condiciones[i].criterioObjetivo}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Text(
            'Firmas de conformidad',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _darkText,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: _bloqueFirmaPdf(
                  etiqueta: solicitante,
                  imagen: firmaSolicitanteImg,
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: _bloqueFirmaPdf(
                  etiqueta: negociacion.dptoReceptor,
                  imagen: firmaReceptorImg,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Generates the PDF and opens the native share chooser (or downloads on web).
  static Future<void> compartirActaPdf(
    NegociacionModel negociacion, {
    required String rolActivo,
  }) async {
    final bytes = await generarActaPdf(negociacion, rolActivo: rolActivo);
    final codigo = _nombreArchivoSeguro(negociacion.codigoActa);
    await compartirPdfBytes(
      bytes: bytes,
      fileName: '$codigo.pdf',
      subject: 'Acta $codigo - ${negociacion.titulo}',
      text: 'Acta de Compromiso Digital formalizada en AcuerdoVecinal.',
    );
  }

  /// Generates the PDF and saves it directly into Downloads.
  static Future<String> guardarActaPdfEnDescargas(
    NegociacionModel negociacion, {
    required String rolActivo,
  }) async {
    final bytes = await generarActaPdf(negociacion, rolActivo: rolActivo);
    final codigo = _nombreArchivoSeguro(negociacion.codigoActa);
    return guardarPdfBytes(bytes: bytes, fileName: '$codigo.pdf');
  }

  static String _nombreArchivoSeguro(String? codigoActa) {
    final base = (codigoActa ?? 'acta_acuerdo').trim();
    if (base.isEmpty) return 'acta_acuerdo';
    return base.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  static pw.MemoryImage? _decodificarFirma(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
      final bytes = base64Decode(base64String);
      if (bytes.length < 8) return null;
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _bloqueFirmaPdf({
    required String etiqueta,
    required pw.MemoryImage? imagen,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            height: 72,
            alignment: pw.Alignment.center,
            child: imagen != null
                ? pw.Image(imagen, fit: pw.BoxFit.contain)
                : pw.Text(
                    'Firma digital registrada',
                    style: pw.TextStyle(fontSize: 9, color: _mutedText),
                  ),
          ),
          pw.Container(height: 0.8, color: _darkText),
          pw.SizedBox(height: 5),
          pw.Text(
            etiqueta,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _darkText,
            ),
          ),
        ],
      ),
    );
  }
}
