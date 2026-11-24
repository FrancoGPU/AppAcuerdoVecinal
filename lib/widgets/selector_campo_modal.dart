import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// Option item displayed inside [SelectorCampoModal].
class OpcionSelector {
  const OpcionSelector({
    required this.valor,
    required this.etiqueta,
    this.subtitulo,
  });

  final String valor;
  final String etiqueta;
  final String? subtitulo;
}

/// Modal-sheet selector field that avoids Flutter DropdownRoute lifecycle bugs
/// and wraps long option titles cleanly on narrow mobile viewports.
class SelectorCampoModal extends StatelessWidget {
  const SelectorCampoModal({
    super.key,
    required this.labelText,
    required this.valorSeleccionado,
    required this.opciones,
    required this.onChanged,
  });

  final String labelText;
  final String valorSeleccionado;
  final List<OpcionSelector> opciones;
  final ValueChanged<String> onChanged;

  Future<void> _abrirSelector(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final seleccionado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.sizeOf(sheetCtx).height * 0.72;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          labelText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: opciones.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final opcion = opciones[index];
                      final activa = opcion.valor == valorSeleccionado;
                      return ListTile(
                        selected: activa,
                        selectedTileColor: AppColors.formalizedBg,
                        title: Text(
                          opcion.etiqueta,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                activa ? FontWeight.w700 : FontWeight.w500,
                            color: activa
                                ? AppColors.formalizedText
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: opcion.subtitulo != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  opcion.subtitulo!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              )
                            : null,
                        trailing: Icon(
                          activa
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: activa
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        onTap: () => Navigator.of(sheetCtx).pop(opcion.valor),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (seleccionado != null) {
      onChanged(seleccionado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final etiquetaActual = opciones
        .firstWhere(
          (o) => o.valor == valorSeleccionado,
          orElse: () => OpcionSelector(
            valor: valorSeleccionado,
            etiqueta: valorSeleccionado,
          ),
        )
        .etiqueta;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _abrirSelector(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          etiquetaActual,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
