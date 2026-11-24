import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// Controller that holds drawn strokes and exports crisp PNG image bytes.
class SignaturePadController extends ChangeNotifier {
  final List<List<Offset>> _trazos = [];
  Size _canvasSize = const Size(320, 200);

  List<List<Offset>> get trazos => _trazos;
  bool get tieneFirma => _trazos.any((t) => t.isNotEmpty);

  void _actualizarSize(Size size) {
    if (size.width > 0 && size.height > 0) {
      _canvasSize = size;
    }
  }

  void _iniciarTrazo(Offset point) {
    _trazos.add([point]);
    notifyListeners();
  }

  void _agregarPunto(Offset point) {
    if (_trazos.isEmpty) {
      _trazos.add([point]);
    } else {
      _trazos.last.add(point);
    }
    notifyListeners();
  }

  void clear() {
    if (_trazos.isEmpty) return;
    _trazos.clear();
    notifyListeners();
  }

  /// Renders the drawn strokes onto a white 2x canvas and returns PNG bytes.
  Future<Uint8List?> exportarPngBytes() async {
    if (!tieneFirma) return null;

    const scale = 2.0;
    final width = (_canvasSize.width * scale).round().clamp(200, 1400);
    final height = (_canvasSize.height * scale).round().clamp(160, 800);

    ui.Picture? picture;
    ui.Image? image;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(scale);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height),
        Paint()..color = const Color(0xFFFFFFFF),
      );

      _SignaturePainter.pintarTrazos(canvas, _trazos);

      picture = recorder.endRecording();
      image = await picture.toImage(width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }
}

/// Native touch signature pad that immediately wins the gesture arena on touch
/// down (0px slop) so parent scrollables never steal vertical pen strokes.
class SignaturePadWidget extends StatefulWidget {
  const SignaturePadWidget({
    super.key,
    required this.controller,
    this.titulo = 'Firma táctil de conformidad',
    this.onChanged,
    this.onDrawingActiveChanged,
  });

  final SignaturePadController controller;
  final String titulo;
  final ValueChanged<bool>? onChanged;
  final ValueChanged<bool>? onDrawingActiveChanged;

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final GlobalKey _canvasKey = GlobalKey();
  bool _hadSignature = false;

  @override
  void initState() {
    super.initState();
    _hadSignature = widget.controller.tieneFirma;
    widget.controller.addListener(_handleControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant SignaturePadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerUpdate);
      _hadSignature = widget.controller.tieneFirma;
      widget.controller.addListener(_handleControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  void _handleControllerUpdate() {
    final nowHas = widget.controller.tieneFirma;
    if (nowHas != _hadSignature) {
      _hadSignature = nowHas;
      widget.onChanged?.call(nowHas);
    }
    if (mounted) setState(() {});
  }

  Offset _toClampedLocal(Offset globalPosition, Size size) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final local = renderBox != null
        ? renderBox.globalToLocal(globalPosition)
        : globalPosition;
    return Offset(
      local.dx.clamp(0.0, size.width),
      local.dy.clamp(0.0, size.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneFirma = widget.controller.tieneFirma;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.titulo,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: tieneFirma ? widget.controller.clear : null,
              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
              label: const Text('Limpiar'),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              widget.controller._actualizarSize(size);

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: const _DashedBorderPainter(
                    color: AppColors.border,
                    radius: 12,
                  ),
                  child: Container(
                    key: _canvasKey,
                    color: AppColors.surface,
                    child: RawGestureDetector(
                      behavior: HitTestBehavior.opaque,
                      gestures: <Type, GestureRecognizerFactory>{
                        _EagerSignatureGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                                _EagerSignatureGestureRecognizer>(
                          () => _EagerSignatureGestureRecognizer(),
                          (_EagerSignatureGestureRecognizer instance) {
                            instance.onStrokeStart = (globalPos) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              widget.onDrawingActiveChanged?.call(true);
                              widget.controller._iniciarTrazo(
                                _toClampedLocal(globalPos, size),
                              );
                            };
                            instance.onStrokeUpdate = (globalPos) {
                              widget.controller._agregarPunto(
                                _toClampedLocal(globalPos, size),
                              );
                            };
                            instance.onStrokeEnd = () {
                              widget.onDrawingActiveChanged?.call(false);
                            };
                          },
                        ),
                      },
                      child: RepaintBoundary(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 34,
                              child: IgnorePointer(
                                child: Container(
                                  height: 1,
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                            if (!tieneFirma)
                              const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.draw_outlined,
                                      size: 28,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Firme aquí con el dedo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            CustomPaint(
                              painter: _SignaturePainter(
                                trazos: widget.controller.trazos,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Immediately accepts pointer down at 0px slop so parent ListViews never
/// hijack the initial touch stroke on mobile touchscreens.
class _EagerSignatureGestureRecognizer extends OneSequenceGestureRecognizer {
  void Function(Offset globalPosition)? onStrokeStart;
  void Function(Offset globalPosition)? onStrokeUpdate;
  VoidCallback? onStrokeEnd;

  int? _activePointer;

  @override
  String get debugDescription => 'eager signature';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onStrokeStart?.call(event.position);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _activePointer) return;

    if (event is PointerMoveEvent) {
      onStrokeUpdate?.call(event.position);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
      _activePointer = null;
      onStrokeEnd?.call();
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (_activePointer == pointer) {
      _activePointer = null;
      onStrokeEnd?.call();
    }
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.trazos});

  final List<List<Offset>> trazos;

  static void pintarTrazos(Canvas canvas, List<List<Offset>> trazos) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    for (final trazo in trazos) {
      if (trazo.isEmpty) continue;
      if (trazo.length == 1) {
        canvas.drawPoints(ui.PointMode.points, trazo, paint);
        continue;
      }

      final path = Path()..moveTo(trazo.first.dx, trazo.first.dy);
      for (var i = 1; i < trazo.length; i++) {
        path.lineTo(trazo[i].dx, trazo[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    pintarTrazos(canvas, trazos);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(1);
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
