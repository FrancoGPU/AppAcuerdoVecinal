import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/reglamento_data.dart';
import '../core/theme/app_theme.dart';
import '../models/negociacion_model.dart';
import '../providers/auth_provider.dart';
import '../providers/negociacion_provider.dart';
import '../providers/reglamento_provider.dart';
import '../widgets/estado_badge.dart';
import '../widgets/selector_campo_modal.dart';
import 'acta_acuerdo_screen.dart';

/// Condominium Administrator portal for managing dynamic bylaws,
/// viewing the invite code & neighbors, and auditing formalized agreements.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _abrirFormularioArticulo(
    BuildContext context, {
    required ReglamentoProvider reglamento,
    ArticuloReglamento? existente,
  }) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModalArticuloReglamento(
        reglamento: reglamento,
        existente: existente,
      ),
    );

    if (guardado == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              existente == null
                  ? 'Artículo agregado al reglamento del condominio'
                  : 'Artículo actualizado',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reglamento = context.watch<ReglamentoProvider>();
    final negociaciones = context.watch<NegociacionProvider>();
    final condominio = auth.condominioActual;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                condominio?.nombre ?? 'Panel Administrador',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Administración de Reglamento y Convivencia',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.adminPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            if (auth.esModoDemo)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => auth.cambiarVistaAdminDemo(false),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Vista Vecino'),
              ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () => auth.cerrarSesion(),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.adminPrimary,
            indicatorColor: AppColors.adminPrimary,
            tabs: [
              Tab(text: 'Reglamento'),
              Tab(text: 'Condominio'),
              Tab(text: 'Acuerdos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TabReglamento(
              reglamento: reglamento,
              onNuevo: () => _abrirFormularioArticulo(
                context,
                reglamento: reglamento,
              ),
              onEditar: (art) => _abrirFormularioArticulo(
                context,
                reglamento: reglamento,
                existente: art,
              ),
            ),
            _TabCondominio(auth: auth),
            _TabAcuerdosAdmin(negociaciones: negociaciones),
          ],
        ),
      ),
    );
  }
}

class _TabReglamento extends StatelessWidget {
  const _TabReglamento({
    required this.reglamento,
    required this.onNuevo,
    required this.onEditar,
  });

  final ReglamentoProvider reglamento;
  final VoidCallback onNuevo;
  final ValueChanged<ArticuloReglamento> onEditar;

  @override
  Widget build(BuildContext context) {
    final articulos = reglamento.articulos;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: articulos.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.adminBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.adminBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.adminPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${articulos.length} artículos vigentes. Los vecinos los usan como criterio objetivo al negociar y el Mediador IA los cita automáticamente.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final art = articulos[index - 1];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          art.etiqueta,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.adminBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          art.categoria,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.adminPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    art.resumen,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 34),
                        ),
                        onPressed: () => onEditar(art),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                      ),
                      if (articulos.length > 1)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.rejectedBtn,
                            minimumSize: const Size(0, 34),
                          ),
                          onPressed: () => reglamento.eliminarArticulo(art.id),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('Eliminar'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.adminPrimary,
        onPressed: onNuevo,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Artículo'),
      ),
    );
  }
}

