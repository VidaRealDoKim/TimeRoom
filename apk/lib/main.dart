import 'package:apk/providers/theme_provider.dart';
import 'package:apk/user/favorito/favoritos.dart';
import 'package:apk/user/perfil/config.dart';
import 'package:apk/user/perfil/perfil.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:apk/user/perfil/notification_service.dart';

// Telas principais
import 'user/dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'user/splash_screen.dart';

// Auth
import 'auth/login_page.dart';
import 'auth/registro_page.dart';
import 'auth/recuperacao_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializa .env
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env carregado com sucesso!");
  } catch (e) {
    print("❌ Erro ao carregar .env: $e");
  }

  // 2. Inicializa Supabase
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("✅ Supabase conectado com sucesso!");
  } catch (e) {
    print("❌ Erro ao conectar Supabase: $e");
  }

  // 3. Inicializa notificações locais
  try {
    await NotificationService().init();
    print("✅ Notification Service inicializado com sucesso!");
  } catch (e) {
    print("❌ Erro ao inicializar Notification Service: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/splash': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/perfil': (context) => const PerfilPage(),
        '/salas': (context) => const SalasFavoritasPage(),
        '/config': (context) => const ConfigPage(),
        '/admindashboard': (context) => const AdminDashboardPage(),
      },
    );
  }
}
