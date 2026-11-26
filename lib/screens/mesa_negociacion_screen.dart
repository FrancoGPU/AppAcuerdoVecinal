import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/reglamento_data.dart';
import '../core/theme/app_theme.dart';
import '../models/condicion_model.dart';
import '../models/negociacion_model.dart';
import '../providers/negociacion_provider.dart';
import '../providers/reglamento_provider.dart';
import '../services/mediador_ia_service.dart';
import '../widgets/dialogo_rechazo.dart';
import '../widgets/estado_badge.dart';
import '../widgets/modal_contrapropuesta.dart';
import '../widgets/modal_mediador_ia.dart';
import '../widgets/modal_reglamento.dart';
import '../widgets/role_switcher_chip.dart';
import '../widgets/selector_campo_modal.dart';
import '../widgets/tarjeta_condicion.dart';
import 'acta_acuerdo_screen.dart';

/// Core Harvard-method negotiation table showing interests, conditions, and actions.
class MesaNegociacionScreen extends StatelessWidget {
  const MesaNegociacionScreen({
    super.key,
    required this.negociacionId,
  });

  final String negociacionId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NegociacionProvider>();
    final negociacion = provider.obtenerPorId(negociacionId);

    if (negociacion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mesa de Negociación')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se encontró esta negociación.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rolActivo = provider.rolActivo;
    final esSolicitante = rolActivo == negociacion.dptoSolicitante;
    final otraParte = esSolicitante
        ? negociacion.dptoReceptor
        : negociacion.nombreVisiblePara(
            negociacion.dptoSolicitante,
            rolActivo,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          negociacion.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const RoleSwitcherChip(),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Reglamento Interno',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: () => mostrarModalReglamento(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.aiPrimary,
            ),
            tooltip: 'Mediador IA Harvard',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: () => mostrarModalMediadorIa(
              context,
              negociacionId: negociacion.id,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (negociacion.estaFormalizada) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.formalizedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.formalizedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Acuerdo formalizado (${negociacion.codigoActa ?? ''}) — modo solo lectura',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.formalizedText,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ActaAcuerdoScreen(
                            negociacionId: negociacion.id,
                          ),
                        ),
                      );
                    },
                    child: const Text('Ver Acta / PDF'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _EncabezadoConflicto(negociacion: negociacion, rolActivo: rolActivo),
          const SizedBox(height: 16),
          _PanelComparativoIntereses(
            negociacion: negociacion,
            rolActivo: rolActivo,
            onEditarMiInteres: () => _editarMiInteres(
              context,
              provider: provider,
              negociacion: negociacion,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Condiciones del Acuerdo',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${negociacion.condicionesAceptadasCount}/${negociacion.condiciones.length} aceptadas',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: negociacion.condiciones.isEmpty
                  ? 0
                  : negociacion.condicionesAceptadasCount /
                      negociacion.condiciones.length,
              minHeight: 5,
              backgroundColor: AppColors.argumentBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                negociacion.todasCondicionesAceptadas
                    ? AppColors.acceptedBtn
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < negociacion.condiciones.length; i++) ...[
            TarjetaCondicion(
              condicion: negociacion.condiciones[i],
              rolActivo: rolActivo,
              otraParte: otraParte,
              esFormalizada: negociacion.estaFormalizada,
              puedeEvaluar: provider.puedeEvaluarCondicion(
                negociacion.condiciones[i],
                negociacion,
              ),
              puedeContraofertar: provider.puedeContraofertarCondicion(
                negociacion.condiciones[i],
                negociacion,
              ),
              onAceptar: () => _aceptarCondicion(
                context,
                provider: provider,
                negociacion: negociacion,
                condicion: negociacion.condiciones[i],
              ),
              onRechazar: () => _rechazarCondicion(
                context,
                provider: provider,
                negociacion: negociacion,
                condicion: negociacion.condiciones[i],
              ),
              onContraofertar: () => _contraofertar(
                context,
                provider: provider,
                negociacion: negociacion,
                condicion: negociacion.condiciones[i],
              ),
            ),
            if (i < negociacion.condiciones.length - 1)
              const SizedBox(height: 12),
          ],
          if (!negociacion.estaFormalizada) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _agregarCondicion(
                context,
                provider: provider,
                negociacion: negociacion,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar otra condición'),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: _BottomFormalizacionBar(negociacion: negociacion),
    );
  }

  Future<void> _editarMiInteres(
    BuildContext context, {
    required NegociacionProvider provider,
    required NegociacionModel negociacion,
  }) async {
    final esSolicitante = provider.rolActivo == negociacion.dptoSolicitante;
    final valorActual = esSolicitante
        ? negociacion.interesSolicitante
        : negociacion.interesReceptor;

    final resultado = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditarInteres(
        rolActivo: provider.rolActivo,
        valorInicial: valorActual,
      ),
    );

    if (resultado == null) return;
    await provider.actualizarInteres(
      negociacionId: negociacion.id,
      nuevoInteres: resultado,
    );
  }

  Future<void> _aceptarCondicion(
    BuildContext context, {
    required NegociacionProvider provider,
    required NegociacionModel negociacion,
    required CondicionModel condicion,
  }) async {
    final ok = await provider.aceptarCondicion(
      negociacionId: negociacion.id,
      condicionId: condicion.id,
    );
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Condición "${condicion.tituloClausula}" aceptada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _rechazarCondicion(
    BuildContext context, {
    required NegociacionProvider provider,
    required NegociacionModel negociacion,
    required CondicionModel condicion,
  }) async {
    final motivo = await mostrarDialogoRechazo(
      context,
      tituloClausula: condicion.tituloClausula,
    );
    if (motivo == null) return;

    await provider.rechazarCondicion(
      negociacionId: negociacion.id,
      condicionId: condicion.id,
      motivoRechazo: motivo,
    );
  }

  Future<void> _contraofertar(
    BuildContext context, {
    required NegociacionProvider provider,
    required NegociacionModel negociacion,
    required CondicionModel condicion,
  }) async {
    final solicitarInteres = provider.rolActivo == negociacion.dptoReceptor &&
        negociacion.interesReceptor.trim().isEmpty;
    final esSolicitante = provider.rolActivo == negociacion.dptoSolicitante;
    final interesPropio = esSolicitante
        ? negociacion.interesSolicitante
        : negociacion.interesReceptor;
    final interesContraparte = esSolicitante
        ? negociacion.interesReceptor
        : negociacion.interesSolicitante;

    final result = await mostrarModalContrapropuesta(
      context,
      condicion: condicion,
      solicitarInteresReceptor: solicitarInteres,
      categoria: negociacion.categoria,
      interesPropio: interesPropio,
      interesContraparte: interesContraparte,
    );
    if (result == null) return;

    await provider.contraofertarCondicion(
      negociacionId: negociacion.id,
      condicionId: condicion.id,
      nuevaPropuesta: result.nuevaPropuesta,
      nuevoCriterioObjetivo: result.nuevoCriterioObjetivo,
      nuevoArgumentoPersuasivo: result.nuevoArgumentoPersuasivo,
      interesReceptorOpcional: result.interesReceptorOpcional,
    );
  }

  Future<void> _agregarCondicion(
    BuildContext context, {
    required NegociacionProvider provider,
    required NegociacionModel negociacion,
  }) async {
    final nueva = await showModalBottomSheet<_NuevaCondicionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModalAgregarCondicion(
        categoria: negociacion.categoria,
        interesPropio: provider.rolActivo == negociacion.dptoSolicitante
            ? negociacion.interesSolicitante
            : negociacion.interesReceptor,
      ),
    );

    if (nueva == null) return;
    await provider.agregarCondicion(
      negociacionId: negociacion.id,
      tituloClausula: nueva.tituloClausula,
      descripcionPropuesta: nueva.descripcionPropuesta,
      criterioObjetivo: nueva.criterioObjetivo,
      argumentoPersuasivo: nueva.argumentoPersuasivo,
    );
  }
}

