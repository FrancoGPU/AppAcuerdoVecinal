import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/reglamento_data.dart';
import '../core/theme/app_theme.dart';
import '../providers/negociacion_provider.dart';
import '../providers/reglamento_provider.dart';

/// Interactive bottom sheet providing impartial Harvard-method AI mediation
/// backed by Gemini Flash in Cloud mode and deterministic local guidance offline.
Future<void> mostrarModalMediadorIa(
  BuildContext context, {
  required String negociacionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ModalMediadorIa(negociacionId: negociacionId),
  );
}

class _ModalMediadorIa extends StatefulWidget {
  const _ModalMediadorIa({required this.negociacionId});

  final String negociacionId;

  @override
  State<_ModalMediadorIa> createState() => _ModalMediadorIaState();
}

class _ModalMediadorIaState extends State<_ModalMediadorIa> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  static const List<String> _sugerenciasRapidas = [
    'Sugerir punto medio',
    '¿Qué artículo del reglamento aplica?',
    'Redactar propuesta empática',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<NegociacionProvider>()
          .cargarMensajesMediador(widget.negociacionId);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar(String texto) async {
    final consulta = texto.trim();
    if (consulta.isEmpty) return;

    _inputCtrl.clear();
    final negProvider = context.read<NegociacionProvider>();
    final regProvider = Provider.of<ReglamentoProvider?>(context, listen: false);
    final articulos = regProvider?.articulos ?? kReglamentoInterno;

    await negProvider.enviarConsultaMediador(
      negociacionId: widget.negociacionId,
      consulta: consulta,
      reglamento: articulos,
    );

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final negProvider = context.watch<NegociacionProvider>();
    final mensajes = negProvider.mensajesMediadorPara(widget.negociacionId);
    final consultando = negProvider.consultandoIa;
    final esNube = negProvider.esModoNube;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.aiBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: AppColors.aiPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mediador IA Harvard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Orientación imparcial basada en el reglamento vivo',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.aiBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.aiBorder),
                          ),
                          child: Text(
                            esNube ? 'Gemini Flash' : 'Asistente Local',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.aiPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _sugerenciasRapidas.length; i++) ...[
                      ActionChip(
                        backgroundColor: AppColors.aiBg,
                        side: const BorderSide(color: AppColors.aiBorder),
                        label: Text(
                          _sugerenciasRapidas[i],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.aiPrimary,
                          ),
                        ),
                        onPressed: consultando
                            ? null
                            : () => _enviar(_sugerenciasRapidas[i]),
                      ),
                      if (i < _sugerenciasRapidas.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: mensajes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.aiBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.aiBorder),
                          ),
                          child: const Text(
                            'Pregunta cómo destrabar un punto, qué artículo del reglamento aplica o cómo formular una contrapropuesta sin escalar el conflicto.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        shrinkWrap: true,
                        itemCount: mensajes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final msg = mensajes[index];
                          return Align(
                            alignment: msg.esUsuario
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: msg.esUsuario
                                    ? AppColors.primary
                                    : AppColors.aiBg,
                                borderRadius: BorderRadius.circular(12),
                                border: msg.esUsuario
                                    ? null
                                    : Border.all(color: AppColors.aiBorder),
                              ),
                              child: Text(
                                msg.texto,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: msg.esUsuario
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (consultando)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.aiPrimary,
                    backgroundColor: AppColors.aiBg,
                  ),
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: consultando ? null : _enviar,
                        decoration: const InputDecoration(
                          hintText: 'Consulta al Mediador IA...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.aiPrimary,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed:
                          consultando ? null : () => _enviar(_inputCtrl.text),
                      child: const Icon(Icons.send_rounded, size: 19),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
