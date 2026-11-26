import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/usuario_model.dart';
import '../providers/auth_provider.dart';

/// Polished Authentication, Condominium onboarding (Admin vs Neighbor), and Demo entry screen.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  final _regNombreCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regDptoCtrl = TextEditingController();
  final _regCodigoCtrl = TextEditingController();
  final _regCondoNombreCtrl = TextEditingController();
  final _regCondoDirCtrl = TextEditingController();

  int _tabIndex = 0; // 0 = Ingresar, 1 = Crear cuenta
  RolUsuario _rolRegistro = RolUsuario.vecino;
  bool _verPassword = false;

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNombreCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regDptoCtrl.dispose();
    _regCodigoCtrl.dispose();
    _regCondoNombreCtrl.dispose();
    _regCondoDirCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirConfiguracionSupabase(AuthProvider auth) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoConfigSupabase(auth: auth),
    );

    if (guardado == true && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Conexión Supabase guardada correctamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _enviarLogin(AuthProvider auth) async {
    if (!auth.supabaseConfigurado) {
      await _abrirConfiguracionSupabase(auth);
      return;
    }
    if (!_loginFormKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await auth.iniciarSesion(
      email: _loginEmailCtrl.text,
      password: _loginPassCtrl.text,
    );
  }

  Future<void> _enviarRegistro(AuthProvider auth) async {
    if (!auth.supabaseConfigurado) {
      await _abrirConfiguracionSupabase(auth);
      return;
    }
    if (!_registerFormKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (_rolRegistro == RolUsuario.administrador) {
      await auth.registrarAdministrador(
        nombre: _regNombreCtrl.text,
        email: _regEmailCtrl.text,
        password: _regPassCtrl.text,
        nombreCondominio: _regCondoNombreCtrl.text,
        direccion: _regCondoDirCtrl.text,
      );
    } else {
      await auth.registrarVecino(
        nombre: _regNombreCtrl.text,
        email: _regEmailCtrl.text,
        password: _regPassCtrl.text,
        departamento: _regDptoCtrl.text,
        codigoInvitacion: _regCodigoCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 44, 22, 54),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B1120),
                      AppColors.heroBlue,
                      AppColors.primary,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.handshake_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AcuerdoVecinal',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Mediación vecinal Método Harvard',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _abrirConfiguracionSupabase(auth),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: auth.supabaseConfigurado
                                    ? const Color(0xFF34D399)
                                        .withValues(alpha: 0.65)
                                    : Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  auth.supabaseConfigurado
                                      ? Icons.circle
                                      : Icons.settings_outlined,
                                  size: auth.supabaseConfigurado ? 8 : 13,
                                  color: auth.supabaseConfigurado
                                      ? const Color(0xFF34D399)
                                      : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  auth.supabaseConfigurado
                                      ? 'Nube lista'
                                      : 'Configurar nube',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tabIndex == 0
                          ? 'Ingresa con tu cuenta para negociar acuerdos en tiempo real y emitir Actas PDF.'
                          : 'Únete con el código de tu condominio o registra tu edificio como Administrador.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -28,
                top: -20,
                child: IgnorePointer(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (auth.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.rejectedBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.rejectedBtn
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: AppColors.rejectedText,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.rejectedText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.argumentBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _SegmentedTabButton(
                                  label: 'Ingresar',
                                  selected: _tabIndex == 0,
                                  onTap: () {
                                    auth.limpiarError();
                                    setState(() => _tabIndex = 0);
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _SegmentedTabButton(
                                  label: 'Crear cuenta',
                                  selected: _tabIndex == 1,
                                  onTap: () {
                                    auth.limpiarError();
                                    setState(() => _tabIndex = 1);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_tabIndex == 0)
                          _buildLoginForm(auth)
                        else
                          _buildRegisterForm(auth),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '¿Quieres probar sin cuenta?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: auth.cargando
                              ? null
                              : () => auth.entrarModoDemo(
                                    rolInicial: RolUsuario.vecino,
                                  ),
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Demo Vecino'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.adminPrimary,
                            side: BorderSide(
                              color:
                                  AppColors.adminPrimary.withValues(alpha: 0.4),
                            ),
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: auth.cargando
                              ? null
                              : () => auth.entrarModoDemo(
                                    rolInicial: RolUsuario.administrador,
                                  ),
                          icon: const Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 18,
                          ),
                          label: const Text('Demo Admin'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Modo Demo Local funciona offline directo en tu dispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider auth) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'vecino@condominio.com',
              prefixIcon: Icon(Icons.email_outlined, size: 19),
            ),
            validator: (v) {
              if (v == null || !v.contains('@')) {
                return 'Ingresa un correo válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPassCtrl,
            obscureText: !_verPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
              suffixIcon: IconButton(
                icon: Icon(
                  _verPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                ),
                onPressed: () => setState(() => _verPassword = !_verPassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Mínimo 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: auth.cargando ? null : () => _enviarLogin(auth),
            child: Text(
              auth.cargando
                  ? 'Ingresando...'
                  : auth.supabaseConfigurado
                      ? 'Iniciar Sesión'
                      : 'Conectar Supabase e Ingresar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(AuthProvider auth) {
    final esAdmin = _rolRegistro == RolUsuario.administrador;
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Elige tu perfil',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RolSelectorCard(
                  icon: Icons.apartment_rounded,
                  title: 'Vecino',
                  subtitle: 'Tengo código',
                  selected: !esAdmin,
                  activeColor: AppColors.primary,
                  activeBg: AppColors.formalizedBg,
                  onTap: () =>
                      setState(() => _rolRegistro = RolUsuario.vecino),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RolSelectorCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Administrador',
                  subtitle: 'Creo edificio',
                  selected: esAdmin,
                  activeColor: AppColors.adminPrimary,
                  activeBg: AppColors.adminBg,
                  onTap: () =>
                      setState(() => _rolRegistro = RolUsuario.administrador),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regNombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              hintText: 'Ej. Franco García',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 19),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 3) {
                return 'Ingresa tu nombre (mín. 3 caracteres).';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined, size: 19),
            ),
            validator: (v) {
              if (v == null || !v.contains('@')) {
                return 'Ingresa un correo válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regPassCtrl,
            obscureText: !_verPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
              suffixIcon: IconButton(
                icon: Icon(
                  _verPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                ),
                onPressed: () => setState(() => _verPassword = !_verPassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Mínimo 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          if (!esAdmin) ...[
            TextFormField(
              controller: _regCodigoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código del condominio',
                hintText: 'Ej. AV-4821',
                prefixIcon: Icon(Icons.key_rounded, size: 19),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 4) {
                  return 'Ingresa el código de invitación.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regDptoCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Departamento o vivienda',
                hintText: 'Ej. Dpto. 301',
                prefixIcon: Icon(Icons.door_front_door_outlined, size: 19),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Indica tu departamento.';
                }
                return null;
              },
            ),
          ] else ...[
            TextFormField(
              controller: _regCondoNombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del condominio o edificio',
                hintText: 'Ej. Residencial Los Cedros',
                prefixIcon: Icon(Icons.domain_rounded, size: 19),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 3) {
                  return 'Ingresa el nombre del edificio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regCondoDirCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Dirección (opcional)',
                hintText: 'Ej. Av. Principal 420',
                prefixIcon: Icon(Icons.location_on_outlined, size: 19),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            style: esAdmin
                ? FilledButton.styleFrom(backgroundColor: AppColors.adminPrimary)
                : null,
            onPressed: auth.cargando ? null : () => _enviarRegistro(auth),
            child: Text(
              auth.cargando
                  ? 'Creando cuenta...'
                  : esAdmin
                      ? 'Crear Condominio y Cuenta Admin'
                      : 'Unirme al Condominio',
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabButton extends StatelessWidget {
  const _SegmentedTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RolSelectorCard extends StatelessWidget {
  const _RolSelectorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.activeColor,
    required this.activeBg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color activeColor;
  final Color activeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? activeBg : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? activeColor : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? activeColor : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogoConfigSupabase extends StatefulWidget {
  const _DialogoConfigSupabase({required this.auth});

  final AuthProvider auth;

  @override
  State<_DialogoConfigSupabase> createState() => _DialogoConfigSupabaseState();
}

class _DialogoConfigSupabaseState extends State<_DialogoConfigSupabase> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;

  @override
  void initState() {
    super.initState();
    final current = widget.auth.configSupabase;
    _urlCtrl = TextEditingController(text: current?.url ?? '');
    _keyCtrl = TextEditingController(text: current?.anonKey ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await widget.auth.configurarSupabase(
      url: _urlCtrl.text,
      anonKey: _keyCtrl.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Conectar con Supabase',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ingresa las credenciales públicas de tu proyecto Supabase para sincronizar vecinos en tiempo real.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Project URL',
                  hintText: 'https://tuproyecto.supabase.co',
                ),
                validator: (v) {
                  if (v == null || !v.trim().startsWith('http')) {
                    return 'Ingresa una URL válida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keyCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Anon Public Key',
                  hintText: 'eyJ...',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 20) {
                    return 'Ingresa la clave anon pública.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
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