class _DialogoEditarInteres extends StatefulWidget {
  const _DialogoEditarInteres({
    required this.rolActivo,
    required this.valorInicial,
  });

  final String rolActivo;
  final String valorInicial;

  @override
  State<_DialogoEditarInteres> createState() => _DialogoEditarInteresState();
}

class _DialogoEditarInteresState extends State<_DialogoEditarInteres> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.valorInicial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Interés de ${widget.rolActivo}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _ctrl,
          maxLines: 3,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Tu interés o necesidad real',
            hintText: 'Ej. Poder descansar sin ruidos desde las 10:00 p.m.',
          ),
          validator: (v) {
            if (v == null || v.trim().length < 8) {
              return 'Describe tu interés (mín. 8 caracteres).';
            }
            return null;
          },
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
          style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _NuevaCondicionResult {
  const _NuevaCondicionResult({
    required this.tituloClausula,
    required this.descripcionPropuesta,
    required this.criterioObjetivo,
    required this.argumentoPersuasivo,
  });

  final String tituloClausula;
  final String descripcionPropuesta;
  final String criterioObjetivo;
  final String argumentoPersuasivo;
}

class _ModalAgregarCondicion extends StatefulWidget {
  const _ModalAgregarCondicion({
    required this.categoria,
    required this.interesPropio,
  });

