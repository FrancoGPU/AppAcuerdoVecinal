import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/reglamento_data.dart';
import '../core/theme/app_theme.dart';
import '../providers/negociacion_provider.dart';
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
  bool _esAnonimo = false;
  bool _enviando = false;

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

  void _sincronizarCriterioPorCategoria(String categoria) {
    final coincidencia = kReglamentoInterno.where(
      (a) => a.categoria == categoria,
    );
    if (coincidencia.isNotEmpty) {
      _criterioObjetivo = coincidencia.first.etiqueta;
    } else {
      _criterioObjetivo = kReglamentoInterno.last.etiqueta;
    }
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
    final articuloSeleccionado = buscarArticuloPorEtiqueta(_criterioObjetivo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Negociación'),
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
                          _sincronizarCriterioPorCategoria(value);
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
                      opciones: kReglamentoInterno
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
                    const SizedBox(height: 12),
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
