import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/usuario_model.dart';
import '../providers/auth_provider.dart';

/// Centered, symmetric Authentication, Condominium onboarding, and Demo screen.
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEF4FF),
              AppColors.background,
              AppColors.background,
            ],
            stops: [0.0, 0.36, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 48).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.heroBlue,
                                    AppColors.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.primary.withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.handshake_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'AcuerdoVecinal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Mediación vecinal • Método Harvard',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
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
                                  const SizedBox(height: 16),
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
                                const SizedBox(height: 20),
                                if (_tabIndex == 0)
                                  _buildLoginForm(auth)
                                else
                                  _buildRegisterForm(auth),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'Modo demostración offline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.9),
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
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
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
                                      color: AppColors.adminPrimary
                                          .withValues(alpha: 0.4),
                                    ),
                                    minimumSize: const Size(0, 44),
                                  ),
                                  onPressed: auth.cargando
                                      ? null
                                      : () => auth.entrarModoDemo(
                                            rolInicial:
                                                RolUsuario.administrador,
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
                          if (!auth.configuradoPorEntorno) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  minimumSize: const Size(0, 34),
                                ),
                                onPressed: () =>
                                    _abrirConfiguracionSupabase(auth),
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  size: 15,
                                ),
                                label: Text(
                                  auth.supabaseConfigurado
                                      ? 'Cambiar servidor (desarrollo)'
                                      : 'Configurar servidor (desarrollo)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _campoDecoration({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      fillColor: AppColors.background,
      prefixIcon: Icon(icon, size: 19, color: AppColors.textSecondary),
      suffixIcon: suffix,
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
            decoration: _campoDecoration(
              label: 'Correo electrónico',
              hint: 'vecino@condominio.com',
              icon: Icons.email_outlined,
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
            decoration: _campoDecoration(
              label: 'Contraseña',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
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
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: auth.cargando ? null : () => _enviarLogin(auth),
              child: Text(
                auth.cargando
                    ? 'Ingresando...'
                    : auth.supabaseConfigurado
                        ? 'Iniciar Sesión'
                        : 'Conectar Supabase e Ingresar',
              ),
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
          Row(
            children: [
              Expanded(
                child: _RolSelectorCard(
                  icon: Icons.apartment_rounded,
                  title: 'Vecino',
                  subtitle: 'Con código',
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
                  subtitle: 'Nuevo edificio',
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
            decoration: _campoDecoration(
              label: 'Nombre completo',
              hint: 'Ej. Franco García',
              icon: Icons.person_outline_rounded,
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
            decoration: _campoDecoration(
              label: 'Correo electrónico',
              icon: Icons.email_outlined,
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
            decoration: _campoDecoration(
              label: 'Contraseña',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
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
              decoration: _campoDecoration(
                label: 'Código del condominio',
                hint: 'Ej. AV-4821',
                icon: Icons.key_rounded,
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
              decoration: _campoDecoration(
                label: 'Departamento o vivienda',
                hint: 'Ej. Dpto. 301',
                icon: Icons.door_front_door_outlined,
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
              decoration: _campoDecoration(
                label: 'Nombre del condominio o edificio',
                hint: 'Ej. Residencial Los Cedros',
                icon: Icons.domain_rounded,
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
              decoration: _campoDecoration(
                label: 'Dirección (opcional)',
                hint: 'Ej. Av. Principal 420',
                icon: Icons.location_on_outlined,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: esAdmin
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                    )
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? activeColor : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? activeColor : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
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
