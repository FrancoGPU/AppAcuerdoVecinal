import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/negociacion_provider.dart';
import 'providers/reglamento_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/mediador_ia_service.dart';
import 'widgets/responsive_app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcuerdoVecinalApp());
}

/// Root application widget configured with Material 3 and MultiProvider state
/// for Authentication, Dynamic Condominium Bylaws, and Real-Time Negotiations.
class AcuerdoVecinalApp extends StatelessWidget {
  const AcuerdoVecinalApp({
    super.key,
    this.providerOverride,
    this.authOverride,
    this.reglamentoOverride,
  });

  final NegociacionProvider? providerOverride;
  final AuthProvider? authOverride;
  final ReglamentoProvider? reglamentoOverride;

  @override
  Widget build(BuildContext context) {
    final esTestConOverride = providerOverride != null;

    return MultiProvider(
      providers: [
        if (authOverride != null)
          ChangeNotifierProvider<AuthProvider>.value(value: authOverride!)
        else
          ChangeNotifierProvider<AuthProvider>(
            create: (_) {
              final auth = AuthProvider();
              if (!esTestConOverride) {
                auth.inicializar();
              }
              return auth;
            },
          ),
        if (reglamentoOverride != null)
          ChangeNotifierProvider<ReglamentoProvider>.value(
            value: reglamentoOverride!,
          )
        else
          ChangeNotifierProvider<ReglamentoProvider>(
            create: (ctx) => ReglamentoProvider(
              supabaseService: ctx.read<AuthProvider>().supabase,
            ),
          ),
        if (providerOverride != null)
          ChangeNotifierProvider<NegociacionProvider>.value(
            value: providerOverride!,
          )
        else
          ChangeNotifierProvider<NegociacionProvider>(
            create: (ctx) {
              final supabase = ctx.read<AuthProvider>().supabase;
              return NegociacionProvider(
                supabaseService: supabase,
                mediadorIaService: MediadorIaService(supabaseService: supabase),
              );
            },
          ),
      ],
      child: MaterialApp(
        title: 'AcuerdoVecinal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: esTestConOverride
            ? const HomeScreen()
            : const ResponsiveAppShell(
                child: _AppSessionRouter(),
              ),
      ),
    );
  }
}

class _AppSessionRouter extends StatefulWidget {
  const _AppSessionRouter();

  @override
  State<_AppSessionRouter> createState() => _AppSessionRouterState();
}

class _AppSessionRouterState extends State<_AppSessionRouter> {
  String _ultimaFirmaReglamento = '';
  String _ultimaFirmaNegociacion = '';

  void _sincronizarSiCambio(AuthProvider auth) {
    if (!auth.inicializado || !auth.estaAutenticado) {
      _ultimaFirmaReglamento = '';
      _ultimaFirmaNegociacion = '';
      return;
    }

    final firmaReglamento = [
      auth.condominioActual?.id ?? '',
      auth.esModoNube,
      auth.esModoDemo,
    ].join('|');

    final firmaNegociacion = [
      auth.usuarioActual?.id ?? '',
      auth.condominioActual?.id ?? '',
      auth.esModoNube,
      auth.esModoDemo,
    ].join('|');

    final sincronizarReglamento = firmaReglamento != _ultimaFirmaReglamento;
    final sincronizarNegociaciones =
        firmaNegociacion != _ultimaFirmaNegociacion;
    if (!sincronizarReglamento && !sincronizarNegociaciones) return;

    _ultimaFirmaReglamento = firmaReglamento;
    _ultimaFirmaNegociacion = firmaNegociacion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (sincronizarReglamento) {
        context.read<ReglamentoProvider>().sincronizarConSesion(
              condominioId: auth.condominioActual?.id,
              esNube: auth.esModoNube,
            );
      }
      if (sincronizarNegociaciones) {
        context.read<NegociacionProvider>().sincronizarConSesion(
              usuario: auth.usuarioActual,
              esNube: auth.esModoNube,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _sincronizarSiCambio(auth);

    if (!auth.inicializado) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text(
                'Iniciando AcuerdoVecinal...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.estaAutenticado) {
      return const AuthScreen();
    }

    if (auth.esAdministrador) {
      return const AdminDashboardScreen();
    }

    return const HomeScreen();
  }
}
