import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/condicion_model.dart';
import 'estado_badge.dart';

/// Displays an individual negotiable condition with persuasive argument,
/// round history, and turn-controlled action buttons.
class TarjetaCondicion extends StatelessWidget {
  const TarjetaCondicion({
    super.key,
    required this.condicion,
    required this.rolActivo,
    required this.otraParte,
    required this.esFormalizada,
    required this.puedeEvaluar,
    required this.puedeContraofertar,
    required this.onAceptar,
    required this.onRechazar,
    required this.onContraofertar,
  });

  final CondicionModel condicion;
  final String rolActivo;
  final String otraParte;
  final bool esFormalizada;
  final bool puedeEvaluar;
  final bool puedeContraofertar;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;
  final VoidCallback onContraofertar;

  @override
  Widget build(BuildContext context) {
    final formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    condicion.tituloClausula,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EstadoBadge.condicion(condicion.estado),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Última oferta: ${condicion.autorUltimaOferta}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              condicion.descripcionPropuesta,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.argumentBg,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Argumento persuasivo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    condicion.argumentoPersuasivo,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            condicion.criterioObjetivo,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (condicion.estado == EstadoCondicion.rechazada &&
                condicion.motivoRechazo != null &&
                condicion.motivoRechazo!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.rejectedBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.rejectedBtn.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Motivo del rechazo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rejectedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condicion.motivoRechazo!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.rejectedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (condicion.historial.isNotEmpty) ...[
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  title: Text(
                    'Ver historial de ofertas (${condicion.historial.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  children: condicion.historial.map((ronda) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ronda.autor,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatoFechaHora.format(ronda.fecha),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ronda.propuestaAnterior,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Argumento: ${ronda.argumentoAnterior}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (!esFormalizada) ...[
              const SizedBox(height: 12),
              _construirPieAcciones(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirPieAcciones() {
    if (condicion.estado == EstadoCondicion.aceptada) {
      return const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.acceptedText,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Cláusula aceptada por ambas partes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.acceptedText,
              ),
            ),
          ),
        ],
      );
    }

    if (puedeEvaluar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (condicion.estado != EstadoCondicion.rechazada) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rejectedBtn,
                      side: const BorderSide(color: AppColors.rejectedBtn),
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: onRechazar,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.acceptedBtn,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: onAceptar,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Aceptar'),
                ),
              ),
            ],
          ),
          if (puedeContraofertar) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(0, 44),
              ),
              onPressed: onContraofertar,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Contraofertar'),
            ),
          ],
        ],
      );
    }

    if (puedeContraofertar) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(0, 44),
        ),
        onPressed: onContraofertar,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Reformular propuesta'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pendingBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            size: 16,
            color: AppColors.pendingText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esperando respuesta de $otraParte',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.pendingText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
