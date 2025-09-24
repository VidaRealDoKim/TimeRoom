import 'package:apk/providers/theme_provider.dart';
import 'package:apk/user/favorito/favoritos.dart';
import 'package:apk/user/perfil/config.dart';
import 'package:apk/user/perfil/perfil.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// -----------------------------------------------------------------------------
// Importações internas (telas principais do projeto)
// -----------------------------------------------------------------------------
import 'user/dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'user/splash_screen.dart';

// Auth
import 'auth/login_page.dart';
import 'auth/registro_page.dart';
import 'auth/recuperacao_page.dart';

// -----------------------------------------------------------------------------
// Função principal do aplicativo
// -----------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env carregado com sucesso!");
  } catch (e) {
    print("❌ Erro ao carregar .env: $e");
  }

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("✅ Supabase conectado com sucesso!");
  } catch (e) {
    print("❌ Erro ao conectar Supabase: $e");
  }

  // ATUALIZAÇÃO: Envolvemos o App com o ChangeNotifierProvider.
  // Isso disponibiliza o ThemeProvider para toda a árvore de widgets.
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
    // ATUALIZAÇÃO: Consumimos o ThemeProvider para obter o estado do tema.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // ATUALIZAÇÃO: As propriedades de tema agora são controladas pelo Provider.
      themeMode: themeProvider.themeMode,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,

      initialRoute: '/splash',
      routes: {
        // Telas Auth
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),

        // Telas principais do usuário
        '/splash': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/perfil': (context) => const PerfilPage(),
        '/salas': (context) => const SalasFavoritasPage(),
        '/config': (context) => const ConfigPage(),

        // Telas Admin
        '/admindashboard': (context) => const AdminDashboardPage(),
      },
    );
  }
}
