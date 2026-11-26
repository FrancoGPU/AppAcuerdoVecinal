import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

import '../core/config/supabase_config.dart';
import '../core/constants/reglamento_data.dart';
import '../data/local_storage_service.dart';
import '../models/condominio_model.dart';
import '../models/usuario_model.dart';
import '../services/supabase_service.dart';

/// Manages user authentication, Condominium metadata, Neighbor directory,
/// and seamless switching between Supabase Cloud mode and Local Demo mode.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    SupabaseService? supabaseService,
    LocalStorageService? storageService,
    bool? configuradoPorEntornoOverride,
  })  : _supabase = supabaseService ?? SupabaseService(),
        _storage = storageService ?? LocalStorageService(),
        _envOverride = configuradoPorEntornoOverride;

  final SupabaseService _supabase;
  final LocalStorageService _storage;
  final bool? _envOverride;

  PerfilUsuario? _usuarioActual;
  CondominioModel? _condominioActual;
  List<PerfilUsuario> _vecinosCondominio = [];
  SupabaseRuntimeConfig? _configSupabase;
  RealtimeChannel? _canalPerfiles;

  bool _inicializado = false;
  bool _cargando = false;
  String? _error;

  SupabaseService get supabase => _supabase;
  PerfilUsuario? get usuarioActual => _usuarioActual;
  CondominioModel? get condominioActual => _condominioActual;
  List<PerfilUsuario> get vecinosCondominio =>
      List.unmodifiable(_vecinosCondominio);
  SupabaseRuntimeConfig? get configSupabase => _configSupabase;

  bool get inicializado => _inicializado;
  bool get cargando => _cargando;
  String? get error => _error;

  bool get estaAutenticado => _usuarioActual != null;
  bool get esModoDemo => _usuarioActual?.esModoDemo ?? false;
  bool get esModoNube =>
      _usuarioActual != null &&
      !(_usuarioActual?.esModoDemo ?? true) &&
      _supabase.estaListo;
  bool get esAdministrador => _usuarioActual?.esAdmin ?? false;
  bool get configuradoPorEntorno =>
      _envOverride ?? (SupabaseRuntimeConfig.fromEnvironmentOrNull() != null);
  bool get supabaseConfigurado =>
      configuradoPorEntorno || (_configSupabase?.isConfigured ?? false);

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Loads compile-time or saved Supabase config and restores any active session.
  Future<void> inicializar() async {
    _cargando = true;
    notifyListeners();

    try {
      final envConfig = SupabaseRuntimeConfig.fromEnvironmentOrNull();
      final savedConfig = await _storage.cargarConfigSupabase();
      _configSupabase = envConfig ?? savedConfig;

      await _supabase.inicializar(_configSupabase);

      if (_supabase.estaListo) {
        final rawSession = await _storage.cargarSesionSupabase();
        if (rawSession != null && rawSession.trim().isNotEmpty) {
          final sesion = await _supabase.restaurarSesion(rawSession);
          if (sesion != null) {
            await _aplicarSesionNube(sesion);
            return;
          } else {
            await _storage.limpiarSesionSupabase();
          }
        }
      }

      final eraDemo = await _storage.cargarModoDemo();
      if (eraDemo) {
        await entrarModoDemo(notificar: false);
      }
    } finally {
      _inicializado = true;
      _cargando = false;
      notifyListeners();
    }
  }

  /// Saves runtime Supabase credentials and connects the client.
  Future<bool> configurarSupabase({
    required String url,
    required String anonKey,
  }) async {
    final cfg = SupabaseRuntimeConfig(url: url.trim(), anonKey: anonKey.trim());
    if (!cfg.isConfigured) {
      _error = 'Ingresa una Project URL (https://...) y una Anon Key válidas.';
      notifyListeners();
      return false;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _storage.guardarConfigSupabase(cfg);
      _configSupabase = cfg;
      await _supabase.inicializar(cfg);
      return true;
    } catch (e) {
      _error = 'No se pudo inicializar Supabase: $e';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Registers a new Condominium Administrator and creates the building invite code.
  Future<bool> registrarAdministrador({
    required String nombre,
    required String email,
    required String password,
    required String nombreCondominio,
    String direccion = '',
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final sesion = await _supabase.registrarAdministrador(
        nombre: nombre,
        email: email,
        password: password,
        nombreCondominio: nombreCondominio,
        direccion: direccion,
      );
      await _aplicarSesionNube(sesion);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Registers a Neighbor inside the building matching [codigoInvitacion].
  Future<bool> registrarVecino({
    required String nombre,
    required String email,
    required String password,
    required String departamento,
    required String codigoInvitacion,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final sesion = await _supabase.registrarVecino(
        nombre: nombre,
        email: email,
        password: password,
        departamento: departamento,
        codigoInvitacion: codigoInvitacion,
      );
      await _aplicarSesionNube(sesion);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Signs in to an existing cloud Neighbor or Administrator account.
  Future<bool> iniciarSesion({
    required String email,
    required String password,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final sesion = await _supabase.iniciarSesion(
        email: email,
        password: password,
      );
      await _aplicarSesionNube(sesion);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Starts Local Demo mode without requiring cloud credentials or internet.
  Future<void> entrarModoDemo({
    RolUsuario rolInicial = RolUsuario.vecino,
    bool notificar = true,
  }) async {
    await _limpiarCanalPerfiles();
    await _storage.guardarModoDemo(true);

    const condominioDemo = 'demo-residencial-cedros';
    _condominioActual = CondominioModel(
      id: condominioDemo,
      nombre: 'Residencial Los Cedros (Demo)',
      direccion: 'Av. Javier Prado Este 420, Lima',
      codigoInvitacion: 'DEMO-301',
      adminId: 'demo-admin',
      fechaCreacion: DateTime(2026, 11, 1),
    );

    _vecinosCondominio = const [
      PerfilUsuario(
        id: 'demo-vecino-301',
        email: 'vecino301@demo.local',
        nombre: 'Vecino 301',
        rol: RolUsuario.vecino,
        departamento: kDpto301,
        condominioId: condominioDemo,
        esModoDemo: true,
      ),
      PerfilUsuario(
        id: 'demo-vecino-402',
        email: 'vecino402@demo.local',
        nombre: 'Vecino 402',
        rol: RolUsuario.vecino,
        departamento: kDpto402,
        condominioId: condominioDemo,
        esModoDemo: true,
      ),
    ];

    _usuarioActual = PerfilUsuario(
      id: rolInicial == RolUsuario.administrador
          ? 'demo-admin'
          : 'demo-vecino-301',
      email: rolInicial == RolUsuario.administrador
          ? 'admin@demo.local'
          : 'vecino301@demo.local',
      nombre: rolInicial == RolUsuario.administrador
          ? 'Administración'
          : 'Demo Local',
      rol: rolInicial,
      departamento: rolInicial == RolUsuario.administrador
          ? 'Administración'
          : kDpto301,
      condominioId: condominioDemo,
      esModoDemo: true,
    );

    _error = null;
    if (notificar) {
      notifyListeners();
    }
  }

  /// Allows Local Demo users to switch cleanly between Neighbor and Admin views.
  Future<void> cambiarVistaAdminDemo(bool verComoAdmin) async {
    if (!esModoDemo || _condominioActual == null) return;
    _usuarioActual = PerfilUsuario(
      id: verComoAdmin ? 'demo-admin' : 'demo-vecino-301',
      email: verComoAdmin ? 'admin@demo.local' : 'vecino301@demo.local',
      nombre: verComoAdmin ? 'Administración' : 'Demo Local',
      rol: verComoAdmin ? RolUsuario.administrador : RolUsuario.vecino,
      departamento: verComoAdmin ? 'Administración' : kDpto301,
      condominioId: _condominioActual!.id,
      esModoDemo: true,
    );
    notifyListeners();
  }

  /// Refreshes the list of neighbors belonging to the active condominium.
  Future<void> refrescarVecinos() async {
    final condominioId = _condominioActual?.id;
    if (condominioId == null || !esModoNube) return;
    try {
      _vecinosCondominio = await _supabase.cargarVecinosCondominio(condominioId);
      notifyListeners();
    } catch (_) {}
  }

  /// Signs out from cloud or demo session and returns to [AuthScreen].
  Future<void> cerrarSesion() async {
    await _limpiarCanalPerfiles();
    if (_supabase.estaListo) {
      await _supabase.cerrarSesion();
    }
    await _storage.limpiarSesionSupabase();
    await _storage.guardarModoDemo(false);

    _usuarioActual = null;
    _condominioActual = null;
    _vecinosCondominio = [];
    _error = null;
    notifyListeners();
  }

  Future<void> _aplicarSesionNube(SesionCondominio sesion) async {
    await _limpiarCanalPerfiles();
    await _storage.guardarModoDemo(false);

    final rawSession = _supabase.serializarSesionActual();
    if (rawSession != null) {
      await _storage.guardarSesionSupabase(rawSession);
    }

    _usuarioActual = sesion.perfil;
    _condominioActual = sesion.condominio;
    _vecinosCondominio =
        await _supabase.cargarVecinosCondominio(sesion.condominio.id);

    _canalPerfiles = _supabase.suscribirPerfiles(
      sesion.condominio.id,
      refrescarVecinos,
    );
  }

  Future<void> _limpiarCanalPerfiles() async {
    if (_canalPerfiles != null) {
      await _supabase.removerCanal(_canalPerfiles);
      _canalPerfiles = null;
    }
  }

  @override
  void dispose() {
    if (_canalPerfiles != null) {
      _supabase.removerCanal(_canalPerfiles);
    }
    super.dispose();
  }
}
