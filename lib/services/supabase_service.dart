import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

import '../core/config/supabase_config.dart';
import '../core/constants/reglamento_data.dart';
import '../models/condominio_model.dart';
import '../models/mensaje_chat_model.dart';
import '../models/negociacion_model.dart';
import '../models/usuario_model.dart';

/// User-friendly domain exception raised for cloud auth and database operations.
class CloudBackendException implements Exception {
  const CloudBackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Session bundle returned after login, signup, or session recovery.
class SesionCondominio {
  const SesionCondominio({
    required this.perfil,
    required this.condominio,
  });

  final PerfilUsuario perfil;
  final CondominioModel condominio;
}

/// Pure-Dart Supabase gateway managing Auth, PostgREST CRUD, Realtime, and Edge Functions.
class SupabaseService {
  SupabaseClient? _client;
  SupabaseRuntimeConfig? _config;

  bool get estaListo => _client != null && (_config?.isConfigured ?? false);
  SupabaseRuntimeConfig? get configActual => _config;
  String? get usuarioIdActual => _client?.auth.currentUser?.id;

  /// Initializes or reconfigures the Supabase client with [config].
  Future<void> inicializar(SupabaseRuntimeConfig? config) async {
    if (_client != null) {
      await _client!.dispose();
      _client = null;
    }
    _config = config;
    if (config == null || !config.isConfigured) return;

    _client = SupabaseClient(
      config.normalizedUrl,
      config.anonKey.trim(),
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const CloudBackendException(
        'La conexión con Supabase aún no está configurada.',
      );
    }
    return client;
  }

  String? serializarSesionActual() {
    final session = _client?.auth.currentSession;
    if (session == null) return null;
    return jsonEncode(session.toJson());
  }

  /// Attempts to restore a previously stored session JSON, returning null on failure.
  Future<SesionCondominio?> restaurarSesion(String rawSessionJson) async {
    final client = _client;
    if (client == null || rawSessionJson.trim().isEmpty) return null;
    try {
      final response = await client.auth.recoverSession(rawSessionJson);
      final user = response.user ?? client.auth.currentUser;
      if (user == null) return null;
      return await cargarPerfilYCondominio(user.id);
    } catch (_) {
      return null;
    }
  }

  /// Registers a Condominium Administrator, creates the building and default bylaws.
  Future<SesionCondominio> registrarAdministrador({
    required String nombre,
    required String email,
    required String password,
    required String nombreCondominio,
    String direccion = '',
  }) async {
    final client = _requireClient();
    try {
      final authResp = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nombre': nombre.trim(),
          'rol': 'administrador',
        },
      );

      if (authResp.session == null) {
        throw const CloudBackendException(
          'Tu cuenta se creó, pero debes confirmar tu correo o desactivar "Confirm email" en Supabase Auth.',
        );
      }

      final rpcResult = await client.rpc(
        'registrar_admin_condominio',
        params: {
          'p_nombre': nombre.trim(),
          'p_email': email.trim(),
          'p_nombre_condominio': nombreCondominio.trim(),
          'p_direccion': direccion.trim(),
        },
      );