  final String categoria;
  final String interesPropio;

  @override
  State<_ModalAgregarCondicion> createState() => _ModalAgregarCondicionState();
}

class _ModalAgregarCondicionState extends State<_ModalAgregarCondicion> {
  final _formKey = GlobalKey<FormState>();
  final _clausulaCtrl = TextEditingController();
  final _propuestaCtrl = TextEditingController();
  final _argumentoCtrl = TextEditingController();
  late String _criterio;
  bool _mejorandoIa = false;

  List<ArticuloReglamento> _articulosDisponibles(BuildContext context) {
    final reg = Provider.of<ReglamentoProvider?>(context, listen: false);
    final lista = reg?.articulos;
    return (lista != null && lista.isNotEmpty) ? lista : kReglamentoInterno;
  }

  @override
  void initState() {
    super.initState();
    final articulos = _articulosDisponibles(context);
    _criterio = articulos.first.etiqueta;
  }

  @override
  void dispose() {
    _clausulaCtrl.dispose();
    _propuestaCtrl.dispose();
    _argumentoCtrl.dispose();
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
        interesPropio: widget.interesPropio,
        intentarNube: negProvider?.esModoNube ?? false,
      );

      if (!mounted) return;
      setState(() {
        _argumentoCtrl.text = sugerencia.argumentoMejorado;
        if (articulos.any((a) => a.etiqueta == sugerencia.criterioSugerido)) {
          _criterio = sugerencia.criterioSugerido;
        }
      });
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
      _NuevaCondicionResult(
        tituloClausula: _clausulaCtrl.text.trim(),
        descripcionPropuesta: _propuestaCtrl.text.trim(),
        criterioObjetivo: _criterio,
        argumentoPersuasivo: _argumentoCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final articulos = _articulosDisponibles(context);
    if (!articulos.any((a) => a.etiqueta == _criterio)) {
      _criterio = articulos.first.etiqueta;
    }

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
                const Text(
                  'Nueva condición',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _clausulaCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título de la cláusula',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return 'Ingresa un título breve.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _propuestaCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Propuesta concreta',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Detalla la propuesta (mín. 10 caracteres).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SelectorCampoModal(
                  labelText: 'Criterio Objetivo',
                  valorSeleccionado: _criterio,
                  opciones: articulos
                      .map(
                        (art) => OpcionSelector(
                          valor: art.etiqueta,
                          etiqueta: art.etiqueta,
                          subtitulo: art.resumen,
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _criterio = value),
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
                    onPressed:
                        _mejorandoIa ? null : _mejorarArgumentoConIa,
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
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 15) {
                      return 'Redacta un argumento (mín. 15 caracteres).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _enviar,
                    child: const Text('Añadir a la mesa'),
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

class _EncabezadoConflicto extends StatelessWidget {
  const _EncabezadoConflicto({
    required this.negociacion,
    required this.rolActivo,
  });

  final NegociacionModel negociacion;
  final String rolActivo;

  @override
  Widget build(BuildContext context) {
    final solicitante = negociacion.nombreVisiblePara(
      negociacion.dptoSolicitante,
      rolActivo,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.argumentBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      negociacion.categoria,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EstadoBadge.negociacion(negociacion.estadoGeneral),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$solicitante → ${negociacion.dptoReceptor}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (negociacion.descripcionProblema.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                negociacion.descripcionProblema,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PanelComparativoIntereses extends StatelessWidget {
  const _PanelComparativoIntereses({
    required this.negociacion,
    required this.rolActivo,
    required this.onEditarMiInteres,
  });

  final NegociacionModel negociacion;
  final String rolActivo;
  final VoidCallback onEditarMiInteres;

  @override
  Widget build(BuildContext context) {
    final solicitanteLabel = negociacion.nombreVisiblePara(
      negociacion.dptoSolicitante,
      rolActivo,
    );
    final receptorLabel = negociacion.dptoReceptor;
    final esSolicitante = rolActivo == negociacion.dptoSolicitante;
    final interesActual = esSolicitante
        ? negociacion.interesSolicitante
        : negociacion.interesReceptor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.balance_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Intereses Reales (Harvard)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!negociacion.estaFormalizada) ...[
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: onEditarMiInteres,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: Text(
                      interesActual.isEmpty ? 'Registrar' : 'Editar',
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CajaInteres(
                      parte: solicitanteLabel,
                      texto: negociacion.interesSolicitante,
                      destacado: esSolicitante,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CajaInteres(
                      parte: receptorLabel,
                      texto: negociacion.interesReceptor,
                      destacado: !esSolicitante,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CajaInteres extends StatelessWidget {
  const _CajaInteres({
    required this.parte,
    required this.texto,
    required this.destacado,
  });

  final String parte;
  final String texto;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final vacio = texto.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: destacado ? AppColors.formalizedBg : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: destacado
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parte,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color:
                  destacado ? AppColors.formalizedText : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            vacio ? 'Pendiente de registrar por la contraparte.' : texto,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              fontStyle: vacio ? FontStyle.italic : FontStyle.normal,
              color: vacio ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomFormalizacionBar extends StatelessWidget {
  const _BottomFormalizacionBar({required this.negociacion});

  final NegociacionModel negociacion;

  @override
  Widget build(BuildContext context) {
    final pendientes = negociacion.condicionesPendientesDeAceptar;
    final habilitado =
        negociacion.estaFormalizada || negociacion.todasCondicionesAceptadas;

    final String label;
    if (negociacion.estaFormalizada) {
      label = 'Ver Acta Formalizada';
    } else if (negociacion.todasCondicionesAceptadas) {
      label = 'Formalizar Acuerdo';
    } else if (pendientes == 1) {
      label = 'Falta 1 condición por aceptar';
    } else {
      label = 'Faltan $pendientes condiciones por aceptar';
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: habilitado
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ActaAcuerdoScreen(
                          negociacionId: negociacion.id,
                        ),
                      ),
                    );
                  }
                : null,
            icon: Icon(
              negociacion.estaFormalizada
                  ? Icons.verified_rounded
                  : Icons.draw_rounded,
            ),
            label: Text(label),
          ),
        ),
      ),
    );
  }
}
