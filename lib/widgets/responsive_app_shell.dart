import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Frames the application nicely on wide Web/desktop screens for classroom projection
/// while passing through directly on mobile devices and widget tests.
class ResponsiveAppShell extends StatefulWidget {
  const ResponsiveAppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ResponsiveAppShell> createState() => _ResponsiveAppShellState();
}

class _ResponsiveAppShellState extends State<ResponsiveAppShell> {
  bool _vistaAmplia = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    final width = MediaQuery.sizeOf(context).width;
    if (width <= 720) return widget.child;

    final auth = Provider.of<AuthProvider?>(context);
    final esNube = auth?.esModoNube ?? false;
    final esDemo = auth?.esModoDemo ?? false;
    final maxCanvasWidth = _vistaAmplia ? 920.0 : 460.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroDark, Color(0xFF1E293B)],
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AcuerdoVecinal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: esNube
                          ? AppColors.acceptedBtn.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: esNube
                            ? AppColors.acceptedBtn
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      esNube
                          ? 'Nube Tiempo Real'
                          : esDemo
                              ? 'Modo Demo Local'
                              : 'Presentación Web',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () {
                      setState(() => _vistaAmplia = !_vistaAmplia);
                    },
                    icon: Icon(
                      _vistaAmplia
                          ? Icons.smartphone_rounded
                          : Icons.tablet_mac_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _vistaAmplia ? 'Vista Móvil' : 'Vista Amplia',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: maxCanvasWidth,
                margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 32,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
