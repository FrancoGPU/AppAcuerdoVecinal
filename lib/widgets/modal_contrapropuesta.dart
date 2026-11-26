import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/reglamento_data.dart';
import '../core/theme/app_theme.dart';
import '../models/condicion_model.dart';
import '../providers/negociacion_provider.dart';
import '../providers/reglamento_provider.dart';
import '../services/mediador_ia_service.dart';
import 'selector_campo_modal.dart';

/// Data returned by the counter-offer bottom sheet modal.
class ContrapropuestaResult {
  const ContrapropuestaResult({
    required this.nuevaPropuesta,
    required this.nuevoCriterioObjetivo,
    required this.nuevoArgumentoPersuasivo,
    this.interesReceptorOpcional,
  });

  final String nuevaPropuesta;
  final String nuevoCriterioObjetivo;
  final String nuevoArgumentoPersuasivo;
  final String? interesReceptorOpcional;
}

/// Opens a ModalBottomSheet to draft a counter-offer with objective criterion and argument.
Future<ContrapropuestaResult?> mostrarModalContrapropuesta(
  BuildContext context, {
  required CondicionModel condicion,
  required bool solicitarInteresReceptor,
  String categoria = 'Otros',
  String interesPropio = '',
  String interesContraparte = '',
}) {
  return showModalBottomSheet<ContrapropuestaResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ModalContrapropuesta(
      condicion: condicion,
      solicitarInteresReceptor: solicitarInteresReceptor,
      categoria: categoria,
      interesPropio: interesPropio,
      interesContraparte: interesContraparte,
    ),
  );
}

class _ModalContrapropuesta extends StatefulWidget {
  const _ModalContrapropuesta({
    required this.condicion,
    required this.solicitarInteresReceptor,
    required this.categoria,
    required this.interesPropio,
    required this.interesContraparte,
  });

  final CondicionModel condicion;
  final bool solicitarInteresReceptor;
  final String categoria;
  final String interesPropio;
  final String interesContraparte;

  @override
  State<_ModalContrapropuesta> createState() => _ModalContrapropuestaState();
}

class _ModalContrapropuestaState extends State<_ModalContrapropuesta> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _propuestaCtrl;
  late final TextEditingController _argumentoCtrl;
  late final TextEditingController _interesCtrl;
  late String _criterioSeleccionado;
  bool _mejorandoIa = false;

  List<ArticuloReglamento> _articulosDisponibles(BuildContext context) {
    final provider = Provider.of<ReglamentoProvider?>(context, listen: false);
    final lista = provider?.articulos;
    return (lista != null && lista.isNotEmpty) ? lista : kReglamentoInterno;
  }

  @override
  void initState() {
    super.initState();
    _propuestaCtrl = TextEditingController(
      text: widget.condicion.descripcionPropuesta,
    );
    _argumentoCtrl = TextEditingController();
    _interesCtrl = TextEditingController();

    final articulos = _articulosDisponibles(context);
    final existe = articulos.any(
      (a) => a.etiqueta == widget.condicion.criterioObjetivo,
    );
    _criterioSeleccionado = existe
        ? widget.condicion.criterioObjetivo
        : articulos.first.etiqueta;
  }

  @override
  void dispose() {
    _propuestaCtrl.dispose();
    _argumentoCtrl.dispose();
    _interesCtrl.dispose();
    super.dispose();
  }

  Future<void> _mejorarArgumentoConIa() async {
    if (_mejorandoIa) return;
    setState(() => _mejorandoIa = true);

    try {
      final articulos = _articulosDisponibles(context);
      final negProvider = Provider.of<NegociacionProvider?>(
        context,
        listen: false,
      );
      final servicioIa = negProvider?.mediadorIa ?? const MediadorIaService();

      final sugerencia = await servicioIa.mejorarArgumentoHarvard(
        categoria: widget.categoria,
        propuesta: _propuestaCtrl.text,
        borradorArgumento: _argumentoCtrl.text,
        reglamento: articulos,
        interesPropio: _interesCtrl.text.trim().isNotEmpty
            ? _interesCtrl.text
            : widget.interesPropio,
        interesContraparte: widget.interesContraparte,
        intentarNube: negProvider?.esModoNube ?? false,
      );

      if (!mounted) return;
      setState(() {
        _argumentoCtrl.text = sugerencia.argumentoMejorado;
        if (articulos.any((a) => a.etiqueta == sugerencia.criterioSugerido)) {
          _criterioSeleccionado = sugerencia.criterioSugerido;
        }
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              sugerencia.esGeminiNube
                  ? 'Argumento optimizado con Gemini Flash'
                  : 'Argumento optimizado con Enfoque Harvard',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _mejorandoIa = false);
      }
    }
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      ContrapropuestaResult(
        nuevaPropuesta: _propuestaCtrl.text.trim(),
        nuevoCriterioObjetivo: _criterioSeleccionado,
        nuevoArgumentoPersuasivo: _argumentoCtrl.text.trim(),
        interesReceptorOpcional: widget.solicitarInteresReceptor
            ? _interesCtrl.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final articulos = _articulosDisponibles(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 14),
                Text(
                  'Contraofertar: ${widget.condicion.tituloClausula}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'La propuesta actual se guardará en el historial de rondas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.solicitarInteresReceptor) ...[
                  TextFormField(
                    controller: _interesCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Tu interés real (opcional)',
                      hintText:
                          'Explica qué necesidad buscas cuidar en este acuerdo.',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _propuestaCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nueva propuesta concreta',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Describe la contrapropuesta (mín. 10 caracteres).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SelectorCampoModal(
                  labelText: 'Criterio Objetivo',
                  valorSeleccionado: _criterioSeleccionado,
                  opciones: articulos
                      .map(
                        (art) => OpcionSelector(
                          valor: art.etiqueta,
                          etiqueta: art.etiqueta,
                          subtitulo: art.resumen,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _criterioSeleccionado = value);
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.aiPrimary,
                      backgroundColor: AppColors.aiBg,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: _mejorandoIa ? null : _mejorarArgumentoConIa,
                    icon: _mejorandoIa
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 15),
                    label: Text(
                      _mejorandoIa ? 'Redactando...' : 'Mejorar con IA',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _argumentoCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Argumento persuasivo',
                    hintText:
                        'Sustenta por qué esta alternativa atiende los intereses de ambos.',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 15) {
                      return 'Redacta un argumento persuasivo (mín. 15 caracteres).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _enviar,
                    child: const Text('Enviar Contrapropuesta'),
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
