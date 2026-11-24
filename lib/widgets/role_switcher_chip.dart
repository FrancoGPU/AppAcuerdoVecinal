import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/negociacion_provider.dart';

/// Quick role toggle chip placed in AppBars to switch between Dpto. 301 and 402.
class RoleSwitcherChip extends StatelessWidget {
  const RoleSwitcherChip({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NegociacionProvider>();
    final rolActivo = provider.rolActivo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Material(
        color: AppColors.formalizedBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await provider.alternarRol();
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text('Rol activo cambiado a ${provider.rolActivo}'),
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
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: AppColors.formalizedText,
                ),
                const SizedBox(width: 4),
                Text(
                  'Soy: $rolActivo',
                  style: const TextStyle(
                    color: AppColors.formalizedText,
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