class _TabCondominio extends StatelessWidget {
  const _TabCondominio({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final condominio = auth.condominioActual;
    final vecinos = auth.vecinosCondominio;
    final codigo = condominio?.codigoInvitacion ?? '---';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppColors.heroDark,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'CÓDIGO DE INVITACIÓN PARA VECINOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: Color(0xFF93C5FD),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        codigo,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: codigo));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('Código $codigo copiado'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copiar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Comparte este código con cada residente para que registre su departamento y negocie en tiempo real.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Vecinos registrados (${vecinos.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (auth.esModoNube)
              IconButton(
                tooltip: 'Actualizar lista',
                onPressed: auth.refrescarVecinos,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (vecinos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aún no hay vecinos registrados con este código.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          for (final vecino in vecinos) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.formalizedBg,
                  foregroundColor: AppColors.formalizedText,
                  child: const Icon(Icons.apartment_rounded, size: 20),
                ),
                title: Text(
                  vecino.departamento,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${vecino.nombre} • ${vecino.email}'),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _TabAcuerdosAdmin extends StatefulWidget {
  const _TabAcuerdosAdmin({required this.negociaciones});

  final NegociacionProvider negociaciones;

  @override
  State<_TabAcuerdosAdmin> createState() => _TabAcuerdosAdminState();
}

class _TabAcuerdosAdminState extends State<_TabAcuerdosAdmin> {
  String _filtro = 'Todos';

  @override
  Widget build(BuildContext context) {
    final todas = widget.negociaciones.negociaciones;
    final enCurso = todas
        .where((n) => n.estadoGeneral == EstadoNegociacion.enNegociacion)
        .length;
    final porFirmar = todas
        .where((n) => n.estadoGeneral == EstadoNegociacion.listoParaFirmar)
        .length;
    final formalizados = widget.negociaciones.formalizados;

    final filtradas = todas.where((n) {
      switch (_filtro) {
        case 'Activos':
          return !n.estaFormalizada;
        case 'Formalizados':
          return n.estaFormalizada;
        case 'Anónimos':
          return n.esAnonimo;
        default:
          return true;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Activos',
                value: '$enCurso',
                color: AppColors.pendingText,
                bg: AppColors.pendingBg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                label: 'Por firmar',
                value: '$porFirmar',
                color: AppColors.primary,
                bg: AppColors.formalizedBg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                label: 'Sellados',
                value: '${formalizados.length}',
                color: AppColors.acceptedText,
                bg: AppColors.acceptedBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.adminBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.adminBorder),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 18,
                color: AppColors.adminPrimary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Supervisión administrativa: los casos anónimos son visibles para seguimiento manteniendo oculto el departamento solicitante.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final opcion in const [
                'Todos',
                'Activos',
                'Formalizados',
                'Anónimos',
              ]) ...[
                ChoiceChip(
                  label: Text(opcion),
                  selected: _filtro == opcion,
                  onSelected: (_) => setState(() => _filtro = opcion),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Negociaciones del condominio (${filtradas.length})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (filtradas.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay negociaciones en esta vista.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.35),
              ),
            ),
          )
        else
          for (final item in filtradas) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.titulo,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        EstadoBadge.negociacion(item.estadoGeneral),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.nombreVisiblePara(item.dptoSolicitante, 'Administración')} ↔ ${item.dptoReceptor}  •  ${item.categoria}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (item.esAnonimo) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.argumentBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Anónimo • Identidad protegida',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (item.estaFormalizada) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 38),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ActaAcuerdoScreen(negociacionId: item.id),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 17,
                        ),
                        label: Text('Ver Acta (${item.codigoActa ?? 'PDF'})'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalArticuloReglamento extends StatefulWidget {
  const _ModalArticuloReglamento({
    required this.reglamento,
    this.existente,
  });

  final ReglamentoProvider reglamento;
  final ArticuloReglamento? existente;

  @override
  State<_ModalArticuloReglamento> createState() =>
      _ModalArticuloReglamentoState();
}

class _ModalArticuloReglamentoState extends State<_ModalArticuloReglamento> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _etiquetaCtrl;
  late final TextEditingController _resumenCtrl;
  late String _categoria;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _etiquetaCtrl = TextEditingController(
      text: widget.existente?.etiqueta ?? '',
    );
    _resumenCtrl = TextEditingController(
      text: widget.existente?.resumen ?? '',
    );
    _categoria = widget.existente?.categoria ?? kCategoriasReglamento.first;
  }

  @override
  void dispose() {
    _etiquetaCtrl.dispose();
    _resumenCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _guardando) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _guardando = true);

    try {
      if (widget.existente == null) {
        await widget.reglamento.agregarArticulo(
          etiqueta: _etiquetaCtrl.text,
          resumen: _resumenCtrl.text,
          categoria: _categoria,
        );
      } else {
        await widget.reglamento.actualizarArticulo(
          widget.existente!.copyWith(
            etiqueta: _etiquetaCtrl.text.trim(),
            resumen: _resumenCtrl.text.trim(),
            categoria: _categoria,
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
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
                Text(
                  widget.existente == null
                      ? 'Nuevo artículo del reglamento'
                      : 'Editar artículo del reglamento',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _etiquetaCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título o artículo',
                    hintText: 'Ej. Art. 35 - Uso de bicicletas',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return 'Ingresa un título válido (mín. 4 caracteres).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SelectorCampoModal(
                  labelText: 'Categoría aplicable',
                  valorSeleccionado: _categoria,
                  opciones: kCategoriasReglamento
                      .map((c) => OpcionSelector(valor: c, etiqueta: c))
                      .toList(),
                  onChanged: (val) => setState(() => _categoria = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _resumenCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Regla o criterio objetivo',
                    hintText:
                        'Ej. Las bicicletas deben estacionarse únicamente en el rack del sótano.',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Describe la norma en al menos 10 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                  ),
                  onPressed: _guardando ? null : _guardar,
                  child: Text(
                    widget.existente == null
                        ? 'Publicar en Reglamento'
                        : 'Guardar Cambios',
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
