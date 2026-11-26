import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/negociacion_provider.dart';

/// Quick role toggle chip in Demo mode, or authenticated apartment badge in Cloud mode.
class RoleSwitcherChip extends StatelessWidget {
  const RoleSwitcherChip({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NegociacionProvider>();
    final rolActivo = provider.rolActivo;
    final esNube = provider.esModoNube;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Material(
        color: esNube ? AppColors.acceptedBg : AppColors.formalizedBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: esNube
              ? null
              : () async {
                  await provider.alternarRol();
                  if (!context.mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Rol activo cambiado a ${provider.rolActivo}',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: esNube
                    ? AppColors.acceptedBtn.withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  esNube ? Icons.circle : Icons.swap_horiz_rounded,
                  size: esNube ? 9 : 16,
                  color: esNube
                      ? AppColors.acceptedBtn
                      : AppColors.formalizedText,
                ),
                const SizedBox(width: 5),
                Text(
                  esNube ? rolActivo : 'Soy: $rolActivo',
                  style: TextStyle(
                    color: esNube
                        ? AppColors.acceptedText
                        : AppColors.formalizedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
