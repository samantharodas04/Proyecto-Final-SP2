import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'providers/usuario_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/clientes_screen.dart';
import 'screens/deudas_screen.dart';
import 'screens/items_screen.dart';
import 'screens/deudas_home_screen.dart';
import 'screens/best_sellers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pagos_deuda_screen.dart';
import 'screens/cliente_register.dart';
import 'screens/cliente_login_screen.dart';
import 'screens/cliente_home_screen.dart';
import 'screens/cliente_deudas_screen.dart';
import 'screens/cliente_pagos_screen.dart';
import 'screens/cliente_deudas_por_aprobar_screen.dart'; // 👈 importante

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("0f89ee35-077f-4411-a0b3-ad2ae2ff1997");
  await OneSignal.Notifications.requestPermission(true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],

      initialRoute: 'login',

      routes: {
        'login': (_) => const LoginScreen(),
        'register': (_) => const RegisterScreen(),
        'home': (_) => const HomeScreen(),
        'clientes': (_) => const ClientesScreen(),
        'deudas': (_) => const DeudasScreen(),
        'items': (_) => const ItemsScreen(),
        'deudas_home': (_) => const DeudasHomeScreen(),
        'best_sellers': (_) => const BestSellersScreen(),
        'dashboard': (_) => const DashboardScreen(),
        // PagosDeudaScreen necesita deudaId real, aquí solo dummy:
        'pagos_deuda': (_) => const PagosDeudaScreen(deudaId: 0),
        'cliente_register': (_) => const ClienteRegisterScreen(),
        'cliente_login': (_) => const ClienteLoginScreen(),
      },

      onGenerateRoute: (settings) {
        // 👇 cliente_home
        if (settings.name == 'cliente_home') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ClienteHomeScreen(
              clienteId: args['clienteId'] as int,
              nombre: args['nombre'] as String,
              dpi: args['dpi'] as String,
            ),
          );
        }

        // 👇 cliente_deudas
        if (settings.name == 'cliente_deudas') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ClienteDeudasScreen(
              clienteId: args['clienteId'] as int,
              nombre: args['nombre'] as String,
            ),
          );
        }

        // 👇 NUEVO: cliente_deudas_por_aprobar
        if (settings.name == 'cliente_deudas_por_aprobar') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ClienteDeudasPorAprobarScreen(
              clienteId: args['clienteId'] as int,
              nombre: args['nombre'] as String,
            ),
          );
        }

        return null;
      },
    );
  }
}
