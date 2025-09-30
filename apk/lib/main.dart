// -----------------------------------------------------------------------------
// main.dart
// Arquivo principal de inicialização do app.
// Configura o Supabase, carrega variáveis de ambiente, e gerencia o tema global
// usando Provider (ThemeProvider).
// -----------------------------------------------------------------------------

import 'package:apk/providers/theme_provider.dart';
import 'package:apk/user/favorito/favoritos.dart';
import 'package:apk/user/perfil/config.dart';
import 'package:apk/user/perfil/perfil.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Telas principais
import 'user/dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'user/splash_screen.dart';

// Telas de autenticação
import 'auth/login_page.dart';
import 'auth/registro_page.dart';
import 'auth/recuperacao_page.dart';

// Telas adicionais de perfil
import 'user/perfil/termos_page.dart';
import 'user/perfil/politica_privacidade_page.dart';

// -----------------------------------------------------------------------------
// Função principal
// -----------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregando variáveis de ambiente (.env)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env carregado com sucesso!");
  } catch (e) {
    debugPrint("❌ Erro ao carregar .env: $e");
  }

  // Inicializando Supabase
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint("✅ Supabase conectado com sucesso!");
  } catch (e) {
    debugPrint("❌ Erro ao conectar Supabase: $e");
  }

  // Rodando app com Provider para controlar o tema global
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// -----------------------------------------------------------------------------
// Classe principal do aplicativo
// -----------------------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumindo o estado do ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Controla qual tema usar: claro, escuro ou automático
      themeMode: themeProvider.themeMode,

      // Temas definidos no ThemeProvider
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,

      // Definindo rota inicial
      initialRoute: '/splash',

      // Rotas nomeadas principais
      routes: {
        // Autenticação
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),

        // Usuário
        '/splash': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/perfil': (context) => const PerfilPage(),
        '/salas': (context) => const SalasFavoritasPage(),
        '/config': (context) => const ConfigPage(),
        '/termos': (context) => const TermosPage(),
        '/politica': (context) => const PoliticaPrivacidadePage(),

        // Admin
        '/admindashboard': (context) => const AdminDashboardPage(),
      },
    );
  }
}
