import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/negociacion_model.dart';

/// Offline-first JSON persistence service backed by SharedPreferences.
class LocalStorageService {
  static const String _negociacionesKey = 'acuerdo_vecinal_negociaciones_v1';
  static const String _rolActivoKey = 'acuerdo_vecinal_rol_activo';

  /// Loads stored negotiations or returns null when storage is empty/corrupt.
  Future<List<NegociacionModel>?> cargarNegociaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_negociacionesKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NegociacionModel.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Persists the complete negotiations list as a JSON array.
  Future<void> guardarNegociaciones(List<NegociacionModel> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(lista.map((n) => n.toJson()).toList());
    await prefs.setString(_negociacionesKey, encoded);
  }

  /// Loads the currently active simulator department role, if saved.
  Future<String?> cargarRolActivo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rolActivoKey);
  }

  /// Saves the currently active simulator department role.
  Future<void> guardarRolActivo(String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rolActivoKey, rol);
  }
}
