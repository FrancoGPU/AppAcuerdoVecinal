import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// Prompts the user for a mandatory reason before rejecting a condition.
Future<String?> mostrarDialogoRechazo(
  BuildContext context, {
  required String tituloClausula,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _DialogoRechazo(
      tituloClausula: tituloClausula,
    ),
  );
}

class _DialogoRechazo extends StatefulWidget {
  const _DialogoRechazo({required this.tituloClausula});

  final String tituloClausula;

  @override
  State<_DialogoRechazo> createState() => _DialogoRechazoState();
}

class _DialogoRechazoState extends State<_DialogoRechazo> {
  final _formKey = GlobalKey<FormState>();
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(_motivoCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Rechazar condición',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cláusula: "${widget.tituloClausula}"',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motivoCtrl,
              maxLines: 3,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo (obligatorio)',
                hintText:
                    'Explica qué aspecto no te resulta viable para facilitar una contraoferta.',
              ),
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Ingresa un motivo claro (mín. 5 caracteres).';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.rejectedBtn,
            minimumSize: const Size(0, 42),
          ),
          onPressed: _confirmar,
          child: const Text('Confirmar rechazo'),
        ),
      ],
    );
  }
}
