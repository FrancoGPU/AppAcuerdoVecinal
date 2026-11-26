import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/negociacion_model.dart';
import '../providers/negociacion_provider.dart';
import '../services/acta_pdf_service.dart';
import '../widgets/modal_firma_tactil.dart';
import '../widgets/role_switcher_chip.dart';

/// Formal agreement summary, per-neighbor intentional signature modal, and PDF export.
class ActaAcuerdoScreen extends StatefulWidget {
  const ActaAcuerdoScreen({
    super.key,
    required this.negociacionId,
  });

  final String negociacionId;

  @override
  State<ActaAcuerdoScreen> createState() => _ActaAcuerdoScreenState();
}

class _ActaAcuerdoScreenState extends State<ActaAcuerdoScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  bool _procesandoFirma = false;
  bool _exportandoPdf = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _firmarComoRolActivo(
    NegociacionProvider provider,
    NegociacionModel negociacion, {
    required String etiquetaRolActivo,
    required String otraParte,
  }) async {
    if (_procesandoFirma || negociacion.estaFormalizada) return;

    final bytes = await mostrarModalFirmaTactil(
      context,
      nombreFirmante: etiquetaRolActivo,
      tituloAcuerdo: negociacion.titulo,
    );
    if (bytes == null || !mounted) return;

    setState(() => _procesandoFirma = true);
    NegociacionModel? actualizada;
    try {
      actualizada = await provider.registrarFirmaParticipante(
        negociacionId: negociacion.id,
        firmaBase64: base64Encode(bytes),
      );
    } finally {
      if (mounted) {
        setState(() => _procesandoFirma = false);
      }
    }

    if (!mounted || actualizada == null) return;

    if (actualizada.estaFormalizada) {
      if (_scrollCtrl.hasClients) {
        await _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Acuerdo formalizado (${actualizada.codigoActa})',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Firma de $etiquetaRolActivo registrada. Cambia a $otraParte para completar el acuerdo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _guardarPdf(
    NegociacionModel negociacion, {
    required String rolActivo,
  }) async {
    if (_exportandoPdf) return;
    setState(() => _exportandoPdf = true);

    try {
      final ubicacion = await ActaPdfService.guardarActaPdfEnDescargas(
        negociacion,
        rolActivo: rolActivo,
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
        setState(() => _exportandoPdf = false);
      }
    }
  }

  Future<void> _compartirPdf(
    NegociacionModel negociacion, {
    required String rolActivo,
  }) async {
    if (_exportandoPdf) return;
    setState(() => _exportandoPdf = true);

    try {
      await ActaPdfService.compartirActaPdf(
        negociacion,
        rolActivo: rolActivo,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('No se pudo exportar el PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _exportandoPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NegociacionProvider>();
    final negociacion = provider.obtenerPorId(widget.negociacionId);

    if (negociacion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acta de Compromiso')),
        body: Center(
          child: FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Volver al Inicio'),
          ),
        ),
      );
    }

    final formatoFecha = DateFormat('dd/MM/yyyy');
    final formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');
    final fechaDocumento = negociacion.fechaFormalizacion ?? DateTime.now();
    final rolActivo = provider.rolActivo;
    final solicitante = negociacion.nombreVisiblePara(
      negociacion.dptoSolicitante,
      rolActivo,
    );
    final esSolicitante = rolActivo == negociacion.dptoSolicitante;
    final etiquetaRolActivo = esSolicitante
        ? solicitante
        : negociacion.dptoReceptor;
    final otraParte = esSolicitante
        ? negociacion.dptoReceptor
        : solicitante;
    final yaFirme = esSolicitante
        ? negociacion.firmadoSolicitante
        : negociacion.firmadoReceptor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Acta de Compromiso',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!negociacion.estaFormalizada) const RoleSwitcherChip(),
          if (negociacion.estaFormalizada)
            IconButton(
              icon: _exportandoPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Guardar PDF',
              onPressed: _exportandoPdf
                  ? null
                  : () => _guardarPdf(negociacion, rolActivo: rolActivo),
            ),
        ],
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        children: [
          if (negociacion.estaFormalizada) ...[
            _SelloFormalizadoBanner(
              codigoActa: negociacion.codigoActa ?? '',
              fechaHora: negociacion.fechaFormalizacion != null
                  ? formatoFechaHora.format(negociacion.fechaFormalizacion!)
                  : formatoFecha.format(fechaDocumento),
            ),
            const SizedBox(height: 16),
          ],
          _DocumentoFormalCard(
            negociacion: negociacion,
            solicitanteVisible: solicitante,
            fechaTexto: formatoFecha.format(fechaDocumento),
          ),
          const SizedBox(height: 16),
          _EstadoFirmasCard(
            solicitanteLabel: solicitante,
            receptorLabel: negociacion.dptoReceptor,
            firmadoSolicitante: negociacion.firmadoSolicitante,
            firmadoReceptor: negociacion.firmadoReceptor,
            firmaSolicitanteBase64: negociacion.firmaSolicitanteBase64,
            firmaReceptorBase64: negociacion.firmaReceptorBase64,
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: negociacion.estaFormalizada
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _exportandoPdf
                                ? null
                                : () => _guardarPdf(
                                      negociacion,
                                      rolActivo: rolActivo,
                                    ),
                            icon: _exportandoPdf
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download_rounded),
                            label: Text(
                              _exportandoPdf ? 'Generando...' : 'Guardar PDF',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportandoPdf
                                ? null
                                : () => _compartirPdf(
                                      negociacion,
                                      rolActivo: rolActivo,
                                    ),
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Compartir'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Volver al Inicio'),
                      ),
                    ),
                  ],
                )
              : yaFirme
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.formalizedBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.formalizedText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.esModoNube
                                      ? 'Tu firma ya está registrada. Esperando la firma de $otraParte en tiempo real.'
                                      : 'Tu firma ya está registrada. Falta la firma de $otraParte (cambia de rol arriba).',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.formalizedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _procesandoFirma
                                ? null
                                : () => _firmarComoRolActivo(
                                      provider,
                                      negociacion,
                                      etiquetaRolActivo: etiquetaRolActivo,
                                      otraParte: otraParte,
                                    ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reemplazar mi firma'),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _procesandoFirma
                            ? null
                            : () => _firmarComoRolActivo(
                                  provider,
                                  negociacion,
                                  etiquetaRolActivo: etiquetaRolActivo,
                                  otraParte: otraParte,
                                ),
                        icon: const Icon(Icons.draw_rounded),
                        label: Text('Firmar como $etiquetaRolActivo'),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _EstadoFirmasCard extends StatelessWidget {
  const _EstadoFirmasCard({
    required this.solicitanteLabel,
    required this.receptorLabel,
    required this.firmadoSolicitante,
    required this.firmadoReceptor,
    required this.firmaSolicitanteBase64,
    required this.firmaReceptorBase64,
  });

  final String solicitanteLabel;
  final String receptorLabel;
  final bool firmadoSolicitante;
  final bool firmadoReceptor;
  final String? firmaSolicitanteBase64;
  final String? firmaReceptorBase64;

  Uint8List? _decodificar(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              firmadoSolicitante && firmadoReceptor
                  ? 'Firmas registradas'
                  : 'Estado de firmas',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CajaFirmaGuardada(
                    etiqueta: solicitanteLabel,
                    firmado: firmadoSolicitante,
                    pngBytes: _decodificar(firmaSolicitanteBase64),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CajaFirmaGuardada(
                    etiqueta: receptorLabel,
                    firmado: firmadoReceptor,
                    pngBytes: _decodificar(firmaReceptorBase64),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CajaFirmaGuardada extends StatelessWidget {
  const _CajaFirmaGuardada({
    required this.etiqueta,
    required this.firmado,
    required this.pngBytes,
  });

  final String etiqueta;
  final bool firmado;
  final Uint8List? pngBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: firmado ? AppColors.acceptedBg : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: firmado
              ? AppColors.acceptedBtn.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 76,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: pngBytes != null
                ? Image.memory(pngBytes!, fit: BoxFit.contain)
                : Center(
                    child: Text(
                      firmado ? 'Firmado' : 'Pendiente de firma',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: firmado ? FontWeight.w600 : FontWeight.w400,
                        color: firmado
                            ? AppColors.acceptedText
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            etiqueta,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            firmado ? 'Firmado' : 'Pendiente',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: firmado ? AppColors.acceptedText : AppColors.pendingText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelloFormalizadoBanner extends StatelessWidget {
  const _SelloFormalizadoBanner({
    required this.codigoActa,
    required this.fechaHora,
  });

  final String codigoActa;
  final String fechaHora;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.acceptedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.acceptedBtn.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 32,
            color: AppColors.acceptedText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACUERDO FORMALIZADO Y VIGENTE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.acceptedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Código: $codigoActa\nSellado el $fechaHora • Modo solo lectura',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.acceptedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentoFormalCard extends StatelessWidget {
  const _DocumentoFormalCard({
    required this.negociacion,
    required this.solicitanteVisible,
    required this.fechaTexto,
  });

  final NegociacionModel negociacion;
  final String solicitanteVisible;
  final String fechaTexto;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ACTA DE COMPROMISO DIGITAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              negociacion.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _MetaChip(
                  icon: Icons.tag_rounded,
                  label:
                      negociacion.codigoActa ?? 'BORRADOR PENDIENTE DE FIRMA',
                ),
                _MetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: fechaTexto,
                ),
                _MetaChip(
                  icon: Icons.category_outlined,
                  label: negociacion.categoria,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 14),
            Text(
              'Partes intervinientes: $solicitanteVisible y ${negociacion.dptoReceptor}',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.argumentBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Intereses conciliados',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• $solicitanteVisible: ${negociacion.interesSolicitante}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ${negociacion.dptoReceptor}: ${negociacion.interesReceptor.isEmpty ? "No registrado" : negociacion.interesReceptor}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cláusulas acordadas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < negociacion.condiciones.length; i++) ...[
              _ClausulaActaItem(
                numero: i + 1,
                titulo: negociacion.condiciones[i].tituloClausula,
                propuesta: negociacion.condiciones[i].descripcionPropuesta,
                criterio: negociacion.condiciones[i].criterioObjetivo,
              ),
              if (i < negociacion.condiciones.length - 1)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ClausulaActaItem extends StatelessWidget {
  const _ClausulaActaItem({
    required this.numero,
    required this.titulo,
    required this.propuesta,
    required this.criterio,
  });

  final int numero;
  final String titulo;
  final String propuesta;
  final String criterio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$numero. $titulo',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            propuesta,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Respaldo: $criterio',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
