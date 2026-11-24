import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/reglamento_data.dart';
import '../core/theme/app_theme.dart';
import '../models/negociacion_model.dart';
import '../providers/negociacion_provider.dart';
import '../widgets/estado_badge.dart';
import '../widgets/modal_reglamento.dart';
import '../widgets/role_switcher_chip.dart';
import 'crear_negociacion_screen.dart';
import 'mesa_negociacion_screen.dart';

/// Main inbox listing active and formalized neighborhood negotiations,
/// with category filtering, keyword search, turn badges, and bylaws lookup.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _busquedaCtrl = TextEditingController();
  String _categoriaFiltro = 'Todas';
  bool _mostrarBusqueda = false;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  List<NegociacionModel> _filtrar(List<NegociacionModel> origen) {
    final query = _busquedaCtrl.text.trim().toLowerCase();
    return origen.where((n) {
      if (_categoriaFiltro != 'Todas' && n.categoria != _categoriaFiltro) {
        return false;
      }
      if (query.isEmpty) return true;
      return n.titulo.toLowerCase().contains(query) ||
          n.descripcionProblema.toLowerCase().contains(query) ||
          n.categoria.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _confirmarRestaurarDemo(NegociacionProvider provider) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          '¿Restaurar casos de ejemplo?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Esta acción reemplazará los casos actuales por los 2 casos iniciales de demostración.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;
    await provider.restaurarDatosDemo();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Datos demo restaurados'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NegociacionProvider>();
    final activos = _filtrar(provider.activos);
    final formalizados = _filtrar(provider.formalizados);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'AcuerdoVecinal',
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _mostrarBusqueda
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
              ),
              tooltip: 'Buscar conflictos',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _mostrarBusqueda = !_mostrarBusqueda;
                  if (!_mostrarBusqueda) {
                    _busquedaCtrl.clear();
                  }
                });
              },
            ),
            const RoleSwitcherChip(),
            PopupMenuButton<String>(
              tooltip: 'Opciones',
              onSelected: (value) async {
                if (value == 'reglamento') {
                  await mostrarModalReglamento(context);
                } else if (value == 'restaurar') {
                  await _confirmarRestaurarDemo(provider);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'reglamento',
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Consultar Reglamento Interno')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'restaurar',
                  child: Row(
                    children: [
                      Icon(Icons.restart_alt_rounded, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Restaurar datos demo')),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Activos (${activos.length})'),
              Tab(text: 'Formalizados (${formalizados.length})'),
            ],
          ),
        ),
        body: provider.cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_mostrarBusqueda)
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: TextField(
                        controller: _busquedaCtrl,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar por título o descripción...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _busquedaCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _busquedaCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  _BarraFiltrosCategoria(
                    seleccionada: _categoriaFiltro,
                    onChanged: (cat) => setState(() => _categoriaFiltro = cat),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ListaNegociaciones(
                          items: activos,
                          provider: provider,
                          emptyTitle: _categoriaFiltro == 'Todas' &&
                                  _busquedaCtrl.text.trim().isEmpty
                              ? 'Sin negociaciones activas'
                              : 'Sin coincidencias en Activos',
                          emptySubtitle:
                              'Inicia una nueva negociación o ajusta el filtro para explorar otros casos.',
                          emptyIcon: Icons.forum_outlined,
                        ),
                        _ListaNegociaciones(
                          items: formalizados,
                          provider: provider,
                          emptyTitle: _categoriaFiltro == 'Todas' &&
                                  _busquedaCtrl.text.trim().isEmpty
                              ? 'Aún no hay acuerdos formalizados'
                              : 'Sin coincidencias en Formalizados',
                          emptySubtitle:
                              'Cuando todas las condiciones de un caso sean aceptadas y firmadas por ambas partes, el acta aparecerá aquí.',
                          emptyIcon: Icons.verified_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CrearNegociacionScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva Negociación'),
        ),
      ),
    );
  }
}

class _BarraFiltrosCategoria extends StatelessWidget {
  const _BarraFiltrosCategoria({
    required this.seleccionada,
    required this.onChanged,
  });

  final String seleccionada;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final categorias = ['Todas', ...kCategoriasConflicto];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < categorias.length; i++) ...[
              ChoiceChip(
                label: Text(categorias[i]),
                selected: seleccionada == categorias[i],
                onSelected: (_) => onChanged(categorias[i]),
                visualDensity: VisualDensity.compact,
              ),
              if (i < categorias.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListaNegociaciones extends StatelessWidget {
  const _ListaNegociaciones({
    required this.items,
    required this.provider,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  final List<NegociacionModel> items;
  final NegociacionProvider provider;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 52, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _NegociacionCard(
          item: item,
          rolActivo: provider.rolActivo,
          condicionesPorRevisar: provider.condicionesPorRevisarParaRol(item),
          faltaMiFirma: provider.faltaMiFirma(item),
        );
      },
    );
  }
}

class _NegociacionCard extends StatelessWidget {
  const _NegociacionCard({
    required this.item,
    required this.rolActivo,
    required this.condicionesPorRevisar,
    required this.faltaMiFirma,
  });

  final NegociacionModel item;
  final String rolActivo;
  final int condicionesPorRevisar;
  final bool faltaMiFirma;

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final solicitante = item.nombreVisiblePara(item.dptoSolicitante, rolActivo);
    final fechaTexto = formatoFecha.format(
      item.fechaFormalizacion ?? item.fechaCreacion,
    );
    final total = item.condiciones.length;
    final progreso =
        total == 0 ? 0.0 : item.condicionesAceptadasCount / total;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MesaNegociacionScreen(negociacionId: item.id),
            ),
          );
        },
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
                        item.categoria,
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
                  EstadoBadge.negociacion(item.estadoGeneral),
                ],
              ),
              if (faltaMiFirma || condicionesPorRevisar > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.formalizedBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    faltaMiFirma
                        ? 'Falta tu firma'
                        : 'Tu turno ($condicionesPorRevisar por revisar)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.formalizedText,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                item.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    item.esAnonimo
                        ? Icons.visibility_off_outlined
                        : Icons.apartment_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$solicitante → ${item.dptoReceptor}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 5,
                  backgroundColor: AppColors.argumentBg,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progreso >= 1.0
                        ? AppColors.acceptedBtn
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.condicionesAceptadasCount}/$total condiciones aceptadas',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.codigoActa != null
                          ? '${item.codigoActa} • $fechaTexto'
                          : fechaTexto,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
