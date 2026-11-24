import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../models/condicion_model.dart';
import '../models/negociacion_model.dart';

/// Semantic status pill used across case cards and condition cards.
class EstadoBadge extends StatelessWidget {
  const EstadoBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  });

  factory EstadoBadge.negociacion(EstadoNegociacion estado) {
    switch (estado) {
      case EstadoNegociacion.enNegociacion:
        return const EstadoBadge(
          label: 'En negociación',
          textColor: AppColors.pendingText,
          backgroundColor: AppColors.pendingBg,
          icon: Icons.hourglass_top_rounded,
        );
      case EstadoNegociacion.listoParaFirmar:
        return const EstadoBadge(
          label: 'Listo para firmar',
          textColor: AppColors.acceptedText,
          backgroundColor: AppColors.acceptedBg,
          icon: Icons.verified_outlined,
        );
      case EstadoNegociacion.formalizada:
        return const EstadoBadge(
          label: 'Formalizada',
          textColor: AppColors.formalizedText,
          backgroundColor: AppColors.formalizedBg,
          icon: Icons.gavel_rounded,
        );
    }
  }

  factory EstadoBadge.condicion(EstadoCondicion estado) {
    switch (estado) {
      case EstadoCondicion.pendiente:
        return const EstadoBadge(
          label: 'Pendiente',
          textColor: AppColors.pendingText,
          backgroundColor: AppColors.pendingBg,
          icon: Icons.schedule_rounded,
        );
      case EstadoCondicion.aceptada:
        return const EstadoBadge(
          label: 'Aceptada',
          textColor: AppColors.acceptedText,
          backgroundColor: AppColors.acceptedBg,
          icon: Icons.check_circle_outline_rounded,
        );
      case EstadoCondicion.rechazada:
        return const EstadoBadge(
          label: 'Rechazada',
          textColor: AppColors.rejectedText,
          backgroundColor: AppColors.rejectedBg,
          icon: Icons.cancel_outlined,
        );
    }
  }

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
