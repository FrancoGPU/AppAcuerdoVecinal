import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/supabase_config.dart';
import '../core/constants/reglamento_data.dart';
import '../models/negociacion_model.dart';

/// Offline-first JSON persistence service backed by SharedPreferences.
class LocalStorageService {
  static const String _negociacionesKey = 'acuerdo_vecinal_negociaciones_v1';
  static const String _rolActivoKey = 'acuerdo_vecinal_rol_activo';
  static const String _reglamentoKey = 'acuerdo_vecinal_reglamento_v1';
  static const String _supabaseSessionKey = 'acuerdo_vecinal_supabase_session';
  static const String _supabaseConfigKey = 'acuerdo_vecinal_supabase_config';
  static const String _modoDemoKey = 'acuerdo_vecinal_modo_demo';

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

  /// Loads custom bylaws saved locally in Demo mode, or null if none exist.
  Future<List<ArticuloReglamento>?> cargarReglamento() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_reglamentoKey);
    if (rawJson == null || rawJson.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ArticuloReglamento.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Persists the local bylaws list in Demo mode.
  Future<void> guardarReglamento(List<ArticuloReglamento> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(lista.map((a) => a.toJson()).toList());
    await prefs.setString(_reglamentoKey, encoded);
  }

  /// Loads the serialized Supabase session JSON if present.
  Future<String?> cargarSesionSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_supabaseSessionKey);
  }

  /// Saves the serialized Supabase session JSON.
  Future<void> guardarSesionSupabase(String rawSession) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_supabaseSessionKey, rawSession);
  }

  /// Clears saved Supabase session JSON.
  Future<void> limpiarSesionSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_supabaseSessionKey);
  }

  /// Loads runtime-entered Supabase credentials when not bundled at build time.
  Future<SupabaseRuntimeConfig?> cargarConfigSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_supabaseConfigKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final cfg = SupabaseRuntimeConfig.fromJson(decoded);
      return cfg.isConfigured ? cfg : null;
    } catch (_) {
      return null;
    }
  }

  /// Saves runtime Supabase credentials entered inside the configuration modal.
  Future<void> guardarConfigSupabase(SupabaseRuntimeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_supabaseConfigKey, jsonEncode(config.toJson()));
  }

  /// Clears stored runtime Supabase credentials.
  Future<void> limpiarConfigSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_supabaseConfigKey);
  }

  /// Reads whether the user previously selected Local Demo mode.
  Future<bool> cargarModoDemo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_modoDemoKey) ?? false;
  }

  /// Persists whether the user is currently using Local Demo mode.
  Future<void> guardarModoDemo(bool activo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modoDemoKey, activo);
  }
}
