import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/usuario_model.dart';
import '../providers/auth_provider.dart';

/// Authentication, Condominium onboarding (Admin vs Neighbor), and Demo entry screen.
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 44, 20, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.heroDark, AppColors.heroBlue],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _abrirConfiguracionSupabase(auth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: auth.supabaseConfigurado
                              ? AppColors.acceptedBtn.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: auth.supabaseConfigurado
                                ? AppColors.acceptedBtn
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              auth.supabaseConfigurado
                                  ? Icons.cloud_done_outlined
                                  : Icons.settings_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              auth.supabaseConfigurado
                                  ? 'Nube lista'
                                  : 'Configurar nube',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'AcuerdoVecinal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mediación vecinal con Método Harvard, reglamento administrado por tu condominio y Mediador IA.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (auth.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.rejectedBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.rejectedBtn.withValues(alpha: 0.4),
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
                  const SizedBox(height: 12),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TabPillButton(
                                label: 'Ingresar',
                                selected: _tabIndex == 0,
                                onTap: () {
                                  auth.limpiarError();
                                  setState(() => _tabIndex = 0);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _TabPillButton(
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
                        const SizedBox(height: 16),
                        if (_tabIndex == 0)
                          _buildLoginForm(auth)
                        else
                          _buildRegisterForm(auth),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  color: AppColors.formalizedBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: AppColors.formalizedText,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Modo Demo Local (Sin registro ni internet)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.formalizedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Prueba al instante los perfiles Vecino, Administrador de Reglamento y Mediador IA directo en tu dispositivo.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.adminPrimary,
                                  side: const BorderSide(
                                    color: AppColors.adminPrimary,
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
                      ],
                    ),
                  ),
                ),
              ],
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
          const SizedBox(height: 16),
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
            'Tipo de usuario',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment_rounded, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Vecino',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  selected: !esAdmin,
                  onSelected: (_) =>
                      setState(() => _rolRegistro = RolUsuario.vecino),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Administrador',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  selected: esAdmin,
                  onSelected: (_) =>
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
                hintText: 'Ej. AV-4821 (te lo da el Administrador)',
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
                labelText: 'Número de departamento o vivienda',
                hintText: 'Ej. Dpto. 301',
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
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
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

class _TabPillButton extends StatelessWidget {
  const _TabPillButton({
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
      color: selected ? AppColors.primary : AppColors.argumentBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
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
