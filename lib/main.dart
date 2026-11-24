import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/negociacion_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcuerdoVecinalApp());
}

/// Root application widget configured with Material 3 and Provider state.
class AcuerdoVecinalApp extends StatelessWidget {
  const AcuerdoVecinalApp({
    super.key,
    this.providerOverride,
  });

  final NegociacionProvider? providerOverride;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (providerOverride != null)
          ChangeNotifierProvider<NegociacionProvider>.value(
            value: providerOverride!,
          )
        else
          ChangeNotifierProvider<NegociacionProvider>(
            create: (_) => NegociacionProvider()..inicializar(),
          ),
      ],
      child: MaterialApp(
        title: 'AcuerdoVecinal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
