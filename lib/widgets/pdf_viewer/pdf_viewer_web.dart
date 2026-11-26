import 'dart:js_interop';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

bool get soportaVisorPdfWebEmbebido => true;

Widget construirVisorPdfWebEmbebido(Uint8List bytes) {
  return _WebPdfIframeViewer(bytes: bytes);
}

class _WebPdfIframeViewer extends StatefulWidget {
  const _WebPdfIframeViewer({required this.bytes});

  final Uint8List bytes;

  @override
  State<_WebPdfIframeViewer> createState() => _WebPdfIframeViewerState();
}

class _WebPdfIframeViewerState extends State<_WebPdfIframeViewer> {
  late String _blobUrl;

  @override
  void initState() {
    super.initState();
    _crearBlob();
  }

  @override
  void didUpdateWidget(covariant _WebPdfIframeViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes) {
      web.URL.revokeObjectURL(_blobUrl);
      _crearBlob();
    }
  }

  void _crearBlob() {
    final blob = web.Blob(
      <JSUint8Array>[widget.bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    _blobUrl = web.URL.createObjectURL(blob);
  }

  @override
  void dispose() {
    web.URL.revokeObjectURL(_blobUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView.fromTagName(
        tagName: 'iframe',
        onElementCreated: (Object element) {
          final iframe = element as web.HTMLIFrameElement;
          iframe
            ..src = '$_blobUrl#toolbar=1&navpanes=0&view=FitH'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
        },
      ),
    );
  }
}