      return _parseSesionDesdeRpc(rpcResult);
    } catch (e) {
      throw CloudBackendException(_traducirError(e));
    }
  }

  /// Registers a Neighbor using the Condominium Invite Code provided by an Admin.
  Future<SesionCondominio> registrarVecino({
    required String nombre,
    required String email,
    required String password,
    required String departamento,
    required String codigoInvitacion,
  }) async {
    final client = _requireClient();
    final codigoLimpio = codigoInvitacion.trim().toUpperCase();
    try {
      final encontrado = await client.rpc(
        'buscar_condominio_por_codigo',
        params: {'p_codigo': codigoLimpio},
      );
      final rows = encontrado as List<dynamic>? ?? const [];
      if (rows.isEmpty) {
        throw const CloudBackendException(
          'Código de invitación inválido o inexistente.',
        );
      }

      final authResp = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nombre': nombre.trim(),
          'rol': 'vecino',
          'departamento': departamento.trim(),
        },
      );

      if (authResp.session == null) {
        throw const CloudBackendException(
          'Tu cuenta se creó, pero debes confirmar tu correo o desactivar "Confirm email" en Supabase Auth.',
        );
      }

      final rpcResult = await client.rpc(
        'registrar_vecino_condominio',
        params: {
          'p_nombre': nombre.trim(),
          'p_email': email.trim(),
          'p_departamento': departamento.trim(),
          'p_codigo_invitacion': codigoLimpio,
        },
      );

      return _parseSesionDesdeRpc(rpcResult);
    } catch (e) {
      throw CloudBackendException(_traducirError(e));
    }
  }

  /// Signs in with email and password and loads profile + condominium info.
  Future<SesionCondominio> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    try {
      final resp = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = resp.user ?? client.auth.currentUser;
      if (user == null) {
        throw const CloudBackendException('No se pudo validar el usuario.');
      }
      final sesion = await cargarPerfilYCondominio(user.id);
      if (sesion == null) {
        throw const CloudBackendException(
          'Tu usuario aún no tiene un condominio vinculado en Supabase.',
        );
      }
      return sesion;
    } catch (e) {
      throw CloudBackendException(_traducirError(e));
    }
  }

  Future<void> cerrarSesion() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (_) {}
  }

  /// Loads profile and condominium records for [userId].
  Future<SesionCondominio?> cargarPerfilYCondominio(String userId) async {
    final client = _client;
    if (client == null) return null;

    final perfilMap = await client
        .from('perfiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (perfilMap == null) return null;

    final perfil = PerfilUsuario.fromSupabaseMap(perfilMap);
    final condominioMap = await client
        .from('condominios')
        .select()
        .eq('id', perfil.condominioId)
        .maybeSingle();
    if (condominioMap == null) return null;

    final condominio = CondominioModel.fromSupabaseMap(condominioMap);
    return SesionCondominio(perfil: perfil, condominio: condominio);
  }

  /// Lists all neighbor profiles registered inside [condominioId].
  Future<List<PerfilUsuario>> cargarVecinosCondominio(
    String condominioId,
  ) async {
    final client = _requireClient();
    final rows = await client
        .from('perfiles')
        .select()
        .eq('condominio_id', condominioId)
        .eq('rol', 'vecino')
        .order('departamento', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((r) => PerfilUsuario.fromSupabaseMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Fetches the dynamic condominium bylaws ordered by [orden].
  Future<List<ArticuloReglamento>> cargarReglamento(String condominioId) async {
    final client = _requireClient();
    final rows = await client
        .from('reglamento_articulos')
        .select()
        .eq('condominio_id', condominioId)
        .order('orden', ascending: true)
        .order('created_at', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map(
          (r) => ArticuloReglamento.fromSupabaseMap(
            Map<String, dynamic>.from(r),
          ),
        )
        .toList();
  }

  /// Creates a new bylaw article (allowed for Administrators by RLS).
  Future<ArticuloReglamento> crearArticuloReglamento({
    required String condominioId,
    required ArticuloReglamento articulo,
  }) async {
    final client = _requireClient();
    try {
      final inserted = await client
          .from('reglamento_articulos')
          .insert(articulo.toSupabaseMap(condominioId))
          .select()
          .single();
      return ArticuloReglamento.fromSupabaseMap(inserted);
    } catch (e) {
      throw CloudBackendException(_traducirError(e));
    }
  }

  /// Updates an existing bylaw article.
  Future<ArticuloReglamento> actualizarArticuloReglamento({
    required String condominioId,
    required ArticuloReglamento articulo,
  }) async {
    final client = _requireClient();
    try {
      final updated = await client
          .from('reglamento_articulos')
          .update(articulo.toSupabaseMap(condominioId))
          .eq('id', articulo.id)
          .select()
          .single();
      return ArticuloReglamento.fromSupabaseMap(updated);
    } catch (e) {
      throw CloudBackendException(_traducirError(e));
    }
  }

  /// Deletes a bylaw article by [articuloId].
  Future<void> eliminarArticuloReglamento(String articuloId) async {
    final client = _requireClient();
    try {
      await client
          .from('reglamento_articulos')
          .delete()
          .eq('id', articuloId);
    } catch (e) {
      throw CloudBackendException(_traducirError(e));
    }
  }

  /// Fetches negotiations visible to the current user inside [condominioId].
  Future<List<NegociacionModel>> cargarNegociaciones(String condominioId) async {
    final client = _requireClient();
    final rows = await client
        .from('negociaciones')
        .select()
        .eq('condominio_id', condominioId)
        .order('fecha_creacion', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map(
          (r) => NegociacionModel.fromSupabaseMap(Map<String, dynamic>.from(r)),
        )
        .toList();
  }

  /// Persists a newly created negotiation row in Supabase.
  Future<NegociacionModel> crearNegociacion(NegociacionModel negociacion) async {
    final client = _requireClient();
    try {
      final inserted = await client
          .from('negociaciones')
          .insert(negociacion.toSupabaseMap())
          .select()
          .single();
      return NegociacionModel.fromSupabaseMap(inserted);
    } catch (e) {
      throw CloudBackendException(_traducirError(e));
    }
  }

  /// Updates an existing negotiation row in Supabase.
  Future<NegociacionModel> actualizarNegociacion(
    NegociacionModel negociacion,
  ) async {
    final client = _requireClient();
    try {
      final updated = await client
          .from('negociaciones')
          .update(negociacion.toSupabaseMap())
          .eq('id', negociacion.id)
          .select()
          .single();
      return NegociacionModel.fromSupabaseMap(updated);
    } catch (e) {
      throw CloudBackendException(_traducirError(e));
    }
  }

  /// Subscribes to live Realtime changes on [negociaciones] for [condominioId].
  RealtimeChannel? suscribirNegociaciones(
    String condominioId,
    VoidCallback onChange,
  ) {
    final client = _client;
    if (client == null) return null;
    final channel = client
        .channel('negociaciones_$condominioId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'negociaciones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'condominio_id',
            value: condominioId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    return channel;
  }

  /// Subscribes to live Realtime changes on [reglamento_articulos] for [condominioId].
  RealtimeChannel? suscribirReglamento(
    String condominioId,
    VoidCallback onChange,
  ) {
    final client = _client;
    if (client == null) return null;
    final channel = client
        .channel('reglamento_$condominioId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reglamento_articulos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'condominio_id',
            value: condominioId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    return channel;
  }

  /// Subscribes to live Realtime updates on [perfiles] (new neighbors joining).
  RealtimeChannel? suscribirPerfiles(
    String condominioId,
    VoidCallback onChange,
  ) {
    final client = _client;
    if (client == null) return null;
    final channel = client
        .channel('perfiles_$condominioId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'perfiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'condominio_id',
            value: condominioId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    return channel;
  }

  Future<void> removerCanal(RealtimeChannel? channel) async {
    final client = _client;
    if (client == null || channel == null) return;
    try {
      await client.removeChannel(channel);
    } catch (_) {}
  }

  /// Loads stored AI Mediator chat history for [negociacionId].
  Future<List<MensajeChatModel>> cargarMensajesMediador(
    String negociacionId,
  ) async {
    final client = _client;
    if (client == null) return const [];
    try {
      final rows = await client
          .from('mensajes_mediador')
          .select()
          .eq('negociacion_id', negociacionId)
          .order('created_at', ascending: true);

      return (rows as List<dynamic>)
          .whereType<Map>()
          .map((m) {
            final map = Map<String, dynamic>.from(m);
            return MensajeChatModel(
              id: map['id']?.toString() ?? '',
              negociacionId: map['negociacion_id']?.toString() ?? negociacionId,
              texto: map['texto'] as String? ?? '',
              esUsuario: map['es_usuario'] as bool? ?? true,
              fecha: DateTime.tryParse(map['created_at'] as String? ?? '') ??
                  DateTime.now(),
            );
          })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Saves a Mediator chat message into Supabase (best-effort).
  Future<void> guardarMensajeMediador(
    MensajeChatModel mensaje, {
    required String usuarioId,
  }) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('mensajes_mediador').insert({
        'id': mensaje.id,
        'negociacion_id': mensaje.negociacionId,
        'usuario_id': usuarioId,
        'texto': mensaje.texto,
        'es_usuario': mensaje.esUsuario,
      });
    } catch (_) {}
  }

  /// Calls the Supabase Edge Function `mediador-ia`. Returns null when unavailable.
  Future<Map<String, dynamic>?> invocarMediadorIa(
    Map<String, dynamic> payload,
  ) async {
    final client = _client;
    if (client == null) return null;
    try {
      final response = await client.functions.invoke(
        'mediador-ia',
        body: payload,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is String && data.trim().isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  SesionCondominio _parseSesionDesdeRpc(dynamic raw) {
    final map = raw is Map<String, dynamic>
        ? raw
        : raw is Map
            ? Map<String, dynamic>.from(raw)
            : throw const CloudBackendException(
                'Respuesta inesperada del servidor.',
              );
    final rawPerfil = map['perfil'];
    final rawCondominio = map['condominio'];
    if (rawPerfil is! Map || rawCondominio is! Map) {
      throw const CloudBackendException(
        'Faltan datos de perfil o condominio en la respuesta del servidor.',
      );
    }
    final perfilMap = Map<String, dynamic>.from(rawPerfil);
    final condominioMap = Map<String, dynamic>.from(rawCondominio);
    return SesionCondominio(
      perfil: PerfilUsuario.fromSupabaseMap(perfilMap),
      condominio: CondominioModel.fromSupabaseMap(condominioMap),
    );
  }

  String _traducirError(Object error) {
    if (error is CloudBackendException) return error.message;
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Correo o contraseña incorrectos.';
      }
      if (msg.contains('already registered') || msg.contains('user already')) {
        return 'Ese correo ya está registrado. Intenta iniciar sesión.';
      }
      if (msg.contains('password')) {
        return 'La contraseña debe tener al menos 6 caracteres.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Debes confirmar tu correo o desactivar "Confirm email" en Supabase.';
      }
      return error.message;
    }
    if (error is PostgrestException) {
      return error.message;
    }
    return 'No se pudo completar la operación en la nube: $error';
  }
}
