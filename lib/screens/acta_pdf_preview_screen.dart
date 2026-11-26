import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../models/negociacion_model.dart';
import '../services/acta_pdf_service.dart';
import '../widgets/pdf_viewer/pdf_viewer_platform.dart';

/// In-app A4 PDF preview screen supporting native Android PdfRenderer pages,
/// embedded Web PDF viewer, and an interactive pinch-to-zoom A4 sheet layout.
class ActaPdfPreviewScreen extends StatefulWidget {
  const ActaPdfPreviewScreen({
    super.key,
    required this.negociacion,
    required this.rolActivo,
  });

  final NegociacionModel negociacion;
  final String rolActivo;

  @override
  State<ActaPdfPreviewScreen> createState() => _ActaPdfPreviewScreenState();
}

class _ActaPdfPreviewScreenState extends State<ActaPdfPreviewScreen> {
  Uint8List? _pdfBytes;
  List<Uint8List>? _paginasNativas;
  String? _error;
  bool _cargando = true;
  bool _exportando = false;
  bool _mostrarIframeWeb = true;
  bool _modoInicializado = false;

  @override
  void initState() {
    super.initState();
    _prepararDocumento();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_modoInicializado) {
      _modoInicializado = true;
      // Mobile browsers often struggle to scroll/render inline PDF iframes;
      // default to A4 sheet on narrow viewports while keeping native toggleable.
      _mostrarIframeWeb = MediaQuery.sizeOf(context).width >= 720;
    }
  }

  Future<void> _prepararDocumento() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final bytes = await ActaPdfService.generarActaPdf(
        widget.negociacion,
        rolActivo: widget.rolActivo,
      );
      List<Uint8List>? paginas;
      if (!kIsWeb) {
        paginas = await ActaPdfService.renderizarPaginasNativas(bytes);
      }

      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _paginasNativas = paginas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo generar la vista previa del PDF: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _guardarPdf() async {
    final bytes = _pdfBytes;
    if (bytes == null || _exportando) return;
    setState(() => _exportando = true);

    try {
      final ubicacion = await ActaPdfService.guardarPdfGenerado(
        bytes,
        widget.negociacion.codigoActa,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('PDF guardado en $ubicacion'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar el PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _exportando = false);
      }
    }
  }

  Future<void> _compartirPdf() async {
    final bytes = _pdfBytes;
    if (bytes == null || _exportando) return;
    setState(() => _exportando = true);

    try {
      await ActaPdfService.compartirPdfGenerado(bytes, widget.negociacion);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('No se pudo compartir el PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _exportando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreArchivo =
        ActaPdfService.nombreArchivoPdf(widget.negociacion.codigoActa);
    final kbTexto = _pdfBytes == null
        ? 'Preparando...'
        : '${(_pdfBytes!.length / 1024).toStringAsFixed(1)} KB';

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vista Previa PDF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '$nombreArchivo • $kbTexto',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (kIsWeb && _pdfBytes != null)
            IconButton(
              tooltip: 'Abrir PDF en nueva pestaña',
              onPressed: () => ActaPdfService.abrirPdfWebGenerado(
                _pdfBytes!,
                widget.negociacion.codigoActa,
              ),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Generando vista previa A4...',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 36,
                              color: AppColors.rejectedBtn,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _prepararDocumento,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : _construirContenidoPreview(),
      bottomNavigationBar: _pdfBytes == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportando ? null : _guardarPdf,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Guardar PDF'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _exportando ? null : _compartirPdf,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Compartir'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _construirContenidoPreview() {
    final paginas = _paginasNativas;
    if (paginas != null && paginas.isNotEmpty) {
      return InteractiveViewer(
        minScale: 0.85,
        maxScale: 3.5,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: paginas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, index) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.heroDark.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Página ${index + 1} de ${paginas.length} • Pellizca para zoom',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    paginas[index],
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    if (kIsWeb && soportaVisorPdfWebEmbebido && _pdfBytes != null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _ModeTogglePill(
                    label: 'PDF Nativo',
                    selected: _mostrarIframeWeb,
                    onTap: () => setState(() => _mostrarIframeWeb = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeTogglePill(
                    label: 'Hoja A4',
                    selected: !_mostrarIframeWeb,
                    onTap: () => setState(() => _mostrarIframeWeb = false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _mostrarIframeWeb
                ? construirVisorPdfWebEmbebido(_pdfBytes!)
                : InteractiveViewer(
                    minScale: 0.85,
                    maxScale: 3.0,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _HojaA4Preview(
                        negociacion: widget.negociacion,
                        rolActivo: widget.rolActivo,
                      ),
                    ),
                  ),
          ),
        ],
      );
    }

    return InteractiveViewer(
      minScale: 0.85,
      maxScale: 3.0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _HojaA4Preview(
          negociacion: widget.negociacion,
          rolActivo: widget.rolActivo,
        ),
      ),
    );
  }
}

class _ModeTogglePill extends StatelessWidget {
  const _ModeTogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.argumentBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HojaA4Preview extends StatelessWidget {
  const _HojaA4Preview({
    required this.negociacion,
    required this.rolActivo,
  });

  final NegociacionModel negociacion;
  final String rolActivo;

  Uint8List? _decodificarFirma(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final bytes = base64Decode(raw);
      return bytes.length < 8 ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');
    final fechaSello = negociacion.fechaFormalizacion ?? DateTime.now();
    final solicitante = negociacion.nombreVisiblePara(
      negociacion.dptoSolicitante,
      rolActivo,
    );
    final codigo = negociacion.codigoActa ?? 'BORRADOR';
    final firmaSol = _decodificarFirma(negociacion.firmaSolicitanteBase64);
    final firmaRec = _decodificarFirma(negociacion.firmaReceptorBase64);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.acceptedBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.acceptedText),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACUERDOVECINAL - ACTA DE COMPROMISO DIGITAL',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      negociacion.titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Código: $codigo   •   Categoría: ${negociacion.categoria}   •   FORMALIZADO Y VIGENTE',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.acceptedText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sellado el ${formatoFechaHora.format(fechaSello)}   •   Partes: $solicitante ↔ ${negociacion.dptoReceptor}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (negociacion.descripcionProblema.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Contexto del conflicto',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  negociacion.descripcionProblema,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.argumentBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Intereses conciliados (Método Harvard)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• $solicitante: ${negociacion.interesSolicitante}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ${negociacion.dptoReceptor}: ${negociacion.interesReceptor.trim().isEmpty ? 'No registrado' : negociacion.interesReceptor}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cláusulas acordadas (${negociacion.condiciones.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < negociacion.condiciones.length; i++) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. ${negociacion.condiciones[i].tituloClausula}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        negociacion.condiciones[i].descripcionPropuesta,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sustento: ${negociacion.condiciones[i].argumentoPersuasivo}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Criterio objetivo: ${negociacion.condiciones[i].criterioObjetivo}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Firmas de conformidad',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _BloqueFirmaHoja(
                      etiqueta: solicitante,
                      pngBytes: firmaSol,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _BloqueFirmaHoja(
                      etiqueta: negociacion.dptoReceptor,
                      pngBytes: firmaRec,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 6),
              Text(
                'AcuerdoVecinal • Documento A4 verificable ($codigo)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BloqueFirmaHoja extends StatelessWidget {
  const _BloqueFirmaHoja({
    required this.etiqueta,
    required this.pngBytes,
  });

  final String etiqueta;
  final Uint8List? pngBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: Center(
              child: pngBytes != null
                  ? Image.memory(pngBytes!, fit: BoxFit.contain)
                  : const Text(
                      'Firma digital registrada',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          Container(height: 1, color: AppColors.textPrimary),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
