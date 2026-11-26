import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/reglamento_data.dart';
import '../data/local_storage_service.dart';
import '../services/supabase_service.dart';

/// Manages dynamic condominium bylaws (Admin CRUD + live Realtime sync for neighbors).
class ReglamentoProvider extends ChangeNotifier {
  ReglamentoProvider({
    LocalStorageService? storageService,
    SupabaseService? supabaseService,
    Uuid? uuid,
  })  : _storage = storageService ?? LocalStorageService(),
        _supabase = supabaseService,
        _uuid = uuid ?? const Uuid();

  final LocalStorageService _storage;
  final SupabaseService? _supabase;
  final Uuid _uuid;

  List<ArticuloReglamento> _articulos = List.of(kReglamentoInterno);
  String? _condominioId;
  bool _esModoNube = false;
  bool _cargando = false;
  RealtimeChannel? _canalReglamento;

  List<ArticuloReglamento> get articulos => List.unmodifiable(_articulos);
  bool get cargando => _cargando;
  bool get esModoNube => _esModoNube;

  /// Syncs the bylaws list with the active session (Cloud Realtime or Local storage).
  Future<void> sincronizarConSesion({
    String? condominioId,
    required bool esNube,
  }) async {
    await _limpiarCanal();
    _condominioId = condominioId;
    _esModoNube = esNube && (_supabase?.estaListo ?? false) && condominioId != null;
    _cargando = true;
    notifyListeners();

    try {
      if (_esModoNube) {
        final remotos = await _supabase!.cargarReglamento(condominioId!);
        _articulos = remotos.isEmpty ? List.of(kReglamentoInterno) : remotos;
        _canalReglamento = _supabase.suscribirReglamento(
          condominioId,
          _recargarDesdeNube,
        );
      } else {
        await inicializarLocal();
      }
    } catch (_) {
      _articulos = List.of(kReglamentoInterno);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Loads locally customized bylaws in Demo mode or seeds defaults.
  Future<void> inicializarLocal() async {
    final guardados = await _storage.cargarReglamento();
    if (guardados != null && guardados.isNotEmpty) {
      _articulos = guardados;
    } else {
      _articulos = List.of(kReglamentoInterno);
    }
    notifyListeners();
  }

  Future<void> _recargarDesdeNube() async {
    if (!_esModoNube || _condominioId == null || _supabase == null) return;
    try {
      final remotos = await _supabase.cargarReglamento(_condominioId!);
      _articulos = remotos;
      notifyListeners();
    } catch (_) {}
  }

  /// Finds an article by label inside the live bylaws (falling back to defaults).
  ArticuloReglamento? buscarPorEtiqueta(String etiqueta) {
    return buscarArticuloPorEtiqueta(etiqueta, _articulos) ??
        buscarArticuloPorEtiqueta(etiqueta, kReglamentoInterno);
  }

  /// Plain-text serialization of live bylaws used by the Gemini / local AI Mediator.
  String comoContextoTexto() => reglamentoComoContextoTexto(_articulos);

  /// Creates a new article in the condominium's bylaws.
  Future<ArticuloReglamento> agregarArticulo({
    required String etiqueta,
    required String resumen,
    required String categoria,
  }) async {
    final nuevo = ArticuloReglamento(
      id: _uuid.v4(),
      etiqueta: etiqueta.trim(),
      resumen: resumen.trim(),
      categoria: categoria,
      orden: _articulos.length + 1,
    );

    if (_esModoNube && _condominioId != null && _supabase != null) {
      final creado = await _supabase.crearArticuloReglamento(
        condominioId: _condominioId!,
        articulo: nuevo,
      );
      _articulos = [..._articulos, creado];
      notifyListeners();
      return creado;
    }

    _articulos = [..._articulos, nuevo];
    await _storage.guardarReglamento(_articulos);
    notifyListeners();
    return nuevo;
  }

  /// Updates an existing bylaw article.
  Future<bool> actualizarArticulo(ArticuloReglamento actualizado) async {
    final idx = _articulos.indexWhere((a) => a.id == actualizado.id);
    if (idx == -1) return false;

    if (_esModoNube && _condominioId != null && _supabase != null) {
      final guardado = await _supabase.actualizarArticuloReglamento(
        condominioId: _condominioId!,
        articulo: actualizado,
      );
      final copia = [..._articulos];
      copia[idx] = guardado;
      _articulos = copia;
      notifyListeners();
      return true;
    }

    final copia = [..._articulos];
    copia[idx] = actualizado;
    _articulos = copia;
    await _storage.guardarReglamento(_articulos);
    notifyListeners();
    return true;
  }

  /// Deletes a bylaw article by [id].
  Future<bool> eliminarArticulo(String id) async {
    final existe = _articulos.any((a) => a.id == id);
    if (!existe) return false;

    if (_esModoNube && _supabase != null) {
      await _supabase.eliminarArticuloReglamento(id);
    }

    _articulos = _articulos.where((a) => a.id != id).toList();
    if (!_esModoNube) {
      await _storage.guardarReglamento(_articulos);
    }
    notifyListeners();
    return true;
  }

  /// Restores the 6 baseline articles in Local Demo mode.
  Future<void> restaurarPorDefecto() async {
    if (_esModoNube) return;
    _articulos = List.of(kReglamentoInterno);
    await _storage.guardarReglamento(_articulos);
    notifyListeners();
  }

  Future<void> _limpiarCanal() async {
    if (_canalReglamento != null && _supabase != null) {
      await _supabase.removerCanal(_canalReglamento);
      _canalReglamento = null;
    }
  }

  @override
  void dispose() {
    if (_canalReglamento != null && _supabase != null) {
      _supabase.removerCanal(_canalReglamento);
    }
    super.dispose();
  }
}
