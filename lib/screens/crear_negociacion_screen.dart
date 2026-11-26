import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/reglamento_data.dart';
import '../core/theme/app_theme.dart';
import '../models/usuario_model.dart';
import '../providers/auth_provider.dart';
import '../providers/negociacion_provider.dart';
import '../providers/reglamento_provider.dart';
import '../services/mediador_ia_service.dart';
import '../widgets/selector_campo_modal.dart';
import 'mesa_negociacion_screen.dart';

/// Guided 3-card form to initiate a structured Harvard-method negotiation.
class CrearNegociacionScreen extends StatefulWidget {
  const CrearNegociacionScreen({super.key});

  @override
  State<CrearNegociacionScreen> createState() => _CrearNegociacionScreenState();
}

class _CrearNegociacionScreenState extends State<CrearNegociacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _interesCtrl = TextEditingController();
  final _clausulaCtrl = TextEditingController();
  final _propuestaCtrl = TextEditingController();
  final _argumentoCtrl = TextEditingController();

  String _categoria = kCategoriasConflicto.first;
  String _criterioObjetivo = kReglamentoInterno.first.etiqueta;
  String? _dptoReceptorSeleccionado;
  String? _receptorIdSeleccionado;
  bool _esAnonimo = false;
  bool _enviando = false;
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
    _criterioObjetivo = articulos.first.etiqueta;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _interesCtrl.dispose();
    _clausulaCtrl.dispose();
    _propuestaCtrl.dispose();
    _argumentoCtrl.dispose();
    super.dispose();
  }

  void _sincronizarCriterioPorCategoria(
    String categoria,
    List<ArticuloReglamento> articulos,
  ) {
    final coincidencia = articulos.where(
      (a) => a.categoria == categoria,
    );
    if (coincidencia.isNotEmpty) {
      _criterioObjetivo = coincidencia.first.etiqueta;
    } else {
      _criterioObjetivo = articulos.last.etiqueta;
    }
  }

  Future<void> _mejorarArgumentoConIa() async {
    if (_mejorandoIa) return;
    setState(() => _mejorandoIa = true);

    try {
      final articulos = _articulosDisponibles(context);
      final provider = context.read<NegociacionProvider>();
      final sugerencia = await provider.mediadorIa.mejorarArgumentoHarvard(
        categoria: _categoria,
        propuesta: _propuestaCtrl.text,
        borradorArgumento: _argumentoCtrl.text,
        reglamento: articulos,
        interesPropio: _interesCtrl.text,
        intentarNube: provider.esModoNube,
      );

      if (!mounted) return;
      setState(() {
        _argumentoCtrl.text = sugerencia.argumentoMejorado;
        if (articulos.any((a) => a.etiqueta == sugerencia.criterioSugerido)) {
          _criterioObjetivo = sugerencia.criterioSugerido;
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

  Future<void> _abrirAsistenteCasoIa(
    List<ArticuloReglamento> articulos,
  ) async {
    final provider = context.read<NegociacionProvider>();
    final estructurado = await showModalBottomSheet<CasoEstructuradoIa>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModalEstructurarCasoIa(
        mediadorIa: provider.mediadorIa,
        articulos: articulos,
        esModoNube: provider.esModoNube,
      ),
    );

    if (estructurado == null || !mounted) return;
    setState(() {
      _tituloCtrl.text = estructurado.titulo;
      _categoria = estructurado.categoria;
      _descripcionCtrl.text = estructurado.descripcionProblema;
      _interesCtrl.text = estructurado.interesSolicitante;
      _clausulaCtrl.text = estructurado.tituloClausula;
      _propuestaCtrl.text = estructurado.descripcionPropuesta;
      _criterioObjetivo = articulos.any(
        (a) => a.etiqueta == estructurado.criterioObjetivo,
      )
          ? estructurado.criterioObjetivo
          : articulos.first.etiqueta;
      _argumentoCtrl.text = estructurado.argumentoPersuasivo;
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            estructurado.esGeminiNube
                ? 'Caso completo estructurado con Gemini IA'
                : 'Caso completo estructurado con Enfoque Harvard',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate() || _enviando) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _enviando = true);

    final provider = context.read<NegociacionProvider>();
    final creada = await provider.crearNegociacion(
      titulo: _tituloCtrl.text,
      categoria: _categoria,
      descripcionProblema: _descripcionCtrl.text,
      esAnonimo: _esAnonimo,
      interesSolicitante: _interesCtrl.text,
      tituloClausulaInicial: _clausulaCtrl.text,
      descripcionPropuestaInicial: _propuestaCtrl.text,
      criterioObjetivoInicial: _criterioObjetivo,
      argumentoPersuasivoInicial: _argumentoCtrl.text,
      dptoReceptorOverride: _dptoReceptorSeleccionado,
      receptorIdOverride: _receptorIdSeleccionado,
    );

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MesaNegociacionScreen(negociacionId: creada.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NegociacionProvider>();
    final auth = Provider.of<AuthProvider?>(context);
    final articulos = _articulosDisponibles(context);
    if (!articulos.any((a) => a.etiqueta == _criterioObjetivo)) {
      _criterioObjetivo = articulos.first.etiqueta;
    }
    final articuloSeleccionado =
        buscarArticuloPorEtiqueta(_criterioObjetivo, articulos);

    final otrosVecinos = (auth != null && provider.esModoNube)
        ? auth.vecinosCondominio
            .where((v) => v.departamento != provider.rolActivo)
            .toList()
        : const <PerfilUsuario>[];

    if (otrosVecinos.isNotEmpty &&
        (_dptoReceptorSeleccionado == null ||
            !otrosVecinos
                .any((v) => v.departamento == _dptoReceptorSeleccionado))) {
      _dptoReceptorSeleccionado = otrosVecinos.first.departamento;
      _receptorIdSeleccionado = otrosVecinos.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nueva Negociación',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.aiPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _abrirAsistenteCasoIa(articulos),
              icon: const Icon(Icons.auto_awesome_rounded, size: 15),
              label: const Text(
                'Con IA',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SeccionCard(
                numero: '1',
                titulo: 'Datos del Conflicto',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (otrosVecinos.isNotEmpty) ...[
                      SelectorCampoModal(
                        labelText: 'Vecino destinatario',
                        valorSeleccionado: _dptoReceptorSeleccionado!,
                        opciones: otrosVecinos
                            .map(
                              (v) => OpcionSelector(
                                valor: v.departamento,
                                etiqueta: v.departamento,
                                subtitulo: v.nombre,
                              ),
                            )
                            .toList(),
                        onChanged: (dpto) {
                          final elegido = otrosVecinos.firstWhere(
                            (v) => v.departamento == dpto,
                          );
                          setState(() {
                            _dptoReceptorSeleccionado = elegido.departamento;
                            _receptorIdSeleccionado = elegido.id;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.formalizedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.swap_horizontal_circle_outlined,
                              size: 18,
                              color: AppColors.formalizedText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'De: ${provider.rolActivo}  →  Para: ${provider.otroDepartamento}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.formalizedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _tituloCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Título del conflicto',
                        hintText: 'Ej. Ruido de música después de las 10 p.m.',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 5) {
                          return 'Ingresa un título descriptivo (mín. 5 caracteres).';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SelectorCampoModal(
                      labelText: 'Categoría',
                      valorSeleccionado: _categoria,
                      opciones: kCategoriasConflicto
                          .map(
                            (cat) => OpcionSelector(valor: cat, etiqueta: cat),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoria = value;
                          _sincronizarCriterioPorCategoria(value, articulos);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descripción objetiva de la situación',
                        hintText:
                            'Describe los hechos concretos sin descalificaciones personales.',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) {
                          return 'Describe el contexto en al menos 10 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Modo Anónimo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Oculta tu número de departamento frente al vecino receptor.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _esAnonimo,
                      onChanged: (value) => setState(() => _esAnonimo = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SeccionCard(
                numero: '2',
                titulo: 'Tu Interés Real',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.argumentBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Enfoque Harvard: explica qué necesidad buscas proteger (descanso, seguridad, acceso) más allá de la exigencia puntual.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _interesCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Mi Interés',
                        hintText:
                            'Ej. Necesito dormir desde las 10 p.m. porque inicio turno a las 5:30 a.m.',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) {
                          return 'Explica tu interés real (mín. 10 caracteres).';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SeccionCard(
                numero: '3',
                titulo: 'Primera Condición y Argumento Persuasivo',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _clausulaCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Título de la cláusula',
                        hintText: 'Ej. Horario de música entre semana',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 4) {
                          return 'Ingresa un título breve para la cláusula.';
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
                        hintText:
                            'Ej. Reducir el volumen a nivel moderado desde las 10:00 p.m. de lunes a viernes.',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) {
                          return 'Detalla la propuesta en al menos 10 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SelectorCampoModal(
                      labelText: 'Criterio Objetivo (Base Normativa)',
                      valorSeleccionado: _criterioObjetivo,
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
                        setState(() => _criterioObjetivo = value);
                      },
                    ),
                    if (articuloSeleccionado != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.formalizedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          articuloSeleccionado.resumen,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.formalizedText,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          backgroundColor: Colors.transparent,
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed:
                            _mejorandoIa ? null : _mejorarArgumentoConIa,
                        icon: _mejorandoIa
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.auto_fix_high_rounded,
                                size: 14,
                              ),
                        label: Text(
                          _mejorandoIa ? 'Puliendo...' : 'Pulir tono',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
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
                            'Sustenta por qué esta solución es justa y conveniente para ambos.',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 15) {
                          return 'Redacta un argumento persuasivo de al menos 15 caracteres.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: const Text('Iniciar Negociación'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  const _SeccionCard({
    required this.numero,
    required this.titulo,
    required this.child,
  });

  final String numero;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    numero,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ModalEstructurarCasoIa extends StatefulWidget {
  const _ModalEstructurarCasoIa({
    required this.mediadorIa,
    required this.articulos,
    required this.esModoNube,
  });

  final MediadorIaService mediadorIa;
  final List<ArticuloReglamento> articulos;
  final bool esModoNube;

  @override
  State<_ModalEstructurarCasoIa> createState() =>
      _ModalEstructurarCasoIaState();
}

class _ModalEstructurarCasoIaState extends State<_ModalEstructurarCasoIa> {
  final _formKey = GlobalKey<FormState>();
  final _relatoCtrl = TextEditingController();
  bool _procesando = false;
  String? _mensajeFueraDeAlcance;

  @override
  void dispose() {
    _relatoCtrl.dispose();
    super.dispose();
  }

  Future<void> _generar() async {
    if (!_formKey.currentState!.validate() || _procesando) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _procesando = true;
      _mensajeFueraDeAlcance = null;
    });

    try {
      final resultado = await widget.mediadorIa.estructurarCasoHarvard(
        relatoUsuario: _relatoCtrl.text,
        reglamento: widget.articulos,
        intentarNube: widget.esModoNube,
      );
      if (!mounted) return;
      if (resultado.fueraDeAlcance) {
        setState(() {
          _mensajeFueraDeAlcance = resultado.motivoFueraDeAlcance ??
              'Describe una situación real de convivencia vecinal en tu condominio.';
        });
        return;
      }
      Navigator.of(context).pop(resultado);
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: AppColors.aiPrimary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estructurar caso con IA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Describe qué está pasando con tus propias palabras. La IA lo transformará en una solicitud respetuosa bajo el Método Harvard.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _relatoCtrl,
                  maxLines: 4,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '¿Qué problema vecinal quieres resolver?',
                    hintText:
                        'Ej. Mi vecino pone música muy fuerte después de las 11 p.m. y me cuesta madrugar al trabajo.',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Cuéntame un poco más (mín. 10 caracteres).';
                    }
                    return null;
                  },
                ),
                if (_mensajeFueraDeAlcance != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.pendingBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.pendingText.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.pendingText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _mensajeFueraDeAlcance!,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.pendingText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.aiPrimary,
                    ),
                    onPressed: _procesando ? null : _generar,
                    icon: _procesando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      _procesando
                          ? 'Estructurando caso...'
                          : 'Estructurar todo el caso',
                    ),
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
