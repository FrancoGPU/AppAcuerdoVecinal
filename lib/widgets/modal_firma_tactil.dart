import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'signature_pad_widget.dart';

/// Opens a dedicated, non-scrollable modal dialog for intentional signing
/// so page scrolling never interferes with finger strokes.
Future<Uint8List?> mostrarModalFirmaTactil(
  BuildContext context, {
  required String nombreFirmante,
  required String tituloAcuerdo,
}) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (_) => _ModalFirmaTactilDialog(
      nombreFirmante: nombreFirmante,
      tituloAcuerdo: tituloAcuerdo,
    ),
  );
}

class _ModalFirmaTactilDialog extends StatefulWidget {
  const _ModalFirmaTactilDialog({
    required this.nombreFirmante,
    required this.tituloAcuerdo,
  });

  final String nombreFirmante;
  final String tituloAcuerdo;

  @override
  State<_ModalFirmaTactilDialog> createState() =>
      _ModalFirmaTactilDialogState();
}

class _ModalFirmaTactilDialogState extends State<_ModalFirmaTactilDialog> {
  final SignaturePadController _controller = SignaturePadController();
  bool _tieneFirma = false;
  bool _acepta = false;
  bool _exportando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_tieneFirma || !_acepta || _exportando) return;
    setState(() => _exportando = true);

    final bytes = await _controller.exportarPngBytes();
    if (!mounted) return;

    if (bytes == null || bytes.isEmpty) {
      setState(() => _exportando = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo capturar la firma. Intenta trazarla nuevamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firmar como ${widget.nombreFirmante}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.tituloAcuerdo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cancelar',
                  onPressed: _exportando
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SignaturePadWidget(
              controller: _controller,
              titulo: 'Traza tu firma debajo',
              onChanged: (has) {
                if (_tieneFirma != has) {
                  setState(() => _tieneFirma = has);
                }
              },
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _acepta,
              onChanged: _exportando
                  ? null
                  : (v) => setState(() => _acepta = v ?? false),
              title: const Text(
                'Confirmo que acepto los términos acordados y deseo estampar mi firma digital.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: (_tieneFirma && _acepta && !_exportando)
                    ? _confirmar
                    : null,
                icon: _exportando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user_rounded),
                label: Text(
                  _exportando ? 'Guardando firma...' : 'Confirmar mi firma',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
